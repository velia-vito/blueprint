part of '../blueprint.dart';

/// A 'Fragment' of UI — i.e. the View.
abstract base class Fragment<Serv extends Service> {
  /// [Service] that drives the Business Logic of this UI Fragment.
  late final Serv _service;

  /// Bind [Service] `S` to this Fragment.
  void bind(Serv service) => _service = service;

  /// Build a 'Fragment' of the Widget tree, using the provided [Service] `S`.
  Widget buildFragment(BuildContext context, Serv service, Widget? child);

  /// A builder function to be used with [ListenableBuilder] within [UtilContainer.build].
  Widget builder(BuildContext context, Widget? child) => buildFragment(context, _service, child);
}
