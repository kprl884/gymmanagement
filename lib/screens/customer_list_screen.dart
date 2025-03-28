import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import 'customer_detail_screen.dart';
import 'add_customer_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  _CustomerListScreenState createState() => _CustomerListScreenState();
}

enum SortOption {
  nameAsc,
  nameDesc,
  paymentDateAsc,
  paymentDateDesc,
  installmentsAsc,
  installmentsDesc,
  paymentTypeAsc,
  paymentTypeDesc,
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  SortOption _currentSortOption = SortOption.nameAsc;

  @override
  void initState() {
    super.initState();
    // Sayfa açılır açılmaz boş liste göster, sonra verileri yükle
    _customers = [];
    _filteredCustomers = [];
    _isLoading = false; // Başlangıçta loading gösterme

    // Hafif gecikme ile yüklemeyi başlat
    Future.delayed(Duration.zero, () {
      _loadCustomers();
    });
  }

  Future<void> _loadCustomers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final customers = await _customerService.getAllCustomers();
      if (mounted) {
        setState(() {
          _customers = customers;
          _applyFiltersAndSort();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Müşteriler yüklenirken hata: $e')),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    // Önce filtreleme yap
    _filteredCustomers = _customers.where((customer) {
      final name = '${customer.name} ${customer.surname}'.toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    // Sonra sıralama yap
    switch (_currentSortOption) {
      case SortOption.nameAsc:
        _filteredCustomers.sort((a, b) =>
            '${a.name} ${a.surname}'.compareTo('${b.name} ${b.surname}'));
        break;
      case SortOption.nameDesc:
        _filteredCustomers.sort((a, b) =>
            '${b.name} ${b.surname}'.compareTo('${a.name} ${a.surname}'));
        break;
      case SortOption.paymentDateAsc:
        _filteredCustomers.sort((a, b) {
          // Ödeme tarihi yaklaşan önce
          final now = DateTime.now();
          final aNextPayment = _calculateNextPaymentDate(a);
          final bNextPayment = _calculateNextPaymentDate(b);

          if (aNextPayment == null && bNextPayment == null) return 0;
          if (aNextPayment == null) return 1;
          if (bNextPayment == null) return -1;

          return aNextPayment
              .difference(now)
              .inDays
              .compareTo(bNextPayment.difference(now).inDays);
        });
        break;
      case SortOption.paymentDateDesc:
        _filteredCustomers.sort((a, b) {
          // Ödeme tarihi uzak olan önce
          final now = DateTime.now();
          final aNextPayment = _calculateNextPaymentDate(a);
          final bNextPayment = _calculateNextPaymentDate(b);

          if (aNextPayment == null && bNextPayment == null) return 0;
          if (aNextPayment == null) return 1;
          if (bNextPayment == null) return -1;

          return bNextPayment
              .difference(now)
              .inDays
              .compareTo(aNextPayment.difference(now).inDays);
        });
        break;
      case SortOption.installmentsAsc:
        _filteredCustomers.sort(
            (a, b) => a.subscriptionMonths.compareTo(b.subscriptionMonths));
        break;
      case SortOption.installmentsDesc:
        _filteredCustomers.sort(
            (a, b) => b.subscriptionMonths.compareTo(a.subscriptionMonths));
        break;
      case SortOption.paymentTypeAsc:
        _filteredCustomers
            .sort((a, b) => a.paymentType.index.compareTo(b.paymentType.index));
        break;
      case SortOption.paymentTypeDesc:
        _filteredCustomers
            .sort((a, b) => b.paymentType.index.compareTo(a.paymentType.index));
        break;
    }
  }

  DateTime? _calculateNextPaymentDate(Customer customer) {
    if (customer.paymentType == PaymentType.cash) {
      // Peşin ödemede ödeme tarihi yok
      return null;
    }

    if (customer.paidMonths.length >= customer.subscriptionMonths) {
      // Tüm taksitler ödenmişse ödeme tarihi yok
      return null;
    }

    // Kayıt tarihinden itibaren ödenmemiş ilk ayı bul
    final registrationDate = customer.registrationDate;
    for (int i = 0; i < customer.subscriptionMonths; i++) {
      final paymentDate = DateTime(
        registrationDate.year,
        registrationDate.month + i,
        registrationDate.day,
      );

      // Bu ay ödendi mi kontrol et
      bool isPaid = customer.paidMonths.any((paidMonth) =>
          paidMonth.year == paymentDate.year &&
          paidMonth.month == paymentDate.month);

      if (!isPaid) {
        return paymentDate;
      }
    }

    return null;
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFiltersAndSort();
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('İsme Göre (A-Z)'),
                leading: const Icon(Icons.sort_by_alpha),
                selected: _currentSortOption == SortOption.nameAsc,
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.nameAsc;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('İsme Göre (Z-A)'),
                leading: const Icon(Icons.sort_by_alpha),
                selected: _currentSortOption == SortOption.nameDesc,
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.nameDesc;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Ödeme Tarihi (Yaklaşan Önce)'),
                leading: const Icon(Icons.calendar_today),
                selected: _currentSortOption == SortOption.paymentDateAsc,
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.paymentDateAsc;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Ödeme Tarihi (Uzak Önce)'),
                leading: const Icon(Icons.calendar_today),
                selected: _currentSortOption == SortOption.paymentDateDesc,
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.paymentDateDesc;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Taksit Sayısı (Az-Çok)'),
                leading: const Icon(Icons.money),
                selected: _currentSortOption == SortOption.installmentsAsc,
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.installmentsAsc;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Taksit Sayısı (Çok-Az)'),
                leading: const Icon(Icons.money),
                selected: _currentSortOption == SortOption.installmentsDesc,
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.installmentsDesc;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Ödeme Tipi (Peşin-Taksit)'),
                leading: const Icon(Icons.payment),
                selected: _currentSortOption == SortOption.paymentTypeAsc,
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.paymentTypeAsc;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Ödeme Tipi (Taksit-Peşin)'),
                leading: const Icon(Icons.payment),
                selected: _currentSortOption == SortOption.paymentTypeDesc,
                onTap: () {
                  setState(() {
                    _currentSortOption = SortOption.paymentTypeDesc;
                    _applyFiltersAndSort();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteriler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sırala',
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama çubuğu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Müşteri Ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _onSearch,
            ),
          ),

          // Sıralama bilgisi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Sıralama: ${_getSortOptionText()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredCustomers.length} müşteri',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Müşteri listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? const Center(
                        child: Text('Müşteri bulunamadı'),
                      )
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            color: _getCustomerCardColor(customer),
                            child: ListTile(
                              title: Text(
                                '${customer.name} ${customer.surname}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tel: ${customer.phone}'),
                                  Row(
                                    children: [
                                      Text(
                                        'Ödeme: ${customer.paymentType == PaymentType.cash ? 'Peşin' : 'Taksitli'}',
                                      ),
                                      const SizedBox(width: 10),
                                      if (customer.paymentType ==
                                          PaymentType.installment)
                                        Text(
                                          'Ödenen: ${customer.paidMonths.length}/${customer.subscriptionMonths}',
                                        ),
                                    ],
                                  ),
                                  if (_calculateNextPaymentDate(customer) !=
                                      null)
                                    Text(
                                      'Sonraki Ödeme: ${DateFormat('dd.MM.yyyy').format(_calculateNextPaymentDate(customer)!)}',
                                      style: TextStyle(
                                        color: _isPaymentSoon(customer)
                                            ? Colors.red
                                            : null,
                                        fontWeight: _isPaymentSoon(customer)
                                            ? FontWeight.bold
                                            : null,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                _showCustomerDetails(customer);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddCustomerScreen(),
            ),
          );

          // Eğer yeni müşteri eklendiyse listeyi yenile
          if (result == true) {
            _loadCustomers();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getSortOptionText() {
    switch (_currentSortOption) {
      case SortOption.nameAsc:
        return 'İsim (A-Z)';
      case SortOption.nameDesc:
        return 'İsim (Z-A)';
      case SortOption.paymentDateAsc:
        return 'Ödeme (Yakın)';
      case SortOption.paymentDateDesc:
        return 'Ödeme (Uzak)';
      case SortOption.installmentsAsc:
        return 'Taksit (Az-Çok)';
      case SortOption.installmentsDesc:
        return 'Taksit (Çok-Az)';
      case SortOption.paymentTypeAsc:
        return 'Ödeme (Peşin-Taksit)';
      case SortOption.paymentTypeDesc:
        return 'Ödeme (Taksit-Peşin)';
    }
  }

  bool _isPaymentSoon(Customer customer) {
    final nextPayment = _calculateNextPaymentDate(customer);
    if (nextPayment == null) return false;

    final now = DateTime.now();
    final difference = nextPayment.difference(now).inDays;
    return difference <= 7 && difference >= 0; // 7 gün veya daha az kaldıysa
  }

  Color _getCustomerCardColor(Customer customer) {
    if (customer.status == MembershipStatus.expired) {
      return Colors.red[100]!;
    }

    if (customer.paymentType == PaymentType.installment) {
      bool allMonthsPaid =
          customer.paidMonths.length >= customer.subscriptionMonths;
      if (allMonthsPaid) {
        return Colors.green[100]!;
      } else {
        return Colors.orange[100]!;
      }
    }

    return Colors.green[100]!; // Peşin ödemede hep yeşil
  }

  void _createDummyCustomer() async {
    final customer = Customer(
      name: 'Test',
      surname: 'Müşteri',
      phone: '5551234567',
      email: 'test@example.com',
      age: 30,
      registrationDate: DateTime.now(),
      subscriptionMonths: 3,
      paymentType: PaymentType.cash,
      paidMonths: [],
      status: MembershipStatus.active,
    );

    await _customerService.addCustomer(customer);
    _loadCustomers();
  }

  Future<void> _showCustomerDetails(Customer customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailScreen(customer: customer),
      ),
    );

    // Eğer müşteri silindiyse veya güncellendiyse listeyi yenile
    if (result == true) {
      _loadCustomers();
    }
  }
}
