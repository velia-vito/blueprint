part of '../blueprint.dart';

/// A Business Logic `Service` — i.e. the ViewModel.
///
/// Subclasses manage their own [Repository] dependencies, allowing a single
/// Service to operate on **multiple** data sources while keeping full type
/// safety.
///
/// ```dart
/// final class CounterService extends Service {
///   final CounterRepository _counter;
///   final LogRepository _log;
///
///   CounterService({
///     required CounterRepository counterRepository,
///     required LogRepository logRepository,
///   })  : _counter = counterRepository,
///         _log = logRepository;
///
///   // ... business logic using both repositories ...
/// }
/// ```
abstract base class Service extends ChangeNotifier {}