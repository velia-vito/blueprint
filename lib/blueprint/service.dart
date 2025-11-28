part of '../blueprint.dart';

/// A Buisness Logic `Service` operating on data [Repository] `R`.
abstract base class Service<Repo extends Repository> extends ChangeNotifier {
  /// The data [Repository] that this Service operates on.
  late final Repo _repository;

  /// Protected access to the repository for subclasses only.
  @protected
  Repo get repository => _repository;

  /// Bind [Repository] `R` to this Service.
  void bind(Repo repository) => _repository = repository;
}