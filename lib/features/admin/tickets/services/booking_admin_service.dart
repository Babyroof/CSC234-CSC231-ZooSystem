import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_admin_model.dart';

class BookingAdminService {
  BookingAdminService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const _col = 'booking';

  Stream<List<BookingAdminModel>> watchBookings() {
    return _db
        .collection(_col)
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap(_mapSnap);
  }

  Future<List<BookingAdminModel>> _mapSnap(QuerySnapshot snap) async {
    final results = <BookingAdminModel>[];
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      results.add(
        BookingAdminModel(
          id: doc.id,
          userId: _resolveUserId(data['userId']),
          userName: await _resolveUserName(data['userId']),
          adultTotal: (data['adultTotal'] as num? ?? 0).toInt(),
          childTotal: (data['childTotal'] as num? ?? 0).toInt(),
          elderTotal: (data['elderTotal'] as num? ?? 0).toInt(),
          date: _toDate(data['date']),
          buffetFood: data['BuffetFood'] == true,
          guideTour: data['GuideTour'] == true,
          golfCar: data['GolfCar'] == true,
          status: _normalizeStatus(data['status'] as String? ?? 'pending'),
        ),
      );
    }
    return results;
  }

  String _resolveUserId(dynamic raw) {
    if (raw is DocumentReference) return raw.id;
    return (raw as String?) ?? '';
  }

  Future<String> _resolveUserName(dynamic raw) async {
    if (raw is! DocumentReference) return 'Unknown';
    try {
      final snap = await raw.get();
      if (!snap.exists) return 'Unknown';
      final d = snap.data() as Map<String, dynamic>;
      final fn = (d['firstname'] as String? ?? '').trim();
      final ln = (d['lastname'] as String? ?? '').trim();
      final full = '$fn $ln'.trim();
      return full.isNotEmpty ? full : (d['username'] as String? ?? 'Unknown');
    } catch (e) {
      debugPrint('[BookingAdminService] _resolveUserName: $e');
      return 'Unknown';
    }
  }

  // 'Cancelled' in Firestore → 'cancel' in UI; reverse on write
  String _normalizeStatus(String s) {
    final lower = s.toLowerCase();
    return lower == 'cancelled' ? 'cancel' : lower;
  }

  String _toFirestoreStatus(String s) => s == 'cancel' ? 'Cancelled' : s;

  DateTime _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }

  Future<void> updateBooking({
    required String id,
    required DateTime date,
    required String status,
  }) async {
    try {
      await _db.collection(_col).doc(id).update({
        'date': Timestamp.fromDate(date),
        'status': _toFirestoreStatus(status),
      });
      debugPrint('[BookingAdminService] updateBooking: $id → $status');
    } catch (e) {
      debugPrint('[BookingAdminService] updateBooking error: $e');
      rethrow;
    }
  }

  Future<void> deleteBooking(String id) async {
    try {
      await _db.collection(_col).doc(id).delete();
      debugPrint('[BookingAdminService] deleteBooking: $id deleted');
    } catch (e) {
      debugPrint('[BookingAdminService] deleteBooking error: $e');
      rethrow;
    }
  }
}

final bookingAdminServiceProvider = Provider<BookingAdminService>(
  (ref) => BookingAdminService(),
);
