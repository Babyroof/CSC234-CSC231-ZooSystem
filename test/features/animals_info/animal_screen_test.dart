import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/animals_info/screens/animal_screen.dart';
import 'package:zoopernova_zoo_system/features/animals_info/services/animal_service.dart';

late FakeFirebaseFirestore _fakeDb;
late AnimalService _service;

Future<void> _seedData() async {
  _fakeDb = FakeFirebaseFirestore();

  final zoneRef = _fakeDb.collection('zone').doc('zone1');
  await zoneRef.set({'zoneName': 'Savanna Zone'});

  await _fakeDb.collection('animal').add({
    'animalName': 'Lion',
    'animalDetail': 'The king of the jungle',
    'animalPicture': 'https://example.com/lion.jpg',
    'zoneId': zoneRef.path,
  });

  _service = AnimalService(db: _fakeDb);
}

Widget _buildApp() {
  return MaterialApp(
    routes: {
      '/booking': (_) => const Scaffold(body: Text('Booking')),
      '/animal_info': (_) => const Scaffold(body: Text('Animal Info')),
      '/home': (_) => const Scaffold(body: Text('Home')),
      '/map': (_) => const Scaffold(body: Text('Map')),
      '/ticket': (_) => const Scaffold(body: Text('Ticket')),
      '/profile': (_) => const Scaffold(body: Text('Profile')),
    },
    home: AnimalScreen(service: _service),
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

  group('AnimalScreen — rendering', () {
    testWidgets('shows loading indicator while fetching data', (tester) async {
      await tester.pumpWidget(_buildApp());

      // First frame: still loading.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders header after data loads', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Get to Know Our Animals'), findsOneWidget);
    });

    testWidgets('renders animal name from Firestore', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Lion'), findsOneWidget);
    });

    testWidgets('renders zone name on the animal card', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Savanna Zone'), findsOneWidget);
    });
  });

  group('AnimalScreen — button interactions', () {
    testWidgets('Book tickets button renders and is tappable', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final bookBtn = find.text('Book your tickets now!');
      expect(bookBtn, findsOneWidget);

      await tester.tap(bookBtn);
      await tester.pumpAndSettle();

      expect(find.text('Booking'), findsOneWidget);
    });

    testWidgets('animal card has semanticLabel', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Verify the Semantics widget exists with the correct label property —
      // no need to enable the full semantics rendering pipeline.
      expect(_hasSemanticLabel(tester, 'Lion'), isTrue);
    });

    testWidgets('tapping animal card navigates to animal info', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // Locate the InkWell that wraps the animal card by finding the nearest
      // InkWell ancestor of the "Lion" text, then scroll it into view and tap.
      final cardFinder = find.ancestor(
        of: find.text('Lion'),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(cardFinder);
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      expect(find.text('Animal Info'), findsOneWidget);
    });
  });
}
