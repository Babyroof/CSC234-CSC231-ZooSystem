import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class PaymentResult {
  final String qrCodeBase64;
  final String chargeId;
  final DateTime? expiresAt;

  const PaymentResult({
    required this.qrCodeBase64,
    required this.chargeId,
    this.expiresAt,
  });
}

class PaymentService {
  Future<PaymentResult> createPromptPayCharge({
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
    return PaymentResult(
      qrCodeBase64: cleanBase64,
      chargeId: data['chargeId'] as String,
      expiresAt: expiresAtRaw != null ? DateTime.parse(expiresAtRaw) : null,
    );
  }
}
