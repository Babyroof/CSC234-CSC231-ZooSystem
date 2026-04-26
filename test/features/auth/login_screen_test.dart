import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoopernova_zoo_system/features/auth/screens/login_screen.dart';
import 'package:zoopernova_zoo_system/features/auth/services/auth_service.dart';

// Fake that intercepts login without touching Firebase.
class _FakeAuthService extends Fake implements AuthService {
  final String? loginResult;
  _FakeAuthService({this.loginResult});

  @override
  Future<String?> login(String email, String password) async => loginResult;
}

Widget _buildApp({AuthService? authService}) {
  return MaterialApp(
    routes: {
      '/register': (_) => const Scaffold(body: Text('Register')),
      '/home': (_) => const Scaffold(body: Text('Home')),
    },
    home: LoginScreen(authService: authService ?? _FakeAuthService()),
  );
}

/// True if any Semantics widget in the current tree has the given label.
bool _hasSemanticLabel(WidgetTester tester, String label) {
  return tester
      .widgetList<Semantics>(find.byType(Semantics))
      .any((s) => s.properties.label == label);
}

void main() {
  group('LoginScreen — rendering', () {
    testWidgets('email field renders', (tester) async {
      await tester.pumpWidget(_buildApp());

      expect(find.text('Email'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('password field renders', (tester) async {
      await tester.pumpWidget(_buildApp());

      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('Sign In button renders', (tester) async {
      await tester.pumpWidget(_buildApp());

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Sign Up link has semanticLabel', (tester) async {
      await tester.pumpWidget(_buildApp());

      // Verify the Semantics widget exists with the correct label property —
      // no need to enable the full semantics rendering pipeline.
      expect(_hasSemanticLabel(tester, 'Sign Up'), isTrue);
    });
  });

  group('LoginScreen — validation errors on empty submit', () {
    testWidgets('shows email required error when email is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());

      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows password required error when password is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp());

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

      await tester.ensureVisible(find.text('Sign In'));
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows invalid email error for bad format', (tester) async {
      await tester.pumpWidget(_buildApp());

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

      // Use find.ancestor to locate the GestureDetector wrapping the "Sign Up"
      // text — more reliable than semantic lookup in the widget test environment.
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
      await tester.pumpWidget(
        _buildApp(authService: _FakeAuthService(loginResult: 'Success')),
      );

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
        _buildApp(
          authService: _FakeAuthService(
            loginResult: 'Email or Password is not correct',
          ),
        ),
      );

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
