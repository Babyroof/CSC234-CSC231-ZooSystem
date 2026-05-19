import '../../constants/booking_pricing.dart';
import 'selected_add_on_entity.dart';

class BookingEntity {
  const BookingEntity({
    required this.id,
    required this.userId,
    required this.adultTotal,
    required this.childTotal,
    required this.elderTotal,
    required this.date,
    required this.status,
    this.selectedAddOns = const [],
    this.chargeId,
    this.totalPrice,
    this.adultUnitPrice = BookingPricing.adultPrice,
    this.childUnitPrice = BookingPricing.kidPrice,
    this.elderUnitPrice = BookingPricing.elderPrice,
  });

  final String id;
  final String userId;
  final int adultTotal;
  final int childTotal;
  final int elderTotal;
  final DateTime date;
  final List<SelectedAddOnEntity> selectedAddOns;
  final String status;
  final String? chargeId;
  final int? totalPrice;
  final int adultUnitPrice;
  final int childUnitPrice;
  final int elderUnitPrice;

  int get totalAmount =>
      (adultTotal * adultUnitPrice) +
      (childTotal * childUnitPrice) +
      (elderTotal * elderUnitPrice) +
      selectedAddOns.fold(0, (acc, a) => acc + a.price);

  BookingEntity copyWith({
    String? id,
    String? userId,
    int? adultTotal,
    int? childTotal,
    int? elderTotal,
    DateTime? date,
    List<SelectedAddOnEntity>? selectedAddOns,
    String? status,
    String? chargeId,
    int? totalPrice,
    int? adultUnitPrice,
    int? childUnitPrice,
    int? elderUnitPrice,
  }) => BookingEntity(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    adultTotal: adultTotal ?? this.adultTotal,
    childTotal: childTotal ?? this.childTotal,
    elderTotal: elderTotal ?? this.elderTotal,
    date: date ?? this.date,
    selectedAddOns: selectedAddOns ?? this.selectedAddOns,
    status: status ?? this.status,
    chargeId: chargeId ?? this.chargeId,
    totalPrice: totalPrice ?? this.totalPrice,
    adultUnitPrice: adultUnitPrice ?? this.adultUnitPrice,
    childUnitPrice: childUnitPrice ?? this.childUnitPrice,
    elderUnitPrice: elderUnitPrice ?? this.elderUnitPrice,
  );
}
