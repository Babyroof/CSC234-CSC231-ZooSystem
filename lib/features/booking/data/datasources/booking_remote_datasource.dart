import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/booking_entity.dart';
import '../models/booking_dto.dart';

abstract class BookingRemoteDataSource {
  Future<String> createBooking(BookingEntity booking);
  Future<void> updateStatus({
    required String bookingId,
    required String status,
  });
  Future<void> updateChargeId({
    required String bookingId,
    required String chargeId,
  });
  Future<BookingDto?> getBookingById(String bookingId);
  Stream<BookingDto?> watchBooking(String bookingId);
  Stream<List<BookingDto>> getUpcomingBookings(String userId);
  Stream<List<BookingDto>> getPastBookings(String userId);
  Future<void> deleteBooking(String bookingId);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  BookingRemoteDataSourceImpl({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const String _collection = 'booking';

  @override
  Future<String> createBooking(BookingEntity booking) async {
    try {
      final map = <String, dynamic>{
        'userId': _db.collection('user').doc(booking.userId),
        'adultTotal': booking.adultTotal,
        'childTotal': booking.childTotal,
        'elderTotal': booking.elderTotal,
        'date': Timestamp.fromDate(booking.date),
        'selectedAddOns': booking.selectedAddOns.map((a) => a.toMap()).toList(),
        'status': 'pending',
        'totalPrice': booking.totalAmount,
      };
      final docRef = await _db.collection(_collection).add(map);
      debugPrint('[BookingDataSource] createBooking: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('[BookingDataSource] createBooking error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      await _db.collection(_collection).doc(bookingId).update({
        'status': status,
      });
      debugPrint('[BookingDataSource] updateStatus: $bookingId → $status');
    } catch (e) {
      debugPrint('[BookingDataSource] updateStatus error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateChargeId({
    required String bookingId,
    required String chargeId,
  }) async {
    try {
      await _db.collection(_collection).doc(bookingId).update({
        'chargeId': chargeId,
      });
      debugPrint('[BookingDataSource] updateChargeId: $bookingId → $chargeId');
    } catch (e) {
      debugPrint('[BookingDataSource] updateChargeId error: $e');
      rethrow;
    }
  }

  @override
  Future<BookingDto?> getBookingById(String bookingId) async {
    try {
      final doc = await _db.collection(_collection).doc(bookingId).get();
      if (!doc.exists) return null;
      return BookingDto.fromFirestore(doc);
    } catch (e) {
      debugPrint('[BookingDataSource] getBookingById error: $e');
      rethrow;
    }
  }

  @override
  Stream<BookingDto?> watchBooking(String bookingId) {
    return _db
        .collection(_collection)
        .doc(bookingId)
        .snapshots()
        .map((doc) => doc.exists ? BookingDto.fromFirestore(doc) : null)
        .handleError((Object e) {
          debugPrint('[BookingDataSource] watchBooking error: $e');
          throw e;
        });
  }

  @override
  Stream<List<BookingDto>> getUpcomingBookings(String userId) {
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
        .map((s) => s.docs.map(BookingDto.fromFirestore).toList())
        .handleError((Object e) {
          debugPrint('[BookingDataSource] getUpcomingBookings error: $e');
          throw e;
        });
  }

  @override
  Stream<List<BookingDto>> getPastBookings(String userId) {
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
        .map((s) => s.docs.map(BookingDto.fromFirestore).toList())
        .handleError((Object e) {
          debugPrint('[BookingDataSource] getPastBookings error: $e');
          throw e;
        });
  }

  @override
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _db.collection(_collection).doc(bookingId).delete();
      debugPrint('[BookingDataSource] deleteBooking: $bookingId deleted');
    } catch (e) {
      debugPrint('[BookingDataSource] deleteBooking error: $e');
      rethrow;
    }
  }
}
