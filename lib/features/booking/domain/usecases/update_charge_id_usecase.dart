import '../repositories/booking_repository.dart';

class UpdateChargeIdUseCase {
  const UpdateChargeIdUseCase(this._repository);
  final BookingRepository _repository;
  Future<void> call({required String bookingId, required String chargeId}) =>
      _repository.updateChargeId(bookingId: bookingId, chargeId: chargeId);
}
