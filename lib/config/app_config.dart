class AppConfig {
  // Timeout değerleri
  static const int defaultTimeoutSeconds = 10;
  static const int shortTimeoutSeconds = 5;
  static const int longTimeoutSeconds = 30;

  // Pagination değerleri
  static const int defaultPageSize = 20;
  static const int largePageSize = 50;

  // Cache politikaları
  static const Duration cacheValidDuration = Duration(hours: 1);

  // API endpoint'leri
  static const String apiBaseUrl = 'https://api.example.com';

  // Uygulama sürümü
  static const String appVersion = '1.0.0';

  // Hata mesajları
  static const Map<String, String> errorMessages = {
    'network_error':
        'İnternet bağlantısı hatası. Lütfen bağlantınızı kontrol edin.',
    'timeout_error':
        'İşlem zaman aşımına uğradı. Lütfen daha sonra tekrar deneyin.',
    'auth_error': 'Oturum açma hatası. Lütfen bilgilerinizi kontrol edin.',
    'permission_error': 'Bu işlemi gerçekleştirmek için yetkiniz yok.',
    'unknown_error':
        'Beklenmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin.',
  };

  // Tema renkleri
  static const Map<String, int> themeColors = {
    'primary': 0xFF2196F3,
    'secondary': 0xFF4CAF50,
    'accent': 0xFFFFC107,
    'error': 0xFFF44336,
  };
}
