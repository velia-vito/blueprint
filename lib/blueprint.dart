/// Implements the [Model ⇋ View ⇋ View Model](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) pattern.
///
/// In this framework:
///
/// 1. The data layer is represented by [Model], meant primarily for CRUD
///    (Create, Read, Update, Delete) operations on data sources.
///
/// 2. The business-logic layer is represented by [ViewModel], which acts as an
///    intermediary between the Model(s) and the Fragment. A ViewModel manages
///    its own [Model] dependencies — received via its constructor — allowing a
///    single ViewModel to operate on **multiple** data sources with full
///    compile-time type safety.
///
/// 3. The UI layer is represented by [Fragment], responsible for rendering and
///    user interactions.
///
/// 4. [Connector] is a utility widget that wires a [Fragment] to its
///    [ViewModel]. It calls [Fragment.bind] with the ViewModel, and rebuilds
///    the Fragment whenever the ViewModel calls [ViewModel.notifyListeners].
///    Models are managed by the ViewModel itself — the Connector never touches
///    them.
///
/// ### How multi-object binding works
///
/// Multiple [Model]s are bound **to the ViewModel, not to the Connector**.
/// The ViewModel declares every Model it needs as a constructor parameter.
/// The Connector only knows about the ViewModel, so it stays at two generics
/// and two arguments regardless of how many Models are involved:
///
/// ```
///  ┌────────────┐      ┌─────────────────┐      ┌────────────┐
///  │ CounterModel│─────▶│                 │      │            │
///  └────────────┘      │   AppViewModel  │◀─────│  Fragment   │
///  ┌────────────┐      │                 │      │            │
///  │  DateModel  │─────▶│                 │      │            │
///  └────────────┘      └─────────────────┘      └────────────┘
///                              ▲
///                              │
///                        ┌───────────┐
///                        │ Connector  │  (wires Fragment ↔ ViewModel)
///                        └───────────┘
/// ```
///
/// ---
///
/// ### Example: Counter + Date Selection App
///
/// This example demonstrates two independent [Model]s (a counter and a date
/// picker) combined in a single [ViewModel] and rendered by one [Fragment].
///
/// #### 1. Models — pure data, no UI, no business logic
///
/// ```dart
/// /// Holds a simple integer counter.
/// final class CounterModel extends Model {
///   int _count = 0;
///   int get count => _count;
///
///   void increment() => _count += 1;
///   void decrement() => _count -= 1;
/// }
///
/// /// Holds a selected date.
/// final class DateModel extends Model {
///   DateTime _selected = DateTime(2026);
///   DateTime get selected => _selected;
///
///   void select(DateTime date) => _selected = date;
/// }
/// ```
///
/// #### 2. ViewModel — business logic, owns the Models
///
/// The ViewModel receives *both* Models via its constructor. All business rules
/// live here. It calls [notifyListeners] after every mutation so that the UI
/// rebuilds.
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
///   // ── Counter ──────────────────────────────
///   int get count => _counter.count;
///
///   void increment() {
///     _counter.increment();
///     notifyListeners();
///   }
///
///   void decrement() {
///     _counter.decrement();
///     notifyListeners();
///   }
///
///   // ── Date ─────────────────────────────────
///   DateTime get selectedDate => _date.selected;
///
///   void selectDate(DateTime date) {
///     _date.select(date);
///     notifyListeners();
///   }
///
///   // ── Derived / cross-model logic ──────────
///   String get summary =>
///       'Count: ${_counter.count}, Date: ${_date.selected.toIso8601String().split("T").first}';
/// }
/// ```
///
/// #### 3. Fragment — the View
///
/// The Fragment receives the *typed* ViewModel in [buildFragment], so
/// every property and method is available with full IDE autocompletion.
///
/// For helper methods, use the [Fragment.viewModel] getter — it returns the
/// same typed instance, so the IDE autocompletes every method there too.
///
/// ```dart
/// final class AppFragment extends Fragment<AppViewModel> {
///   @override
///   Widget buildFragment(
///       BuildContext context, AppViewModel viewModel, Widget? child) {
///     return Column(
///       mainAxisSize: MainAxisSize.min,
///       children: [
///         Text('${viewModel.count}'),          // IDE autocompletes .count
///         _buildDateLine(),                     // helper uses this.viewModel
///         Text(viewModel.summary),              // IDE autocompletes .summary
///       ],
///     );
///   }
///
///   /// Helper — viewModel getter is typed as AppViewModel, not base ViewModel.
///   Widget _buildDateLine() {
///     return Text('${viewModel.selectedDate}'); // IDE autocompletes .selectedDate
///   }
/// }
/// ```
///
/// #### 4. Connector — wiring it all together
///
/// ```dart
/// Connector<AppFragment, AppViewModel>(
///   fragment: AppFragment(),
///   viewModel: AppViewModel(
///     counterModel: CounterModel(),
///     dateModel: DateModel(),
///   ),
/// );
/// ```
///
/// That's it — two Models, one ViewModel, one Fragment, one Connector.
/// {@category framework}
library;

import 'package:flutter/widgets.dart';

part 'blueprint/connector.dart';

part 'blueprint/model.dart';
part 'blueprint/view_model.dart';
part 'blueprint/fragment.dart';
