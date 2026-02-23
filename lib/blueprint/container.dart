part of '../blueprint.dart';

/// Utility container to connect [Service]s and [Fragment]s.
///
/// [Repository] instances are managed by the [Service] itself (typically
/// passed via the Service constructor), so the container only needs to wire
/// the View ([Fragment]) to the ViewModel ([Service]).
base class UtilContainer<Frag extends Fragment<Serv>, Serv extends Service>
    extends StatelessWidget {
  final Frag _fragment;
  final Serv _service;

  /// Creates a [UtilContainer] that binds the provided [Fragment] to the [Service].
  UtilContainer({super.key, required Frag fragment, required Serv service})
    : _fragment = fragment,
      _service = service {
    _fragment.bind(_service);
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _service, builder: _fragment.builder);
}
