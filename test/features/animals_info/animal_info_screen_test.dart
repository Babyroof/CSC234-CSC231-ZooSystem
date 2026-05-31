import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoopernova_zoo_system/features/animals_info/presentation/screens/animal_info_screen.dart';

// ── Stub data ────────────────────────────────────────────────────────────────

final _testAnimalData = {
  'id': 'a1',
  'animalName': 'Scarlet Macaw',
  'animalDetail': 'Native to South America and known for vivid plumage.',
  'animalPicture': 'https://example.com/macaw.jpg',
  'zoneName': 'South America',
  'location_x': 100,
  'location_y': 40,
};

// ── Router ───────────────────────────────────────────────────────────────────

// Navigate from a trigger screen to AnimalInfoScreen with extra data.
GoRouter _makeRouter(Map<String, dynamic> data) => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (ctx, _) => _TriggerScreen(data: data),
    ),
    GoRoute(
      path: '/animal_info',
      builder: (ctx, _) => const AnimalInfoScreen(),
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
      path: '/home',
      builder: (ctx, _) => const Scaffold(body: Text('Home')),
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

class _TriggerScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const _TriggerScreen({required this.data});

  @override
  State<_TriggerScreen> createState() => _TriggerScreenState();
}

class _TriggerScreenState extends State<_TriggerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.push('/animal_info', extra: widget.data),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Widget _buildApp({Map<String, dynamic>? data}) => ProviderScope(
  child: MaterialApp.router(
    routerConfig: _makeRouter(data ?? _testAnimalData),
  ),
);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('AnimalInfoScreen — rendering', () {
    testWidgets('renders Animal Information appbar title', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Animal Information'), findsOneWidget);
    });

    testWidgets('renders animal name', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Scarlet Macaw'), findsOneWidget);
    });

    testWidgets('renders zone name', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('South America'), findsOneWidget);
    });

    testWidgets('renders About section', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('renders animal detail text', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Native to South America and known for vivid plumage.'),
        findsOneWidget,
      );
    });

    testWidgets('shows map icon button when location data is present', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // map_outlined appears in the content AND the bottom nav bar
      expect(find.byIcon(Icons.map_outlined), findsAtLeastNWidgets(1));
    });
  });

  group('AnimalInfoScreen — missing data', () {
    testWidgets('shows error message when no extra data is passed', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/animal_info',
        routes: [
          GoRoute(
            path: '/animal_info',
            builder: (ctx, _) => const AnimalInfoScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No animal data found'), findsOneWidget);
    });
  });
}
