import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class WatchBookingUseCase {
  const WatchBookingUseCase(this._repository);
  final BookingRepository _repository;
  Stream<BookingEntity?> call(String bookingId) =>
      _repository.watchBooking(bookingId);
}
