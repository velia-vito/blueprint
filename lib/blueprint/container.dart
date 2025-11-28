part of '../blueprint.dart';

/// Utility container to connect [Repository]s, [Service]s, and [Fragment]s.
base class UtilContainer<Frag extends Fragment<Serv>, Serv extends Service<Repo>, Repo extends Repository>
    extends StatelessWidget {
  final Frag _fragment;
  final Serv _service;
  final Repo _repository;

  /// Creates a [Container] that binds the provided [Fragment], [Service], and [Repository].
  UtilContainer({super.key, required Frag fragment, required Serv service, required Repo repository})
    : _fragment = fragment,
      _service = service,
      _repository = repository {
    _fragment.bind(_service);
    _service.bind(_repository);
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _service, builder: _fragment.builder);
}
