import 'package:blueprint/blueprint.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
//  Test doubles
// ---------------------------------------------------------------------------

/// A simple counter model (single data source).
final class _CounterModel extends Model {
  int _count = 0;
  int get count => _count;

  void increment() => _count += 1;
  void decrement() => _count -= 1;
}

/// A date-selection model (second, independent data source).
final class _DateModel extends Model {
  DateTime _selected = DateTime(2026);
  DateTime get selected => _selected;

  void select(DateTime date) => _selected = date;
}

/// ViewModel that depends on a *single* model (counter only).
final class _CounterVM extends ViewModel {
  final _CounterModel _counter;

  _CounterVM({required _CounterModel counterModel})
      : _counter = counterModel;

  int get count => _counter.count;

  void increment() {
    _counter.increment();
    notifyListeners();
  }

  void decrement() {
    _counter.decrement();
    notifyListeners();
  }
}

/// ViewModel that depends on *two* models (counter + date).
///
/// This is the scenario the user asked about: two separate objects
/// (counter, date selection) bound to one ViewModel and one Fragment.
final class _AppViewModel extends ViewModel {
  final _CounterModel _counter;
  final _DateModel _date;

  _AppViewModel({
    required _CounterModel counterModel,
    required _DateModel dateModel,
  })  : _counter = counterModel,
        _date = dateModel;

  // counter
  int get count => _counter.count;
  void increment() {
    _counter.increment();
    notifyListeners();
  }

  void decrement() {
    _counter.decrement();
    notifyListeners();
  }

  // date
  DateTime get selectedDate => _date.selected;
  void selectDate(DateTime date) {
    _date.select(date);
    notifyListeners();
  }

  // cross-model derived state
  String get summary =>
      'Count: ${_counter.count}, '
      'Date: ${_date.selected.toIso8601String().split("T").first}';
}

/// Fragment for the single-model counter ViewModel.
final class _CounterFragment extends Fragment<_CounterVM> {
  @override
  Widget buildFragment(
      BuildContext context, _CounterVM viewModel, Widget? child) {
    return Text('${viewModel.count}', textDirection: TextDirection.ltr);
  }
}

/// Fragment for the multi-model app ViewModel (counter + date).
final class _AppFragment extends Fragment<_AppViewModel> {
  @override
  Widget buildFragment(
      BuildContext context, _AppViewModel viewModel, Widget? child) {
    return Text(viewModel.summary, textDirection: TextDirection.ltr);
  }
}

/// Fragment that uses the [viewModel] getter from a helper method to verify
/// IDE-friendly autocomplete works outside [buildFragment].
final class _HelperFragment extends Fragment<_AppViewModel> {
  @override
  Widget buildFragment(
      BuildContext context, _AppViewModel viewModel, Widget? child) {
    return Column(
      textDirection: TextDirection.ltr,
      children: [
        Text('${viewModel.count}', textDirection: TextDirection.ltr),
        _buildDateWidget(),
      ],
    );
  }

  /// Helper that accesses the typed ViewModel via the protected getter.
  Widget _buildDateWidget() {
    // viewModel getter is fully typed as _AppViewModel — IDE autocompletes
    // .selectedDate, .selectDate(), .count, .increment(), .summary, etc.
    return Text(
      viewModel.selectedDate.toIso8601String().split('T').first,
      textDirection: TextDirection.ltr,
    );
  }
}

// ---------------------------------------------------------------------------
//  Tests
// ---------------------------------------------------------------------------

