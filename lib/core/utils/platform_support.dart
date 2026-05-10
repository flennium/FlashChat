import 'package:flutter/foundation.dart';

class PlatformSupport {
  const PlatformSupport._();

  static bool get isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  static bool get supportsPushNotifications => kIsWeb || isMobile;

  static bool get supportsRealtimePresence => kIsWeb || isMobile;

  static bool get supportsRemoteConfig => kIsWeb || isMobile;

  static bool get supportsCrashlytics => isMobile;

  static bool get supportsGoogleSignIn => kIsWeb || isMobile;
}
