import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_datasource.dart';

class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl(this._dataSource);
  final EventRemoteDataSource _dataSource;

  @override
  Future<List<EventEntity>> getEvents() async {
    final dtos = await _dataSource.getEvents();
    return dtos.map((d) => d.toEntity()).toList();
  }

  @override
  Future<List<EventEntity>> getRandomEvents(int count) async {
    final dtos = await _dataSource.getRandomEvents(count);
    return dtos.map((d) => d.toEntity()).toList();
  }
}