void main() {
  // ---- Model tests ---------------------------------------------------------

  group('Model', () {
    test('CounterModel holds and mutates data', () {
      final model = _CounterModel();
      expect(model.count, 0);

      model.increment();
      expect(model.count, 1);

      model.decrement();
      expect(model.count, 0);
    });

    test('DateModel holds and mutates data', () {
      final model = _DateModel();
      expect(model.selected, DateTime(2026));

      final newDate = DateTime(2026, 6, 15);
      model.select(newDate);
      expect(model.selected, newDate);
    });

    test('multiple models remain independent', () {
      final counter = _CounterModel();
      final date = _DateModel();

      counter.increment();
      date.select(DateTime(2030));

      expect(counter.count, 1);
      expect(date.selected, DateTime(2030));
    });
  });

  // ---- ViewModel tests -----------------------------------------------------

  group('ViewModel', () {
    test('is a ChangeNotifier', () {
      final vm = _CounterVM(counterModel: _CounterModel());
      expect(vm, isA<ChangeNotifier>());
    });

    test('single-model ViewModel reads from its model', () {
      final model = _CounterModel();
      final vm = _CounterVM(counterModel: model);

      expect(vm.count, 0);
      model.increment();
      expect(vm.count, 1);
    });

    test('single-model ViewModel notifies listeners on mutation', () {
      final vm = _CounterVM(counterModel: _CounterModel());
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.increment();
      expect(notifyCount, 1);
      expect(vm.count, 1);

      vm.decrement();
      expect(notifyCount, 2);
      expect(vm.count, 0);
    });

    test('multi-model ViewModel operates on counter + date', () {
      final counter = _CounterModel();
      final date = _DateModel();
      final vm = _AppViewModel(counterModel: counter, dateModel: date);

      // initial state
      expect(vm.count, 0);
      expect(vm.selectedDate, DateTime(2026));
      expect(vm.summary, 'Count: 0, Date: 2026-01-01');

      // mutate counter
      vm.increment();
      expect(vm.count, 1);
      expect(vm.summary, 'Count: 1, Date: 2026-01-01');

      // mutate date
      vm.selectDate(DateTime(2026, 7, 4));
      expect(vm.selectedDate, DateTime(2026, 7, 4));
      expect(vm.summary, 'Count: 1, Date: 2026-07-04');

      // both in one summary
      vm.increment();
      expect(vm.summary, 'Count: 2, Date: 2026-07-04');
    });

    test('multi-model ViewModel notifies listeners for counter changes', () {
      final vm = _AppViewModel(
        counterModel: _CounterModel(),
        dateModel: _DateModel(),
      );
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.increment();
      expect(notifyCount, 1);

      vm.decrement();
      expect(notifyCount, 2);
    });

    test('multi-model ViewModel notifies listeners for date changes', () {
      final vm = _AppViewModel(
        counterModel: _CounterModel(),
        dateModel: _DateModel(),
      );
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.selectDate(DateTime(2026, 12, 25));
      expect(notifyCount, 1);
      expect(vm.selectedDate, DateTime(2026, 12, 25));
    });
  });

  // ---- Fragment tests ------------------------------------------------------

  group('Fragment', () {
    test('bind sets the viewModel and builder delegates correctly', () {
      final vm = _CounterVM(counterModel: _CounterModel());
      final fragment = _CounterFragment();

      fragment.bind(vm);

      // builder should not throw after binding
      expect(
        () => fragment.builder,
        returnsNormally,
      );
    });

    test('Fragment generic preserves ViewModel type', () {
      final fragment = _CounterFragment();
      expect(fragment, isA<Fragment<_CounterVM>>());

      final appFragment = _AppFragment();
      expect(appFragment, isA<Fragment<_AppViewModel>>());
    });

    test('viewModel getter returns the bound instance with full type info', () {
      final vm = _AppViewModel(
        counterModel: _CounterModel(),
        dateModel: _DateModel(),
      );
      final fragment = _AppFragment();
      fragment.bind(vm);

      // The getter returns the exact typed ViewModel, not just ViewModel base.
      // This means IDE autocomplete shows .count, .increment(), .selectedDate, etc.
      expect(fragment.viewModel, same(vm));
      expect(fragment.viewModel.count, 0);
      expect(fragment.viewModel.selectedDate, DateTime(2026));
      expect(fragment.viewModel.summary, 'Count: 0, Date: 2026-01-01');
    });
  });

  // ---- Connector (widget) tests --------------------------------------------

  group('Connector', () {
    testWidgets('renders single-model counter Fragment',
        (WidgetTester tester) async {
      final vm = _CounterVM(counterModel: _CounterModel());

      await tester.pumpWidget(
        Connector<_CounterFragment, _CounterVM>(
          fragment: _CounterFragment(),
          viewModel: vm,
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('rebuilds when single-model ViewModel notifies',
        (WidgetTester tester) async {
      final vm = _CounterVM(counterModel: _CounterModel());

      await tester.pumpWidget(
        Connector<_CounterFragment, _CounterVM>(
          fragment: _CounterFragment(),
          viewModel: vm,
        ),
      );

      expect(find.text('0'), findsOneWidget);

      vm.increment();
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      vm.increment();
      vm.increment();
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders multi-model (counter + date) Fragment',
        (WidgetTester tester) async {
      final vm = _AppViewModel(
        counterModel: _CounterModel(),
        dateModel: _DateModel(),
      );

      await tester.pumpWidget(
        Connector<_AppFragment, _AppViewModel>(
          fragment: _AppFragment(),
          viewModel: vm,
        ),
      );

      expect(find.text('Count: 0, Date: 2026-01-01'), findsOneWidget);
    });

    testWidgets('rebuilds on counter change in multi-model ViewModel',
        (WidgetTester tester) async {
      final vm = _AppViewModel(
        counterModel: _CounterModel(),
        dateModel: _DateModel(),
      );

      await tester.pumpWidget(
        Connector<_AppFragment, _AppViewModel>(
          fragment: _AppFragment(),
          viewModel: vm,
        ),
      );

      vm.increment();
      await tester.pump();
      expect(find.text('Count: 1, Date: 2026-01-01'), findsOneWidget);
    });

    testWidgets('rebuilds on date change in multi-model ViewModel',
        (WidgetTester tester) async {
      final vm = _AppViewModel(
        counterModel: _CounterModel(),
        dateModel: _DateModel(),
      );

      await tester.pumpWidget(
        Connector<_AppFragment, _AppViewModel>(
          fragment: _AppFragment(),
          viewModel: vm,
        ),
      );

      vm.selectDate(DateTime(2026, 7, 4));
      await tester.pump();
      expect(find.text('Count: 0, Date: 2026-07-04'), findsOneWidget);
    });

    testWidgets('rebuilds on interleaved counter + date changes',
        (WidgetTester tester) async {
      final vm = _AppViewModel(
        counterModel: _CounterModel(),
        dateModel: _DateModel(),
      );

      await tester.pumpWidget(
        Connector<_AppFragment, _AppViewModel>(
          fragment: _AppFragment(),
          viewModel: vm,
        ),
      );

      // increment, then change date, then increment again
      vm.increment();
      await tester.pump();
      expect(find.text('Count: 1, Date: 2026-01-01'), findsOneWidget);

      vm.selectDate(DateTime(2026, 12, 25));
      await tester.pump();
      expect(find.text('Count: 1, Date: 2026-12-25'), findsOneWidget);

      vm.increment();
      await tester.pump();
      expect(find.text('Count: 2, Date: 2026-12-25'), findsOneWidget);
    });

    testWidgets(
        'Fragment.viewModel getter enables helper methods with IDE autocomplete',
        (WidgetTester tester) async {
      final vm = _AppViewModel(
        counterModel: _CounterModel(),
        dateModel: _DateModel(),
      );

      await tester.pumpWidget(
        Connector<_HelperFragment, _AppViewModel>(
          fragment: _HelperFragment(),
          viewModel: vm,
        ),
      );

      // _HelperFragment._buildDateWidget() uses `viewModel.selectedDate`
      // via the protected getter — verifying it works at render time.
      expect(find.text('0'), findsOneWidget);
      expect(find.text('2026-01-01'), findsOneWidget);

      vm.increment();
      vm.selectDate(DateTime(2026, 7, 4));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2026-07-04'), findsOneWidget);
    });
  });
}
