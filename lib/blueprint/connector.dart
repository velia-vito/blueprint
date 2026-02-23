part of '../blueprint.dart';

/// Connects a [Fragment] (View) to a [ViewModel].
///
/// The Connector binds the Fragment to the ViewModel via [Fragment.bind] and
/// rebuilds the Fragment whenever the ViewModel calls [ViewModel.notifyListeners].
///
/// [Model] instances are the ViewModel's responsibility — the Connector never
/// touches them. This keeps the Connector at just **two** generic parameters
/// and **two** constructor arguments, no matter how many Models are involved.
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
base class Connector<Frag extends Fragment<VM>, VM extends ViewModel>
    extends StatelessWidget {
  final Frag _fragment;
  final VM _viewModel;

  /// Creates a [Connector] that binds [fragment] to [viewModel].
  Connector({super.key, required Frag fragment, required VM viewModel})
      : _fragment = fragment,
        _viewModel = viewModel {
    _fragment.bind(_viewModel);
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _viewModel, builder: _fragment.builder);
}
