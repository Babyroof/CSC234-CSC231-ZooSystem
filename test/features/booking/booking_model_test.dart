import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/data/models/booking_dto.dart';
import 'package:zoopernova_zoo_system/features/booking/domain/entities/booking_entity.dart';
import 'package:zoopernova_zoo_system/features/booking/domain/entities/selected_add_on_entity.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ── Helper ──────────────────────────────────────────────────────────────
  BookingEntity baseEntity({
    String id = 'bk1',
    int adultTotal = 2,
    int childTotal = 1,
    int elderTotal = 0,
    DateTime? date,
    String status = 'pending',
    String userId = 'user123',
    List<SelectedAddOnEntity> selectedAddOns = const [],
  }) => BookingEntity(
    id: id,
    adultTotal: adultTotal,
    childTotal: childTotal,
    elderTotal: elderTotal,
    date: date ?? DateTime(2026, 5, 10),
    status: status,
    userId: userId,
    selectedAddOns: selectedAddOns,
  );

  // ── fromFirestore ────────────────────────────────────────────────────────
  group('BookingDto.fromFirestore', () {
    test(
      'maps all fields correctly when userId is a DocumentReference',
      () async {
        // Arrange
        final userRef = fakeFirestore.collection('user').doc('user123');
        await fakeFirestore.collection('booking').doc('bk1').set({
          'adultTotal': 2,
          'childTotal': 1,
          'elderTotal': 0,
          'date': Timestamp.fromDate(DateTime(2026, 5, 10)),
          'status': 'pending',
          'userId': userRef,
          'selectedAddOns': [],
        });
        final doc = await fakeFirestore.collection('booking').doc('bk1').get();

        // Act
        final dto = BookingDto.fromFirestore(doc);

        // Assert
        expect(dto.id, 'bk1');
        expect(dto.adultTotal, 2);
        expect(dto.childTotal, 1);
        expect(dto.elderTotal, 0);
        expect(dto.date, DateTime(2026, 5, 10));
        expect(dto.status, 'pending');
        expect(dto.userId, 'user123');
      },
    );

    test('handles userId stored as plain String', () async {
      // Arrange
      await fakeFirestore.collection('booking').doc('bk2').set({
        'adultTotal': 1,
        'childTotal': 0,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'status': 'Done',
        'userId': 'plainStringUid',
        'selectedAddOns': [],
      });
      final doc = await fakeFirestore.collection('booking').doc('bk2').get();

      // Act
      final dto = BookingDto.fromFirestore(doc);

      // Assert
      expect(dto.userId, 'plainStringUid');
      expect(dto.status, 'Done');
    });

    test('falls back to epoch when date field is missing', () async {
      // Arrange
      await fakeFirestore.collection('booking').doc('bk3').set({
        'adultTotal': 0,
        'childTotal': 0,
        'elderTotal': 0,
        'status': 'pending',
        'userId': 'uid',
      });
      final doc = await fakeFirestore.collection('booking').doc('bk3').get();

      // Act
      final dto = BookingDto.fromFirestore(doc);

      // Assert
      expect(dto.date, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('defaults numeric fields to 0 when missing', () async {
      // Arrange
      await fakeFirestore.collection('booking').doc('bk4').set({
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'status': 'pending',
        'userId': 'uid',
      });
      final doc = await fakeFirestore.collection('booking').doc('bk4').get();

      // Act
      final dto = BookingDto.fromFirestore(doc);

      // Assert
      expect(dto.adultTotal, 0);
      expect(dto.childTotal, 0);
      expect(dto.elderTotal, 0);
    });

    test(
      'selectedAddOns defaults to empty list when field is absent',
      () async {
        // Arrange
        await fakeFirestore.collection('booking').doc('bk5').set({
          'adultTotal': 1,
          'childTotal': 0,
          'elderTotal': 0,
          'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
          'status': 'pending',
          'userId': 'uid',
        });
        final doc = await fakeFirestore.collection('booking').doc('bk5').get();

        // Act
        final dto = BookingDto.fromFirestore(doc);

        // Assert
        expect(dto.selectedAddOns, isEmpty);
      },
    );
  });

  // ── entity fields ────────────────────────────────────────────────────────
  group('BookingEntity fields', () {
    test('stores all field values correctly', () {
      // Arrange
      final date = DateTime(2026, 5, 10);
      final entity = baseEntity(date: date);

      // Assert
      expect(entity.adultTotal, 2);
      expect(entity.childTotal, 1);
      expect(entity.elderTotal, 0);
      expect(entity.date, date);
      expect(entity.status, 'pending');
      expect(entity.userId, 'user123');
    });

    test('numeric fields are int', () {
      final entity = baseEntity(adultTotal: 3, childTotal: 2, elderTotal: 1);

      expect(entity.adultTotal, isA<int>());
      expect(entity.childTotal, isA<int>());
      expect(entity.elderTotal, isA<int>());
    });

    test('userId is a String', () {
      final entity = baseEntity(userId: 'user123');

      expect(entity.userId, isA<String>());
      expect(entity.userId, 'user123');
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────
  group('BookingEntity.copyWith', () {
    test('updates only specified fields, leaves others unchanged', () {
      // Arrange
      final original = baseEntity();

      // Act
      final updated = original.copyWith(adultTotal: 5, status: 'Done');

      // Assert — changed
      expect(updated.adultTotal, 5);
      expect(updated.status, 'Done');
      // Assert — unchanged
      expect(updated.id, original.id);
      expect(updated.childTotal, original.childTotal);
      expect(updated.elderTotal, original.elderTotal);
      expect(updated.date, original.date);
      expect(updated.userId, original.userId);
    });

    test('returns equivalent object when no fields are changed', () {
      // Arrange
      final original = baseEntity();

      // Act
      final copy = original.copyWith();

      // Assert
      expect(copy.id, original.id);
      expect(copy.adultTotal, original.adultTotal);
      expect(copy.childTotal, original.childTotal);
      expect(copy.elderTotal, original.elderTotal);
      expect(copy.date, original.date);
      expect(copy.status, original.status);
      expect(copy.userId, original.userId);
    });

    test('can update status to Done', () {
      // Arrange/Act
      final updated = baseEntity().copyWith(status: 'Done');

      // Assert
      expect(updated.status, 'Done');
    });
  });
}
