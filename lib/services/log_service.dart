import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory LogService() {
    return _instance;
  }

  LogService._internal();

  // Hata logla
  Future<void> logError(
      String source, dynamic error, StackTrace? stackTrace) async {
    // Konsola hata mesajını yazdır
    debugPrint('HATA [$source]: $error');
    if (stackTrace != null) {
      debugPrint('STACK TRACE: $stackTrace');
    }

    try {
      // Firestore'a hata kaydı ekle
      await _firestore.collection('error_logs').add({
        'source': source,
        'error': error.toString(),
        'stackTrace': stackTrace?.toString(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Firestore'a kayıt yapılamazsa sadece konsola yazdır
      debugPrint('Hata loglanırken sorun oluştu: $e');
    }
  }

  // Bilgi logla
  void logInfo(String source, String message) {
    debugPrint('BİLGİ [$source]: $message');
  }

  // Uyarı logla
  void logWarning(String source, String message) {
    debugPrint('UYARI [$source]: $message');
  }
}
