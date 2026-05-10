import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../core/constants/firebase_constants.dart';
import '../core/utils/platform_support.dart';

class RemoteConfigService {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig;

  final FirebaseRemoteConfig? _remoteConfig;

  FirebaseRemoteConfig get _client =>
      _remoteConfig ?? FirebaseRemoteConfig.instance;

  // FIREBASE LESSON: Remote Config lets us change app content like a global
  // announcement without shipping a new app build.
  Future<String> fetchPinnedMessage() async {
    if (!PlatformSupport.supportsRemoteConfig) return '';

    await _client.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await _client.setDefaults({FirebaseConstants.announcementKey: ''});
    await _client.fetchAndActivate();
    return _client.getString(FirebaseConstants.announcementKey);
  }
}
