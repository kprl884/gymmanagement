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

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = CustomerService();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await _customerService.getAllCustomers();
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Müşteriler yüklenirken hata: $e')),
      );
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final fullName = customer.name.toLowerCase();
          final email = customer.email.toLowerCase();
          final phone = customer.phone?.toLowerCase() ?? '';

          return fullName.contains(_searchQuery) ||
              email.contains(_searchQuery) ||
              phone.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _refreshCustomers() async {
    await _loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müşteriler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Müşteri Ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterCustomers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? const Center(child: Text('Müşteri bulunamadı'))
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              title: Text(
                                customer.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Tel: ${customer.phone ?? 'Belirtilmemiş'}\n'
                                'Durum: ${_getStatusText(customer.status)}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (customer.membershipEndDate != null)
                                    Chip(
                                      label: Text(
                                        DateFormat('dd/MM/yyyy').format(
                                            customer.membershipEndDate!),
                                      ),
                                      backgroundColor:
                                          _getMembershipColor(customer),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CustomerDetailScreen(
                                            customer: customer,
                                          ),
                                        ),
                                      ).then((value) {
                                        if (value == true) {
                                          _refreshCustomers();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerDetailScreen(
                                      customer: customer,
                                    ),
                                  ),
                                ).then((value) {
                                  if (value == true) {
                                    _refreshCustomers();
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          ).then((value) {
            if (value == true) {
              _refreshCustomers();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getStatusText(MembershipStatus status) {
    switch (status) {
      case MembershipStatus.active:
        return 'Aktif';
      case MembershipStatus.expired:
        return 'Süresi Dolmuş';
      case MembershipStatus.pending:
        return 'Beklemede';
      case MembershipStatus.cancelled:
        return 'İptal Edilmiş';
      default:
        return 'Bilinmiyor';
    }
  }

  Color _getMembershipColor(Customer customer) {
    if (customer.status == MembershipStatus.expired) {
      return Colors.red[100]!;
    }

    if (customer.membershipEndDate != null) {
      final now = DateTime.now();
      final difference = customer.membershipEndDate!.difference(now).inDays;

      if (difference <= 7) {
        return Colors.orange[100]!;
      }
    }

    return Colors.green[100]!;
  }

  void _createDummyCustomer() async {
    final customer = Customer(
      name: 'Test Müşteri',
      phone: '5551234567',
      email: 'test@example.com',
      registrationDate: DateTime.now(),
      subscriptionMonths: 3,
      paymentType: PaymentType.cash,
      paidInstallments: 1,
      totalInstallments: 1,
      status: MembershipStatus.active,
    );

    await _customerService.addCustomer(customer);
    _loadCustomers();
  }
}
