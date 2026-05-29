import 'dart:typed_data';

class LocalImageService {
  // In-memory cache for the current session (perfect for bypassing Firebase Storage in demos)
  static final Map<String, Uint8List> _cache = {};

  static Future<String> saveImage(String issueId, Uint8List bytes) async {
    // Keep memory footprint low by limiting cache size
    if (_cache.length >= 10) {
      _cache.remove(_cache.keys.first);
    }
    _cache[issueId] = bytes;
    return 'local://$issueId';
  }

  static Uint8List? getImage(String url) {
    if (url.startsWith('local://')) {
      return _cache[url.replaceAll('local://', '')];
    }
    return null;
  }
}
