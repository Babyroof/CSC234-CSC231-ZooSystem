import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/payment_result_entity.dart';

abstract class PaymentRemoteDataSource {
  Future<PaymentResultEntity> createPromptPayCharge({
    required String bookingId,
    required int amount,
  });
}

class PaymentRemoteDataSourceImpl implements PaymentRemoteDataSource {
  @override
  Future<PaymentResultEntity> createPromptPayCharge({
    required String bookingId,
    required int amount,
  }) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'createPromptPayCharge',
    );
    final result = await callable.call<Map<String, dynamic>>({
      'bookingId': bookingId,
      'amount': amount,
    });
    final data = result.data;
    final rawBase64 = data['qrCodeBase64'] as String;
    final cleanBase64 = rawBase64.replaceAll(RegExp(r'\s+'), '');
    debugPrint('QR base64 length received: ${cleanBase64.length}');
    final expiresAtRaw = data['expiresAt'] as String?;
    return PaymentResultEntity(
      qrCodeBase64: cleanBase64,
      chargeId: data['chargeId'] as String,
      expiresAt: expiresAtRaw != null ? DateTime.parse(expiresAtRaw) : null,
    );
  }
}
