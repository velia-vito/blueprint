## 0.0.2

* Streamlined Object-View-ViewModel pattern for simpler usage.
* **Renamed classes for MVVM clarity:**
  - `Repository` → `Model` (data layer)
  - `Service` → `ViewModel` (business logic layer)
  - `Fragment` stays as `Fragment` (UI layer; `View` conflicts with Flutter's `View` widget)
  - `UtilContainer` → `Connector` (wires Fragment to ViewModel)
* `ViewModel` no longer requires a generic `Model` type parameter — ViewModels now manage their own model dependencies via their constructor, enabling **multiple objects** per ViewModel.
* `Connector` simplified from 3 generic parameters to 2 (`Fragment` + `ViewModel`).
* Updated documentation with revised examples reflecting the new API.
* Added comprehensive unit and widget tests.
* Added `flutter pub get`, `flutter analyze`, and `flutter test` steps to CI workflow.

## 0.0.1

* Initial release.
