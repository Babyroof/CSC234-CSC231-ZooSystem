import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zoopernova_zoo_system/features/animals_info/domain/entities/animal_with_zone_entity.dart';
import 'package:zoopernova_zoo_system/features/animals_info/presentation/providers/animal_providers.dart';
import 'package:zoopernova_zoo_system/features/animals_info/presentation/screens/animal_screen.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/screens/login_screen.dart';
import 'package:zoopernova_zoo_system/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:zoopernova_zoo_system/features/auth/data/models/user_dto.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/providers/auth_providers.dart';
import 'package:zoopernova_zoo_system/features/events_show/domain/entities/event_entity.dart';
import 'package:zoopernova_zoo_system/features/events_show/presentation/providers/event_providers.dart';
import 'package:zoopernova_zoo_system/features/home/presentation/providers/home_providers.dart';
import 'package:zoopernova_zoo_system/features/home/presentation/screens/home_screen.dart';
import 'package:zoopernova_zoo_system/features/auth/domain/entities/user_entity.dart';
import 'package:zoopernova_zoo_system/features/profile/presentation/providers/profile_providers.dart';

// ── Stubs ────────────────────────────────────────────────────────────────────

class _FakeAuthDataSource extends Fake implements AuthRemoteDataSource {
  @override
  Future<String?> login(String email, String password) async => 'Success';
  @override
  Future<UserDto?> getCurrentUser() async => null;
  @override
  Future<void> logout() async {}
  @override
  Future<String?> register({
    required String email,
    required String password,
    required String firstname,
    required String lastname,
    required String phoneNumber,
    required String username,
  }) async => null;
}

class _FakeProfileNotifier extends ProfileNotifier {
  @override
  Future<UserEntity?> build() async => const UserEntity(
    uid: 'u1',
    email: 'test@zoo.com',
    firstname: 'Tana',
    lastname: 'Poom',
    phoneNumber: '0812345678',
    username: 'tanapoom',
  );
}

const _testEvents = [
  EventEntity(
    id: 'e1',
    eventName: 'Seal Show',
    eventDetail: 'Daily seal performance.',
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

// ── Shared router factory ─────────────────────────────────────────────────────

GoRouter _buildRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', builder: (ctx, st) => const LoginScreen()),
    GoRoute(path: '/home', builder: (ctx, st) => const HomeScreen()),
    GoRoute(path: '/animals', builder: (ctx, st) => const AnimalScreen()),
    GoRoute(
      path: '/animal_info',
      builder: (ctx, st) => const Scaffold(body: Text('Animal Info')),
    ),
    GoRoute(
      path: '/events',
      builder: (ctx, st) => const Scaffold(body: Text('Events')),
    ),
    GoRoute(
      path: '/events_info',
      builder: (ctx, st) => const Scaffold(body: Text('Event Info')),
    ),
    GoRoute(
      path: '/booking',
      builder: (ctx, st) => const Scaffold(body: Text('Booking')),
    ),
    GoRoute(
      path: '/map',
      builder: (ctx, st) => const Scaffold(body: Text('Map')),
    ),
    GoRoute(
      path: '/ticket',
      builder: (ctx, st) => const Scaffold(body: Text('Ticket')),
    ),
    GoRoute(
      path: '/profile',
      builder: (ctx, st) => const Scaffold(body: Text('Profile')),
    ),
    GoRoute(
      path: '/register',
      builder: (ctx, st) => const Scaffold(body: Text('Register')),
    ),
  ],
);

Widget _buildApp({String initialLocation = '/'}) => ProviderScope(
  overrides: [
    authRemoteDataSourceProvider.overrideWith(
      (ref) => _FakeAuthDataSource(),
    ),
    eventsProvider.overrideWith((ref) async => _testEvents),
    profileNotifierProvider.overrideWith(() => _FakeProfileNotifier()),
    homePopularAnimalsProvider.overrideWith((ref) async => _testAnimals),
    featurePopularAnimalsProvider.overrideWith((ref) => true),
    animalsWithZoneProvider.overrideWith((ref) async => _testAnimals),
  ],
  child: MaterialApp.router(
    routerConfig: _buildRouter(initialLocation: initialLocation),
  ),
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login flow (Android + Web)', () {
    testWidgets('login screen renders with all required elements', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
    });

    testWidgets('empty form shows validation errors', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('invalid email format shows error', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'not-valid-email',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('successful login navigates to home screen', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@zoo.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Hi, Tana Poom'), findsOneWidget);
    });

    testWidgets('guest button navigates to home without login', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      // Home screen shows anonymous greeting
      expect(find.text('Hi, Anonymous...'), findsOneWidget);
    });
  });

  group('Home screen — feature flag (Android + Web)', () {
    testWidgets('Recommend Animals section shows when flag is true', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(initialLocation: '/home'));
      await tester.pumpAndSettle();

      expect(
        find.text('Recommend Animals', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('Events section renders event cards', (tester) async {
      await tester.pumpWidget(_buildApp(initialLocation: '/home'));
      await tester.pumpAndSettle();

      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Seal Show'), findsOneWidget);
    });
  });

  group('Animals screen (Android + Web)', () {
    testWidgets('renders animal list with zone names', (tester) async {
      await tester.pumpWidget(_buildApp(initialLocation: '/animals'));
      await tester.pumpAndSettle();

      expect(find.text('Get to Know Our Animals'), findsOneWidget);
      expect(find.text('Scarlet Macaw'), findsOneWidget);
      expect(find.text('Bird Zone'), findsOneWidget);
    });

    testWidgets('tapping animal navigates to detail screen', (tester) async {
      await tester.pumpWidget(_buildApp(initialLocation: '/animals'));
      await tester.pumpAndSettle();

      final card = find.ancestor(
        of: find.text('Scarlet Macaw'),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.text('Animal Info'), findsOneWidget);
    });

    testWidgets('Book tickets button navigates to booking', (tester) async {
      await tester.pumpWidget(_buildApp(initialLocation: '/animals'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Book your tickets now!'));
      await tester.pumpAndSettle();

      expect(find.text('Booking'), findsOneWidget);
    });
  });
}
