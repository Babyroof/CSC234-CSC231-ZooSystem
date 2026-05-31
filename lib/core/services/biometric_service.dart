import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _enabledKey = 'biometric_enabled';

  /// True if the device has biometric hardware (fingerprint / face).
  /// Always false on Web — Web uses WebAuthn which requires a server RP.
  static Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
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
  /// Returns true on success, false on failure or cancellation.
  static Future<bool> authenticate() async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Verify your identity to access Zoopernova',
        options: const AuthenticationOptions(
          // Allow device PIN / pattern as fallback so users without
          // enrolled biometrics are not locked out.
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
