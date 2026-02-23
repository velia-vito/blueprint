// ignore_for_file: avoid_print
/// Example: Counter + Date Selection app using the blueprint package.
///
/// Two independent Models (CounterModel, DateModel) are combined in a single
/// ViewModel (AppViewModel) and rendered by one Fragment (AppFragment).
///
/// This file is a self-contained demonstration. Run it with:
///   flutter run example/main.dart
library;

import 'package:blueprint/blueprint.dart';
import 'package:flutter/widgets.dart';

// ---------------------------------------------------------------------------
//  Models — pure data, no UI, no business logic
// ---------------------------------------------------------------------------

/// Holds a simple integer counter.
final class CounterModel extends Model {
  int _count = 0;

  /// Current count value.
  int get count => _count;

  /// Add 1 to the counter.
  void increment() => _count += 1;

  /// Subtract 1 from the counter.
  void decrement() => _count -= 1;
}

/// Holds a selected date.
final class DateModel extends Model {
  DateTime _selected = DateTime(2026);

  /// Currently selected date.
  DateTime get selected => _selected;

  /// Replace the selected date.
  void select(DateTime date) => _selected = date;
}

// ---------------------------------------------------------------------------
//  ViewModel — business logic, owns both Models
// ---------------------------------------------------------------------------

/// Combines counter logic and date-selection logic in one ViewModel.
final class AppViewModel extends ViewModel {
  final CounterModel _counter;
  final DateModel _date;

  /// Creates an [AppViewModel] with the given [counterModel] and [dateModel].
  AppViewModel({
    required CounterModel counterModel,
    required DateModel dateModel,
  })  : _counter = counterModel,
        _date = dateModel;

  // ── Counter ──────────────────────────────────────────────────────────────
  /// Current counter value.
  int get count => _counter.count;

  /// Increment counter and notify the UI.
  void increment() {
    _counter.increment();
    notifyListeners();
  }

  /// Decrement counter and notify the UI.
  void decrement() {
    _counter.decrement();
    notifyListeners();
  }

  // ── Date ─────────────────────────────────────────────────────────────────
  /// Currently selected date.
  DateTime get selectedDate => _date.selected;

  /// Change the selected date and notify the UI.
  void selectDate(DateTime date) {
    _date.select(date);
    notifyListeners();
  }

  // ── Derived / cross-model logic ──────────────────────────────────────────
  /// Human-readable summary combining both Models.
  String get summary =>
      'Count: ${_counter.count}, '
      'Date: ${_date.selected.toIso8601String().split("T").first}';
}

// ---------------------------------------------------------------------------
//  Fragment — the View
// ---------------------------------------------------------------------------

/// Renders counter, date, and a combined summary.
final class AppFragment extends Fragment<AppViewModel> {
  @override
  Widget buildFragment(
      BuildContext context, AppViewModel viewModel, Widget? child) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Counter: ${viewModel.count}'),
          Text('Date: ${viewModel.selectedDate.toIso8601String().split("T").first}'),
          const SizedBox(height: 8),
          Text('Summary: ${viewModel.summary}'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  App entry point
// ---------------------------------------------------------------------------

void main() {
  runApp(
    Connector<AppFragment, AppViewModel>(
      fragment: AppFragment(),
      viewModel: AppViewModel(
        counterModel: CounterModel(),
        dateModel: DateModel(),
      ),
    ),
  );
}
