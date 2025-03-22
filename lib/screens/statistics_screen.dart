import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import 'customer_list_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  int _totalCustomers = 0;
  int _cashCustomers = 0;
  int _installmentCustomers = 0;
  int _newCustomersThisMonth = 0;
  double _totalRevenue = 0;
  Map<String, int> _monthlyCustomers = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tüm müşterileri getir
      final snapshot =
          await FirebaseFirestore.instance.collection('customers').get();

      final customers =
          snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();

      // Toplam müşteri sayısı
      _totalCustomers = customers.length;

      // Peşin ve taksitli müşteri sayıları
      _cashCustomers = customers.where((c) => !c.isInstallment).length;
      _installmentCustomers = customers.where((c) => c.isInstallment).length;

      // Bu ayki yeni müşteriler
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month);
      _newCustomersThisMonth =
          customers.where((c) => c.registrationDate.isAfter(thisMonth)).length;

      // Toplam gelir (üyelik süresi * aylık ücret olarak varsayalım)
      // Gerçek uygulamada ücret bilgisi de eklenebilir
      const monthlyFee = 200.0; // Örnek aylık ücret
      _totalRevenue = customers.fold(0,
          (sum, customer) => sum + (customer.membershipDuration * monthlyFee));

      // Aylara göre müşteri dağılımı
      _monthlyCustomers = {};
      for (var customer in customers) {
        final month = DateFormat('MMMM yyyy').format(customer.registrationDate);
        _monthlyCustomers[month] = (_monthlyCustomers[month] ?? 0) + 1;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İstatistikler yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _navigateToScreen(Widget screen) async {
    setState(() {
      _isLoading = true;
    });

    // Kısa bir yükleme göstergesi için bekleme
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildCustomerDistribution(),
                  const SizedBox(height: 24),
                  _buildMonthlyCustomers(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genel Bakış',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              'Toplam Müşteri',
              _totalCustomers.toString(),
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Bu Ay Yeni',
              _newCustomersThisMonth.toString(),
              Icons.person_add,
              Colors.green,
            ),
            _buildStatCard(
              'Toplam Gelir',
              '${_totalRevenue.toStringAsFixed(0)} ₺',
              Icons.attach_money,
              Colors.amber,
            ),
            _buildStatCard(
              'Ortalama Üyelik',
              _totalCustomers > 0
                  ? '${(_totalRevenue / _totalCustomers / 200).toStringAsFixed(1)} ay'
                  : '0 ay',
              Icons.calendar_month,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ödeme Tipi Dağılımı',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: _cashCustomers,
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.horizontal(
                            left: const Radius.circular(15),
                            right: _installmentCustomers == 0
                                ? const Radius.circular(15)
                                : Radius.zero,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: _installmentCustomers,
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.horizontal(
                            left: _cashCustomers == 0
                                ? const Radius.circular(15)
                                : Radius.zero,
                            right: const Radius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(
                      'Peşin',
                      _cashCustomers,
                      Colors.green,
                      _totalCustomers,
                    ),
                    _buildLegendItem(
                      'Taksitli',
                      _installmentCustomers,
                      Colors.orange,
                      _totalCustomers,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int value, Color color, int total) {
    final percentage =
        total > 0 ? (value / total * 100).toStringAsFixed(1) : '0';
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $value (%$percentage)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMonthlyCustomers() {
    // Ayları kronolojik sıraya dizelim
    final sortedMonths = _monthlyCustomers.entries.toList()
      ..sort((a, b) => DateFormat('MMMM yyyy')
          .parse(a.key)
          .compareTo(DateFormat('MMMM yyyy').parse(b.key)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aylık Müşteri Dağılımı',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: sortedMonths.map((entry) {
                final month = entry.key;
                final count = entry.value;
                final percentage = _totalCustomers > 0
                    ? (count / _totalCustomers * 100).toStringAsFixed(1)
                    : '0';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$month: $count müşteri (%$percentage)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value:
                            _totalCustomers > 0 ? count / _totalCustomers : 0,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          HSLColor.fromAHSL(
                            1.0,
                            (sortedMonths.indexOf(entry) * 137.5) % 360,
                            0.7,
                            0.5,
                          ).toColor(),
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Erişim',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Müşteri Listesi',
                Icons.people,
                Colors.blue,
                () => _navigateToScreen(const CustomerListScreen()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Ödeme Takibi',
                Icons.payment,
                Colors.green,
                () => _navigateToScreen(const PaymentTrackingScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Raporlar',
                Icons.bar_chart,
                Colors.purple,
                () => _navigateToScreen(const ReportsScreen()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                'Ayarlar',
                Icons.settings,
                Colors.grey,
                () => _navigateToScreen(const SettingsScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(title),
        ],
      ),
    );
  }
}

// Henüz oluşturulmamış ekranlar için geçici sınıflar
class PaymentTrackingScreen extends StatelessWidget {
  const PaymentTrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Takibi'),
      ),
      body: const Center(
        child: Text('Ödeme takip ekranı geliştirme aşamasında'),
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
      ),
      body: const Center(
        child: Text('Raporlar ekranı geliştirme aşamasında'),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: const Center(
        child: Text('Ayarlar ekranı geliştirme aşamasında'),
      ),
    );
  }
}
