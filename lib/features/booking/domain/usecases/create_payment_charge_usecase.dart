import '../entities/payment_result_entity.dart';
import '../repositories/payment_repository.dart';

class CreatePaymentChargeUseCase {
  const CreatePaymentChargeUseCase(this._repository);
  final PaymentRepository _repository;
  Future<PaymentResultEntity> call({
    required String bookingId,
    required int amount,
  }) => _repository.createPromptPayCharge(bookingId: bookingId, amount: amount);
}
