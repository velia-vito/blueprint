part of '../blueprint.dart';

/// The **ViewModel** — business logic that sits between [Model]s and a [Fragment].
///
/// A ViewModel receives its [Model] dependencies through the constructor,
/// which means it can hold **any number** of Models with full compile-time
/// type safety. Call [notifyListeners] after every mutation so the UI rebuilds.
///
/// ```dart
/// final class AppViewModel extends ViewModel {
///   final CounterModel _counter;
///   final DateModel _date;
///
///   AppViewModel({
///     required CounterModel counterModel,
///     required DateModel dateModel,
///   })  : _counter = counterModel,
///         _date = dateModel;
///
///   int get count => _counter.count;
///   DateTime get selectedDate => _date.selected;
///
///   void increment() {
///     _counter.increment();
///     notifyListeners();
///   }
///
///   void selectDate(DateTime d) {
///     _date.select(d);
///     notifyListeners();
///   }
/// }
/// ```
abstract base class ViewModel extends ChangeNotifier {}
