import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String userId;
  final int adultTotal;
  final int childTotal;
  final int elderTotal;
  final DateTime date;
  final bool buffetFood;
  final bool golfCar;
  final bool guidTour;
  final String status;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.adultTotal,
    required this.childTotal,
    required this.elderTotal,
    required this.date,
    required this.buffetFood,
    required this.golfCar,
    required this.guidTour,
    required this.status,
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

    return BookingModel(
      id: id,
      userId: resolvedUserId,
      adultTotal: (map['adultTotal'] as num? ?? 0).toInt(),
      childTotal: (map['childTotal'] as num? ?? 0).toInt(),
      elderTotal: (map['elderTotal'] as num? ?? 0).toInt(),
      date: resolvedDate,
      buffetFood: map['BuffetFood'] == true,
      golfCar: map['GolfCar'] == true,
      guidTour: map['GuidTour'] == true,
      status: map['status'] as String? ?? 'pending',
    );
  }

  factory BookingModel.fromFirestore(DocumentSnapshot doc) =>
      BookingModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);

  // userId is a plain String here; BookingService converts it to a
  // DocumentReference before writing so the model stays db-instance-free.
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'adultTotal': adultTotal,
    'childTotal': childTotal,
    'elderTotal': elderTotal,
    'date': Timestamp.fromDate(date),
    'BuffetFood': buffetFood,
    'GolfCar': golfCar,
    'GuidTour': guidTour,
    'status': status,
  };

  Map<String, dynamic> toFirestore({required FirebaseFirestore db}) => {
    'userId': db.collection('user').doc(userId),
    'adultTotal': adultTotal,
    'childTotal': childTotal,
    'elderTotal': elderTotal,
    'date': Timestamp.fromDate(date),
    'BuffetFood': buffetFood,
    'GolfCar': golfCar,
    'GuidTour': guidTour,
    'status': status,
  };

  BookingModel copyWith({
    String? id,
    String? userId,
    int? adultTotal,
    int? childTotal,
    int? elderTotal,
    DateTime? date,
    bool? buffetFood,
    bool? golfCar,
    bool? guidTour,
    String? status,
  }) => BookingModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    adultTotal: adultTotal ?? this.adultTotal,
    childTotal: childTotal ?? this.childTotal,
    elderTotal: elderTotal ?? this.elderTotal,
    date: date ?? this.date,
    buffetFood: buffetFood ?? this.buffetFood,
    golfCar: golfCar ?? this.golfCar,
    guidTour: guidTour ?? this.guidTour,
    status: status ?? this.status,
  );
}
