import 'package:blueprint/blueprint.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
//  Test doubles
// ---------------------------------------------------------------------------

/// A simple counter repository (single Object).
final class _CounterRepository extends Repository {
  int _count = 0;
  int get count => _count;

  void increment() => _count += 1;
  void decrement() => _count -= 1;
}

/// A second repository to prove multi-object support.
final class _LogRepository extends Repository {
  final List<String> entries = <String>[];

  void log(String message) => entries.add(message);
}

/// Service that depends on a *single* repository.
final class _SingleRepoService extends Service {
  final _CounterRepository _counter;

  _SingleRepoService({required _CounterRepository counterRepository})
      : _counter = counterRepository;

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

/// Service that depends on *multiple* repositories.
final class _MultiRepoService extends Service {
  final _CounterRepository _counter;
  final _LogRepository _log;

  _MultiRepoService({
    required _CounterRepository counterRepository,
    required _LogRepository logRepository,
  })  : _counter = counterRepository,
        _log = logRepository;

  int get count => _counter.count;
  List<String> get logs => List<String>.unmodifiable(_log.entries);

  void increment() {
    _counter.increment();
    _log.log('incremented to ${_counter.count}');
    notifyListeners();
  }
}

/// Minimal fragment that renders the count as a [Text] widget.
final class _CounterFragment extends Fragment<_SingleRepoService> {
  @override
  Widget buildFragment(
      BuildContext context, _SingleRepoService service, Widget? child) {
    return Text('${service.count}', textDirection: TextDirection.ltr);
  }
}

/// Fragment for the multi-repo service.
final class _MultiRepoFragment extends Fragment<_MultiRepoService> {
  @override
  Widget buildFragment(
      BuildContext context, _MultiRepoService service, Widget? child) {
    return Text('${service.count} (${service.logs.length} logs)',
        textDirection: TextDirection.ltr);
  }
}

// ---------------------------------------------------------------------------
//  Tests
// ---------------------------------------------------------------------------

void main() {
  // ---- Repository tests ---------------------------------------------------

  group('Repository', () {
    test('subclass holds and mutates data', () {
      final repo = _CounterRepository();
      expect(repo.count, 0);

      repo.increment();
      expect(repo.count, 1);

      repo.decrement();
      expect(repo.count, 0);
    });

    test('multiple repositories remain independent', () {
      final counter = _CounterRepository();
      final log = _LogRepository();

      counter.increment();
      log.log('hello');

      expect(counter.count, 1);
      expect(log.entries, ['hello']);
    });
  });

  // ---- Service tests ------------------------------------------------------

  group('Service', () {
    test('is a ChangeNotifier', () {
      final service =
          _SingleRepoService(counterRepository: _CounterRepository());
      expect(service, isA<ChangeNotifier>());
    });

    test('single-repo service reads from its repository', () {
      final repo = _CounterRepository();
      final service = _SingleRepoService(counterRepository: repo);

      expect(service.count, 0);
      repo.increment();
      expect(service.count, 1);
    });

    test('single-repo service notifies listeners on mutation', () {
      final service =
          _SingleRepoService(counterRepository: _CounterRepository());
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      service.increment();
      expect(notifyCount, 1);
      expect(service.count, 1);

      service.decrement();
      expect(notifyCount, 2);
      expect(service.count, 0);
    });

    test('multi-repo service operates on multiple repositories', () {
      final counter = _CounterRepository();
      final log = _LogRepository();
      final service = _MultiRepoService(
        counterRepository: counter,
        logRepository: log,
      );

      expect(service.count, 0);
      expect(service.logs, isEmpty);

      service.increment();
      expect(service.count, 1);
      expect(service.logs, ['incremented to 1']);

      service.increment();
      expect(service.count, 2);
      expect(service.logs, ['incremented to 1', 'incremented to 2']);
    });

    test('multi-repo service notifies listeners', () {
      final service = _MultiRepoService(
        counterRepository: _CounterRepository(),
        logRepository: _LogRepository(),
      );
      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      service.increment();
      expect(notifyCount, 1);
    });
  });

  // ---- Fragment tests -----------------------------------------------------

  group('Fragment', () {
    test('bind sets the service and builder delegates correctly', () {
      final service =
          _SingleRepoService(counterRepository: _CounterRepository());
      final fragment = _CounterFragment();

      fragment.bind(service);

      // builder should not throw after binding
      expect(
        () => fragment.builder,
        returnsNormally,
      );
    });
  });

  // ---- UtilContainer (widget) tests ----------------------------------------

  group('UtilContainer', () {
    testWidgets('renders fragment with single-repo service',
        (WidgetTester tester) async {
      final repo = _CounterRepository();
      final service = _SingleRepoService(counterRepository: repo);
      final fragment = _CounterFragment();

      await tester.pumpWidget(
        UtilContainer<_CounterFragment, _SingleRepoService>(
          fragment: fragment,
          service: service,
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('rebuilds when service notifies listeners',
        (WidgetTester tester) async {
      final repo = _CounterRepository();
      final service = _SingleRepoService(counterRepository: repo);

      await tester.pumpWidget(
        UtilContainer<_CounterFragment, _SingleRepoService>(
          fragment: _CounterFragment(),
          service: service,
        ),
      );

      expect(find.text('0'), findsOneWidget);

      service.increment();
      await tester.pump();

      expect(find.text('1'), findsOneWidget);

      service.increment();
      service.increment();
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('works with multi-repo service',
        (WidgetTester tester) async {
      final counter = _CounterRepository();
      final log = _LogRepository();
      final service = _MultiRepoService(
        counterRepository: counter,
        logRepository: log,
      );

      await tester.pumpWidget(
        UtilContainer<_MultiRepoFragment, _MultiRepoService>(
          fragment: _MultiRepoFragment(),
          service: service,
        ),
      );

      expect(find.text('0 (0 logs)'), findsOneWidget);

      service.increment();
      await tester.pump();

      expect(find.text('1 (1 logs)'), findsOneWidget);
    });
  });

  // ---- Type-safety compile-time guarantees ---------------------------------

  group('Type safety', () {
    test('fragment is correctly typed to its service', () {
      final fragment = _CounterFragment();
      expect(fragment, isA<Fragment<_SingleRepoService>>());
    });

    test('multi-repo fragment is correctly typed', () {
      final fragment = _MultiRepoFragment();
      expect(fragment, isA<Fragment<_MultiRepoService>>());
    });
  });
}
