import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/toast_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  AppUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userData = await _userService.getCurrentUserData();
      setState(() {
        _user = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı bilgileri yüklenirken hata: $e')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_user == null) return;

    final nameController = TextEditingController(text: _user!.name);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Bilgilerini Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text,
              });
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final name = result['name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          // Here's the fix: We need to use the non-nullable name variable
          // Since we've checked it's not null above, we can safely use the non-null version
          final success = await _userService.updateUserName(_user!.id!, name!);

          if (success) {
            await _loadUserData();
            ToastHelper.showSuccessToast(
                context, 'Profil bilgileri güncellendi');
          } else {
            setState(() {
              _isLoading = false;
            });
            ToastHelper.showErrorToast(context, 'Güncelleme başarısız oldu');
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          ToastHelper.showErrorToast(context, 'İsim boş olamaz');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ToastHelper.showErrorToast(context, 'Güncelleme başarısız oldu: $e');
      }
    }
  }

  Future<void> _changePassword() async {
    final emailController = TextEditingController(text: _user?.email);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Sıfırlama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Şifre sıfırlama bağlantısı aşağıdaki e-posta adresine gönderilecektir:'),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'E-posta'),
              readOnly: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );

    if (result == true && _user?.email != null) {
      try {
        await _userService.sendPasswordResetEmail(_user!.email);
        ToastHelper.showSuccessToast(
            context, 'Şifre sıfırlama bağlantısı gönderildi');
      } catch (e) {
        ToastHelper.showErrorToast(
            context, 'Şifre sıfırlama bağlantısı gönderilemedi: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Kullanıcı bilgileri yüklenemedi'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profil kartı
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      _user!.name.isNotEmpty
                                          ? _user!.name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _user!.name,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _user!.email,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Üyelik: ${_formatDate(_user!.createdAt)}',
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _updateProfile,
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Düzenle'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _changePassword,
                                    icon: const Icon(Icons.lock),
                                    label: const Text('Şifre Değiştir'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Hesap bilgileri
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hesap Bilgileri',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              _buildInfoRow(
                                  'Kullanıcı Tipi',
                                  _user!.role == UserRole.admin
                                      ? 'Admin'
                                      : 'Üye'),
                              _buildInfoRow('Hesap Durumu', 'Aktif'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
