part of '../blueprint.dart';

/// A **Fragment** of UI — i.e. the **View** in MVVM.
///
/// The generic [VM] ensures that [buildFragment] receives the correctly-typed
/// ViewModel, giving you full autocompletion and compile-time checking on every
/// property and method.
///
/// ```dart
/// final class AppFragment extends Fragment<AppViewModel> {
///   @override
///   Widget buildFragment(
///       BuildContext context, AppViewModel viewModel, Widget? child) {
///     return Text('${viewModel.count}');
///   }
/// }
/// ```
abstract base class Fragment<VM extends ViewModel> {
  /// The [ViewModel] that drives this Fragment. Set once by [bind].
  late final VM _viewModel;

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
