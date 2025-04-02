import 'dart:async';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart' as sms_inbox;
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import '../models/customer.dart';
import 'log_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  final LogService _logService = LogService();
  final sms_inbox.SmsQuery _query = sms_inbox.SmsQuery();
  final Telephony _telephony = Telephony.instance;

  // Son SMS okuma tarihleri
  Map<String, DateTime> _lastSmsDateByCustomer = {};

  factory SmsService() {
    return _instance;
  }

  SmsService._internal() {
    _loadLastSmsData();
  }

  // SMS izinlerini kontrol et ve iste
  Future<bool> checkAndRequestSmsPermission() async {
    bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    return permissionsGranted ?? false;
  }

  // Son SMS okuma verilerini yükle
  Future<void> _loadLastSmsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final smsData = prefs.getStringList('last_sms_dates') ?? [];

      for (var item in smsData) {
        final parts = item.split('|');
        if (parts.length == 2) {
          final customerId = parts[0];
          final dateStr = parts[1];
          _lastSmsDateByCustomer[customerId] = DateTime.parse(dateStr);
        }
      }
    } catch (e) {
      _logService.logError(
          'SmsService', 'SMS verisi yüklenirken hata: $e', null);
    }
  }

  // Son SMS okuma verilerini kaydet
  Future<void> _saveLastSmsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final smsData = _lastSmsDateByCustomer.entries
          .map((e) => '${e.key}|${e.value.toIso8601String()}')
          .toList();

      await prefs.setStringList('last_sms_dates', smsData);
    } catch (e) {
      _logService.logError(
          'SmsService', 'SMS verisi kaydedilirken hata: $e', null);
    }
  }

  // Müşteri için gelen SMS'leri oku
  Future<List<sms_inbox.SmsMessage>> getCustomerSmsMessages(
      Customer customer) async {
    if (!(await checkAndRequestSmsPermission())) {
      _logService.logWarning('SmsService', 'SMS okuma izni reddedildi');
      return [];
    }

    try {
      // Son 30 gün içindeki mesajları getir
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(Duration(days: 30));

      // Telefon numarasını formatla
      String phoneNumber = _formatPhoneNumber(customer.phone);

      // SMS'leri oku
      var messages = await _query.querySms(
        address: phoneNumber,
        kinds: [sms_inbox.SmsQueryKind.inbox],
        count: 30,
      );

      // Son okuma tarihini güncelle
      if (customer.id != null) {
        _lastSmsDateByCustomer[customer.id!] = now;
        await _saveLastSmsData();
      }

      return messages;
    } catch (e) {
      _logService.logError(
          'SmsService', 'SMS mesajları okunurken hata: $e', null);
      return [];
    }
  }

  // Tüm SMS mesajlarını oku (son 7 günlük)
  Future<List<sms_inbox.SmsMessage>> getAllRecentSms() async {
    if (!(await checkAndRequestSmsPermission())) {
      _logService.logWarning('SmsService', 'SMS okuma izni reddedildi');
      return [];
    }

    try {
      // Son 7 gün içindeki mesajları getir
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));

      // SMS'leri oku
      var messages = await _query.querySms(
        kinds: [sms_inbox.SmsQueryKind.inbox],
        count: 100,
      );

      return messages;
    } catch (e) {
      _logService.logError(
          'SmsService', 'SMS mesajları okunurken hata: $e', null);
      return [];
    }
  }

  // Ödeme ilgili SMS mesajlarını filtrele
  List<sms_inbox.SmsMessage> filterPaymentRelatedSms(
      List<sms_inbox.SmsMessage> messages) {
    // Ödeme ile ilgili anahtar kelimeler
    final List<String> paymentKeywords = [
      'ödeme',
      'odeme',
      'payment',
      'fatura',
      'invoice',
      'aidat',
      'ücret',
      'ucret',
      'borç',
      'borc',
      'banka',
      'bank',
      'tl',
      'kredi',
      'credit',
      'havale',
      'eft',
    ];

    return messages.where((message) {
      final lowerCaseBody = message.body?.toLowerCase() ?? '';

      return paymentKeywords.any((keyword) => lowerCaseBody.contains(keyword));
    }).toList();
  }

  // Telefon numarasını formatla
  String _formatPhoneNumber(String phoneNumber) {
    // + işaretini kaldır
    if (phoneNumber.startsWith('+')) {
      phoneNumber = phoneNumber.substring(1);
    }

    // Başında 0 varsa kaldır
    if (phoneNumber.startsWith('0')) {
      phoneNumber = phoneNumber.substring(1);
    }

    // Türkiye kodu ekle (eğer yoksa)
    if (!phoneNumber.startsWith('90') && phoneNumber.length < 12) {
      phoneNumber = '90$phoneNumber';
    }

    return phoneNumber;
  }

  // Bir müşterinin SMS ile ödeme yapıp yapmadığını kontrol et
  Future<bool> checkCustomerSmsPayment(Customer customer) async {
    var messages = await getCustomerSmsMessages(customer);

    // Ödeme ile ilgili mesajları filtrele
    var paymentMessages = filterPaymentRelatedSms(messages);

    // Son ödeme tarihini hesapla
    DateTime lastPaymentDate = customer.registrationDate;
    if (customer.paidMonths.isNotEmpty) {
      var sortedPayments = List<DateTime>.from(customer.paidMonths)
        ..sort((a, b) => b.compareTo(a));
      lastPaymentDate = sortedPayments.first;
    }

    // Son ödemeden sonraki SMS'leri kontrol et
    return paymentMessages.any((msg) {
      if (msg.date != null) {
        final dateValue =
            msg.date is int ? msg.date! as int : int.parse(msg.date.toString());
        var messageDate = DateTime.fromMillisecondsSinceEpoch(dateValue);
        return messageDate.isAfter(lastPaymentDate);
      }
      return false;
    });
  }

  // Test SMS gönderimi (sahte, artık sadece bir SMS bakma işlevi)
  Future<bool> sendPaymentReminder(Customer customer) async {
    if (customer.id == null || customer.phone.isEmpty) {
      _logService.logWarning('SmsService',
          'Müşteri ID veya telefon numarası eksik: ${customer.name} ${customer.surname}');
      return false;
    }

    // Bu fonksiyon artık SMS göndermek yerine, SMS'leri kontrol eder
    final hasSmsPayment = await checkCustomerSmsPayment(customer);

    if (hasSmsPayment) {
      _logService.logInfo('SmsService',
          'Müşteri SMS ile ödeme yapmış olabilir: ${customer.name} ${customer.surname}');
    } else {
      _logService.logInfo('SmsService',
          'Müşterinin SMS ile ödemesi tespit edilemedi: ${customer.name} ${customer.surname}');
    }

    return hasSmsPayment;
  }

  // Add a replacement for the checkAndSendPaymentReminders method
  Future<void> checkAndSendPaymentReminders(List<Customer> customers) async {
    // This now checks SMS payments instead of sending reminders
    for (var customer in customers) {
      if (customer.isActive) {
        await checkCustomerSmsPayment(customer);
      }
    }
  }

  // Test için tek bir SMS gönder
  Future<bool> sendTestSms(String phoneNumber, String message) async {
    try {
      // SMS iznini kontrol et
      bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
      if (permissionsGranted != true) {
        _logService.logWarning('SmsService', 'SMS gönderme izni reddedildi');
        return false;
      }

      // Telefon numarasını formatla
      String formattedPhone = _formatPhoneNumber(phoneNumber);

      // Remove country code if present for local sending
      if (formattedPhone.startsWith('90')) {
        formattedPhone = formattedPhone.substring(2);
      }

      // Add leading 0 if not present
      if (!formattedPhone.startsWith('0')) {
        formattedPhone = '0$formattedPhone';
      }

      // SMS gönder
      await _telephony.sendSms(to: formattedPhone, message: message);

      return true;
    } catch (e) {
      _logService.logError(
          'SmsService', 'SMS gönderilirken hata oluştu: $e', null);
      return false;
    }
  }

  // SMS gönderme izni kontrolü (telephony kullanım için yeniden düzenlendi)
  Future<bool> _checkSendSmsPermission() async {
    bool? permissionsGranted = await _telephony.requestPhoneAndSmsPermissions;
    return permissionsGranted ?? false;
  }

  // Toplu SMS gönder
  Future<Map<String, bool>> sendBulkSms(
      List<Customer> customers, String messageTemplate) async {
    Map<String, bool> results = {};

    for (var customer in customers) {
      if (customer.phone.isEmpty) {
        results[customer.id ?? 'unknown'] = false;
        continue;
      }

      // Kişiselleştirilmiş mesaj hazırla
      final personalizedMessage = messageTemplate
          .replaceAll('{AD}', customer.name)
          .replaceAll('{SOYAD}', customer.surname)
          .replaceAll('{TAM_AD}', '${customer.name} ${customer.surname}');

      // SMS gönder
      try {
        final success = await sendTestSms(customer.phone, personalizedMessage);
        results[customer.id ?? 'unknown'] = success;

        // SMS arasında biraz bekle (hız sınırlarına takılmamak için)
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        _logService.logError('SmsService', 'SMS gönderilirken hata: $e', null);
        results[customer.id ?? 'unknown'] = false;
      }
    }

    return results;
  }
}
