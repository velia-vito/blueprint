/// Implements the [Model ⇋ View ⇋ View Model](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel) pattern.
///
/// In this framework:
///
/// 1. The data layer is represented by [Model], meant primarily for CRUD (Create, Read, Update, Delete) operations on data sources.
///
/// 1. The business-logic layer is represented by [ViewModel], which acts as an intermediary between the Model and the Fragment. A ViewModel manages its own [Model] dependencies — typically received via its constructor — allowing a single ViewModel to operate on **multiple** data sources.
///
/// 1. The UI layer is represented by [Fragment], responsible for rendering and user interactions.
///
/// 1. [Connector] is a utility widget that wires a [Fragment] to its [ViewModel]. Models are managed by the ViewModel itself.
///
/// ### Example Counter Application
///
/// #### [Model]s
///
/// Model code, note how there is only data read and update logic here.
///
/// ```dart
/// /// Counter Data.
/// final class CounterModel extends Model {
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
/// #### [ViewModel]s
///
/// Next, the ViewModel code — i.e. all the details and controls to connect the UI and the data.
///
/// Notice how the ViewModel receives its [Model] through the constructor — this makes it
/// straightforward to use multiple models, and keeps things easy to test.
///
/// ```dart
/// /// Counter Business Logic.
/// final class CounterViewModel extends ViewModel {
///   final CounterModel _counterModel;
///
///   /// History of operations on counter.
///   final List<String> actionHistory = <String>[];
///
///   /// Creates a [CounterViewModel] operating on the given [CounterModel].
///   CounterViewModel({required CounterModel counterModel})
///     : _counterModel = counterModel;
///
///   /// Get count.
///   int get count => _counterModel.count;
///
///   set count(int _) {
///     throw UnsupportedError('setter for count not supported, property is read-only.');
///   }
///
///   /// Increment count by 1.
///   void increment() {
///     int previousCount = _counterModel.count;
///
///     _counterModel.increment();
///     actionHistory.add('Incremented from $previousCount to ${_counterModel.count}');
///
///     notifyListeners();
///   }
///
///   /// Decrement count by 1.
///   void decrement() {
///     int previousCount = _counterModel.count;
///
///     _counterModel.decrement();
///     actionHistory.add('Decremented from $previousCount to ${_counterModel.count}');
///
///     notifyListeners();
///   }
///
///   /// Double count.
///   void double() {
///     int previousCount = _counterModel.count;
///
///     _counterModel.double();
///     actionHistory.add('Doubled from $previousCount to ${_counterModel.count}');
///
///     notifyListeners();
///   }
///
///   /// Half count.
///   void half() {
///     int previousCount = _counterModel.count;
///
///     _counterModel.half();
///     actionHistory.add('Halved from $previousCount to ${_counterModel.count}');
///
///     notifyListeners();
///   }
/// }
/// ```
///
/// ### [Fragment]s (i.e. A Fragment of the View.)
///
/// UI fragment for this piece of the interface.
///
/// ```dart
/// /// Counter View
/// final class CounterFragment extends Fragment<CounterViewModel> {
///   @override
///   Widget buildFragment(BuildContext context, CounterViewModel viewModel, Widget? child) {
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
///                         onPressed: viewModel.increment,
///                         child: Text('+1', style: FluentTheme.of(context).typography.subtitle),
///                       ),
///                     ),
///                     Padding(
///                       padding: const EdgeInsets.all(8.0),
///                       child: Button(
///                         onPressed: viewModel.double,
///                         child: Text('×2', style: FluentTheme.of(context).typography.subtitle),
///                       ),
///                     ),
///                   ],
///                 ),
///                 Padding(
///                   padding: const EdgeInsets.all(9.0),
///                   child: Text(
///                     '${viewModel.count}',
///                     style: FluentTheme.of(context).typography.titleLarge,
///                   ),
///                 ),
///                 Row(
///                   mainAxisSize: MainAxisSize.min,
///                   children: [
///                     Padding(
///                       padding: const EdgeInsets.all(8.0),
///                       child: Button(
///                         onPressed: viewModel.decrement,
///                         child: Text('-1', style: FluentTheme.of(context).typography.subtitle),
///                       ),
///                     ),
///                     Padding(
///                       padding: const EdgeInsets.all(8.0),
///                       child: Button(
///                         onPressed: viewModel.half,
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
///                     itemCount: viewModel.actionHistory.length,
///                     itemBuilder: (context, index) => IntrinsicWidth(
///                       child: ListTile(
///                         title: Text('Action #${index + 1}'),
///                         subtitle: Text(viewModel.actionHistory[index]),
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
/// #### Connector
///
/// Using the [Connector] is easy, just insert the below into your widget tree.
///
/// ```dart
/// Connector<CounterFragment, CounterViewModel>(
///       fragment: CounterFragment(),
///       viewModel: CounterViewModel(
///         counterModel: CounterModel(),
///       ),
///     );
/// ```
/// {@category framework}
library;

import 'package:flutter/widgets.dart';

part 'blueprint/connector.dart';

part 'blueprint/model.dart';
part 'blueprint/view_model.dart';
part 'blueprint/fragment.dart';
