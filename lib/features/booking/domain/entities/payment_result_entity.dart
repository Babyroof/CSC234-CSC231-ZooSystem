class PaymentResultEntity {
  const PaymentResultEntity({
    required this.qrCodeBase64,
    required this.chargeId,
    this.expiresAt,
  });

  final String qrCodeBase64;
  final String chargeId;
  final DateTime? expiresAt;
}
