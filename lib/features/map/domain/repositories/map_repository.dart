import '../../../animals_info/domain/entities/animal_with_zone_entity.dart';
import '../../../events_show/domain/entities/event_entity.dart';
import '../entities/map_entity.dart';

abstract class MapRepository {
  Stream<MapEntity?> watchMap();
  Stream<List<AnimalWithZoneEntity>> watchAnimalsWithZone();
  Stream<List<EventEntity>> watchEvents();
}
