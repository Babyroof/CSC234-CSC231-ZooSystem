import '../repositories/booking_repository.dart';

class UpdateBookingStatusUseCase {
  const UpdateBookingStatusUseCase(this._repository);
  final BookingRepository _repository;
  Future<void> call({required String bookingId, required String status}) =>
      _repository.updateStatus(bookingId: bookingId, status: status);
}
