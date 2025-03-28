import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _hasLogError = false; // Log yazma hatası olup olmadığını takip et

  factory LogService() {
    return _instance;
  }

  LogService._internal();

  // Bilgi logu
  void logInfo(String tag, String message) {
    _log('INFO', tag, message, null);
  }

  // Uyarı logu
  void logWarning(String tag, String message) {
    _log('WARNING', tag, message, null);
  }

  // Hata logu
  void logError(String tag, String message, StackTrace? stackTrace) {
    _log('ERROR', tag, message, stackTrace);
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
