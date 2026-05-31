import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoopernova_zoo_system/features/animals_info/domain/entities/animal_with_zone_entity.dart';
import 'package:zoopernova_zoo_system/features/auth/domain/entities/user_entity.dart';
import 'package:zoopernova_zoo_system/features/events_show/domain/entities/event_entity.dart';
import 'package:zoopernova_zoo_system/features/events_show/presentation/providers/event_providers.dart';
import 'package:zoopernova_zoo_system/features/home/presentation/providers/home_providers.dart';
import 'package:zoopernova_zoo_system/features/home/presentation/screens/home_screen.dart';
import 'package:zoopernova_zoo_system/features/profile/presentation/providers/profile_providers.dart';

// ── Stub data ────────────────────────────────────────────────────────────────

const _testUser = UserEntity(
  uid: 'u1',
  email: 'test@zoo.com',
  firstname: 'Tana',
  lastname: 'Poom',
  phoneNumber: '0812345678',
  username: 'tanapoom',
);

const _testEvents = [
  EventEntity(
    id: 'e1',
    eventName: 'Seal Show',
    eventDetail: 'Exciting seal performance.',
    eventPicture: 'https://example.com/seal.jpg',
  ),
];

const _testAnimals = [
  AnimalWithZoneEntity(
    id: 'a1',
    animalName: 'Scarlet Macaw',
    animalDetail: 'Native to South America.',
    animalPicture: 'https://example.com/macaw.jpg',
    zoneName: 'Bird Zone',
  ),
];

// ── Stub notifier ─────────────────────────────────────────────────────────────

class _FakeProfileNotifier extends ProfileNotifier {
  @override
  Future<UserEntity?> build() async => _testUser;
}

// ── Router ───────────────────────────────────────────────────────────────────

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, _) => const HomeScreen()),
    GoRoute(
      path: '/booking',
      builder: (ctx, _) => const Scaffold(body: Text('Booking')),
    ),
    GoRoute(
      path: '/events',
      builder: (ctx, _) => const Scaffold(body: Text('Events')),
    ),
    GoRoute(
      path: '/events_info',
      builder: (ctx, _) => const Scaffold(body: Text('Event Info')),
    ),
    GoRoute(
      path: '/animals',
      builder: (ctx, _) => const Scaffold(body: Text('Animals')),
    ),
    GoRoute(
      path: '/animal_info',
      builder: (ctx, _) => const Scaffold(body: Text('Animal Info')),
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

Widget _buildApp({bool showPopularAnimals = true}) => ProviderScope(
  overrides: [
    eventsProvider.overrideWith((ref) async => _testEvents),
    profileNotifierProvider.overrideWith(() => _FakeProfileNotifier()),
    homePopularAnimalsProvider.overrideWith((ref) async => _testAnimals),
    featurePopularAnimalsProvider.overrideWith((ref) => showPopularAnimals),
  ],
  child: MaterialApp.router(routerConfig: _makeRouter()),
);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('HomeScreen — rendering', () {
    testWidgets('shows greeting with user name after data loads', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Hi, Tana Poom'), findsOneWidget);
    });

    testWidgets('shows Book tickets button', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Book your tickets now!'), findsOneWidget);
    });

    testWidgets('shows Events section header', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Events'), findsOneWidget);
    });

    testWidgets('renders event name from provider', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Seal Show'), findsOneWidget);
    });

    testWidgets('shows Recommend Animals section when flag is true', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(showPopularAnimals: true));
      await tester.pumpAndSettle();

      // Section may be below the fold — skipOffstage: false finds it in the tree
      expect(
        find.text('Recommend Animals', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Scarlet Macaw', skipOffstage: false), findsOneWidget);
    });

    testWidgets('hides Recommend Animals section when flag is false', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(showPopularAnimals: false));
      await tester.pumpAndSettle();

      expect(find.text('Recommend Animals', skipOffstage: false), findsNothing);
      expect(find.text('Scarlet Macaw', skipOffstage: false), findsNothing);
    });
  });

  group('HomeScreen — navigation', () {
    testWidgets('Book tickets button navigates to booking', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Book your tickets now!'));
      await tester.pumpAndSettle();

      expect(find.text('Booking'), findsOneWidget);
    });

    testWidgets('Event menu button navigates to events', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Event'));
      await tester.pumpAndSettle();

      expect(find.text('Events'), findsOneWidget);
    });

    testWidgets('Animals menu button navigates to animals', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Animals'));
      await tester.pumpAndSettle();

      expect(find.text('Animals'), findsOneWidget);
    });
  });
}
