import 'package:flutter/material.dart';
import 'customer_list_screen.dart';
import 'statistics_screen.dart';
import 'add_customer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  final List<Widget> _screens = [
    const CustomerListScreen(),
    const StatisticsScreen(),
  ];

  Future<void> _onItemTapped(int index) async {
    if (_selectedIndex == index) return;

    setState(() {
      _isLoading = true;
    });

    // Kısa bir yükleme göstergesi için bekleme
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _selectedIndex = index;
      _isLoading = false;
    });
  }

  void _addNewCustomer() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Müşteriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'İstatistikler',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewCustomer,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
