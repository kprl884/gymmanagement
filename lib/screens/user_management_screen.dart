import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/toast_helper.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  List<AppUser> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _userService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcılar yüklenirken hata: $e')),
      );
    }
  }

  Future<void> _createAdminAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.ensureAdminExists();
      await _loadUsers(); // Kullanıcı listesini yenile
      ToastHelper.showSuccessToast(
          context, 'Admin hesabı oluşturuldu/kontrol edildi');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ToastHelper.showErrorToast(context, 'Admin hesabı oluşturulamadı: $e');
    }
  }

  Future<void> _changeUserRole(AppUser user, UserRole newRole) async {
    try {
      await _userService.updateUserRole(user.id!, newRole);
      await _loadUsers(); // Kullanıcı listesini yenile
      ToastHelper.showSuccessToast(context, 'Kullanıcı rolü güncellendi');
    } catch (e) {
      ToastHelper.showErrorToast(context, 'Rol güncellenemedi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Admin hesabı oluşturma butonu
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _createAdminAccount,
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Admin Hesabı Oluştur/Kontrol Et'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),

                // Kullanıcı listesi
                Expanded(
                  child: _users.isEmpty
                      ? const Center(child: Text('Kullanıcı bulunamadı'))
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: ListTile(
                                title: Text(user.name),
                                subtitle: Text(user.email),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Chip(
                                      label: Text(
                                        user.role == UserRole.admin
                                            ? 'Admin'
                                            : 'Kullanıcı',
                                      ),
                                      backgroundColor:
                                          user.role == UserRole.admin
                                              ? Colors.red[100]
                                              : Colors.blue[100],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {
                                        _showUserOptions(user);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showUserOptions(AppUser user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(user.name),
            subtitle: Text(user.email),
          ),
          const Divider(),
          if (user.role != UserRole.admin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Yap'),
              onTap: () {
                Navigator.pop(context);
                _changeUserRole(user, UserRole.admin);
              },
            ),
          if (user.role == UserRole.admin)
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Normal Kullanıcı Yap'),
              onTap: () {
                Navigator.pop(context);
                _changeUserRole(user, UserRole.customer);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Kullanıcıyı Sil'),
            onTap: () {
              Navigator.pop(context);
              _confirmDeleteUser(user);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcıyı Sil'),
        content: Text(
            '${user.name} kullanıcısını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userService.deleteUser(user.id!);
                await _loadUsers();
                ToastHelper.showSuccessToast(context, 'Kullanıcı silindi');
              } catch (e) {
                ToastHelper.showErrorToast(context, 'Kullanıcı silinemedi: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
