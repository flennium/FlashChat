import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_env.dart';
import '../core/utils/firebase_platform_options.dart';
import '../core/utils/platform_support.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(options: FirebasePlatformOptions.current);
      if (AppEnv.hasSupabaseStorageConfig) {
        await Supabase.initialize(
          url: AppEnv.supabaseUrl,
          anonKey: AppEnv.supabaseAnonKey,
        );
      }
      if (PlatformSupport.supportsCrashlytics) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }
    } catch (error, stack) {
      Error.throwWithStackTrace(error, stack);
    }
  }
}
