import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoopernova_zoo_system/features/booking/presentation/providers/booking_providers.dart';
import 'package:zoopernova_zoo_system/features/booking/presentation/screens/booking_screen.dart';

// ── Stub notifiers ────────────────────────────────────────────────────────────

class _StubBookingFormNotifier extends BookingFormNotifier {
  @override
  BookingFormState build() => const BookingFormState(
    adultPrice: 200,
    kidPrice: 100,
    elderPrice: 150,
  );
}

// ── Router ───────────────────────────────────────────────────────────────────

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, _) => const BookingScreen()),
    GoRoute(
      path: '/payment',
      builder: (ctx, _) => const Scaffold(body: Text('Payment')),
    ),
    GoRoute(
      path: '/home',
      builder: (ctx, _) => const Scaffold(body: Text('Home')),
    ),
    GoRoute(
      path: '/login',
      builder: (ctx, _) => const Scaffold(body: Text('Login')),
    ),
  ],
);

Widget _buildApp() => ProviderScope(
  overrides: [
    bookingFormNotifierProvider.overrideWith(() => _StubBookingFormNotifier()),
    activeAddOnsProvider.overrideWith((ref) => Stream.value([])),
  ],
  child: MaterialApp.router(routerConfig: _makeRouter()),
);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('BookingScreen — rendering', () {
    testWidgets('renders Date section', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // "Date" also appears in the date picker placeholder text
      expect(find.text('Date'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Ticket Types section', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Ticket Types'), findsOneWidget);
    });

    testWidgets('renders Adult ticket row', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Adult'), findsOneWidget);
    });

    testWidgets('renders Kid ticket row', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Kid'), findsOneWidget);
    });

    testWidgets('renders Elder ticket row', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Elder'), findsOneWidget);
    });

    testWidgets('renders Add-ons section', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Add-ons'), findsOneWidget);
    });

    testWidgets('renders Checkout button', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Checkout'), findsOneWidget);
    });
  });

  group('BookingScreen — ticket counter', () {
    testWidgets('adult count starts at 0', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Three rows (Adult, Kid, Elder) each show "0" initially
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('tapping + on Adult increments count', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Find the first + button (Adult row)
      final addButtons = find.byIcon(Icons.add);
      expect(addButtons, findsWidgets);

      await tester.tap(addButtons.first);
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });
  });
}
