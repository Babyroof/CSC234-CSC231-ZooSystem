import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/event_dto.dart';

abstract class EventRemoteDataSource {
  Future<List<EventDto>> getEvents();
  Future<List<EventDto>> getRandomEvents(int count);
}

class EventRemoteDataSourceImpl implements EventRemoteDataSource {
  final FirebaseFirestore _db;

  EventRemoteDataSourceImpl({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  @override
  Future<List<EventDto>> getEvents() async {
    try {
      final snap = await _db.collection('event').get();
      return snap.docs.map((d) => EventDto.fromMap(d.id, d.data())).toList();
    } catch (e) {
      debugPrint('[EventDataSource] getEvents failed: $e');
      return [];
    }
  }

  @override
  Future<List<EventDto>> getRandomEvents(int count) async {
    try {
      final snap = await _db.collection('event').get();
      final list = snap.docs
          .map((d) => EventDto.fromMap(d.id, d.data()))
          .toList();
      list.shuffle();
      return list.take(count).toList();
    } catch (e) {
      debugPrint('[EventDataSource] getRandomEvents failed: $e');
      return [];
    }
  }
}
