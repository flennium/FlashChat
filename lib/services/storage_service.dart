import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_env.dart';

class StorageService {
  StorageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  // MEDIA LESSON: Supabase Storage is used only for media files while
  // Firebase remains the source of truth for auth, chat, and profile data.
  Future<String?> pickAndUploadImage({
    required String path,
    required String bucket,
    ImageSource source = ImageSource.gallery,
  }) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 75);
    if (picked == null) return null;

    _assertConfigured();
    final bytes = await picked.readAsBytes();
    final objectPath = _buildObjectPath(path, picked.name);
    final contentType = picked.mimeType ?? _guessContentType(picked.name);

    await Supabase.instance.client.storage.from(bucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: contentType,
          ),
        );

    return '${AppEnv.supabaseUrl}/storage/v1/object/public/$bucket/$objectPath';
  }

  void _assertConfigured() {
    if (!AppEnv.hasSupabaseStorageConfig) {
      throw Exception(
        'Supabase storage is not configured ',
      );
    }
  }

  String _buildObjectPath(String path, String fileName) {
    final safePath = path.replaceAll('\\', '/').replaceAll(RegExp(r'^/+'), '');
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return '$safePath/${DateTime.now().millisecondsSinceEpoch}_$safeName';
  }

  String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
