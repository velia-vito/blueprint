# Design Rationale

## Changes Made

### 1. Renamed classes to match standard MVVM terminology

| Before | After | Rationale |
|--------|-------|-----------|
| `Repository` | `Model` | Standard MVVM data-layer term |
| `Service` | `ViewModel` | Eliminates "service" ambiguity (web service? backend?) |
| `Fragment` | `Fragment` *(kept)* | `View` conflicts with Flutter's `View` widget |
| `UtilContainer` | `Connector` | Drops meaningless "Util"; describes its purpose |

### 2. Removed generic `Model` type parameter from `ViewModel`

**Before:** `Service<Repo extends Repository>` — each Service was hard-bound to
exactly one Repository type via a generic parameter and a `late final` field
set through a `bind()` method.

**After:** `ViewModel extends ChangeNotifier` — ViewModels manage their own
Model dependencies directly, typically received through their constructor.

### 3. Simplified `Connector` from 3 generics to 2

**Before:**
```dart
UtilContainer<CounterFragment, CounterService, CounterRepository>(
  fragment: CounterFragment(),
  service: CounterService(),
  repository: CounterRepository(),
);
```

**After:**
```dart
Connector<CounterFragment, CounterViewModel>(
  fragment: CounterFragment(),
  viewModel: CounterViewModel(counterModel: CounterModel()),
);
```

The connector no longer needs to know about Model types at all — it only
wires the View (Fragment) to the ViewModel.

### 4. Updated `Fragment` type constraint

`Fragment<Serv extends Service<Repository>>` → `Fragment<VM extends ViewModel>`

This follows naturally from the ViewModel change above.

---

## Alternative Designs Considered

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

**Rejected because:** Retrieving a model by type at runtime loses
compile-time type safety and incurs a runtime lookup cost on every access.
It also obscures which models a ViewModel actually depends on.

### C. Mixin-based multi-model support

```dart
mixin UsesCounterModel on ViewModel { late final CounterModel counterModel; }
mixin UsesLogModel on ViewModel { late final LogModel logModel; }

class MyViewModel extends ViewModel with UsesCounterModel, UsesLogModel { ... }
```

**Rejected because:** While type-safe, this introduces significant ceremony
(a dedicated mixin per model type) without a clear benefit over simply
accepting models through the constructor. It also requires a separate
`bind` step for each mixin, reintroducing the `late final` pattern the
redesign aims to remove.

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
(`counterModel:`) are self-documenting. Records for dependency injection
is also non-idiomatic in Dart/Flutter.

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
guarantee that all required models have been registered, and obscures
the actual dependencies of a ViewModel behind a dynamic map.

### F. Status quo — keep single generic with `bind()`

Keeping `Service<Repo>` and adding a second mechanism for extra models.

**Rejected because:** It preserves the single-object limitation of the core API,
while any "escape hatch" for additional models would be inconsistent with
the primary pattern and confusing for users.

---

## Why the Implemented Design Was Chosen

The constructor-injection approach was selected because it:

1. **Supports multiple objects naturally.** A ViewModel declares exactly the
   models it needs as constructor parameters — no limit on count, no extra
   generics, no runtime lookups.

2. **Is simpler to use.** `Connector` drops from 3 generic parameters to 2,
   and from 3 named arguments to 2. The mental model becomes: *"The connector
   wires a View to a ViewModel; the ViewModel owns its data sources."*

3. **Preserves full type safety.** Model types are checked at compile time
   through the ViewModel constructor signature — no `dynamic`, no casting.

4. **Improves testability.** Models are explicit constructor dependencies,
   making it trivial to inject mocks or fakes without any `bind()` ceremony.

5. **Optimises for performance.** Removing the `late final` indirection and the
   extra `bind()` call eliminates one layer of initialization. The ViewModel
   accesses its models through direct final fields — the fastest possible
   Dart field access.

6. **Follows Dart idioms.** Constructor injection is the standard Dart pattern
   for declaring dependencies; `late final` with a separate setter method is
   generally discouraged when constructor injection is viable.
