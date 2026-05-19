import '../../../animals_info/domain/entities/animal_with_zone_entity.dart';
import '../../../events_show/domain/entities/event_entity.dart';
import '../../domain/entities/map_entity.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  const MapRepositoryImpl(this._dataSource);
  final MapRemoteDataSource _dataSource;

  @override
  Stream<MapEntity?> watchMap() => _dataSource.watchMap();

  @override
  Stream<List<AnimalWithZoneEntity>> watchAnimalsWithZone() =>
      _dataSource.watchAnimalsWithZone();

  @override
  Stream<List<EventEntity>> watchEvents() => _dataSource.watchEvents();
}
