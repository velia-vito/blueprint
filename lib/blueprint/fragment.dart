part of '../blueprint.dart';

/// A **Fragment** of UI — i.e. the **View** in MVVM.
///
/// The generic [VM] ensures that [buildFragment] receives the correctly-typed
/// ViewModel, giving you full IDE autocompletion and compile-time checking on
/// every property and method.
///
/// Use the [viewModel] getter from any helper method in your subclass to
/// access the bound ViewModel with full type information:
///
/// ```dart
/// final class AppFragment extends Fragment<AppViewModel> {
///   @override
///   Widget buildFragment(
///       BuildContext context, AppViewModel viewModel, Widget? child) {
///     return Column(
///       children: [
///         Text('${viewModel.count}'),     // ← IDE autocompletes .count
///         Text('${viewModel.summary}'),   // ← IDE autocompletes .summary
///         _buildDateRow(context),          // helper can use this.viewModel
///       ],
///     );
///   }
///
///   Widget _buildDateRow(BuildContext context) {
///     // viewModel is fully typed as AppViewModel here too:
///     return Text('${viewModel.selectedDate}');
///   }
/// }
/// ```
abstract base class Fragment<VM extends ViewModel> {
  late final VM _viewModel;

  /// The bound [ViewModel], fully typed as [VM].
  ///
  /// Available after [Connector] calls [bind]. Use this from helper methods
  /// in your Fragment subclass — the IDE will autocomplete every public
  /// property and method on [VM].
  @protected
  VM get viewModel => _viewModel;

  /// Bind a [ViewModel] to this Fragment.
  ///
  /// Called internally by [Connector] — you do not need to call this yourself.
  void bind(VM viewModel) => _viewModel = viewModel;

  /// Override this to build your widget tree.
  ///
  /// The [viewModel] parameter is the same instance passed to [bind], fully
  /// typed as [VM] so every property and method is available at compile time.
  Widget buildFragment(BuildContext context, VM viewModel, Widget? child);

  /// Adapter used by [ListenableBuilder] inside [Connector.build].
  Widget builder(BuildContext context, Widget? child) =>
      buildFragment(context, _viewModel, child);
}
