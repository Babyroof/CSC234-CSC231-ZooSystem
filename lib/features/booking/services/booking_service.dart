import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _db;

  static const String _collection = 'booking';

  BookingService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Future<void> createBooking(BookingModel booking) async {
    try {
      final map = booking.toMap();
      // Convert userId String → DocumentReference before writing to Firestore
      map['userId'] = _db.collection('user').doc(booking.userId);
      await _db.collection(_collection).add(map);
      debugPrint('[BookingService] createBooking: success');
    } catch (e) {
      debugPrint('[BookingService] createBooking error: $e');
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
