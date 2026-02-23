part of '../blueprint.dart';

/// Business Logic layer — i.e. the **ViewModel**.
///
/// Subclasses manage their own [Model] dependencies, allowing a single
/// ViewModel to operate on **multiple** data sources while keeping full type
/// safety.
///
/// ```dart
/// final class CounterViewModel extends ViewModel {
///   final CounterModel _counter;
///   final LogModel _log;
///
///   CounterViewModel({
///     required CounterModel counterModel,
///     required LogModel logModel,
///   })  : _counter = counterModel,
///         _log = logModel;
///
///   // ... business logic using both models ...
/// }
/// ```
abstract base class ViewModel extends ChangeNotifier {}
