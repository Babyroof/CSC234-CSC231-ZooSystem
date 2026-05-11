import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _db;

  static const String _collection = 'booking';

  BookingService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  Future<String> createBooking(BookingModel booking) async {
    try {
      final map = booking.toMap();
      // Convert userId String → DocumentReference before writing to Firestore
      map['userId'] = _db.collection('user').doc(booking.userId);
      map['totalPrice'] = booking.totalAmount;
      // New bookings always start as 'pending' regardless of model value
      map['status'] = 'pending';
      final docRef = await _db.collection(_collection).add(map);
      debugPrint('[BookingService] createBooking: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('[BookingService] createBooking error: $e');
      rethrow;
    }
  }

  Future<void> updateStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      await _db.collection(_collection).doc(bookingId).update({
        'status': status,
      });
      debugPrint('[BookingService] updateStatus: $bookingId → $status');
    } catch (e) {
      debugPrint('[BookingService] updateStatus error: $e');
      rethrow;
    }
  }

  Future<void> updateChargeId({
    required String bookingId,
    required String chargeId,
  }) async {
    try {
      await _db.collection(_collection).doc(bookingId).update({
        'chargeId': chargeId,
      });
      debugPrint('[BookingService] updateChargeId: $bookingId → $chargeId');
    } catch (e) {
      debugPrint('[BookingService] updateChargeId error: $e');
      rethrow;
    }
  }

  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _db.collection(_collection).doc(bookingId).get();
      if (!doc.exists) return null;
      return BookingModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[BookingService] getBookingById error: $e');
      rethrow;
    }
  }

  Stream<BookingModel?> watchBooking(String bookingId) {
    try {
      return _db
          .collection(_collection)
          .doc(bookingId)
          .snapshots()
          .map((doc) => doc.exists ? BookingModel.fromFirestore(doc) : null)
          .handleError((Object e) {
            debugPrint('[BookingService] watchBooking stream error: $e');
            throw e;
          });
    } catch (e) {
      debugPrint('[BookingService] watchBooking error: $e');
      rethrow;
    }
  }

  Stream<List<BookingModel>> getBookingsByUser(String userId) {
    try {
      final userRef = _db.collection('user').doc(userId);
      return _db
          .collection(_collection)
          .where('userId', isEqualTo: userRef)
          .orderBy('date', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) => BookingModel.fromFirestore(doc))
                .toList(),
          )
          .handleError((Object e) {
            debugPrint('[BookingService] getBookingsByUser stream error: $e');
            throw e;
          });
    } catch (e) {
      debugPrint('[BookingService] getBookingsByUser error: $e');
      rethrow;
    }
  }

  Stream<List<BookingModel>> getUpcomingBookings(String userId) {
    try {
      final startOfToday = Timestamp.fromDate(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      );
      final userRef = _db.collection('user').doc(userId);
      return _db
          .collection(_collection)
          .where('userId', isEqualTo: userRef)
          .where('status', isEqualTo: 'Done')
          .where('date', isGreaterThanOrEqualTo: startOfToday)
          .orderBy('date', descending: false)
          .snapshots()
          .map((s) => s.docs.map(BookingModel.fromFirestore).toList())
          .handleError((Object e) {
            debugPrint('[BookingService] getUpcomingBookings stream error: $e');
            throw e;
          });
    } catch (e) {
      debugPrint('[BookingService] getUpcomingBookings error: $e');
      rethrow;
    }
  }

  Stream<List<BookingModel>> getPastBookings(String userId) {
    try {
      final startOfToday = Timestamp.fromDate(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
      );
      final userRef = _db.collection('user').doc(userId);
      return _db
          .collection(_collection)
          .where('userId', isEqualTo: userRef)
          .where('status', isEqualTo: 'Done')
          .where('date', isLessThan: startOfToday)
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) => s.docs.map(BookingModel.fromFirestore).toList())
          .handleError((Object e) {
            debugPrint('[BookingService] getPastBookings stream error: $e');
            throw e;
          });
    } catch (e) {
      debugPrint('[BookingService] getPastBookings error: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      await _db.collection(_collection).doc(bookingId).delete();
      debugPrint('[BookingService] deleteBooking: $bookingId deleted');
    } catch (e) {
      debugPrint('[BookingService] deleteBooking error: $e');
      rethrow;
    }
  }
}
