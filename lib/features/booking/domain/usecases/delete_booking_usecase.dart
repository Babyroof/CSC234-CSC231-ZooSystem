import '../repositories/booking_repository.dart';

class DeleteBookingUseCase {
  const DeleteBookingUseCase(this._repository);
  final BookingRepository _repository;
  Future<void> call(String bookingId) => _repository.deleteBooking(bookingId);
}
