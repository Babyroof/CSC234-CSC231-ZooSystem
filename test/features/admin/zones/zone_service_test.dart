import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/zones/models/zone_admin_model.dart';
import 'package:zoopernova_zoo_system/features/admin/zones/services/zone_admin_service.dart';

// Fake Firestore that throws on every collection() call — used for error tests
class _ErrorFirestore extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
      message: 'Simulated Firestore error',
    );
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ZoneAdminService service;

  setUp(() {
    // Each test gets a fresh, isolated FakeFirebaseFirestore instance
    fakeFirestore = FakeFirebaseFirestore();
    service = ZoneAdminService(db: fakeFirestore);
  });

  // ── Shared seed helper ───────────────────────────────────────────────────
  Future<String> seedZone({
    String? docId,
    String zoneName = 'Bird Zone',
    Map<String, dynamic> extra = const {},
  }) async {
    final ref = docId != null
        ? fakeFirestore.collection('zone').doc(docId)
        : fakeFirestore.collection('zone').doc();
    await ref.set({'zoneName': zoneName, ...extra});
    return ref.id;
  }

  // ── getZones ──────────────────────────────────────────────────────────────
  group('getZones', () {
    test('returns empty list when collection is empty', () async {
      // Arrange — fakeFirestore has no documents

      // Act
      final result = await service.getZones().first;

      // Assert
      expect(result, isEmpty);
    });

    test('streams all zone documents', () async {
      // Arrange — seed two known zones
      await seedZone(docId: 'z1', zoneName: 'Bird Zone');
      await seedZone(docId: 'z2', zoneName: 'Aquatic Zone');

      // Act — take the first emission from the stream
      final result = await service.getZones().first;

      // Assert — both documents are returned with correct names
      expect(result.length, 2);
      expect(result, isA<List<ZoneAdminModel>>());
      final names = result.map((z) => z.zoneName).toSet();
      expect(names, containsAll(['Bird Zone', 'Aquatic Zone']));
    });

    test('reflects new document added after stream starts', () async {
      // Arrange — start listening before any data exists
      final streamFuture = service
          .getZones()
          .skip(1) // skip the initial empty emission
          .first;

      // Act — add a document after the stream has started
      await fakeFirestore.collection('zone').add({'zoneName': 'Safari Zone'});

      // Assert — the second emission contains the newly added zone
      final result = await streamFuture;
      expect(result.length, 1);
      expect(result.first.zoneName, 'Safari Zone');
    });
  });

  // ── addZone ───────────────────────────────────────────────────────────────
  group('addZone', () {
    test('writes correct zoneName field to Firestore', () async {
      // Arrange — fresh fakeFirestore (done in setUp)

      // Act
      await service.addZone('Safari Zone');

      // Assert — read back the collection and verify the written field
      final snap = await fakeFirestore.collection('zone').get();
      expect(snap.docs.length, 1);
      expect(snap.docs.first.data()['zoneName'], 'Safari Zone');
    });

    test('adds multiple zones independently', () async {
      // Arrange — fresh fakeFirestore (done in setUp)

      // Act — call addZone twice with different names
      await service.addZone('Reptile Zone');
      await service.addZone('Aquatic Zone');

      // Assert — two separate documents exist with correct names
      final snap = await fakeFirestore.collection('zone').get();
      expect(snap.docs.length, 2);
      final names = snap.docs.map((d) => d.data()['zoneName'] as String).toSet();
      expect(names, containsAll(['Reptile Zone', 'Aquatic Zone']));
    });
  });

  // ── updateZone ────────────────────────────────────────────────────────────
  group('updateZone', () {
    test('updates only the zoneName field', () async {
      // Arrange — seed a document with an extra field that must be preserved
      final id = await seedZone(
        docId: 'z1',
        zoneName: 'Old Name',
        extra: {'otherField': 'keep_me'},
      );

      // Act
      await service.updateZone(id, 'New Name');

      // Assert — zoneName is updated
      final data =
          (await fakeFirestore.collection('zone').doc(id).get()).data()!;
      expect(data['zoneName'], 'New Name');

      // Assert — the unrelated field is NOT overwritten (update, not set)
      expect(data['otherField'], 'keep_me');
    });

    test(
        'silently succeeds on non-existent doc — fake_cloud_firestore does not '
        'throw for update() on missing documents (unlike production Firestore)',
        () async {
      // Arrange — empty Firestore; no document exists with this ID
      // NOTE: Real Firestore would throw a NOT_FOUND error when calling
      // .update() on a missing document. fake_cloud_firestore ^3.0.0 creates
      // the document instead of throwing, so we cannot assert a throw here.
      // This test documents the known limitation of the fake implementation.

      // Act + Assert — no exception is thrown
      await expectLater(
        service.updateZone('nonexistent_id', 'Name'),
        completes,
      );
    });
  });

  // ── deleteZone ────────────────────────────────────────────────────────────
  group('deleteZone', () {
    test('removes the document from Firestore', () async {
      // Arrange — add a document and capture its ID
      final docId = await seedZone(docId: 'todelete');

      // Act
      await service.deleteZone(docId);

      // Assert — the document no longer exists
      final doc =
          await fakeFirestore.collection('zone').doc(docId).get();
      expect(doc.exists, false);
    });

    test('does not affect other documents when deleting', () async {
      // Arrange — seed two documents
      await seedZone(docId: 'keep', zoneName: 'Bird Zone');
      await seedZone(docId: 'remove', zoneName: 'Temp Zone');

      // Act — delete only one
      await service.deleteZone('remove');

      // Assert — collection still has exactly 1 document
      final remaining = await fakeFirestore.collection('zone').get();
      expect(remaining.docs.length, 1);

      // Assert — the surviving document is the correct one
      expect(remaining.docs.first.id, 'keep');
      expect(remaining.docs.first.data()['zoneName'], 'Bird Zone');
    });
  });
}
