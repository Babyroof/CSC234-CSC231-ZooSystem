import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_admin_model.dart';

class BookingAdminService {
  // TODO: Inject FirebaseFirestore — replace all methods with real Firestore calls
  final List<BookingAdminModel> _bookings = [
    BookingAdminModel(
      id: 'mock_1',
      userId: 'user_1',
      userName: 'Nathithorn B.',
      adultTotal: 2,
      childTotal: 1,
      elderTotal: 0,
      date: DateTime(2026, 5, 20),
      buffetFood: true,
      guideTour: false,
      golfCar: false,
      status: 'pending',
    ),
    BookingAdminModel(
      id: 'mock_2',
      userId: 'user_2',
      userName: 'Somchai K.',
      adultTotal: 1,
      childTotal: 0,
      elderTotal: 1,
      date: DateTime(2026, 5, 22),
      buffetFood: false,
      guideTour: true,
      golfCar: true,
      status: 'done',
    ),
    BookingAdminModel(
      id: 'mock_3',
      userId: 'user_3',
      userName: 'Malee W.',
      adultTotal: 3,
      childTotal: 2,
      elderTotal: 1,
      date: DateTime(2026, 5, 25),
      buffetFood: true,
      guideTour: true,
      golfCar: false,
      status: 'pending',
    ),
  ];

  Future<List<BookingAdminModel>> getBookings() async {
    // TODO: Query 'booking' ordered by date desc, then fetch each userId from 'user' for userName
    return List.from(_bookings);
  }

  Future<void> updateStatus(String id, String status) async {
    // TODO: _db.collection('booking').doc(id).update({'status': status})
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index == -1) return;
    final old = _bookings[index];
    _bookings[index] = BookingAdminModel(
      id: old.id,
      userId: old.userId,
      userName: old.userName,
      adultTotal: old.adultTotal,
      childTotal: old.childTotal,
      elderTotal: old.elderTotal,
      date: old.date,
      buffetFood: old.buffetFood,
      guideTour: old.guideTour,
      golfCar: old.golfCar,
      status: status,
    );
  }
}

final bookingAdminServiceProvider = Provider<BookingAdminService>(
  (ref) => BookingAdminService(),
);
