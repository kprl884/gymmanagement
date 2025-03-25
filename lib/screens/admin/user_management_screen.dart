import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  List<AppUser> _users = [];
  AppUser? _currentUser;

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
      _currentUser = await _userService.getCurrentUserData();
      _users = await _userService.getAllUsers();

      // Kendimizi listeden çıkaralım
      if (_currentUser != null) {
        _users = _users.where((user) => user.id != _currentUser!.id).toList();
      }

      // Kullanıcıları role göre sıralayalım
      _users.sort((a, b) {
        final roleOrder = {
          UserRole.admin: 0,
          UserRole.staff: 1,
          UserRole.customer: 2,
        };

        return roleOrder[a.role]!.compareTo(roleOrder[b.role]!);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcılar yüklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Yönetici';
      case UserRole.staff:
        return 'Personel';
      case UserRole.customer:
        return 'Müşteri';
      default:
        return 'Bilinmiyor';
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.staff:
        return Colors.blue;
      case UserRole.customer:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showEditUserDialog(AppUser user) async {
    final nameController = TextEditingController(text: user.name);
    UserRole selectedRole = user.role;
    bool isActive = user.isActive;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Rol:'),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  children: UserRole.values.map((role) {
                    return RadioListTile<UserRole>(
                      title: Text(_getRoleName(role)),
                      value: role,
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => SwitchListTile(
                  title: const Text('Aktif'),
                  value: isActive,
                  onChanged: (value) {
                    setState(() {
                      isActive = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              setState(() {
                _isLoading = true;
              });

              try {
                // Kullanıcı adını güncelle
                if (nameController.text != user.name) {
                  await _userService.updateUserName(
                      user.id!, nameController.text);
                }

                // Kullanıcı rolünü güncelle
                if (selectedRole != user.role) {
                  await _userService.updateUserRole(user.id!, selectedRole);
                }

                // Kullanıcı durumunu güncelle
                if (isActive != user.isActive) {
                  await _userService.updateUserStatus(user.id!, isActive);
                }

                // Kullanıcı listesini yenile
                await _loadUsers();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kullanıcı başarıyla güncellendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kullanıcı güncellenirken hata oluştu: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddUserDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.customer;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Kullanıcı Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const Text('Rol:'),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  children: UserRole.values.map((role) {
                    return RadioListTile<UserRole>(
                      title: Text(_getRoleName(role)),
                      value: role,
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              // Basit doğrulama
              if (nameController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen tüm alanları doldurun'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              setState(() {
                _isLoading = true;
              });

              try {
                await _userService.registerWithEmailAndPassword(
                  emailController.text.trim(),
                  passwordController.text,
                  nameController.text.trim(),
                  selectedRole,
                );

                // Kullanıcı listesini yenile
                await _loadUsers();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kullanıcı başarıyla eklendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                String errorMessage = 'Kullanıcı eklenirken hata oluştu';

                if (e.toString().contains('email-already-in-use')) {
                  errorMessage = 'Bu e-posta adresi zaten kullanılıyor';
                } else if (e.toString().contains('invalid-email')) {
                  errorMessage = 'Geçersiz e-posta adresi';
                } else if (e.toString().contains('weak-password')) {
                  errorMessage = 'Şifre çok zayıf';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPassword(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Sıfırlama'),
        content: Text(
            '${user.name} kullanıcısının şifresini sıfırlamak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _userService.sendPasswordResetEmail(user.email);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre sıfırlama bağlantısı gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şifre sıfırlanırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
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
          : _users.isEmpty
              ? const Center(child: Text('Henüz kullanıcı bulunmamaktadır'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(user.role),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(user.role),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getRoleName(user.role),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: user.isActive
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.isActive ? 'Aktif' : 'Pasif',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Düzenle'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'reset_password',
                              child: Row(
                                children: [
                                  Icon(Icons.lock_reset),
                                  SizedBox(width: 8),
                                  Text('Şifre Sıfırla'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showEditUserDialog(user);
                            } else if (value == 'reset_password') {
                              _resetPassword(user);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
