import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class GetPastBookingsUseCase {
  const GetPastBookingsUseCase(this._repository);
  final BookingRepository _repository;
  Stream<List<BookingEntity>> call(String userId) =>
      _repository.getPastBookings(userId);
}
