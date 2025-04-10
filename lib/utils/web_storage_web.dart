// Web platformu için import
import 'dart:html' as html;

/// Web depolama işlemleri için implementasyon (web platformu için)
class WebStorageImpl {
  /// localStorage'a veri kaydet
  static void setItem(String key, String value) {
    try {
      html.window.localStorage[key] = value;
    } catch (e) {
      print('Web storage setItem error: $e');
    }
  }

  /// localStorage'dan veri oku
  static String? getItem(String key) {
    try {
      return html.window.localStorage[key];
    } catch (e) {
      print('Web storage getItem error: $e');
      return null;
    }
  }

  /// localStorage'dan veri sil
  static void removeItem(String key) {
    try {
      html.window.localStorage.remove(key);
    } catch (e) {
      print('Web storage removeItem error: $e');
    }
  }
}
