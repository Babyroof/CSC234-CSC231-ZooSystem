import '../../domain/entities/animal_entity.dart';
import '../../domain/entities/zone_entity.dart';
import '../../domain/entities/animal_with_zone_entity.dart';
import '../../domain/repositories/animal_repository.dart';
import '../datasources/animal_remote_datasource.dart';
import '../datasources/animal_local_datasource.dart';

class AnimalRepositoryImpl implements AnimalRepository {
  AnimalRepositoryImpl(this._dataSource) : _cache = AnimalLocalDataSource();
  final AnimalRemoteDataSource _dataSource;
  final AnimalLocalDataSource _cache;

  @override
  Future<List<AnimalEntity>> getAnimals() async {
    final dtos = await _dataSource.getAnimals();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<AnimalEntity>> getRandomAnimals(int count) async {
    final dtos = await _dataSource.getRandomAnimals(count);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<AnimalEntity>> getAnimalsByZone(String zoneId) async {
    final dtos = await _dataSource.getAnimalsByZone(zoneId);
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<ZoneEntity>> getZones() async {
    final dtos = await _dataSource.getZones();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<AnimalWithZoneEntity>> getAnimalsWithZone() async {
    // Return cached data immediately while fetching fresh data in background
    final cached = await _cache.getAnimalsWithZone();
    if (cached != null && cached.isNotEmpty) {
      _dataSource.getAnimalsWithZone().then(_cache.saveAnimalsWithZone);
      return cached;
    }
    final fresh = await _dataSource.getAnimalsWithZone();
    await _cache.saveAnimalsWithZone(fresh);
    return fresh;
  }
}
