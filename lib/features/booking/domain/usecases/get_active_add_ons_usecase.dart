import '../entities/add_on_entity.dart';
import '../repositories/add_on_repository.dart';

class GetActiveAddOnsUseCase {
  const GetActiveAddOnsUseCase(this._repository);
  final AddOnRepository _repository;
  Stream<List<AddOnEntity>> call() => _repository.getActiveAddOns();
}
