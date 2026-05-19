import '../../domain/entities/payment_result_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._dataSource);
  final PaymentRemoteDataSource _dataSource;

  @override
  Future<PaymentResultEntity> createPromptPayCharge({
    required String bookingId,
    required int amount,
  }) => _dataSource.createPromptPayCharge(bookingId: bookingId, amount: amount);
}
