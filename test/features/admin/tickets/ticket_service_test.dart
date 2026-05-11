import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/admin/tickets/services/ticket_service.dart';

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
  late TicketService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = TicketService(db: fakeFirestore);
  });

  // ── Shared seed helper ───────────────────────────────────────────────────
  Future<void> seedTicket({
    required String docId,
    String userId = 'user123',
    bool buffetFood = true,
    bool golfCar = false,
    bool guidTour = true,
    int adultTotal = 2,
    int childTotal = 1,
    int elderTotal = 0,
    DateTime? date,
    String status = 'pending',
  }) async {
    final userRef = fakeFirestore.collection('user').doc(userId);
    await fakeFirestore.collection('booking').doc(docId).set({
      'BuffetFood': buffetFood,
      'GolfCar': golfCar,
      'GuidTour': guidTour,
      'adultTotal': adultTotal,
      'childTotal': childTotal,
      'elderTotal': elderTotal,
      'date': Timestamp.fromDate(date ?? DateTime(2026, 5, 10)),
      'status': status,
      'userId': userRef,
    });
  }

  // ── getAllTickets ──────────────────────────────────────────────────────────
  group('getAllTickets', () {
    test('returns stream containing all seeded tickets', () async {
      // Arrange
      await seedTicket(docId: 'tk1', userId: 'user1', status: 'pending');
      await seedTicket(docId: 'tk2', userId: 'user2', status: 'Done');

      // Act
      final results = await service.getAllTickets().first;

      // Assert
      expect(results.length, 2);
      final ids = results.map((t) => t.id).toSet();
      expect(ids, containsAll(['tk1', 'tk2']));
    });

    test(
      'returns empty list when booking collection has no documents',
      () async {
        final results = await service.getAllTickets().first;
        expect(results, isEmpty);
      },
    );

    test('returns tickets from ALL users — no user filter applied', () async {
      // Arrange
      await seedTicket(docId: 'tk1', userId: 'userA');
      await seedTicket(docId: 'tk2', userId: 'userB');
      await seedTicket(docId: 'tk3', userId: 'userC');

      // Act
      final results = await service.getAllTickets().first;

      // Assert
      expect(results.length, 3);
    });

    test('throws on Firestore error', () {
      final errorService = TicketService(db: _ErrorFirestore());
      expect(
        () => errorService.getAllTickets(),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── getTicketById ──────────────────────────────────────────────────────────
  group('getTicketById', () {
    test('returns correct TicketModel for existing document', () async {
      // Arrange
      await seedTicket(
        docId: 'tk1',
        userId: 'user123',
        buffetFood: true,
        golfCar: false,
        guidTour: true,
        adultTotal: 2,
        childTotal: 1,
        elderTotal: 0,
        date: DateTime(2026, 5, 10),
        status: 'pending',
      );

      // Act
      final result = await service.getTicketById('tk1');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'tk1');
      expect(result.buffetFood, true);
      expect(result.golfCar, false);
      expect(result.guidTour, true);
      expect(result.adultTotal, 2);
      expect(result.childTotal, 1);
      expect(result.elderTotal, 0);
      expect(result.date, DateTime(2026, 5, 10));
      expect(result.status, 'pending');
      expect(result.userId.id, 'user123');
    });

    test('returns null when document does not exist', () async {
      // Act
      final result = await service.getTicketById('nonexistent');

      // Assert
      expect(result, isNull);
    });

    test('throws on Firestore error', () {
      final errorService = TicketService(db: _ErrorFirestore());
      expect(
        () => errorService.getTicketById('any'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── updateTicket ──────────────────────────────────────────────────────────
  group('updateTicket', () {
    test('writes all fields correctly', () async {
      // Arrange
      await seedTicket(docId: 'tk1');
      final newUserRef = fakeFirestore.collection('user').doc('user456');
      final newDate = DateTime(2026, 8, 20);

      // Act
      await service.updateTicket(
        ticketId: 'tk1',
        buffetFood: false,
        golfCar: true,
        guidTour: false,
        adultTotal: 4,
        childTotal: 2,
        elderTotal: 1,
        date: newDate,
        status: 'Done',
        userId: newUserRef,
      );

      // Assert
      final data = (await fakeFirestore.collection('booking').doc('tk1').get())
          .data()!;
      expect(data['BuffetFood'], false);
      expect(data['GolfCar'], true);
      expect(data['GuidTour'], false);
      expect(data['adultTotal'], 4);
      expect(data['childTotal'], 2);
      expect(data['elderTotal'], 1);
      expect(data['date'], Timestamp.fromDate(newDate));
      expect(data['status'], 'Done');
      expect((data['userId'] as DocumentReference).id, 'user456');
    });

    test('updates status from pending to Done', () async {
      // Arrange
      await seedTicket(docId: 'tk1', status: 'pending');
      final userRef = fakeFirestore.collection('user').doc('user123');

      // Act
      await service.updateTicket(
        ticketId: 'tk1',
        buffetFood: true,
        golfCar: false,
        guidTour: true,
        adultTotal: 2,
        childTotal: 1,
        elderTotal: 0,
        date: DateTime(2026, 5, 10),
        status: 'Done',
        userId: userRef,
      );

      // Assert
      final data = (await fakeFirestore.collection('booking').doc('tk1').get())
          .data()!;
      expect(data['status'], 'Done');
    });

    test('does not affect other documents', () async {
      // Arrange
      await seedTicket(docId: 'tk1', status: 'pending');
      await seedTicket(docId: 'tk2', status: 'pending');
      final userRef = fakeFirestore.collection('user').doc('user123');

      // Act — update only tk1
      await service.updateTicket(
        ticketId: 'tk1',
        buffetFood: false,
        golfCar: false,
        guidTour: false,
        adultTotal: 1,
        childTotal: 0,
        elderTotal: 0,
        date: DateTime(2026, 5, 10),
        status: 'Done',
        userId: userRef,
      );

      // Assert — tk2 is untouched
      final data = (await fakeFirestore.collection('booking').doc('tk2').get())
          .data()!;
      expect(data['status'], 'pending');
    });

    test('throws on Firestore error', () {
      final errorService = TicketService(db: _ErrorFirestore());
      final userRef = fakeFirestore.collection('user').doc('user123');
      expect(
        () => errorService.updateTicket(
          ticketId: 'any',
          buffetFood: false,
          golfCar: false,
          guidTour: false,
          adultTotal: 1,
          childTotal: 0,
          elderTotal: 0,
          date: DateTime(2026, 5, 10),
          status: 'pending',
          userId: userRef,
        ),
        throwsA(isA<FirebaseException>()),
      );
    });
  });

  // ── deleteTicket ──────────────────────────────────────────────────────────
  group('deleteTicket', () {
    test('removes the document from Firestore', () async {
      // Arrange
      await seedTicket(docId: 'todelete');

      // Act
      await service.deleteTicket('todelete');

      // Assert
      final doc = await fakeFirestore
          .collection('booking')
          .doc('todelete')
          .get();
      expect(doc.exists, false);
    });

    test('does not affect other documents', () async {
      // Arrange
      await seedTicket(docId: 'keep');
      await seedTicket(docId: 'remove');

      // Act
      await service.deleteTicket('remove');

      // Assert
      final remaining = await fakeFirestore.collection('booking').get();
      expect(remaining.docs.length, 1);
      expect(remaining.docs.first.id, 'keep');
    });

    test('throws on Firestore error', () {
      final errorService = TicketService(db: _ErrorFirestore());
      expect(
        () => errorService.deleteTicket('any'),
        throwsA(isA<FirebaseException>()),
      );
    });
  });
}
