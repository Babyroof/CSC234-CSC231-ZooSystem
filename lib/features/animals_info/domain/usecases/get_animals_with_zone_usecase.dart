import '../entities/animal_with_zone_entity.dart';
import '../repositories/animal_repository.dart';

class GetAnimalsWithZoneUseCase {
  const GetAnimalsWithZoneUseCase(this._repository);
  final AnimalRepository _repository;

  Future<List<AnimalWithZoneEntity>> call() => _repository.getAnimalsWithZone();
}
