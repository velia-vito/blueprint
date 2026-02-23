## 0.0.2

* Streamlined Object-View-ViewModel pattern for simpler usage.
* `Service` no longer requires a generic `Repository` type parameter — services now manage their own repository dependencies via their constructor, enabling **multiple objects** per ViewModel.
* `UtilContainer` simplified from 3 generic parameters to 2 (`Fragment` + `Service`); the `repository` parameter has been removed.
* Updated documentation with revised examples reflecting the new API.
* Added comprehensive unit and widget tests.

## 0.0.1

* Initial release.
