import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoopernova_zoo_system/features/events_show/domain/entities/event_entity.dart';
import 'package:zoopernova_zoo_system/features/events_show/presentation/providers/event_providers.dart';
import 'package:zoopernova_zoo_system/features/events_show/presentation/screens/event_screen.dart';

final _testEvents = [
  const EventEntity(
    id: 'event1',
    eventName: 'Smart Seal Show',
    eventDetail: '2 shows per day at the aquatic zone.',
    eventPicture: 'https://example.com/seal.jpg',
  ),
];

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, _) => const EventScreen()),
    GoRoute(
      path: '/events_info',
      builder: (ctx, _) => const Scaffold(body: Text('Event Info')),
    ),
    GoRoute(
      path: '/home',
      builder: (ctx, _) => const Scaffold(body: Text('Home')),
    ),
    GoRoute(
      path: '/map',
      builder: (ctx, _) => const Scaffold(body: Text('Map')),
    ),
    GoRoute(
      path: '/booking',
      builder: (ctx, _) => const Scaffold(body: Text('Booking')),
    ),
    GoRoute(
      path: '/ticket',
      builder: (ctx, _) => const Scaffold(body: Text('Ticket')),
    ),
    GoRoute(
      path: '/profile',
      builder: (ctx, _) => const Scaffold(body: Text('Profile')),
    ),
  ],
);

Widget _buildApp() => ProviderScope(
  overrides: [eventsProvider.overrideWith((ref) async => _testEvents)],
  child: MaterialApp.router(routerConfig: _makeRouter()),
);

/// True if any Semantics widget in the current tree has the given label.
bool _hasSemanticLabel(WidgetTester tester, String label) {
  return tester
      .widgetList<Semantics>(find.byType(Semantics))
      .any((s) => s.properties.label == label);
}

void main() {
  group('EventScreen — rendering', () {
    testWidgets('shows loading indicator while fetching data', (tester) async {
      await tester.pumpWidget(_buildApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders ZOO EVENTS header', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('ZOO EVENTS'), findsOneWidget);
    });

    testWidgets('renders event name from provider', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Smart Seal Show'), findsOneWidget);
    });

    testWidgets('renders event detail text', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('2 shows per day at the aquatic zone.'), findsOneWidget);
    });
  });

  group('EventScreen — button interactions', () {
    testWidgets('event card has semanticLabel', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(_hasSemanticLabel(tester, 'Smart Seal Show'), isTrue);
    });

    testWidgets('tapping event card navigates to event info', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final cardFinder = find.ancestor(
        of: find.text('Smart Seal Show'),
        matching: find.byType(GestureDetector),
      );
      await tester.ensureVisible(cardFinder);
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      expect(find.text('Event Info'), findsOneWidget);
    });
  });
}
