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
        await _client.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        return _client.getToken(vapidKey: _webVapidKey);
      }
      await _client.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return _client.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Sends a push notification to [tokens] via the Supabase Edge Function.
  /// Failures are silently swallowed so they never block the send flow.
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
      await Supabase.instance.client.functions.invoke(
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
    } catch (_) {
      // Notification delivery is best-effort; never crash the app.
    }
  }
}
