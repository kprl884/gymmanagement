import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/customer_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermissions();
  }

  Future<void> _checkNotificationPermissions() async {
    setState(() {
      _isLoading = true;
    });

    final permissionsGranted =
        await _notificationService.checkNotificationPermissions();

    setState(() {
      _notificationsEnabled = permissionsGranted;
      _isLoading = false;
    });
  }

  Future<void> _requestNotificationPermissions() async {
    setState(() {
      _isLoading = true;
    });

    await _notificationService.requestNotificationPermissions();
    await _checkNotificationPermissions();
  }

  Future<void> _updateAllNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tüm müşterileri getir
      final customers = await _customerService.getAllCustomers();

      // Tüm bildirimleri güncelle
      await _notificationService.scheduleAllPaymentReminders(customers);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bildirimler güncellendi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bildirimler güncellenirken hata: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAllNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.cancelAllNotifications();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm bildirimler iptal edildi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bildirim İzinleri',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                _notificationsEnabled
                                    ? Icons.notifications_active
                                    : Icons.notifications_off,
                                color: _notificationsEnabled
                                    ? Colors.green
                                    : Colors.red,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _notificationsEnabled
                                          ? 'Bildirimler Etkin'
                                          : 'Bildirimler Devre Dışı',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _notificationsEnabled
                                          ? 'Yaklaşan ödemeler için bildirimler alacaksınız.'
                                          : 'Bildirimleri etkinleştirmek için izin vermeniz gerekiyor.',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (!_notificationsEnabled)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _requestNotificationPermissions,
                                child: const Text('Bildirimlere İzin Ver'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Bildirim Yönetimi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ödeme Hatırlatıcıları',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Yaklaşan ödemeler için bildirimler, ödeme tarihinden 3 gün önce gönderilir.',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _notificationsEnabled
                                      ? _updateAllNotifications
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Bildirimleri Güncelle'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _notificationsEnabled
                                      ? _cancelAllNotifications
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child:
                                      const Text('Tüm Bildirimleri İptal Et'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bildirim Hakkında',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bildirimler, müşterilerinizin ödeme tarihlerini takip etmenize yardımcı olur. Ödenmemiş taksitler için otomatik hatırlatıcılar alırsınız.',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Not: Bazı cihazlarda, pil tasarrufu modu veya diğer sistem ayarları bildirimleri engelleyebilir. Bildirimlerin düzgün çalışması için cihaz ayarlarınızı kontrol edin.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
