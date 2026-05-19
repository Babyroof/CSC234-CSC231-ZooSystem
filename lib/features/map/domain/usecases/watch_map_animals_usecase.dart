import '../../../animals_info/domain/entities/animal_with_zone_entity.dart';
import '../repositories/map_repository.dart';

class WatchMapAnimalsUseCase {
  const WatchMapAnimalsUseCase(this._repository);
  final MapRepository _repository;

  Stream<List<AnimalWithZoneEntity>> call() =>
      _repository.watchAnimalsWithZone();
}
