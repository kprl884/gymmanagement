import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/navigation.dart';
import '../utils/web_storage.dart'; // Web storage işlemleri için yardımcı sınıf
import 'log_service.dart';
import 'user_service.dart';

/// Oturum zaman aşımı süresini yöneten servis
class SessionTimeoutService {
  static const int sessionTimeoutMinutes = 30; // 30 dakika zaman aşımı süresi
  static const String lastActivityKey = 'last_activity_time';

  Timer? _sessionTimer;
  DateTime? _lastActivityTime;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LogService _logService = LogService();
  final UserService _userService = UserService();
  bool _isTimerActive = false;

  // Singleton pattern
  static final SessionTimeoutService _instance =
      SessionTimeoutService._internal();
  factory SessionTimeoutService() => _instance;
  SessionTimeoutService._internal();

  /// Servis başlatılıyor
  Future<void> init() async {
    _logService.logInfo('SessionTimeoutService', 'Servis başlatılıyor');

    // Uygulama başlatıldığında son aktivite zamanını kontrol et
    await checkSession();

    // Kullanıcı oturum açma/kapatma durumunu dinle
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _logService.logInfo('SessionTimeoutService',
            'Kullanıcı oturum açtı, timer başlatılıyor');
        _startSessionTimer();
        _updateLastActivityTime(); // Oturum açıldığında son aktivite zamanını güncelle
      } else {
        _logService.logInfo('SessionTimeoutService',
            'Kullanıcı oturum kapattı, timer durduruluyor');
        _stopSessionTimer();
      }
    });
  }

  /// Kullanıcı aktivitesi gerçekleştiğinde çağrılır
  void userActivity() {
    if (_auth.currentUser != null) {
      _updateLastActivityTime();
      _resetSessionTimer();
      _logService.logInfo('SessionTimeoutService',
          'Kullanıcı aktivitesi algılandı, timer sıfırlandı');
    }
  }

  /// Uygulamanın arka plandan ön plana geçtiğinde oturumu kontrol eder
  Future<void> checkSession() async {
    if (_auth.currentUser != null) {
      final isSessionValid = await _isSessionValid();

      if (!isSessionValid) {
        _logService.logInfo(
            'SessionTimeoutService', 'Oturum süresi doldu, çıkış yapılıyor');
        await _signOut();
      } else {
        _logService.logInfo(
            'SessionTimeoutService', 'Oturum geçerli, devam ediliyor');
        _startSessionTimer();
        _updateLastActivityTime(); // Oturum geçerli ise son aktivite zamanını güncelle
      }
    }
  }

  /// Son aktivite zamanını günceller (hem bellek hem de storage'da)
  Future<void> _updateLastActivityTime() async {
    _lastActivityTime = DateTime.now();

    try {
      // Mobil veya web platformuna göre storage seçimi
      if (kIsWeb) {
        // Web için localStorage kullan
        WebStorage.setItem(
            lastActivityKey, _lastActivityTime!.toIso8601String());
      } else {
        // Mobil için SharedPreferences kullan
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            lastActivityKey, _lastActivityTime!.toIso8601String());
      }

      _logService.logInfo('SessionTimeoutService',
          'Son aktivite zamanı güncellendi: ${_lastActivityTime.toString()}');
    } catch (e) {
      _logService.logError('SessionTimeoutService',
          'Son aktivite zamanı güncellenirken hata: $e', null);
    }
  }

  /// Storage'dan son aktivite zamanını alır
  Future<DateTime?> _getLastActivityTime() async {
    try {
      if (kIsWeb) {
        // Web için localStorage'dan al
        final timeString = WebStorage.getItem(lastActivityKey);
        if (timeString != null && timeString.isNotEmpty) {
          return DateTime.parse(timeString);
        }
      } else {
        // Mobil için SharedPreferences'dan al
        final prefs = await SharedPreferences.getInstance();
        final timeString = prefs.getString(lastActivityKey);

        if (timeString != null) {
          return DateTime.parse(timeString);
        }
      }
    } catch (e) {
      _logService.logError('SessionTimeoutService',
          'Son aktivite zamanı alınırken hata: $e', null);
    }

    return null;
  }

  /// Session timer'ı başlatır
  void _startSessionTimer() {
    if (_isTimerActive) return;

    _stopSessionTimer(); // Önceki timer varsa durdur

    _sessionTimer = Timer.periodic(
      const Duration(minutes: 1), // Her dakika kontrol et
      (timer) async {
        final isValid = await _isSessionValid();
        if (!isValid) {
          _logService.logInfo(
              'SessionTimeoutService', 'Timer kontrolü: Oturum süresi doldu');
          await _signOut();
        }
      },
    );

    _isTimerActive = true;
    _logService.logInfo('SessionTimeoutService', 'Session timer başlatıldı');
  }

  /// Session timer'ı durdurur
  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _isTimerActive = false;
    _logService.logInfo('SessionTimeoutService', 'Session timer durduruldu');
  }

  /// Session timer'ı sıfırlar
  void _resetSessionTimer() {
    _stopSessionTimer();
    _startSessionTimer();
  }

  /// Oturumun hala geçerli olup olmadığını kontrol eder
  Future<bool> _isSessionValid() async {
    // Kullanıcı giriş yapmamışsa geçersiz kabul et
    if (_auth.currentUser == null) {
      return false;
    }

    // Son aktivite zamanını kontrol et
    final lastActivity = _lastActivityTime ?? await _getLastActivityTime();

    if (lastActivity == null) {
      // Son aktivite zamanı yoksa, şu anki zamanı kaydet ve geçerli kabul et
      await _updateLastActivityTime();
      return true;
    }

    // Şu anki zaman ile son aktivite zamanı arasındaki farkı hesapla
    final now = DateTime.now();
    final difference = now.difference(lastActivity);

    // Zaman aşımı süresini aşıp aşmadığını kontrol et
    final isValid = difference.inMinutes < sessionTimeoutMinutes;

    _logService.logInfo(
        'SessionTimeoutService',
        'Oturum kontrolü: ${isValid ? "Geçerli" : "Geçersiz"}, '
            'Son aktiviteden bu yana geçen süre: ${difference.inMinutes} dakika');

    return isValid;
  }

  /// Oturumu sonlandırır ve login sayfasına yönlendirir
  Future<void> _signOut() async {
    try {
      _stopSessionTimer();
      _logService.logInfo('SessionTimeoutService',
          'Oturum zaman aşımı nedeniyle sonlandırılıyor');

      // UserService kullanarak çıkış yap
      await _userService.signOut();

      // navigatorKey null durumunu kontrol ederek login sayfasına yönlendir
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      _logService.logError(
          'SessionTimeoutService', 'Çıkış yapılırken hata: $e', null);
    }
  }
}
