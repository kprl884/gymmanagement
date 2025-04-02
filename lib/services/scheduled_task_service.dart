import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'customer_service.dart';
import 'sms_service.dart';
import 'log_service.dart';

class ScheduledTaskService {
  static final ScheduledTaskService _instance =
      ScheduledTaskService._internal();
  Timer? _dailyCheckTimer;
  final CustomerService _customerService = CustomerService();
  final SmsService _smsService = SmsService();
  final LogService _logService = LogService();

  factory ScheduledTaskService() {
    return _instance;
  }

  ScheduledTaskService._internal();

  // Zamanlayıcıyı başlat
  void startScheduledTasks() {
    // Önceki zamanlayıcıyı durdur
    _stopTimers();

    // Her gün kontrol et (Sabah 9'da)
    _scheduleDailyCheck();

    _logService.logInfo('ScheduledTaskService', 'Zamanlı görevler başlatıldı');
  }

  // Zamanlayıcıları durdur
  void _stopTimers() {
    _dailyCheckTimer?.cancel();
  }

  // Günlük kontrol zamanlayıcısını ayarla
  void _scheduleDailyCheck() {
    // Bir sonraki sabah 9'u hesapla
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, 9, 0);

    // Eğer saat 9'u geçtiyse, bir sonraki güne ayarla
    if (now.isAfter(nextRun)) {
      nextRun = nextRun.add(Duration(days: 1));
    }

    // İlk çalışma için beklenecek süre
    final initialDelay = nextRun.difference(now);

    // Zamanlayıcıyı başlat
    _dailyCheckTimer = Timer(initialDelay, () {
      // İlk çalıştırma
      _runDailyChecks();

      // Sonraki her 24 saatte bir
      _dailyCheckTimer = Timer.periodic(Duration(hours: 24), (timer) {
        _runDailyChecks();
      });
    });

    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');
    _logService.logInfo('ScheduledTaskService',
        'Bir sonraki günlük kontrol: ${dateFormatter.format(nextRun)}');
  }

  // Günlük kontrolleri çalıştır
  Future<void> _runDailyChecks() async {
    try {
      _logService.logInfo(
          'ScheduledTaskService', 'Günlük kontroller çalışıyor...');

      // Son çalışma zamanını kaydet
      _saveLastRunTime();

      // Tüm müşterileri al
      final customers = await _customerService.getAllCustomers();

      // SMS ile ödemeleri kontrol et (implement a new method here)
      for (var customer in customers) {
        if (customer.isActive) {
          await _smsService.checkCustomerSmsPayment(customer);
        }
      }

      _logService.logInfo(
          'ScheduledTaskService', 'Günlük kontroller tamamlandı');
    } catch (e) {
      _logService.logError(
          'ScheduledTaskService', 'Günlük kontroller sırasında hata: $e', null);
    }
  }

  // Son çalışma zamanını kaydet
  Future<void> _saveLastRunTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString('last_daily_check', now.toIso8601String());
    } catch (e) {
      _logService.logError('ScheduledTaskService',
          'Son çalışma zamanı kaydedilirken hata: $e', null);
    }
  }

  // Uygulama başladığında hemen kontrol yap
  Future<void> runImmediateChecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRunStr = prefs.getString('last_daily_check');

      if (lastRunStr != null) {
        final lastRun = DateTime.parse(lastRunStr);
        final now = DateTime.now();

        // Son çalışmadan bu yana 24 saat geçtiyse
        if (now.difference(lastRun).inHours >= 24) {
          await _runDailyChecks();
        }
      } else {
        // İlk kez çalışıyorsa
        await _runDailyChecks();
      }
    } catch (e) {
      _logService.logError(
          'ScheduledTaskService', 'Anlık kontroller sırasında hata: $e', null);
    }
  }

  // Kaynakları temizle
  void dispose() {
    _stopTimers();
  }
}
