part of '../blueprint.dart';

/// A 'Fragment' of UI — i.e. the **View**.
abstract base class Fragment<VM extends ViewModel> {
  /// [ViewModel] that drives the Business Logic of this UI Fragment.
  late final VM _viewModel;

  /// Bind [ViewModel] to this Fragment.
  void bind(VM viewModel) => _viewModel = viewModel;

  /// Build a 'Fragment' of the Widget tree, using the bound [ViewModel].
  Widget buildFragment(BuildContext context, VM viewModel, Widget? child);

  /// A builder function to be used with [ListenableBuilder] within [Connector.build].
  Widget builder(BuildContext context, Widget? child) => buildFragment(context, _viewModel, child);
}
