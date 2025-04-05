import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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

  // Grafik verileri
  List<FlSpot> _customerSpots = [];
  double _maxY = 10; // Varsayılan değer

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

      // Toplam gelir hesaplama
      _calculateTotalRevenue();

      // Aylık müşteri dağılımını hesapla
      _calculateMonthlyCustomers();

      // Grafik verilerini hazırla
      _prepareChartData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('İstatistikler yüklenirken hata: $e');
    }
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

  // Aylık müşteri dağılımını hesapla
  void _calculateMonthlyCustomers() async {
    try {
      final customers = await _customerService.getAllCustomers();
      final Map<String, int> monthlyData = {};

      // Son 6 ayı hesapla
      final now = DateTime.now();
      for (int i = 0; i < 6; i++) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthKey = DateFormat('MMMM yyyy', 'tr_TR').format(month);
        monthlyData[monthKey] = 0;
      }

      // Her müşteri için kayıt ayını bul ve sayıyı artır
      for (var customer in customers) {
        final registrationMonth = DateTime(
          customer.registrationDate.year,
          customer.registrationDate.month,
          1,
        );
        final monthKey =
        DateFormat('MMMM yyyy', 'tr_TR').format(registrationMonth);

        if (monthlyData.containsKey(monthKey)) {
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
        }
      }

      setState(() {
        _monthlyCustomers = monthlyData;
      });
    } catch (e) {
      print('Aylık müşteri dağılımı hesaplama hatası: $e');
    }
  }

  // Grafik verilerini hazırla
  void _prepareChartData() {
    _customerSpots = [];

    // Son 6 ayı al ve sırala
    final sortedMonths = _monthlyCustomers.entries.toList()
      ..sort((a, b) {
        final aDate = DateFormat('MMMM yyyy', 'tr_TR').parse(a.key);
        final bDate = DateFormat('MMMM yyyy', 'tr_TR').parse(b.key);
        return aDate.compareTo(bDate);
      });

    // Grafik için x ve y değerlerini hazırla
    for (int i = 0; i < sortedMonths.length; i++) {
      _customerSpots
          .add(FlSpot(i.toDouble(), sortedMonths[i].value.toDouble()));
    }

    // Maksimum y değerini bul (grafik yüksekliği için)
    if (_customerSpots.isNotEmpty) {
      _maxY =
          _customerSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      _maxY = (_maxY * 1.2).ceilToDouble(); // %20 marj ekle
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Genel bakış kartı
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
                      NumberFormat.currency(locale: 'tr_TR', symbol: '₺')
                          .format(_totalRevenue),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Müşteri Grafiği Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aylık Müşteri Grafiği',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 250, // Daha fazla alan ayır
                      child: _customerSpots.isEmpty
                          ? const Center(child: Text('Veri yok'))
                          : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40, // Yüksekliği artır
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() <
                                          _monthlyCustomers
                                              .length) {
                                    final monthNames = _monthlyCustomers
                                        .keys
                                        .toList();
                                    // Doğru sıralama için indeksleri kontrol et
                                    if (value.toInt() < monthNames.length) {
                                      final month = monthNames[value.toInt()];
                                      final shortMonth = month.split(' ')[0].substring(0, 3);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          shortMonth, // Ay adının kısaltması
                                          style: const TextStyle(
                                            fontSize: 10,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                        fontSize: 10),
                                  );
                                },
                                reservedSize: 30,
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles:
                              SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles:
                              SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          minX: 0,
                          maxX: (_customerSpots.length - 1)
                              .toDouble(),
                          minY: 0,
                          maxY: _maxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _customerSpots,
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Aylık müşteri dağılımı kartı
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

            const SizedBox(height: 16),

            // Üyelik Durumu Pasta Grafiği
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Üyelik Durumu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 250, // Yüksekliği artır
                      child: _totalCustomers == 0
                          ? const Center(child: Text('Veri yok'))
                          : PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: _activeCustomers.toDouble(),
                              title: 'Aktif\n${_activeCustomers}',
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              color: Colors.green,
                              radius: 80,
                            ),
                            PieChartSectionData(
                              value: _expiredCustomers.toDouble(),
                              title: 'Sona\nEren\n${_expiredCustomers}',
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              color: Colors.red,
                              radius: 80,
                            ),
                            PieChartSectionData(
                              value: (_totalCustomers -
                                  _activeCustomers -
                                  _expiredCustomers)
                                  .toDouble(),
                              title: 'Diğer\n${_totalCustomers - _activeCustomers - _expiredCustomers}',
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              color: Colors.grey,
                              radius: 80,
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 40, // Orta boşluğu artır
                        ),
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
}