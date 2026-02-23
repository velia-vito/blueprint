part of '../blueprint.dart';

/// The **Model** — a quantum of data / API / task interaction.
///
/// Subclass [Model] to hold data and expose CRUD operations. A Model should
/// contain **no** business logic and **no** UI code.
///
/// ```dart
/// final class CounterModel extends Model {
///   int _count = 0;
///   int get count => _count;
///
///   void increment() => _count += 1;
///   void decrement() => _count -= 1;
/// }
/// ```
abstract base class Model {}
