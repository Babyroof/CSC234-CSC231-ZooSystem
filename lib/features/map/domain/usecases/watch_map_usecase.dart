import '../entities/map_entity.dart';
import '../repositories/map_repository.dart';

class WatchMapUseCase {
  const WatchMapUseCase(this._repository);
  final MapRepository _repository;

  Stream<MapEntity?> call() => _repository.watchMap();
}
