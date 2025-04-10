import 'package:flutter/foundation.dart';

// Platform-specific implementation will be imported here
import 'web_storage_stub.dart' if (dart.library.html) 'web_storage_web.dart';

/// Platformlar arası localStorage erişimi sağlayan arayüz
class WebStorage {
  /// localStorage'a veri kaydet
  static void setItem(String key, String value) {
    if (kIsWeb) {
      // Web platformu için implementasyon çağrısı
      WebStorageImpl.setItem(key, value);
    }
  }

  /// localStorage'dan veri oku
  static String? getItem(String key) {
    if (kIsWeb) {
      // Web platformu için implementasyon çağrısı
      return WebStorageImpl.getItem(key);
    }
    return null;
  }

  /// localStorage'dan veri sil
  static void removeItem(String key) {
    if (kIsWeb) {
      // Web platformu için implementasyon çağrısı
      WebStorageImpl.removeItem(key);
    }
  }
}
