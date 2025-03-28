import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/customer.dart';
import 'log_service.dart';
import 'dart:async';
import 'dart:math';
import '../services/customer_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final LogService _logService = LogService();
  final CustomerService _customerService = CustomerService();

  final BehaviorSubject<String?> onNotificationClick = BehaviorSubject();

  // Bildirim kanalları
  static const String paymentChannelId = 'payment_channel';
  static const String paymentChannelName = 'Ödeme Bildirimleri';
  static const String paymentChannelDescription =
      'Yaklaşan ödemeler için bildirimler';

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    // Bildirim kanallarını oluştur (Android 8.0+)
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel paymentChannel =
        AndroidNotificationChannel(
      paymentChannelId,
      paymentChannelName,
      description: paymentChannelDescription,
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(paymentChannel);
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    if (payload != null) {
      onNotificationClick.add(payload);
    }
  }

  void onDidReceiveNotificationResponse(NotificationResponse response) {
    if (response.payload != null) {
      onNotificationClick.add(response.payload);
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gym_management_channel',
            'Spor Salonu Bildirimleri',
            channelDescription: 'Spor salonu ile ilgili bildirimler',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      _logService.logInfo(
        'NotificationService',
        'Bildirim planlandı: ID=$id, Tarih=${scheduledDate.toString()}',
      );
    } catch (e) {
      _logService.logError(
        'NotificationService',
        'Bildirim planlanırken hata: $e',
        null,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  // Müşteri için ödeme hatırlatması gönder
  Future<void> schedulePaymentReminder(
      Customer customer, String monthKey) async {
    try {
      final int notificationId = Random().nextInt(100000);
      final String title = 'Yaklaşan Ödeme Hatırlatması';
      final String body =
          '${customer.name} için $monthKey ödemesi 3 gün içinde yapılmalıdır.';

      // Bildirim detayları
      final Map<String, dynamic> payload = {
        'type': 'payment_reminder',
        'customerId': customer.id,
        'month': monthKey,
      };

      // 3 gün önceden hatırlat
      final DateTime now = DateTime.now();
      final DateTime reminderDate = DateTime(
        now.year,
        now.month,
        now.day,
        9, // Sabah 9'da bildirim gönder
        0,
      ).add(const Duration(days: 1)); // Test için 1 gün sonra

      await showNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: reminderDate,
        payload: payload.toString(),
      );

      _logService.logInfo(
        'NotificationService',
        'Ödeme hatırlatması planlandı: ${customer.name} için $monthKey',
      );
    } catch (e) {
      _logService.logError(
        'NotificationService',
        'Ödeme hatırlatması planlanırken hata: $e',
        null,
      );
    }
  }

  // Ödeme hatırlatıcılarını planla
  Future<void> scheduleAllPaymentReminders(List<Customer> customers) async {
    try {
      final now = DateTime.now();
      final currentMonthKey = DateFormat('MM-yyyy').format(now);

      for (final customer in customers) {
        // Taksitli ödeme yapan müşteriler için
        if (customer.paymentType == PaymentType.installment) {
          // Ödenmemiş aylar için hatırlatma gönder
          if (customer.paidMonths.length < customer.subscriptionMonths) {
            await schedulePaymentReminder(customer, currentMonthKey);
          }
        }
      }
    } catch (e) {
      _logService.logError('NotificationService',
          'Ödeme hatırlatıcıları planlanırken hata: $e', null);
    }
  }

  // Üyelik hatırlatıcılarını planla
  Future<void> scheduleAllMembershipReminders() async {
    try {
      final customers = await _customerService.getActiveCustomers();
      final now = DateTime.now();
      final currentMonthKey = DateFormat('MM-yyyy').format(now);

      for (final customer in customers) {
        // Üyelik süresi dolmamış müşteriler için hatırlatma gönder
        if (customer.status == MembershipStatus.active) {
          await schedulePaymentReminder(customer, currentMonthKey);
        }
      }
    } catch (e) {
      _logService.logError('NotificationService',
          'Üyelik hatırlatıcıları planlanırken hata: $e', null);
    }
  }

  // Zamanlanmış bildirimleri kaydet
  Future<void> _saveScheduledNotification(
      int id, String notificationId, tz.TZDateTime scheduledDate) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduledNotifications =
        prefs.getStringList('scheduled_notifications') ?? [];

    final notificationData = {
      'id': id,
      'notificationId': notificationId,
      'scheduledDate': scheduledDate.millisecondsSinceEpoch,
    };

    scheduledNotifications.add(jsonEncode(notificationData));
    await prefs.setStringList(
        'scheduled_notifications', scheduledNotifications);
  }

  // Belirli bir müşteri için bildirimleri iptal et
  Future<void> cancelCustomerNotifications(String customerId) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduledNotifications =
        prefs.getStringList('scheduled_notifications') ?? [];

    final updatedNotifications = <String>[];
    final cancelIds = <int>[];

    for (final notification in scheduledNotifications) {
      final data = jsonDecode(notification);
      final notificationId = data['notificationId'] as String;

      if (notificationId.startsWith('${customerId}_')) {
        cancelIds.add(data['id'] as int);
      } else {
        updatedNotifications.add(notification);
      }
    }

    // Bildirimleri iptal et
    for (final id in cancelIds) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }

    // Güncellenmiş listeyi kaydet
    await prefs.setStringList('scheduled_notifications', updatedNotifications);
  }

  // Bildirim izinlerini kontrol et
  Future<bool> checkNotificationPermissions() async {
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final iosPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    bool permissionsGranted = false;

    if (androidPlugin != null) {
      permissionsGranted =
          await androidPlugin.areNotificationsEnabled() ?? false;
    }

    if (iosPlugin != null) {
      permissionsGranted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return permissionsGranted;
  }

  // Bildirim izinlerini iste
  Future<void> requestNotificationPermissions() async {
    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final iosPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestPermission();
    }

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
}
