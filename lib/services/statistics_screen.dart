import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../widgets/common_widgets.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final CustomerService _customerService = CustomerService();

  bool _isLoading = true;
  int _totalCustomers = 0;
  int _activeCustomers = 0;
  int _expiredCustomers = 0;
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
      final customers = await _customerService.getAllCustomers();

      // Toplam müşteri sayısı
      _totalCustomers = customers.length;

      // Aktif ve süresi dolmuş müşteri sayıları
      _activeCustomers =
          customers.where((c) => c.status == MembershipStatus.active).length;
      _expiredCustomers =
          customers.where((c) => c.status == MembershipStatus.expired).length;

      // Bu ayki yeni müşteriler
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      _newCustomersThisMonth = customers
          .where((c) => c.registrationDate.isAfter(firstDayOfMonth))
          .length;

      // Toplam gelir (aylık ücret x üyelik süresi)
      const monthlyFee = 200.0; // Örnek aylık ücret
      _totalRevenue = 0;
      for (var customer in customers) {
        if (customer.membershipStartDate != null &&
            customer.membershipEndDate != null) {
          // Ay farkını hesapla
          final months = (customer.membershipEndDate!.year -
                      customer.membershipStartDate!.year) *
                  12 +
              customer.membershipEndDate!.month -
              customer.membershipStartDate!.month;
          _totalRevenue += months * monthlyFee;
        }
      }

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
        SnackBar(content: Text('İstatistikler yüklenirken hata: $e')),
      );
    }
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
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Özet kartı
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Genel Bakış',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            _buildStatRow(
                                'Toplam Müşteri', _totalCustomers.toString()),
                            _buildStatRow(
                                'Aktif Üyelikler', _activeCustomers.toString()),
                            _buildStatRow('Süresi Dolmuş Üyelikler',
                                _expiredCustomers.toString()),
                            _buildStatRow('Bu Ay Yeni Kayıtlar',
                                _newCustomersThisMonth.toString()),
                            _buildStatRow(
                              'Toplam Gelir',
                              NumberFormat.currency(
                                      locale: 'tr_TR', symbol: '₺')
                                  .format(_totalRevenue),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Aylık müşteri dağılımı
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Aylık Müşteri Dağılımı',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            ..._monthlyCustomers.entries
                                .toList()
                                .reversed // En son aydan başla
                                .map((entry) => _buildStatRow(
                                    entry.key, entry.value.toString()))
                                .toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value) {
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
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Toplam geliri hesapla
  void _calculateTotalRevenue() async {
    try {
      final customers = await _customerService.getAllCustomers();
      final monthlyFee = 200; // Aylık ücret (örnek değer)

      setState(() {
        _totalRevenue = 0;
        for (var customer in customers) {
          // Abonelik süresine göre geliri hesapla
          _totalRevenue += customer.subscriptionMonths * monthlyFee;
        }
      });
    } catch (e) {
      print('Gelir hesaplama hatası: $e');
    }
  }
}
