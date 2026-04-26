import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/events_show/screens/event_screen.dart';
import 'package:zoopernova_zoo_system/features/events_show/services/event.service.dart';

late FakeFirebaseFirestore _fakeDb;
late EventService _service;

Future<void> _seedData() async {
  _fakeDb = FakeFirebaseFirestore();
  await _fakeDb.collection('event').add({
    'eventName': 'Smart Seal Show',
    'eventDetail': '2 shows per day at the aquatic zone.',
    'eventPicture': 'https://example.com/seal.jpg',
  });
  _service = EventService(db: _fakeDb);
}

Widget _buildApp() {
  return MaterialApp(
    routes: {
      '/events_info': (_) => const Scaffold(body: Text('Event Info')),
      '/home': (_) => const Scaffold(body: Text('Home')),
      '/map': (_) => const Scaffold(body: Text('Map')),
      '/ticket': (_) => const Scaffold(body: Text('Ticket')),
      '/profile': (_) => const Scaffold(body: Text('Profile')),
    },
    home: EventScreen(eventService: _service),
  );
}

/// True if any Semantics widget in the current tree has the given label.
bool _hasSemanticLabel(WidgetTester tester, String label) {
  return tester
      .widgetList<Semantics>(find.byType(Semantics))
      .any((s) => s.properties.label == label);
}

void main() {
  setUp(_seedData);

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

    testWidgets('renders event name from Firestore', (tester) async {
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

      // Verify the Semantics widget exists with the correct label property —
      // no need to enable the full semantics rendering pipeline.
      expect(_hasSemanticLabel(tester, 'Smart Seal Show'), isTrue);
    });

    testWidgets('tapping event card navigates to event info', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Locate the GestureDetector that wraps the event card by finding the
      // nearest GestureDetector ancestor of the event name text.
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
