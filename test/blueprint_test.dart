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

/// A second model to prove multi-object support.
final class _LogModel extends Model {
  final List<String> entries = <String>[];

  void log(String message) => entries.add(message);
}

/// ViewModel that depends on a *single* model.
final class _SingleModelVM extends ViewModel {
  final _CounterModel _counter;

  _SingleModelVM({required _CounterModel counterModel})
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

/// ViewModel that depends on *multiple* models.
final class _MultiModelVM extends ViewModel {
  final _CounterModel _counter;
  final _LogModel _log;

  _MultiModelVM({
    required _CounterModel counterModel,
    required _LogModel logModel,
  })  : _counter = counterModel,
        _log = logModel;

  int get count => _counter.count;
  List<String> get logs => List<String>.unmodifiable(_log.entries);

  void increment() {
    _counter.increment();
    _log.log('incremented to ${_counter.count}');
    notifyListeners();
  }
}

/// Minimal fragment that renders the count as a [Text] widget.
final class _CounterFragment extends Fragment<_SingleModelVM> {
  @override
  Widget buildFragment(
      BuildContext context, _SingleModelVM viewModel, Widget? child) {
    return Text('${viewModel.count}', textDirection: TextDirection.ltr);
  }
}

/// Fragment for the multi-model view model.
final class _MultiModelFragment extends Fragment<_MultiModelVM> {
  @override
  Widget buildFragment(
      BuildContext context, _MultiModelVM viewModel, Widget? child) {
    return Text('${viewModel.count} (${viewModel.logs.length} logs)',
        textDirection: TextDirection.ltr);
  }
}

// ---------------------------------------------------------------------------
//  Tests
// ---------------------------------------------------------------------------

void main() {
  // ---- Model tests ---------------------------------------------------------

  group('Model', () {
    test('subclass holds and mutates data', () {
      final model = _CounterModel();
      expect(model.count, 0);

      model.increment();
      expect(model.count, 1);

      model.decrement();
      expect(model.count, 0);
    });

    test('multiple models remain independent', () {
      final counter = _CounterModel();
      final log = _LogModel();

      counter.increment();
      log.log('hello');

      expect(counter.count, 1);
      expect(log.entries, ['hello']);
    });
  });

  // ---- ViewModel tests -----------------------------------------------------

  group('ViewModel', () {
    test('is a ChangeNotifier', () {
      final vm = _SingleModelVM(counterModel: _CounterModel());
      expect(vm, isA<ChangeNotifier>());
    });

    test('single-model ViewModel reads from its model', () {
      final model = _CounterModel();
      final vm = _SingleModelVM(counterModel: model);

      expect(vm.count, 0);
      model.increment();
      expect(vm.count, 1);
    });

    test('single-model ViewModel notifies listeners on mutation', () {
      final vm = _SingleModelVM(counterModel: _CounterModel());
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.increment();
      expect(notifyCount, 1);
      expect(vm.count, 1);

      vm.decrement();
      expect(notifyCount, 2);
      expect(vm.count, 0);
    });

    test('multi-model ViewModel operates on multiple models', () {
      final counter = _CounterModel();
      final log = _LogModel();
      final vm = _MultiModelVM(
        counterModel: counter,
        logModel: log,
      );

      expect(vm.count, 0);
      expect(vm.logs, isEmpty);

      vm.increment();
      expect(vm.count, 1);
      expect(vm.logs, ['incremented to 1']);

      vm.increment();
      expect(vm.count, 2);
      expect(vm.logs, ['incremented to 1', 'incremented to 2']);
    });

    test('multi-model ViewModel notifies listeners', () {
      final vm = _MultiModelVM(
        counterModel: _CounterModel(),
        logModel: _LogModel(),
      );
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.increment();
      expect(notifyCount, 1);
    });
  });

  // ---- Fragment tests ------------------------------------------------------

  group('Fragment', () {
    test('bind sets the viewModel and builder delegates correctly', () {
      final vm = _SingleModelVM(counterModel: _CounterModel());
      final fragment = _CounterFragment();

      fragment.bind(vm);

      // builder should not throw after binding
      expect(
        () => fragment.builder,
        returnsNormally,
      );
    });
  });

  // ---- Connector (widget) tests --------------------------------------------

  group('Connector', () {
    testWidgets('renders fragment with single-model ViewModel',
        (WidgetTester tester) async {
      final model = _CounterModel();
      final vm = _SingleModelVM(counterModel: model);
      final fragment = _CounterFragment();

      await tester.pumpWidget(
        Connector<_CounterFragment, _SingleModelVM>(
          fragment: fragment,
          viewModel: vm,
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('rebuilds when ViewModel notifies listeners',
        (WidgetTester tester) async {
      final model = _CounterModel();
      final vm = _SingleModelVM(counterModel: model);

      await tester.pumpWidget(
        Connector<_CounterFragment, _SingleModelVM>(
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

    testWidgets('works with multi-model ViewModel',
        (WidgetTester tester) async {
      final counter = _CounterModel();
      final log = _LogModel();
      final vm = _MultiModelVM(
        counterModel: counter,
        logModel: log,
      );

      await tester.pumpWidget(
        Connector<_MultiModelFragment, _MultiModelVM>(
          fragment: _MultiModelFragment(),
          viewModel: vm,
        ),
      );

      expect(find.text('0 (0 logs)'), findsOneWidget);

      vm.increment();
      await tester.pump();

      expect(find.text('1 (1 logs)'), findsOneWidget);
    });
  });

  // ---- Type-safety compile-time guarantees ---------------------------------

  group('Type safety', () {
    test('fragment is correctly typed to its ViewModel', () {
      final fragment = _CounterFragment();
      expect(fragment, isA<Fragment<_SingleModelVM>>());
    });

    test('multi-model fragment is correctly typed', () {
      final fragment = _MultiModelFragment();
      expect(fragment, isA<Fragment<_MultiModelVM>>());
    });
  });
}
