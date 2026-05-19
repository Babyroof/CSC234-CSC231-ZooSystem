import '../entities/payment_result_entity.dart';

abstract class PaymentRepository {
  Future<PaymentResultEntity> createPromptPayCharge({
    required String bookingId,
    required int amount,
  });
}
