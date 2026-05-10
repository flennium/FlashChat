class AppEnv {
  const AppEnv._();

  static const supabaseUrl =
      String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: '',
      );
  static const supabaseAnonKey =
      String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      );
  static const supabaseAvatarBucket =
      String.fromEnvironment('SUPABASE_AVATAR_BUCKET', defaultValue: 'avatars');
  static const supabaseChatImageBucket =
      String.fromEnvironment('SUPABASE_CHAT_IMAGE_BUCKET', defaultValue: 'chat-images');
  static const googleWebClientId =
      String.fromEnvironment(
        'GOOGLE_WEB_CLIENT_ID',
        defaultValue: '',
      );

  static bool get hasSupabaseStorageConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
