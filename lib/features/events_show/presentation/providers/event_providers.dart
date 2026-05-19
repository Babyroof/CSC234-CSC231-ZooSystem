import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/datasources/event_remote_datasource.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/get_events_usecase.dart';

part 'event_providers.g.dart';

@Riverpod(keepAlive: true)
EventRemoteDataSource eventRemoteDataSource(Ref ref) =>
    EventRemoteDataSourceImpl();

@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) =>
    EventRepositoryImpl(ref.watch(eventRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
GetEventsUseCase getEventsUseCase(Ref ref) =>
    GetEventsUseCase(ref.watch(eventRepositoryProvider));

@riverpod
Future<List<EventEntity>> events(Ref ref) =>
    ref.read(getEventsUseCaseProvider).call();
