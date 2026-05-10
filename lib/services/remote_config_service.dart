import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../core/constants/firebase_constants.dart';

class RemoteConfigService {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  // FIREBASE LESSON: Remote Config lets us change app content like a global
  // announcement without shipping a new app build.
  Future<String> fetchPinnedMessage() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await _remoteConfig.setDefaults({FirebaseConstants.announcementKey: ''});
    await _remoteConfig.fetchAndActivate();
    return _remoteConfig.getString(FirebaseConstants.announcementKey);
  }
}
