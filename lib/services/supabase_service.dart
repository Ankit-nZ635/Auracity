import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _bucketName = 'issue-images';

  static Future<String> uploadImage(String fileName, Uint8List bytes, {String folder = 'issues'}) async {
    final String path = '$folder/$fileName.jpg';
    
    try {
      await _client.storage.from(_bucketName).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final String publicUrl = _client.storage.from(_bucketName).getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      if (e.message.toLowerCase().contains('not found')) {
        throw 'Supabase Storage Bucket "$_bucketName" not found. Please create a Public bucket named "$_bucketName" in your Supabase dashboard.';
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
