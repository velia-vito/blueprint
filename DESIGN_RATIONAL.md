# Design Rationale

## Changes Made

### 1. Removed generic `Repository` type parameter from `Service`

**Before:** `Service<Repo extends Repository>` — each Service was hard-bound to
exactly one Repository type via a generic parameter and a `late final` field
set through a `bind()` method.

**After:** `Service extends ChangeNotifier` — Services manage their own
Repository dependencies directly, typically received through their constructor.

### 2. Simplified `UtilContainer` from 3 generics to 2

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
UtilContainer<CounterFragment, CounterService>(
  fragment: CounterFragment(),
  service: CounterService(counterRepository: CounterRepository()),
);
```

The container no longer needs to know about Repository types at all — it only
wires the View (Fragment) to the ViewModel (Service).

### 3. Updated `Fragment` type constraint

`Fragment<Serv extends Service<Repository>>` → `Fragment<Serv extends Service>`

This follows naturally from the Service change above.

---

## Alternative Designs Considered

### A. Keep single generic, add a second optional generic

```dart
abstract base class Service<R1 extends Repository, R2 extends Repository?> { ... }
```

**Rejected because:** This scales poorly — every additional Repository requires
another generic parameter, leading to verbose signatures
(`Service<RepoA, RepoB, RepoC, ...>`). It also forces unused type parameters
on services that need only one repository.

### B. Repository list / map inside Service base class

```dart
abstract base class Service extends ChangeNotifier {
  final List<Repository> _repositories = [];
  T repo<T extends Repository>() => _repositories.whereType<T>().first;
}
```

**Rejected because:** Retrieving a repository by type at runtime loses
compile-time type safety and incurs a runtime lookup cost on every access.
It also obscures which repositories a Service actually depends on.

### C. Mixin-based multi-repository support

```dart
mixin UsesCounterRepo on Service { late final CounterRepository counterRepo; }
mixin UsesLogRepo on Service { late final LogRepository logRepo; }

class MyService extends Service with UsesCounterRepo, UsesLogRepo { ... }
```

**Rejected because:** While type-safe, this introduces significant ceremony
(a dedicated mixin per repository type) without a clear benefit over simply
accepting repositories through the constructor. It also requires a separate
`bind` step for each mixin, reintroducing the `late final` pattern the
redesign aims to remove.

### D. Status quo — keep single generic with `bind()`

Keeping `Service<Repo>` and adding a second mechanism for extra repositories.

**Rejected because:** It preserves the single-object limitation of the core API,
while any "escape hatch" for additional repositories would be inconsistent with
the primary pattern and confusing for users.

---

## Why the Implemented Design Was Chosen

The constructor-injection approach was selected because it:

1. **Supports multiple objects naturally.** A Service declares exactly the
   repositories it needs as constructor parameters — no limit on count, no extra
   generics, no runtime lookups.

2. **Is simpler to use.** `UtilContainer` drops from 3 generic parameters to 2,
   and from 3 named arguments to 2. The mental model becomes: *"The container
   connects a View to a ViewModel; the ViewModel owns its data sources."*

3. **Preserves full type safety.** Repository types are checked at compile time
   through the Service constructor signature — no `dynamic`, no casting.

4. **Improves testability.** Repositories are explicit constructor dependencies,
   making it trivial to inject mocks or fakes without any `bind()` ceremony.

5. **Optimises for performance.** Removing the `late final` indirection and the
   extra `bind()` call eliminates one layer of initialization. The Service
   accesses its repositories through direct final fields — the fastest possible
   Dart field access.

6. **Follows Dart idioms.** Constructor injection is the standard Dart pattern
   for declaring dependencies; `late final` with a separate setter method is
   generally discouraged when constructor injection is viable.
