import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../animals_info/domain/entities/animal_with_zone_entity.dart';
import '../../../events_show/domain/entities/event_entity.dart';
import '../../data/datasources/map_remote_datasource.dart';
import '../../data/repositories/map_repository_impl.dart';
import '../../domain/entities/map_entity.dart';
import '../../domain/repositories/map_repository.dart';
import '../../domain/usecases/watch_map_animals_usecase.dart';
import '../../domain/usecases/watch_map_events_usecase.dart';
import '../../domain/usecases/watch_map_usecase.dart';

part 'map_providers.g.dart';

@Riverpod(keepAlive: true)
MapRemoteDataSource mapRemoteDataSource(Ref ref) => MapRemoteDataSourceImpl();

@Riverpod(keepAlive: true)
MapRepository mapRepository(Ref ref) =>
    MapRepositoryImpl(ref.watch(mapRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
WatchMapUseCase watchMapUseCase(Ref ref) =>
    WatchMapUseCase(ref.watch(mapRepositoryProvider));

@Riverpod(keepAlive: true)
WatchMapAnimalsUseCase watchMapAnimalsUseCase(Ref ref) =>
    WatchMapAnimalsUseCase(ref.watch(mapRepositoryProvider));

@Riverpod(keepAlive: true)
WatchMapEventsUseCase watchMapEventsUseCase(Ref ref) =>
    WatchMapEventsUseCase(ref.watch(mapRepositoryProvider));

@riverpod
Stream<MapEntity?> mapPicture(Ref ref) =>
    ref.watch(watchMapUseCaseProvider).call();

@riverpod
Stream<List<AnimalWithZoneEntity>> mapAnimals(Ref ref) =>
    ref.watch(watchMapAnimalsUseCaseProvider).call();

@riverpod
Stream<List<EventEntity>> mapEvents(Ref ref) =>
    ref.watch(watchMapEventsUseCaseProvider).call();
