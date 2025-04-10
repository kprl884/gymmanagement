/// Web depolama işlemleri için boş implementasyon (mobil platformlar için)
class WebStorageImpl {
  /// localStorage'a veri kaydet (mobil için boş implementasyon)
  static void setItem(String key, String value) {
    // Mobil platformda implementasyon yok
  }

  /// localStorage'dan veri oku (mobil için boş implementasyon)
  static String? getItem(String key) {
    // Mobil platformda implementasyon yok
    return null;
  }

  /// localStorage'dan veri sil (mobil için boş implementasyon)
  static void removeItem(String key) {
    // Mobil platformda implementasyon yok
  }
}
