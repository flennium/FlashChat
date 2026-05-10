import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmService {
  FcmService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  static const _webVapidKey =
      'BJ0rBsQH5oBw6gYIopr2DvdbH5kKomvmuWlaKX4ydrMcH8PubyC3GFaLgKe1BQiQEmR5MnAdSwvhMTiX9AFJQFU';

  Future<String?> initAndGetToken() async {
    try {
      if (kIsWeb) {
        await _messaging.requestPermission(
            alert: true, badge: true, sound: true);
        return _messaging.getToken(vapidKey: _webVapidKey);
      }
      await _messaging.requestPermission(
          alert: true, badge: true, sound: true);
      return _messaging.getToken();
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
  }) async {
    if (tokens.isEmpty) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'tokens': tokens,
          'title': title,
          'body': body.length > 120 ? '${body.substring(0, 120)}…' : body,
          'data': data,
        },
      );
    } catch (_) {
      // Notification delivery is best-effort; never crash the app.
    }
  }
}
