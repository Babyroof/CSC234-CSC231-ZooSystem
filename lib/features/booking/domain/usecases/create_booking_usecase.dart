import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase {
  const CreateBookingUseCase(this._repository);
  final BookingRepository _repository;
  Future<String> call(BookingEntity booking) =>
      _repository.createBooking(booking);
}
