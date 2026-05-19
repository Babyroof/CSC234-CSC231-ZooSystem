import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class GetUpcomingBookingsUseCase {
  const GetUpcomingBookingsUseCase(this._repository);
  final BookingRepository _repository;
  Stream<List<BookingEntity>> call(String userId) =>
      _repository.getUpcomingBookings(userId);
}
