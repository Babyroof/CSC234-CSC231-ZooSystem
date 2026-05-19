import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking_entity.dart';
import 'selected_add_on_dto.dart';

class BookingDto {
  const BookingDto({
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
  });

  final String id;
  final String userId;
  final int adultTotal;
  final int childTotal;
  final int elderTotal;
  final DateTime date;
  final List<SelectedAddOnDto> selectedAddOns;
  final String status;
  final String? chargeId;
  final int? totalPrice;

  factory BookingDto.fromMap(String id, Map<String, dynamic> map) {
    String resolvedUserId = '';
    final rawUserId = map['userId'];
    if (rawUserId is DocumentReference) {
      resolvedUserId = rawUserId.id;
    } else if (rawUserId is String) {
      resolvedUserId = rawUserId;
    }

    DateTime resolvedDate = DateTime.fromMillisecondsSinceEpoch(0);
    final rawDate = map['date'];
    if (rawDate is Timestamp) {
      resolvedDate = rawDate.toDate();
    }

    final rawAddOns = map['selectedAddOns'];
    final addOns = <SelectedAddOnDto>[];
    if (rawAddOns is List) {
      for (final item in rawAddOns) {
        if (item is Map<String, dynamic>) {
          addOns.add(SelectedAddOnDto.fromMap(item));
        }
      }
    }

    return BookingDto(
      id: id,
      userId: resolvedUserId,
      adultTotal: (map['adultTotal'] as num? ?? 0).toInt(),
      childTotal: (map['childTotal'] as num? ?? 0).toInt(),
      elderTotal: (map['elderTotal'] as num? ?? 0).toInt(),
      date: resolvedDate,
      selectedAddOns: addOns,
      status: map['status'] as String? ?? 'pending',
      chargeId: map['chargeId'] as String?,
      totalPrice: (map['totalPrice'] as num?)?.toInt(),
    );
  }

  factory BookingDto.fromFirestore(DocumentSnapshot doc) =>
      BookingDto.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  BookingEntity toEntity() => BookingEntity(
    id: id,
    userId: userId,
    adultTotal: adultTotal,
    childTotal: childTotal,
    elderTotal: elderTotal,
    date: date,
    selectedAddOns: selectedAddOns.map((d) => d.toEntity()).toList(),
    status: status,
    chargeId: chargeId,
    totalPrice: totalPrice,
  );
}
