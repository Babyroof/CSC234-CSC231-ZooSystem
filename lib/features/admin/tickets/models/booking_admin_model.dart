class BookingAdminModel {
  final String id;
  final String userId;
  final String userName;
  final int adultTotal;
  final int childTotal;
  final int elderTotal;
  final DateTime date;
  final bool buffetFood;
  final bool guideTour;
  final bool golfCar;
  final String status;

  const BookingAdminModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.adultTotal,
    required this.childTotal,
    required this.elderTotal,
    required this.date,
    required this.buffetFood,
    required this.guideTour,
    required this.golfCar,
    required this.status,
  });

  int get totalTickets => adultTotal + childTotal + elderTotal;

  // TODO (backend): service layer must convert Firestore Timestamp → DateTime before calling fromMap
  factory BookingAdminModel.fromMap(
    String id,
    Map<String, dynamic> map,
    String userName,
  ) {
    return BookingAdminModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: userName,
      adultTotal: (map['adultTotal'] as num?)?.toInt() ?? 0,
      childTotal: (map['childTotal'] as num?)?.toInt() ?? 0,
      elderTotal: (map['elderTotal'] as num?)?.toInt() ?? 0,
      date: (map['date'] as DateTime?) ?? DateTime.now(),
      buffetFood: map['BuffetFood'] ?? false,
      guideTour: map['GuideTour'] ?? false,
      golfCar: map['GolfCar'] ?? false,
      status: map['status'] ?? 'pending',
    );
  }
}
