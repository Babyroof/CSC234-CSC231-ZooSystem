import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/add_ons/services/add_on_admin_service.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late AddOnAdminService service;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    service = AddOnAdminService(db: fakeDb);
  });

  // ── Helper ────────────────────────────────────────────────────────────────
  Future<String> seedAddOn({
    String name = 'Test Add-On',
    int price = 100,
    String priceType = 'per_booking',
    int order = 1,
    bool isActive = true,
  }) async {
    final ref = await fakeDb.collection('addOns').add({
      'name': name,
      'price': price,
      'priceType': priceType,
      'order': order,
      'isActive': isActive,
    });
    return ref.id;
  }

  // ── getAddOns ─────────────────────────────────────────────────────────────
  group('getAddOns', () {
    test('returns stream of all addOns sorted by order field ascending', () async {
      // Arrange — insert in reverse order to verify sorting
      await fakeDb.collection('addOns').add({
        'name': 'B',
        'price': 200,
        'priceType': 'per_booking',
        'order': 2,
        'isActive': true,
      });
      await fakeDb.collection('addOns').add({
        'name': 'A',
        'price': 100,
        'priceType': 'per_person',
        'order': 1,
        'isActive': true,
      });

      // Act
      final result = await service.getAddOns().first;

      // Assert
      expect(result.length, 2);
      expect(result[0].name, 'A');
      expect(result[1].name, 'B');
    });

    test('returns empty list when collection is empty', () async {
      // Arrange — fakeDb has no documents

      // Act
      final result = await service.getAddOns().first;

      // Assert
      expect(result, isEmpty);
    });

    test('stream emits updated list when document is added (real-time update)', () async {
      // Arrange — subscribe before any data exists
      final streamFuture = service.getAddOns().skip(1).first;

      // Act — add a document after the stream has started
      await fakeDb.collection('addOns').add({
        'name': 'Golf Car',
        'price': 500,
        'priceType': 'per_booking',
        'order': 1,
        'isActive': true,
      });

      // Assert — second emission contains the newly added document
      final result = await streamFuture;
      expect(result.length, 1);
      expect(result.first.name, 'Golf Car');
    });
  });

  // ── createAddOn ───────────────────────────────────────────────────────────
  group('createAddOn', () {
    test('writes name, price, priceType, order to Firestore', () async {
      // Arrange — fresh fakeDb (done in setUp)

      // Act
      await service.createAddOn(
        name: 'Buffet Food',
        price: 350,
        priceType: 'per_person',
        order: 2,
      );

      // Assert
      final snap = await fakeDb.collection('addOns').get();
      expect(snap.docs.length, 1);
      final data = snap.docs.first.data();
      expect(data['name'], 'Buffet Food');
      expect(data['price'], 350);
      expect(data['priceType'], 'per_person');
      expect(data['order'], 2);
    });

    test('isActive defaults to true when not specified', () async {
      // Arrange — fresh fakeDb (done in setUp)

      // Act
      await service.createAddOn(
        name: 'Guide Tour',
        price: 200,
        priceType: 'per_booking',
        order: 1,
      );

      // Assert
      final snap = await fakeDb.collection('addOns').get();
      expect(snap.docs.first.data()['isActive'], true);
    });

    test('isActive can be set to false explicitly', () async {
      // Arrange — fresh fakeDb (done in setUp)

      // Act
      await service.createAddOn(
        name: 'Inactive Option',
        price: 100,
        priceType: 'per_booking',
        order: 3,
        isActive: false,
      );

      // Assert
      final snap = await fakeDb.collection('addOns').get();
      expect(snap.docs.first.data()['isActive'], false);
    });
  });

  // ── updateAddOn ───────────────────────────────────────────────────────────
  group('updateAddOn', () {
    test('updates all fields in Firestore document', () async {
      // Arrange
      final id = await seedAddOn(
        name: 'Old Name',
        price: 100,
        priceType: 'per_booking',
        order: 1,
        isActive: true,
      );

      // Act
      await service.updateAddOn(
        id: id,
        name: 'New Name',
        price: 999,
        priceType: 'per_person',
        order: 5,
        isActive: false,
      );

      // Assert
      final data = (await fakeDb.collection('addOns').doc(id).get()).data()!;
      expect(data['name'], 'New Name');
      expect(data['price'], 999);
      expect(data['priceType'], 'per_person');
      expect(data['order'], 5);
      expect(data['isActive'], false);
    });

    test('does NOT delete document — document still exists after update', () async {
      // Arrange
      final id = await seedAddOn(name: 'Persistent');

      // Act
      await service.updateAddOn(
        id: id,
        name: 'Persistent Updated',
        price: 200,
        priceType: 'per_booking',
        order: 2,
        isActive: true,
      );

      // Assert
      final doc = await fakeDb.collection('addOns').doc(id).get();
      expect(doc.exists, true);
    });

    test('updated fields are readable back from Firestore', () async {
      // Arrange
      final id = await seedAddOn(name: 'Before', price: 50);

      // Act
      await service.updateAddOn(
        id: id,
        name: 'After',
        price: 750,
        priceType: 'per_person',
        order: 10,
        isActive: true,
      );

      // Assert — read back via raw Firestore get to confirm persistence
      final snap = await fakeDb.collection('addOns').doc(id).get();
      expect(snap.data()!['name'], 'After');
      expect(snap.data()!['price'], 750);
    });
  });

  // ── deleteAddOn ───────────────────────────────────────────────────────────
  group('deleteAddOn', () {
    test('document no longer exists after delete', () async {
      // Arrange
      final id = await seedAddOn(name: 'To Delete');

      // Act
      await service.deleteAddOn(id);

      // Assert
      final doc = await fakeDb.collection('addOns').doc(id).get();
      expect(doc.exists, false);
    });

    test('other documents are not affected when one is deleted', () async {
      // Arrange
      final keepId = await seedAddOn(name: 'Keep Me', order: 1);
      final removeId = await seedAddOn(name: 'Remove Me', order: 2);

      // Act
      await service.deleteAddOn(removeId);

      // Assert — only the targeted document is gone
      final remaining = await fakeDb.collection('addOns').get();
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.id, keepId);
      expect(remaining.docs.first.data()['name'], 'Keep Me');
    });
  });

  // ── toggleActive ──────────────────────────────────────────────────────────
  group('toggleActive', () {
    test('only isActive field changes when toggled', () async {
      // Arrange
      final ref = await fakeDb.collection('addOns').add({
        'name': 'Golf Car',
        'price': 500,
        'priceType': 'per_booking',
        'order': 1,
        'isActive': true,
      });

      // Act
      await service.toggleActive(ref.id, false);

      // Assert — isActive flipped; other fields untouched
      final data = (await fakeDb.collection('addOns').doc(ref.id).get()).data()!;
      expect(data['isActive'], false);
      expect(data['name'], 'Golf Car');
      expect(data['price'], 500);
    });

    test('name and price remain unchanged after toggleActive', () async {
      // Arrange
      final id = await seedAddOn(name: 'Buffet', price: 300, isActive: false);

      // Act — toggle from false to true
      await service.toggleActive(id, true);

      // Assert — only isActive was mutated
      final data = (await fakeDb.collection('addOns').doc(id).get()).data()!;
      expect(data['isActive'], true);
      expect(data['name'], 'Buffet');
      expect(data['price'], 300);
    });
  });
}
