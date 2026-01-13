import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final featureFlagsProvider = Provider<FeatureFlags>((ref) => FeatureFlags());

class FeatureFlags {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      // Use shorter interval in debug for faster testing
      minimumFetchInterval: kDebugMode ? const Duration(minutes: 5) : const Duration(hours: 12),
    ));

    // Set default values (fallback if offline)
    await _remoteConfig.setDefaults({
      'enable_gen_z_dialog': true,
    });

    await _remoteConfig.fetchAndActivate();
  }

  bool get isGenZDialogEnabled => _remoteConfig.getBool('enable_gen_z_dialog');
}