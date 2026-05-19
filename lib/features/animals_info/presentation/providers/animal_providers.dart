import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/animal_remote_datasource.dart';
import '../../data/repositories/animal_repository_impl.dart';
import '../../domain/entities/animal_with_zone_entity.dart';
import '../../domain/repositories/animal_repository.dart';
import '../../domain/usecases/get_animals_with_zone_usecase.dart';
import '../../domain/usecases/get_animals_usecase.dart';

part 'animal_providers.g.dart';

@Riverpod(keepAlive: true)
AnimalRemoteDataSource animalRemoteDataSource(Ref ref) =>
    AnimalRemoteDataSourceImpl();

@Riverpod(keepAlive: true)
AnimalRepository animalRepository(Ref ref) =>
    AnimalRepositoryImpl(ref.watch(animalRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
GetAnimalsUseCase getAnimalsUseCase(Ref ref) =>
    GetAnimalsUseCase(ref.watch(animalRepositoryProvider));

@Riverpod(keepAlive: true)
GetAnimalsWithZoneUseCase getAnimalsWithZoneUseCase(Ref ref) =>
    GetAnimalsWithZoneUseCase(ref.watch(animalRepositoryProvider));

@riverpod
Future<List<AnimalWithZoneEntity>> animalsWithZone(Ref ref) =>
    ref.read(getAnimalsWithZoneUseCaseProvider).call();
