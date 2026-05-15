import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/tickets/models/ticket_model.dart';
import 'package:zoopernova_zoo_system/features/booking/models/selected_add_on_model.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
  });

  // ── Helper ──────────────────────────────────────────────────────────────
  TicketModel baseModel({
    String id = 'tk1',
    List<SelectedAddOnModel>? selectedAddOns,
    int adultTotal = 2,
    int childTotal = 1,
    int elderTotal = 0,
    DateTime? date,
    String status = 'pending',
    DocumentReference? userId,
  }) {
    final ref = fakeFirestore.collection('user').doc('user123');
    return TicketModel(
      id: id,
      selectedAddOns: selectedAddOns ?? [
        const SelectedAddOnModel(
          addOnId: 'addon1',
          name: 'Golf Car',
          price: 500,
          priceType: 'per_booking',
        ),
      ],
      adultTotal: adultTotal,
      childTotal: childTotal,
      elderTotal: elderTotal,
      date: date ?? DateTime(2026, 5, 10),
      status: status,
      userId: userId ?? ref,
    );
  }

  // ── fromFirestore ────────────────────────────────────────────────────────
  group('TicketModel.fromFirestore', () {
    test('maps all fields correctly', () async {
      // Arrange
      final userRef = fakeFirestore.collection('user').doc('user123');
      await fakeFirestore.collection('booking').doc('tk1').set({
        'selectedAddOns': [
          {'addOnId': 'addon1', 'name': 'Golf Car', 'price': 500, 'priceType': 'per_booking'},
        ],
        'adultTotal': 2,
        'childTotal': 1,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 5, 10)),
        'status': 'pending',
        'userId': userRef,
      });
      final doc = await fakeFirestore.collection('booking').doc('tk1').get();

      // Act
      final model = TicketModel.fromFirestore(doc);

      // Assert
      expect(model.id, 'tk1');
      expect(model.selectedAddOns, hasLength(1));
      expect(model.selectedAddOns.first.addOnId, 'addon1');
      expect(model.selectedAddOns.first.name, 'Golf Car');
      expect(model.adultTotal, 2);
      expect(model.childTotal, 1);
      expect(model.elderTotal, 0);
      expect(model.date, DateTime(2026, 5, 10));
      expect(model.status, 'pending');
      expect(model.userId, isA<DocumentReference>());
      expect(model.userId.id, 'user123');
    });

    test('boolean fields default to false when absent', () async {
      // Arrange
      final userRef = fakeFirestore.collection('user').doc('uid');
      await fakeFirestore.collection('booking').doc('tk2').set({
        'adultTotal': 1,
        'childTotal': 0,
        'elderTotal': 0,
        'date': Timestamp.fromDate(DateTime(2026, 6, 1)),
        'status': 'Done',
        'userId': userRef,
      });
      final doc = await fakeFirestore.collection('booking').doc('tk2').get();

      // Act
      final model = TicketModel.fromFirestore(doc);

      // Assert
      expect(model.selectedAddOns, isEmpty);
    });

    test('falls back to epoch when date field is missing', () async {
      // Arrange
      final userRef = fakeFirestore.collection('user').doc('uid');
      await fakeFirestore.collection('booking').doc('tk3').set({
        'selectedAddOns': <Map<String, dynamic>>[],
        'adultTotal': 0,
        'childTotal': 0,
        'elderTotal': 0,
        'status': 'pending',
        'userId': userRef,
      });
      final doc = await fakeFirestore.collection('booking').doc('tk3').get();

      // Act
      final model = TicketModel.fromFirestore(doc);

      // Assert
      expect(model.date, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('numeric fields default to 0 when absent', () async {
      // Arrange
      final userRef = fakeFirestore.collection('user').doc('uid');
      await fakeFirestore.collection('booking').doc('tk4').set({
        'selectedAddOns': <Map<String, dynamic>>[],
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'status': 'pending',
        'userId': userRef,
      });
      final doc = await fakeFirestore.collection('booking').doc('tk4').get();

      // Act
      final model = TicketModel.fromFirestore(doc);

      // Assert
      expect(model.adultTotal, 0);
      expect(model.childTotal, 0);
      expect(model.elderTotal, 0);
    });
  });

  // ── toMap ────────────────────────────────────────────────────────────────
  group('TicketModel.toMap', () {
    test('returns map with all fields and correct values', () {
      // Arrange
      final date = DateTime(2026, 5, 10);
      final model = baseModel(date: date);

      // Act
      final map = model.toMap();

      // Assert
      expect(map['selectedAddOns'], isA<List>());
      expect(map['adultTotal'], 2);
      expect(map['childTotal'], 1);
      expect(map['elderTotal'], 0);
      expect(map['date'], Timestamp.fromDate(date));
      expect(map['status'], 'pending');
      expect(map['userId'], isA<DocumentReference>());
    });

    test('boolean fields are bool not String', () {
      final model = baseModel(
        selectedAddOns: [
          const SelectedAddOnModel(
            addOnId: 'addon1',
            name: 'Buffet Food',
            price: 200,
            priceType: 'per_person',
          ),
          const SelectedAddOnModel(
            addOnId: 'addon2',
            name: 'Golf Car',
            price: 500,
            priceType: 'per_booking',
          ),
        ],
      );
      final map = model.toMap();

      expect(map['selectedAddOns'], isA<List>());
      final addOns = map['selectedAddOns'] as List;
      expect(addOns.first['addOnId'], isA<String>());
    });

    test('numeric fields are int not String', () {
      final map = baseModel(
        adultTotal: 3,
        childTotal: 2,
        elderTotal: 1,
      ).toMap();

      expect(map['adultTotal'], isA<int>());
      expect(map['childTotal'], isA<int>());
      expect(map['elderTotal'], isA<int>());
    });

    test('date field is Timestamp not String', () {
      final map = baseModel().toMap();
      expect(map['date'], isA<Timestamp>());
    });

    test('userId field is DocumentReference', () {
      final map = baseModel().toMap();
      expect(map['userId'], isA<DocumentReference>());
      expect((map['userId'] as DocumentReference).id, 'user123');
    });
  });

  // ── copyWith ─────────────────────────────────────────────────────────────
  group('TicketModel.copyWith', () {
    test('updates only specified fields, leaves others unchanged', () {
      // Arrange
      final original = baseModel();

      // Act
      final updated = original.copyWith(status: 'Done', adultTotal: 5);

      // Assert — changed
      expect(updated.status, 'Done');
      expect(updated.adultTotal, 5);
      // Assert — unchanged
      expect(updated.id, original.id);
      expect(updated.selectedAddOns, original.selectedAddOns);
      expect(updated.childTotal, original.childTotal);
      expect(updated.elderTotal, original.elderTotal);
      expect(updated.date, original.date);
      expect(updated.userId, original.userId);
    });

    test('returns equivalent object when no fields are changed', () {
      final original = baseModel();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.selectedAddOns, original.selectedAddOns);
      expect(copy.adultTotal, original.adultTotal);
      expect(copy.childTotal, original.childTotal);
      expect(copy.elderTotal, original.elderTotal);
      expect(copy.date, original.date);
      expect(copy.status, original.status);
      expect(copy.userId, original.userId);
    });

    test('can update userId to a different DocumentReference', () {
      // Arrange
      final original = baseModel();
      final newRef = fakeFirestore.collection('user').doc('user999');

      // Act
      final updated = original.copyWith(userId: newRef);

      // Assert
      expect(updated.userId.id, 'user999');
      expect(updated.id, original.id);
    });
  });
}
