import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ticket_model.dart';

class TicketService {
  final FirebaseFirestore _db;

  static const String _collection = 'booking';

  TicketService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  Stream<List<TicketModel>> getAllTickets() {
    try {
      return _db
          .collection(_collection)
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((doc) => TicketModel.fromFirestore(doc)).toList(),
          )
          .handleError((Object e) {
            debugPrint('[TicketService] getAllTickets stream error: $e');
            throw e;
          });
    } catch (e) {
      debugPrint('[TicketService] getAllTickets error: $e');
      rethrow;
    }
  }

  Future<TicketModel?> getTicketById(String ticketId) async {
    try {
      final doc = await _db.collection(_collection).doc(ticketId).get();
      if (!doc.exists) return null;
      return TicketModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[TicketService] getTicketById error: $e');
      rethrow;
    }
  }

  Future<void> updateTicket({
    required String ticketId,
    required bool buffetFood,
    required bool golfCar,
    required bool guidTour,
    required int adultTotal,
    required int childTotal,
    required int elderTotal,
    required DateTime date,
    required String status,
    required DocumentReference userId,
  }) async {
    try {
      await _db.collection(_collection).doc(ticketId).update({
        'BuffetFood': buffetFood,
        'GolfCar': golfCar,
        'GuidTour': guidTour,
        'adultTotal': adultTotal,
        'childTotal': childTotal,
        'elderTotal': elderTotal,
        'date': Timestamp.fromDate(date),
        'status': status,
        'userId': userId,
      });
      debugPrint('[TicketService] updateTicket: $ticketId updated');
    } catch (e) {
      debugPrint('[TicketService] updateTicket error: $e');
      rethrow;
    }
  }

  Future<void> deleteTicket(String ticketId) async {
    try {
      await _db.collection(_collection).doc(ticketId).delete();
      debugPrint('[TicketService] deleteTicket: $ticketId deleted');
    } catch (e) {
      debugPrint('[TicketService] deleteTicket error: $e');
      rethrow;
    }
  }
}
