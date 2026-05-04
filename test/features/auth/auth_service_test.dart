import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:zoopernova_zoo_system/features/auth/models/auth_model.dart';
import 'package:zoopernova_zoo_system/features/auth/services/auth_service.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([FirebaseAuth, UserCredential, User])
void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore fakeFirestore;
    late AuthService service;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      fakeFirestore = FakeFirebaseFirestore();
      service = AuthService(auth: mockAuth, firestore: fakeFirestore);
    });

    // ─── login ────────────────────────────────────────────────────────────────

    group('login', () {
      test('returns "Success" with valid credentials', () async {
        when(
          mockAuth.signInWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => MockUserCredential());

        final result = await service.login('valid@test.com', 'password123');

        expect(result, 'Success');
      });

      test(
        'returns error message when FirebaseAuthException is thrown',
        () async {
          when(
            mockAuth.signInWithEmailAndPassword(
              email: anyNamed('email'),
              password: anyNamed('password'),
            ),
          ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

          final result = await service.login('bad@test.com', 'wrongpass');

          expect(result, 'Email or Password is not correct');
        },
      );

      test('returns generic error on unexpected exception', () async {
        when(
          mockAuth.signInWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(Exception('network failure'));

        final result = await service.login('test@test.com', 'pass');

        expect(result, 'Something went wrong');
      });
    });

    // ─── register ─────────────────────────────────────────────────────────────

    group('register', () {
      test(
        'creates Firestore document keyed by Firebase Auth UID (not Auto-ID)',
        () async {
          const testUid = 'firebase-auth-uid-abc123';
          final mockUser = MockUser();
          final mockCredential = MockUserCredential();

          when(mockUser.uid).thenReturn(testUid);
          when(mockCredential.user).thenReturn(mockUser);
          when(
            mockAuth.createUserWithEmailAndPassword(
              email: anyNamed('email'),
              password: anyNamed('password'),
            ),
          ).thenAnswer((_) async => mockCredential);

          final result = await service.register(
            email: 'newuser@test.com',
            password: 'password123',
            firstname: 'John',
            lastname: 'Doe',
            phoneNumber: '0812345678',
            username: 'john_doe',
          );

          expect(result, 'Success');

          // Document must exist under the Auth UID, not an auto-generated ID
          final doc = await fakeFirestore.collection('user').doc(testUid).get();
          expect(
            doc.exists,
            true,
            reason: 'user doc should be stored under the Auth UID',
          );
          expect(
            doc.id,
            testUid,
            reason: 'document ID must equal the Firebase Auth UID',
          );
        },
      );

      test('stores correct user data in Firestore', () async {
        const testUid = 'uid-xyz-789';
        final mockUser = MockUser();
        final mockCredential = MockUserCredential();

        when(mockUser.uid).thenReturn(testUid);
        when(mockCredential.user).thenReturn(mockUser);
        when(
          mockAuth.createUserWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenAnswer((_) async => mockCredential);

        await service.register(
          email: 'jane@test.com',
          password: 'securepass',
          firstname: 'Jane',
          lastname: 'Smith',
          phoneNumber: '0899999999',
          username: 'jane_smith',
        );

        final data = (await fakeFirestore.collection('user').doc(testUid).get())
            .data()!;
        expect(data['email'], 'jane@test.com');
        expect(data['firstname'], 'Jane');
        expect(data['lastname'], 'Smith');
        expect(data['phoneNumber'], '0899999999');
        expect(data['username'], 'jane_smith');
        // Password must NOT be stored in Firestore
        expect(
          data.containsKey('password'),
          false,
          reason: 'password must never be stored in Firestore',
        );
      });

      test('returns error message for weak password', () async {
        when(
          mockAuth.createUserWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'weak-password'));

        final result = await service.register(
          email: 'test@test.com',
          password: '123',
          firstname: 'A',
          lastname: 'B',
          phoneNumber: '0800000000',
          username: 'ab',
        );

        expect(result, 'Password must be at least 6 characters.');
      });

      test('returns error message when email already in use', () async {
        when(
          mockAuth.createUserWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

        final result = await service.register(
          email: 'existing@test.com',
          password: 'password123',
          firstname: 'Dup',
          lastname: 'User',
          phoneNumber: '0800000001',
          username: 'dup_user',
        );

        expect(result, 'This email is already in use.');
      });

      test(
        'returns "Cannot create an account." when Auth returns null user',
        () async {
          final mockCredential = MockUserCredential();
          when(mockCredential.user).thenReturn(null);
          when(
            mockAuth.createUserWithEmailAndPassword(
              email: anyNamed('email'),
              password: anyNamed('password'),
            ),
          ).thenAnswer((_) async => mockCredential);

          final result = await service.register(
            email: 'ghost@test.com',
            password: 'pass1234',
            firstname: 'Ghost',
            lastname: 'User',
            phoneNumber: '0800000002',
            username: 'ghost',
          );

          expect(result, 'Cannot create an account.');
        },
      );
    });

    // ─── logout ───────────────────────────────────────────────────────────────

    group('logout', () {
      test('calls signOut on FirebaseAuth', () async {
        when(mockAuth.signOut()).thenAnswer((_) async {});

        await service.logout();

        verify(mockAuth.signOut()).called(1);
      });
    });

    // ─── getCurrentUserData ───────────────────────────────────────────────────

    group('getCurrentUserData', () {
      test(
        'returns UserModel when a user is logged in and doc exists',
        () async {
          const uid = 'logged-in-uid';
          final mockUser = MockUser();
          when(mockUser.uid).thenReturn(uid);
          when(mockAuth.currentUser).thenReturn(mockUser);

          await fakeFirestore.collection('user').doc(uid).set({
            'email': 'loggedin@test.com',
            'firstname': 'Logged',
            'lastname': 'In',
            'phoneNumber': '0811111111',
            'username': 'logged_in',
          });

          final result = await service.getCurrentUserData();

          expect(result, isA<UserModel>());
          expect(result?.uid, uid);
          expect(result?.email, 'loggedin@test.com');
        },
      );

      test('returns null when no user is currently signed in', () async {
        when(mockAuth.currentUser).thenReturn(null);

        final result = await service.getCurrentUserData();

        expect(result, isNull);
      });

      test('returns null when user doc does not exist in Firestore', () async {
        final mockUser = MockUser();
        when(mockUser.uid).thenReturn('uid-no-doc');
        when(mockAuth.currentUser).thenReturn(mockUser);

        final result = await service.getCurrentUserData();

        expect(result, isNull);
      });
    });
  });
}
