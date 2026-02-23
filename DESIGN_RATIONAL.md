# Design Rationale

## Overview

This document explains the design decisions behind the `blueprint` package —
a lightweight [Model–View–ViewModel](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)
(MVVM) framework for Flutter.

The framework exposes four classes:

| Class | MVVM Role | Purpose |
|-------|-----------|---------|
| `Model` | **Model** | Data / API / Task interaction — CRUD only |
| `ViewModel` | **ViewModel** | Business logic; owns one or more `Model`s |
| `Fragment` | **View** | A fragment of UI bound to a `ViewModel` |
| `Connector` | *(wiring)* | Connects a `Fragment` to its `ViewModel` |

---

## 1. Naming Decisions

### Why `Model` (not `Repository`)

The original name `Repository` implies a persistence-layer pattern (e.g. the
Repository pattern from Domain-Driven Design). In the MVVM context, the data
layer is the **Model** — a broader, more familiar term that matches both the
Wikipedia description and most MVVM literature.

### Why `ViewModel` (not `Service`)

`Service` is ambiguous in Flutter / Dart codebases — it could refer to a web
service, a background service, a platform channel wrapper, etc. `ViewModel` is
the canonical MVVM term for the business-logic layer that sits between the
Model and the View.

### Why `Fragment` (not `View`)

Flutter ≥ 3.10 exports a `View` widget from `package:flutter/widgets.dart`.
Naming our class `View` would clash with this framework-level symbol, forcing
users to write `hide View` or use prefixed imports. `Fragment` avoids the
conflict while remaining descriptive — it represents *a fragment of UI* that
is driven by a ViewModel.

### Why `Connector` (not `UtilContainer`)

`UtilContainer` was a generic, non-descriptive name. `Connector` communicates
exactly what it does: it *connects* a View (`Fragment`) to a `ViewModel`.

---

## 2. Structural Changes

### 2a. Removed the generic `Model` type parameter from `ViewModel`

**Before (original API):**

```dart
// Service was hard-bound to exactly one Repository via a generic
abstract base class Service<Repo extends Repository> extends ChangeNotifier {
  late final Repo _repository;
  Repo get repository => _repository;
  void bind(Repo repository) => _repository = repository;
}
```

**After (current API):**

```dart
// ViewModel has no generic — it owns its Models directly
abstract base class ViewModel extends ChangeNotifier {}

// Subclass declares its own dependencies via the constructor
final class CounterViewModel extends ViewModel {
  final CounterModel _counter;
  final LogModel _log;

  CounterViewModel({
    required CounterModel counterModel,
    required LogModel logModel,
  })  : _counter = counterModel,
        _log = logModel;
}
```

**Why:** The single-generic design locked each ViewModel to *one* data source.
Constructor injection removes that limit, keeps compile-time type safety, and
eliminates the `late final` + `bind()` ceremony.

### 2b. Simplified `Connector` from 3 generics to 2

**Before (original API):**

```dart
UtilContainer<CounterFragment, CounterService, CounterRepository>(
  fragment: CounterFragment(),
  service: CounterService(),
  repository: CounterRepository(),
);
```

**After (current API):**

```dart
Connector<CounterFragment, CounterViewModel>(
  fragment: CounterFragment(),
  viewModel: CounterViewModel(counterModel: CounterModel()),
);
```

**Why:** Since the ViewModel now owns its own Models, the `Connector` no longer
needs a third generic or parameter. It just wires the View to the ViewModel —
that's it.

### 2c. Simplified `Fragment` type constraint

**Before:** `Fragment<Serv extends Service<Repository>>`
**After:** `Fragment<VM extends ViewModel>`

This follows naturally from removing the generic on `ViewModel`.

---

## 3. Alternative Designs Considered

### A. Keep single generic, add a second optional generic

```dart
abstract base class ViewModel<M1 extends Model, M2 extends Model?> { ... }
```

