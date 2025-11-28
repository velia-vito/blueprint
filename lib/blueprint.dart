/// Implements the [Model ⇋ View ⇋ View Model](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) pattern.
///
/// In this framework:
///
/// 1. Model is represented by [Repository], meant primarily for CRUD (Create, Read, Update, Delete) operations on data sources.
///
/// 1. The ViewModel is represented by [Service], which contains business logic and acts as an intermediary between the Repository and the Fragment.
///
/// 1. The View is represented by [Fragment], responsible for the UI and user interactions.
///
/// 1. [UtilContainer] is a utility class that simplifies the *hooking up* of Repositories, Services, and Fragments.
///
/// ### Example Counter Application
///
/// #### [Repository]s
///
/// Repository code, note how there is only data read and update logic here.
///
/// ```dart
/// Counter Data.
/// final class CounterRepository extends Repository {
///   int _count = 0;
///
///   /// Internal count.
///   int get count => _count;
///
///   /// Increment [count] by 1.
///   void increment() {
///     _count += 1;
///   }
///
///   /// Decrement [count] by 1.
///   void decrement() {
///     _count -= 1;
///   }
///
///   /// Double [count].
///   void double() {
///     _count *= 2;
///   }
///
///   /// Half [count].
///   void half() {
///     _count ~/= 2;
///   }
/// }
/// ```
///
///
/// #### [Service]s
///
/// Next, the Service code — i.e. all the details and controls to connect the UI and the data. Even though most of this
/// is just data pass through from Repository, keep in mind that this is not always true, e.g. the "action history"
/// provided by `CounterService` class.
///
/// ```dart
/// /// Counter Buisness Logic.
/// final class CounterService extends Service<CounterRepository> {
///   /// History of operations on counter.
///   final List<String> actionHistory = <String>[];
///
///   /// Get count.
///   int get count => repository.count;
///
///   set count(int _) {
///     throw UnsupportedError('setter for count not supported, property is read-only.');
///   }
///
///   /// Increment count by 1.
///   void increment() {
///     CounterRepository repo = repository;
///     int previousCount = repo.count;
///
///     repo.increment();
///     actionHistory.add('Incremented from $previousCount to ${repo.count}');
///
///     notifyListeners();
///   }
///
///   /// Decrement count by 1.
///   void decrement() {
///     CounterRepository repo = repository;
///     int previousCount = repo.count;
///
///     repo.decrement();
///     actionHistory.add('Decremented from $previousCount to ${repo.count}');
///
///     notifyListeners();
///   }
///
///   /// Double count.
///   void double() {
///     CounterRepository repo = repository;
///     int previousCount = repo.count;
///
///     repo.double();
///     actionHistory.add('Doubled from $previousCount to ${repo.count}');
///
///     notifyListeners();
///   }
///
///   /// Half count.
///   void half() {
///     CounterRepository repo = repository;
///     int previousCount = repo.count;
///
///     repo.half();
///     actionHistory.add('Halved from $previousCount to ${repo.count}');
///
///     notifyListeners();
///   }
/// }
/// ```
///
/// ### [Fragment]s (i.e. A Fragment of view.)
///
/// UI view for this 'fragment of UI.'
///
/// ```dart
/// /// Counter View
/// final class CounterFragment extends Fragment<CounterService> {
///   @override
///   Widget buildFragment(BuildContext context, CounterService service, Widget? child) {
///     return Row(
///       mainAxisAlignment: MainAxisAlignment.spaceBetween,
///       children: [
///         Expanded(
///           flex: 2,
///           child: Padding(
///             padding: const EdgeInsets.all(16.0),
///             child: Column(
///               mainAxisSize: MainAxisSize.min,
///               children: [
///                 Row(
///                   mainAxisSize: MainAxisSize.min,
///                   children: [
///                     Padding(
///                       padding: const EdgeInsets.all(8.0),
///                       child: Button(
///                         onPressed: service.increment,
///                         child: Text('+1', style: FluentTheme.of(context).typography.subtitle),
///                       ),
///                     ),
///                     Padding(
///                       padding: const EdgeInsets.all(8.0),
///                       child: Button(
///                         onPressed: service.double,
///                         child: Text('×2', style: FluentTheme.of(context).typography.subtitle),
///                       ),
///                     ),
///                   ],
///                 ),
///                 Padding(
///                   padding: const EdgeInsets.all(9.0),
///                   child: Text(
///                     '${service.count}',
///                     style: FluentTheme.of(context).typography.titleLarge,
///                   ),
///                 ),
///                 Row(
///                   mainAxisSize: MainAxisSize.min,
///                   children: [
///                     Padding(
///                       padding: const EdgeInsets.all(8.0),
///                       child: Button(
///                         onPressed: service.decrement,
///                         child: Text('-1', style: FluentTheme.of(context).typography.subtitle),
///                       ),
///                     ),
///                     Padding(
///                       padding: const EdgeInsets.all(8.0),
///                       child: Button(
///                         onPressed: service.half,
///                         child: Text('÷2', style: FluentTheme.of(context).typography.subtitle),
///                       ),
///                     ),
///                   ],
///                 ),
///               ],
///             ),
///           ),
///         ),
///         Expanded(
///           child: Padding(
///             padding: const EdgeInsets.all(8.0),
///             child: Column(
///               crossAxisAlignment: CrossAxisAlignment.start,
///               children: [
///                 Padding(
///                   padding: const EdgeInsets.all(8.0),
///                   child: Text(
///                     'Action History',
///                     style: FluentTheme.of(context).typography.title,
///                   ),
///                 ),
///                 Expanded(
///                   child: ListView.builder(
///                     itemCount: service.actionHistory.length,
///                     itemBuilder: (context, index) => IntrinsicWidth(
///                       child: ListTile(
///                         title: Text('Action #${index + 1}'),
///                         subtitle: Text(service.actionHistory[index]),
///                       ),
///                     ),
///                   ),
///                 ),
///               ],
///             ),
///           ),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// #### UtilContainer
///
/// Using the [UtilContainer] is easy, just insert the below into your tech tree.
///
/// ```dart
/// UtilContainer<CounterFragment, CounterService, CounterRepository>(
///       fragment: CounterFragment(),
///       service: CounterService(),
///       repository: CounterRepository(),
///     );
/// ```
/// {@category framework}
library;

import 'package:flutter/widgets.dart';

part 'blueprint/container.dart';

part 'blueprint/repository.dart';
part 'blueprint/service.dart';
part 'blueprint/fragment.dart';
