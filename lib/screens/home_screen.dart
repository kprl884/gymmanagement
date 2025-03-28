import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/theme_service.dart';
import 'customer_list_screen.dart';
import 'equipment_list_screen.dart';
import 'fitness_plan_list_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'admin/user_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserService _userService = UserService();
  AppUser? _currentUser;
  bool _isLoading = true;
  int _selectedIndex = 0;

  // Admin için ekranlar
  final List<Widget> adminScreens = [
    const CustomerListScreen(), // Müşteriler
    const StatisticsScreen(), // İstatistikler
    const UserManagementScreen(), // Kullanıcı Yönetimi
    const SettingsScreen(), // Ayarlar
  ];

  // Normal kullanıcı için ekranlar
  final List<Widget> userScreens = [
    const EquipmentListScreen(), // Ekipmanlar
    const FitnessPlanListScreen(), // Fitness Planları
    const SettingsScreen(), // Ayarlar
  ];

  // Admin için navigasyon öğeleri
  final List<BottomNavigationBarItem> adminNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Müşteriler',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart),
      label: 'İstatistikler',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.admin_panel_settings),
      label: 'Kullanıcılar',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Ayarlar',
    ),
  ];

  // Normal kullanıcı için navigasyon öğeleri
  final List<BottomNavigationBarItem> userNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center),
      label: 'Ekipmanlar',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.directions_run),
      label: 'Fitness Planları',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Ayarlar',
    ),
  ];

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
        _currentUser = userData;
        _isLoading = false;
      });

      // Kullanıcı admin ise, admin hesabının varlığını kontrol et
      if (_currentUser?.role == UserRole.admin) {
        await _userService.ensureAdminExists();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı bilgileri yüklenirken hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading
            ? 'Yükleniyor...'
            : _currentUser?.role == UserRole.admin
                ? 'Spor Salonu Yönetimi (Admin)'
                : 'Spor Salonu'),
        actions: [
          IconButton(
            icon: Icon(
                themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              themeService.toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await _userService.signOut();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser?.role == UserRole.admin
              ? adminScreens[_selectedIndex]
              : userScreens[_selectedIndex],
      bottomNavigationBar: _isLoading
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: _currentUser?.role == UserRole.admin
                  ? adminNavItems
                  : userNavItems,
              type: BottomNavigationBarType.fixed,
            ),
    );
  }
}
