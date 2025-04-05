import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'crashlytics_service.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CrashlyticsService _crashlytics = CrashlyticsService();
  bool _hasLogError = false; // Log yazma hatası olup olmadığını takip et

  factory LogService() {
    return _instance;
  }

  LogService._internal();

  // Bilgi logu
  void logInfo(String tag, String message) {
    final logMessage = '[$tag] INFO: $message';
    debugPrint(logMessage);
    _crashlytics.log(logMessage);
  }

  // Uyarı logu
  void logWarning(String tag, String message) {
    final logMessage = '[$tag] WARNING: $message';
    debugPrint(logMessage);
    _crashlytics.log(logMessage);
  }

  // Hata logu
  void logError(String tag, String message, StackTrace? stackTrace) {
    final logMessage = '[$tag] ERROR: $message';
    debugPrint(logMessage);

    // Record error in Crashlytics
    final error = Exception('$tag: $message');
    _crashlytics.recordError(error, stackTrace);
  }

  // Set current user for better error tracking
  void setUser(String userId) {
    _crashlytics.setUserIdentifier(userId);
  }

  // Log yazma işlemi
  void _log(String level, String tag, String message, StackTrace? stackTrace) {
    // Konsola yazdır
    if (kDebugMode) {
      print('$level: [$tag] $message');
      if (stackTrace != null) {
        print(stackTrace);
      }
    }

    // Eğer daha önce log yazma hatası olduysa, Firestore'a yazmayı deneme
    if (_hasLogError) {
      return;
    }

    // Firestore'a kaydet (hata olursa sessizce devam et)
    try {
      _firestore.collection('logs').add({
        'level': level,
        'tag': tag,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'stackTrace': stackTrace?.toString(),
      }).catchError((e) {
        // Log yazma hatası olduğunu işaretle
        _hasLogError = true;

        // Sadece konsola yazdır
        if (kDebugMode) {
          print('Log yazma hatası: $e');
        }
      });
    } catch (e) {
      // Log yazma hatası olduğunu işaretle
      _hasLogError = true;

      // Sadece konsola yazdır
      if (kDebugMode) {
        print('Log yazma hatası: $e');
      }
    }
  }
}
