import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/platform_support.dart';

class FcmService {
  FcmService({FirebaseMessaging? messaging}) : _messaging = messaging;

  final FirebaseMessaging? _messaging;
  static const _webVapidKey =
      'BJ0rBsQH5oBw6gYIopr2DvdbH5kKomvmuWlaKX4ydrMcH8PubyC3GFaLgKe1BQiQEmR5MnAdSwvhMTiX9AFJQFU';

  FirebaseMessaging get _client => _messaging ?? FirebaseMessaging.instance;

  Future<String?> initAndGetToken() async {
    if (!PlatformSupport.supportsPushNotifications) return null;
    try {
      if (kIsWeb) {
        final settings = await _client.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (!_isAuthorized(settings.authorizationStatus)) {
          _debugLog('Notification permission denied on web.');
          return null;
        }
        return _client.getToken(vapidKey: _webVapidKey);
      }
      final settings = await _client.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (!_isAuthorized(settings.authorizationStatus)) {
        _debugLog('Notification permission denied on this device.');
        return null;
      }
      return _client.getToken();
    } catch (error, stackTrace) {
      _debugLog('Could not initialize FCM: $error\n$stackTrace');
      return null;
    }
  }

  Future<void> sendNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String? notificationTag,
    String? iosThreadId,
    String? collapseId,
  }) async {
    if (tokens.isEmpty || !PlatformSupport.supportsPushNotifications) return;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'tokens': tokens,
          'title': title,
          'body': body.length > 120 ? '${body.substring(0, 120)}...' : body,
          'data': data,
          if (notificationTag != null && notificationTag.isNotEmpty)
            'notificationTag': notificationTag,
          if (iosThreadId != null && iosThreadId.isNotEmpty)
            'iosThreadId': iosThreadId,
          if (collapseId != null && collapseId.isNotEmpty)
            'collapseId': collapseId,
        },
      );
      if (response.status >= 400) {
        _debugLog(
          'send-notification failed with ${response.status}: ${response.data}',
        );
      } else {
        _debugLog('send-notification response: ${response.data}');
      }
    } catch (error, stackTrace) {
      _debugLog('Could not send notification: $error\n$stackTrace');
      // Notification delivery is best-effort; never crash the app.
    }
  }

  bool _isAuthorized(AuthorizationStatus status) {
    return status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[FCM] $message');
  }
}
