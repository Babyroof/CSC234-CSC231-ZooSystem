import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoopernova_zoo_system/features/auth/domain/entities/user_entity.dart';
import 'package:zoopernova_zoo_system/features/profile/presentation/providers/profile_providers.dart';
import 'package:zoopernova_zoo_system/features/profile/presentation/screens/profile_screen.dart';

// ── Stub data ────────────────────────────────────────────────────────────────

const _testUser = UserEntity(
  uid: 'u1',
  email: 'tana@zoo.com',
  firstname: 'Tana',
  lastname: 'Poom',
  phoneNumber: '0812345678',
  username: 'tanapoom',
);

// ── Stub notifiers ────────────────────────────────────────────────────────────

class _LoggedInProfileNotifier extends ProfileNotifier {
  @override
  Future<UserEntity?> build() async => _testUser;
}

class _GuestProfileNotifier extends ProfileNotifier {
  @override
  Future<UserEntity?> build() async => null;
}

// ── Router ───────────────────────────────────────────────────────────────────

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, _) => const ProfileScreen()),
    GoRoute(
      path: '/home',
      builder: (ctx, _) => const Scaffold(body: Text('Home')),
    ),
    GoRoute(
      path: '/login',
      builder: (ctx, _) => const Scaffold(body: Text('Login')),
    ),
    GoRoute(
      path: '/change_name',
      builder: (ctx, _) => const Scaffold(body: Text('Change Name')),
    ),
    GoRoute(
      path: '/change_phone',
      builder: (ctx, _) => const Scaffold(body: Text('Change Phone')),
    ),
    GoRoute(
      path: '/change_password',
      builder: (ctx, _) => const Scaffold(body: Text('Change Password')),
    ),
    GoRoute(
      path: '/booking',
      builder: (ctx, _) => const Scaffold(body: Text('Booking')),
    ),
    GoRoute(
      path: '/map',
      builder: (ctx, _) => const Scaffold(body: Text('Map')),
    ),
    GoRoute(
      path: '/ticket',
      builder: (ctx, _) => const Scaffold(body: Text('Ticket')),
    ),
  ],
);

Widget _buildApp({bool loggedIn = true}) => ProviderScope(
  overrides: [
    profileNotifierProvider.overrideWith(
      () => loggedIn ? _LoggedInProfileNotifier() : _GuestProfileNotifier(),
    ),
  ],
  child: MaterialApp.router(routerConfig: _makeRouter()),
);

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ProfileScreen — logged-in user', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders Profile title after data loads', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      // "Profile" appears in the header and the bottom nav bar
      expect(find.text('Profile'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders user full name', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Tana Poom'), findsOneWidget);
    });

    testWidgets('renders user email', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('tana@zoo.com'), findsOneWidget);
    });
  });

  group('ProfileScreen — guest user', () {
    testWidgets('shows guest state when not logged in', (tester) async {
      await tester.pumpWidget(_buildApp(loggedIn: false));
      await tester.pumpAndSettle();

      // Guest view renders Profile title (may appear in header + bottom nav)
      expect(find.text('Profile'), findsAtLeastNWidgets(1));
    });
  });
}
