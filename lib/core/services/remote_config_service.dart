import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  static final _rc = FirebaseRemoteConfig.instance;

  static const _defaults = <String, dynamic>{
    'feature_popular_animals': true,
    'feature_map_3d': false,
    'feature_ar_animals': false,
  };

  static Future<void> init() async {
    try {
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 1),
        ),
      );
      await _rc.setDefaults(_defaults);
      await _rc.fetchAndActivate();
    } catch (e) {
      debugPrint('[RemoteConfig] init failed, using defaults: $e');
    }
  }

  static bool get featurePopularAnimals =>
      _rc.getBool('feature_popular_animals');
  static bool get featureMap3d => _rc.getBool('feature_map_3d');
  static bool get featureArAnimals => _rc.getBool('feature_ar_animals');
}
