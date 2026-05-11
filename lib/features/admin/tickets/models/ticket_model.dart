import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String id;
  final bool buffetFood;
  final bool golfCar;
  final bool guidTour;
  final int adultTotal;
  final int childTotal;
  final int elderTotal;
  final DateTime date;
  final String status;
  final DocumentReference userId;

  const TicketModel({
    required this.id,
    required this.buffetFood,
    required this.golfCar,
    required this.guidTour,
    required this.adultTotal,
    required this.childTotal,
    required this.elderTotal,
    required this.date,
    required this.status,
    required this.userId,
  });

  factory TicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime resolvedDate = DateTime.fromMillisecondsSinceEpoch(0);
    final rawDate = data['date'];
    if (rawDate is Timestamp) {
      resolvedDate = rawDate.toDate();
    }

    return TicketModel(
      id: doc.id,
      buffetFood: data['BuffetFood'] == true,
      golfCar: data['GolfCar'] == true,
      guidTour: data['GuidTour'] == true,
      adultTotal: (data['adultTotal'] as num? ?? 0).toInt(),
      childTotal: (data['childTotal'] as num? ?? 0).toInt(),
      elderTotal: (data['elderTotal'] as num? ?? 0).toInt(),
      date: resolvedDate,
      status: data['status'] as String? ?? 'pending',
      userId: data['userId'] as DocumentReference,
    );
  }

  Map<String, dynamic> toMap() => {
    'BuffetFood': buffetFood,
    'GolfCar': golfCar,
    'GuidTour': guidTour,
    'adultTotal': adultTotal,
    'childTotal': childTotal,
    'elderTotal': elderTotal,
    'date': Timestamp.fromDate(date),
    'status': status,
    'userId': userId,
  };

  TicketModel copyWith({
    String? id,
    bool? buffetFood,
    bool? golfCar,
    bool? guidTour,
    int? adultTotal,
    int? childTotal,
    int? elderTotal,
    DateTime? date,
    String? status,
    DocumentReference? userId,
  }) => TicketModel(
    id: id ?? this.id,
    buffetFood: buffetFood ?? this.buffetFood,
    golfCar: golfCar ?? this.golfCar,
    guidTour: guidTour ?? this.guidTour,
    adultTotal: adultTotal ?? this.adultTotal,
    childTotal: childTotal ?? this.childTotal,
    elderTotal: elderTotal ?? this.elderTotal,
    date: date ?? this.date,
    status: status ?? this.status,
    userId: userId ?? this.userId,
  );
}
