import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

class GetEventsUseCase {
  const GetEventsUseCase(this._repository);
  final EventRepository _repository;

  Future<List<EventEntity>> call() => _repository.getEvents();
}
