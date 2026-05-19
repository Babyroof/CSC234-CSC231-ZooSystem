import '../../../events_show/domain/entities/event_entity.dart';
import '../repositories/map_repository.dart';

class WatchMapEventsUseCase {
  const WatchMapEventsUseCase(this._repository);
  final MapRepository _repository;

  Stream<List<EventEntity>> call() => _repository.watchEvents();
}
