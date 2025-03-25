import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // TimeoutException için
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuthException için
import '../config/app_config.dart';

class AppUtils {
  // Tarih formatlama
  static String formatDate(DateTime date, {String format = 'dd.MM.yyyy'}) {
    return DateFormat(format).format(date);
  }

  // Para birimi formatlama
  static String formatCurrency(double amount, {String symbol = '₺'}) {
    return '${NumberFormat('#,##0.00', 'tr_TR').format(amount)} $symbol';
  }

  // Telefon numarası formatlama
  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length != 10) return phoneNumber;

    return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6)}';
  }

  // Hata mesajı getirme
  static String getErrorMessage(dynamic error) {
    if (error is TimeoutException) {
      return AppConfig.errorMessages['timeout_error']!;
    } else if (error.toString().contains('SocketException')) {
      return AppConfig.errorMessages['network_error']!;
    } else if (error is FirebaseAuthException) {
      // Firebase Auth hata mesajlarını işle
      switch (error.code) {
        case 'user-not-found':
          return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
        case 'wrong-password':
          return 'Hatalı şifre';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi';
        case 'user-disabled':
          return 'Bu hesap devre dışı bırakılmış';
        case 'too-many-requests':
          return 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin.';
        default:
          return 'Hata kodu: ${error.code}';
      }
    }

    return AppConfig.errorMessages['unknown_error']!;
  }

  // Ekran boyutlarına göre responsive değer hesaplama
  static double responsiveSize(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return size * 0.8; // Küçük ekranlar için
    } else if (screenWidth > 600) {
      return size * 1.2; // Büyük ekranlar için
    }

    return size; // Normal ekranlar için
  }

  // Klavyeyi kapat
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}
