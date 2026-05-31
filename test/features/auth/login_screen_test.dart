import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zoopernova_zoo_system/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:zoopernova_zoo_system/features/auth/data/models/user_dto.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/providers/auth_providers.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/screens/login_screen.dart';

// Disable local_auth platform channel so biometric checks return false in tests.
void _stubBiometricChannel() {
  const channel = MethodChannel('plugins.flutter.io/local_auth');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    return switch (call.method) {
      'canCheckBiometrics' => false,
      'isDeviceSupported' => false,
      'getAvailableBiometrics' => <String>[],
      _ => null,
    };
  });
}

// Fake datasource — intercepts login without touching Firebase.
class _FakeAuthDataSource extends Fake implements AuthRemoteDataSource {
  final String? loginResult;
  _FakeAuthDataSource({this.loginResult});

  @override
  Future<String?> login(String email, String password) async => loginResult;

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

GoRouter _makeRouter() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, _) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (ctx, _) => const Scaffold(body: Text('Register')),
    ),
    GoRoute(
      path: '/home',
      builder: (ctx, _) => const Scaffold(body: Text('Home')),
    ),
  ],
);

Widget _buildApp({String? loginResult}) => ProviderScope(
  overrides: [
    authRemoteDataSourceProvider.overrideWith(
      (ref) => _FakeAuthDataSource(loginResult: loginResult),
    ),
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
  setUp(_stubBiometricChannel);

  group('LoginScreen — rendering', () {
    testWidgets('email field renders', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('password field renders', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('Sign In button renders', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Sign Up link has semanticLabel', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(_hasSemanticLabel(tester, 'Sign Up'), isTrue);
    });
  });

  group('LoginScreen — validation errors on empty submit', () {
    testWidgets('shows email required error when email is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows password required error when password is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows both errors when all fields are empty', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows invalid email error for bad format', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });
  });

  group('LoginScreen — button interactions', () {
    testWidgets('Sign In button is tappable (triggers validation)', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Empty-field validation ran without crash — button is functional.
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('Sign Up link is tappable and navigates to register screen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      final signUpFinder = find.ancestor(
        of: find.text('Sign Up'),
        matching: find.byType(GestureDetector),
      );
      await tester.ensureVisible(signUpFinder);
      await tester.tap(signUpFinder);
      await tester.pumpAndSettle();

      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('successful login navigates to home', (tester) async {
      await tester.pumpWidget(_buildApp(loginResult: 'Success'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('failed login shows backend error without navigating', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(loginResult: 'Email or Password is not correct'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).last, 'wrongpass');
      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email or Password is not correct'), findsOneWidget);
    });
  });
}
