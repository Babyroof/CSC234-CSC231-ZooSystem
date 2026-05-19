// test/features/booking/ticket/booking_service_date_test.dart
//
// Unit tests for the date-filtered stream methods on BookingService:
//   - getUpcomingBookings(userId) → status == 'Done' && date >= startOfToday, asc
//   - getPastBookings(userId)     → status == 'Done' && date <  startOfToday, desc
//
// FakeFirebaseFirestore is injected via the BookingService({FirebaseFirestore? db})
// constructor — no source modifications required.
//
// Dates are computed relative to DateTime.now() so the tests are time-independent:
//   future  → DateTime.now().add(Duration(days: 3))
//   past    → DateTime.now().subtract(Duration(days: 3))
//   today   → DateTime(now.year, now.month, now.day)  ← exact midnight

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/booking/data/datasources/booking_remote_datasource.dart';

// ---------------------------------------------------------------------------
// Top-level date helpers (getters cannot live inside void main())
// ---------------------------------------------------------------------------
DateTime futureDate() => DateTime.now().add(const Duration(days: 3));
DateTime pastDate() => DateTime.now().subtract(const Duration(days: 3));
DateTime todayMidnight() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late BookingRemoteDataSourceImpl service;
  late DocumentReference userRef;
  late DocumentReference otherUserRef;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = BookingRemoteDataSourceImpl(db: fakeFirestore);
    userRef = fakeFirestore.collection('user').doc('user_123');
    otherUserRef = fakeFirestore.collection('user').doc('other_user');
  });

  // ---------------------------------------------------------------------------
  // Seed helper — adds one booking document to the fake store
  // ---------------------------------------------------------------------------
  Future<void> seedBooking({
    required DocumentReference userId,
    required String status,
    required DateTime date,
  }) async {
    await fakeFirestore.collection('booking').add({
      'userId': userId,
      'status': status,
      'date': Timestamp.fromDate(date),
      'adultTotal': 1,
      'childTotal': 0,
      'elderTotal': 0,
      'BuffetFood': false,
      'GuideTour': false,
      'GolfCar': false,
    });
  }

  // =========================================================================
  // getUpcomingBookings
  // =========================================================================
  group('getUpcomingBookings', () {
    test('returns Done bookings with date >= today', () async {
      // Arrange — one Done booking in the future
      await seedBooking(userId: userRef, status: 'Done', date: futureDate());

      // Act
      final bookings = await service.getUpcomingBookings('user_123').first;

      // Assert
      expect(bookings.length, 1);
      expect(bookings.first.status, 'Done');
      expect(bookings.first.userId, 'user_123');
    });

    test('excludes Done bookings with date < today', () async {
      // Arrange — Done booking in the past should NOT appear
      await seedBooking(userId: userRef, status: 'Done', date: pastDate());

      // Act
      final bookings = await service.getUpcomingBookings('user_123').first;

      // Assert
      expect(bookings, isEmpty);
    });

    test('excludes Pending bookings with future date', () async {
      // Arrange — Pending status, even with a future date, must be excluded
      await seedBooking(userId: userRef, status: 'Pending', date: futureDate());

      // Act
      final bookings = await service.getUpcomingBookings('user_123').first;

      // Assert
      expect(bookings, isEmpty);
    });

    test('excludes Cancelled bookings with future date', () async {
      // Arrange — Cancelled status with a future date must be excluded
      await seedBooking(
        userId: userRef,
        status: 'Cancelled',
        date: futureDate(),
      );

      // Act
      final bookings = await service.getUpcomingBookings('user_123').first;

      // Assert
      expect(bookings, isEmpty);
    });

    test('orders results by date ascending', () async {
      // Arrange — three Done bookings at different future offsets
      final d1 = DateTime.now().add(const Duration(days: 1));
      final d2 = DateTime.now().add(const Duration(days: 5));
      final d3 = DateTime.now().add(const Duration(days: 10));

      // Seed out-of-order to confirm the service applies the sort
      await seedBooking(userId: userRef, status: 'Done', date: d3);
      await seedBooking(userId: userRef, status: 'Done', date: d1);
      await seedBooking(userId: userRef, status: 'Done', date: d2);

      // Act
      final bookings = await service.getUpcomingBookings('user_123').first;

      // Assert — ascending order: d1 < d2 < d3
      expect(bookings.length, 3);
      expect(
        bookings[0].date.isBefore(bookings[1].date) ||
            bookings[0].date.isAtSameMomentAs(bookings[1].date),
        isTrue,
      );
      expect(
        bookings[1].date.isBefore(bookings[2].date) ||
            bookings[1].date.isAtSameMomentAs(bookings[2].date),
        isTrue,
      );
    });

    test('returns empty list when no matching bookings', () async {
      // Arrange — no documents at all

      // Act
      final bookings = await service.getUpcomingBookings('user_123').first;

      // Assert
      expect(bookings, isEmpty);
    });

    test('excludes bookings belonging to other users', () async {
      // Arrange — one booking for the target user, one for another user
      await seedBooking(userId: userRef, status: 'Done', date: futureDate());
      await seedBooking(
        userId: otherUserRef,
        status: 'Done',
        date: futureDate(),
      );

      // Act
      final bookings = await service.getUpcomingBookings('user_123').first;

      // Assert — only the target user's booking is returned
      expect(bookings.length, 1);
      expect(bookings.first.userId, 'user_123');
    });
  });

  // =========================================================================
  // getPastBookings
  // =========================================================================
  group('getPastBookings', () {
    test('returns Done bookings with date < today', () async {
      // Arrange — one Done booking in the past
      await seedBooking(userId: userRef, status: 'Done', date: pastDate());

      // Act
      final bookings = await service.getPastBookings('user_123').first;

      // Assert
      expect(bookings.length, 1);
      expect(bookings.first.status, 'Done');
      expect(bookings.first.userId, 'user_123');
    });

    test('excludes Done bookings with date >= today', () async {
      // Arrange — Done bookings dated today or in the future must NOT appear
      await seedBooking(userId: userRef, status: 'Done', date: futureDate());
      await seedBooking(userId: userRef, status: 'Done', date: todayMidnight());

      // Act
      final bookings = await service.getPastBookings('user_123').first;

      // Assert
      expect(bookings, isEmpty);
    });

    test('excludes Pending bookings with past date', () async {
      // Arrange — Pending status, even with a past date, must be excluded
      await seedBooking(userId: userRef, status: 'Pending', date: pastDate());

      // Act
      final bookings = await service.getPastBookings('user_123').first;

      // Assert
      expect(bookings, isEmpty);
    });

    test('excludes Cancelled bookings with past date', () async {
      // Arrange — Cancelled status with a past date must be excluded
      await seedBooking(userId: userRef, status: 'Cancelled', date: pastDate());

      // Act
      final bookings = await service.getPastBookings('user_123').first;

      // Assert
      expect(bookings, isEmpty);
    });

    test('orders results by date descending', () async {
      // Arrange — three Done bookings at different past offsets
      final d1 = DateTime.now().subtract(const Duration(days: 10));
      final d2 = DateTime.now().subtract(const Duration(days: 5));
      final d3 = DateTime.now().subtract(const Duration(days: 1));

      // Seed out-of-order to confirm the service applies the sort
      await seedBooking(userId: userRef, status: 'Done', date: d1);
      await seedBooking(userId: userRef, status: 'Done', date: d3);
      await seedBooking(userId: userRef, status: 'Done', date: d2);

      // Act
      final bookings = await service.getPastBookings('user_123').first;

      // Assert — descending order: d3 > d2 > d1
      expect(bookings.length, 3);
      expect(
        bookings[0].date.isAfter(bookings[1].date) ||
            bookings[0].date.isAtSameMomentAs(bookings[1].date),
        isTrue,
      );
      expect(
        bookings[1].date.isAfter(bookings[2].date) ||
            bookings[1].date.isAtSameMomentAs(bookings[2].date),
        isTrue,
      );
    });

    test('returns empty list when no matching bookings', () async {
      // Arrange — no documents at all

      // Act
      final bookings = await service.getPastBookings('user_123').first;

      // Assert
      expect(bookings, isEmpty);
    });

    test('excludes bookings belonging to other users', () async {
      // Arrange — one booking for the target user, one for another user
      await seedBooking(userId: userRef, status: 'Done', date: pastDate());
      await seedBooking(userId: otherUserRef, status: 'Done', date: pastDate());

      // Act
      final bookings = await service.getPastBookings('user_123').first;

      // Assert — only the target user's booking is returned
      expect(bookings.length, 1);
      expect(bookings.first.userId, 'user_123');
    });
  });

  // =========================================================================
  // Edge cases
  // =========================================================================
  group('Edge cases', () {
    test(
      'booking exactly on today midnight appears in upcoming, not history',
      () async {
        // Arrange — date is exactly midnight today (the startOfToday boundary)
        final today = todayMidnight();
        await seedBooking(userId: userRef, status: 'Done', date: today);

        // Act
        final upcoming = await service.getUpcomingBookings('user_123').first;
        final past = await service.getPastBookings('user_123').first;

        // Assert — midnight today satisfies date >= startOfToday → upcoming
        expect(
          upcoming.length,
          1,
          reason: 'midnight today should satisfy date >= startOfToday',
        );
        // Assert — midnight today does NOT satisfy date < startOfToday → not past
        expect(
          past,
          isEmpty,
          reason: 'midnight today should not satisfy date < startOfToday',
        );
      },
    );

    test('both streams emit independently without interference', () async {
      // Arrange — one past Done, one future Done
      await seedBooking(userId: userRef, status: 'Done', date: pastDate());
      await seedBooking(userId: userRef, status: 'Done', date: futureDate());

      // Act — request both streams
      final upcoming = await service.getUpcomingBookings('user_123').first;
      final past = await service.getPastBookings('user_123').first;

      // Assert — each stream returns exactly its own subset
      expect(
        upcoming.length,
        1,
        reason: 'upcoming should contain only the future booking',
      );
      expect(
        past.length,
        1,
        reason: 'past should contain only the past booking',
      );

      expect(upcoming.first.date.isAfter(DateTime.now()), isTrue);
      expect(past.first.date.isBefore(DateTime.now()), isTrue);
    });
  });
}
