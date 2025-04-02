import 'package:flutter/material.dart';
import 'notification_settings_screen.dart';
import 'admin/user_management_screen.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../utils/toast_helper.dart';
import 'sms_reminder_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadUserData());
  }

  Future<void> _loadUserData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      _currentUser = await _userService.getCurrentUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Kullanıcı bilgileri yüklenirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _userService.signOut();

        // Ana sayfaya yönlendir (login ekranına)
        if (!mounted) return;

        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılırken hata oluştu: $e')),
        );

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (_currentUser != null && _currentUser!.isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Yönetici Paneli',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Kullanıcı Yönetimi'),
                    subtitle:
                        const Text('Kullanıcıları ekle, düzenle ve yönet'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Genel Ayarlar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Bildirim Ayarları'),
                  subtitle: const Text('Ödeme hatırlatıcılarını yönetin'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Uygulama Hakkında'),
                  subtitle: const Text('Versiyon 1.0.0'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Müşteri Yönetimi',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2023 Tüm Hakları Saklıdır',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sms),
                  title: const Text('SMS Hatırlatmaları'),
                  subtitle: const Text('Ödeme hatırlatma mesajları ayarları'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SmsReminderSettingsScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Hesap',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_currentUser != null)
                  ListTile(
                    leading: CircleAvatar(
                      child: Text(_currentUser!.name.isNotEmpty
                          ? _currentUser!.name[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(_currentUser!.name),
                    subtitle: Text(_currentUser!.email),
                  ),
                if (_currentUser?.role == UserRole.admin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Admin Hesabı Oluştur/Kontrol Et'),
                    subtitle: const Text(
                        'Varsayılan admin hesabını oluşturur veya kontrol eder'),
                    onTap: () async {
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        await _userService.ensureAdminExists();
                        setState(() {
                          _isLoading = false;
                        });
                        ToastHelper.showSuccessToast(
                            context, 'Admin hesabı kontrol edildi');
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                        ToastHelper.showErrorToast(
                            context, 'İşlem sırasında hata: $e');
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Çıkış Yap',
                      style: TextStyle(color: Colors.red)),
                  onTap: _logout,
                ),
              ],
            ),
    );
  }
}
