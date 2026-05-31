import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _enabledKey = 'biometric_enabled';

  /// True only when the device has biometric hardware AND at least one
  /// fingerprint / face is enrolled. `isDeviceSupported` is intentionally
  /// excluded — it returns true even with no enrolled biometrics, which would
  /// show the button but always fail on authenticate().
  static Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// True if the user has opted-in to biometric session resumption.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Persist the user's biometric preference.
  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_enabledKey, true);
    } else {
      await prefs.remove(_enabledKey);
    }
  }

  /// True when the Firebase Auth session is still active (token not expired).
  /// Biometric is used to *resume* an existing session, not create a new one.
  static bool hasActiveSession() =>
      FirebaseAuth.instance.currentUser != null;

  /// Show the platform biometric prompt.
  /// Returns true on success, error message string on failure.
  static Future<({bool success, String? error})> authenticate() async {
    if (kIsWeb) return (success: false, error: 'Not supported on Web');
    try {
      final result = await _auth.authenticate(
        localizedReason: 'Verify your identity to access Zoopernova',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return (success: result, error: result ? null : 'Cancelled');
    } catch (e) {
      debugPrint('[BiometricService] error: $e');
      return (success: false, error: e.toString());
    }
  }
}
