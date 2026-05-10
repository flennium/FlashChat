import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebasePlatformOptions {
  const FirebasePlatformOptions._();

  static FirebaseOptions get current {
    if (kIsWeb) {
      return DefaultFirebaseOptions.web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return DefaultFirebaseOptions.android;
      case TargetPlatform.iOS:
        return DefaultFirebaseOptions.ios;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        // Desktop builds in this project reuse the same Firebase project
        // settings as the web client.
        return DefaultFirebaseOptions.web;
      default:
        return DefaultFirebaseOptions.web;
    }
  }
}
