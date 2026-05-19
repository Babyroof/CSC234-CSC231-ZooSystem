import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoopernova_zoo_system/features/animals_info/domain/entities/animal_with_zone_entity.dart';
import 'package:zoopernova_zoo_system/features/animals_info/presentation/providers/animal_providers.dart';
import 'package:zoopernova_zoo_system/features/animals_info/presentation/screens/animal_screen.dart';

final _testAnimals = [
  const AnimalWithZoneEntity(
    id: 'animal1',
    animalName: 'Lion',
    animalDetail: 'The king of the jungle',
    animalPicture: 'https://example.com/lion.jpg',
    zoneName: 'Savanna Zone',
  ),
];

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, _) => const AnimalScreen()),
    GoRoute(
      path: '/animal_info',
      builder: (ctx, _) => const Scaffold(body: Text('Animal Info')),
    ),
    GoRoute(
      path: '/booking',
      builder: (ctx, _) => const Scaffold(body: Text('Booking')),
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
  overrides: [
    animalsWithZoneProvider.overrideWith((ref) async => _testAnimals),
  ],
  child: MaterialApp.router(routerConfig: _makeRouter()),
);

/// True if any Semantics widget in the current tree has the given label.
bool _hasSemanticLabel(WidgetTester tester, String label) {
  return tester
      .widgetList<Semantics>(find.byType(Semantics))
      .any((s) => s.properties.label == label);
}

void main() {
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

    testWidgets('renders animal name from provider', (tester) async {
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

      expect(_hasSemanticLabel(tester, 'Lion'), isTrue);
    });

    testWidgets('tapping animal card navigates to animal info', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

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
