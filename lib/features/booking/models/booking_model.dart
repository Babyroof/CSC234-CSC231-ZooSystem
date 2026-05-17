import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/booking_pricing.dart';
import 'selected_add_on_model.dart';

class BookingModel {
  final String id;
  final String userId;
  final int adultTotal;
  final int childTotal;
  final int elderTotal;
  final DateTime date;
  final List<SelectedAddOnModel> selectedAddOns;
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

  const BookingModel({
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

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
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
    final addOns = <SelectedAddOnModel>[];
    if (rawAddOns is List) {
      for (final item in rawAddOns) {
        if (item is Map<String, dynamic>) {
          addOns.add(SelectedAddOnModel.fromMap(item));
        }
      }
    }

    return BookingModel(
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

  factory BookingModel.fromFirestore(DocumentSnapshot doc) =>
      BookingModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  // userId is a plain String here; BookingService converts it to a
  // DocumentReference before writing so the model stays db-instance-free.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'adultTotal': adultTotal,
      'childTotal': childTotal,
      'elderTotal': elderTotal,
      'date': Timestamp.fromDate(date),
      'selectedAddOns': selectedAddOns.map((a) => a.toMap()).toList(),
      'status': status,
    };
    if (chargeId != null) map['chargeId'] = chargeId;
    if (totalPrice != null) map['totalPrice'] = totalPrice;
    return map;
  }

  Map<String, dynamic> toFirestore({required FirebaseFirestore db}) {
    final map = <String, dynamic>{
      'userId': db.collection('user').doc(userId),
      'adultTotal': adultTotal,
      'childTotal': childTotal,
      'elderTotal': elderTotal,
      'date': Timestamp.fromDate(date),
      'selectedAddOns': selectedAddOns.map((a) => a.toMap()).toList(),
      'status': status,
    };
    if (chargeId != null) map['chargeId'] = chargeId;
    if (totalPrice != null) map['totalPrice'] = totalPrice;
    return map;
  }

  BookingModel copyWith({
    String? id,
    String? userId,
    int? adultTotal,
    int? childTotal,
    int? elderTotal,
    DateTime? date,
    List<SelectedAddOnModel>? selectedAddOns,
    String? status,
    String? chargeId,
    int? totalPrice,
    int? adultUnitPrice,
    int? childUnitPrice,
    int? elderUnitPrice,
  }) => BookingModel(
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