**Rejected because:** This scales poorly — every additional Model requires
another generic parameter, leading to verbose signatures
(`ViewModel<ModelA, ModelB, ModelC, ...>`). It also forces unused type parameters
on ViewModels that need only one model.

### B. Model list / map inside ViewModel base class

```dart
abstract base class ViewModel extends ChangeNotifier {
  final List<Model> _models = [];
  T model<T extends Model>() => _models.whereType<T>().first;
}
```

**Rejected because:** Retrieving a model by type at runtime loses compile-time
type safety and incurs a runtime lookup cost on every access. It also obscures
which models a ViewModel actually depends on.

### C. Mixin-based multi-model support

```dart
mixin UsesCounterModel on ViewModel { late final CounterModel counterModel; }
mixin UsesLogModel on ViewModel { late final LogModel logModel; }

class MyViewModel extends ViewModel with UsesCounterModel, UsesLogModel { ... }
```

**Rejected because:** While type-safe, this introduces significant ceremony
(a dedicated mixin per model type) without a clear benefit over simply
accepting models through the constructor. It also requires a separate `bind`
step for each mixin, reintroducing the `late final` pattern the redesign aims
to remove.

### D. Dart Records as a type-safe model tuple

```dart
abstract base class ViewModel<Objects extends Record> extends ChangeNotifier {
  final Objects objects;
  ViewModel(this.objects);
}

final class CounterViewModel extends ViewModel<(CounterModel, LogModel)> {
  CounterViewModel(super.objects);
  CounterModel get counter => objects.$1;
  LogModel get log => objects.$2;
}
```

**Rejected because:** While compile-time type-safe, positional Record fields
(`$1`, `$2`) are cryptic and hinder readability — a developer cannot tell at a
glance what each field represents. Named constructor parameters
(`counterModel:`) are self-documenting. Records for dependency injection is
also non-idiomatic in Dart / Flutter.

### E. `registerObject<T>()` service-locator pattern

```dart
abstract base class ViewModel extends ChangeNotifier {
  final Map<Type, Model> _objects = {};
  void registerObject<T extends Model>(T model) => _objects[T] = model;
  T object<T extends Model>() => _objects[T] as T;
}
```

**Rejected because:** This is a service-locator anti-pattern. It trades
compile-time type safety for runtime casting (`as T`), provides no compile-time
guarantee that all required models have been registered, and obscures the
actual dependencies of a ViewModel behind a dynamic map.

### F. Status quo — keep single generic with `bind()`

Keeping `Service<Repo>` and adding a second mechanism for extra models.

**Rejected because:** It preserves the single-object limitation of the core API,
while any "escape hatch" for additional models would be inconsistent with the
primary pattern and confusing for users.

---

## 4. Why the Implemented Design Was Chosen

The constructor-injection approach was selected because it:

1. **Supports multiple data sources naturally.** A ViewModel declares exactly
   the models it needs as constructor parameters — no limit on count, no extra
   generics, no runtime lookups.

2. **Minimises mental overhead.** The class names (`Model`, `ViewModel`,
   `Fragment`, `Connector`) map directly to MVVM concepts. `Connector` drops
   from 3 type parameters / 3 arguments to 2 / 2. The mental model is simply:
   *"Connector wires a Fragment to a ViewModel; the ViewModel owns its Models."*

3. **Preserves full type safety.** Model types are checked at compile time
   through the ViewModel constructor — no `dynamic`, no casting.

4. **Improves testability.** Models are explicit constructor dependencies,
   making it trivial to inject mocks or fakes without any `bind()` ceremony.

5. **Optimises for performance.** Removing the `late final` indirection and the
   extra `bind()` call eliminates one layer of initialisation. The ViewModel
   accesses its models through direct `final` fields — the fastest possible
   Dart field access.

6. **Follows Dart idioms.** Constructor injection is the standard Dart pattern
   for declaring dependencies; `late final` with a separate setter is generally
   discouraged when constructor injection is viable.

