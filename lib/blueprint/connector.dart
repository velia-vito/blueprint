part of '../blueprint.dart';

/// Connects a [Fragment] (View) to a [ViewModel].
///
/// [Model] instances are managed by the [ViewModel] itself (typically
/// passed via the ViewModel constructor), so the connector only needs to wire
/// the View ([Fragment]) to the [ViewModel].
base class Connector<Frag extends Fragment<VM>, VM extends ViewModel>
    extends StatelessWidget {
  final Frag _fragment;
  final VM _viewModel;

  /// Creates a [Connector] that binds the provided [Fragment] to the [ViewModel].
  Connector({super.key, required Frag fragment, required VM viewModel})
    : _fragment = fragment,
      _viewModel = viewModel {
    _fragment.bind(_viewModel);
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _viewModel, builder: _fragment.builder);
}
