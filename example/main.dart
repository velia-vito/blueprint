/// Example: Interactive Counter + Date Selection app using blueprint.
///
/// Two independent Models ([CounterModel], [DateModel]) are combined in a
/// single ViewModel ([AppViewModel]) and rendered by one Fragment
/// ([AppFragment]). The Fragment uses Material Design widgets so you can
/// actually tap buttons and pick dates.
///
/// Run with:
///
/// ```sh
/// cd example && flutter run
/// ```
library;

import 'package:blueprint/blueprint.dart';
import 'package:flutter/material.dart';

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
//  Fragment — the View (Material Design)
// ---------------------------------------------------------------------------

/// Interactive UI with tappable + / − buttons and a date picker.
final class AppFragment extends Fragment<AppViewModel> {
  @override
  Widget buildFragment(
      BuildContext context, AppViewModel viewModel, Widget? child) {
    return MaterialApp(
      title: 'Blueprint Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Blueprint Demo')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Counter section ──────────────────────────────
              _buildCounterCard(),
              const SizedBox(height: 16),

              // ── Date section ─────────────────────────────────
              _buildDateCard(context),
              const SizedBox(height: 24),

              // ── Cross-model summary ──────────────────────────
              Card(
                child: ListTile(
                  leading: const Icon(Icons.summarize),
                  title: const Text('Summary'),
                  subtitle: Text(viewModel.summary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper: Counter card ────────────────────────────────────────────────
  /// Builds the counter display with +/− buttons.
  ///
  /// `viewModel` here is typed as `AppViewModel` via the getter, so
  /// `.count`, `.increment()`, `.decrement()` all autocomplete in the IDE.
  Widget _buildCounterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.tag, size: 28),
            const SizedBox(width: 12),
            Text(
              '${viewModel.count}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton.filled(
              icon: const Icon(Icons.remove),
              onPressed: viewModel.decrement,
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.add),
              onPressed: viewModel.increment,
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper: Date card ───────────────────────────────────────────────────
  /// Builds the date display with a "Pick Date" button.
  ///
  /// `viewModel` here is typed as `AppViewModel` via the getter, so
  /// `.selectedDate`, `.selectDate()` autocomplete in the IDE.
  Widget _buildDateCard(BuildContext context) {
    final dateStr =
        viewModel.selectedDate.toIso8601String().split('T').first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 28),
            const SizedBox(width: 12),
            Text(dateStr, style: const TextStyle(fontSize: 20)),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Pick Date'),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: viewModel.selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) viewModel.selectDate(picked);
              },
            ),
          ],
        ),
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
