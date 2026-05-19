import '../../domain/entities/animal_entity.dart';
import '../../domain/entities/zone_entity.dart';
import '../../domain/entities/animal_with_zone_entity.dart';
import '../../domain/repositories/animal_repository.dart';
import '../datasources/animal_remote_datasource.dart';

class AnimalRepositoryImpl implements AnimalRepository {
  const AnimalRepositoryImpl(this._dataSource);
  final AnimalRemoteDataSource _dataSource;

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
  Future<List<AnimalWithZoneEntity>> getAnimalsWithZone() =>
      _dataSource.getAnimalsWithZone();
}
