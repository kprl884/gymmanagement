import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../utils/toast_helper.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({Key? key, required this.customer})
      : super(key: key);

  @override
  _CustomerDetailScreenState createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Customer _customer;
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  Future<void> _updatePaidInstallments(int newValue) async {
    if (newValue < 0 || newValue > _customer.totalInstallments) {
      ToastHelper.showErrorToast(context, 'Geçersiz taksit sayısı');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _customerService.updatePaidInstallments(_customer.id!, newValue);

      setState(() {
        _customer = _customer.copyWith(paidInstallments: newValue);
        _isLoading = false;
      });

      ToastHelper.showSuccessToast(context, 'Taksit bilgisi güncellendi');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ToastHelper.showErrorToast(context, 'Güncelleme başarısız: $e');
    }
  }

  Future<void> _updateCustomer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedCustomer = _customer.copyWith(
        status: MembershipStatus.active,
      );

      await _customerService.updateCustomer(updatedCustomer);

      setState(() {
        _customer = updatedCustomer;
        _isLoading = false;
      });

      ToastHelper.showSuccessToast(context, 'Müşteri bilgileri güncellendi');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ToastHelper.showErrorToast(context, 'Güncelleme başarısız: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Müşteri düzenleme ekranına git
            },
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
                  // Temel Bilgiler Kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Temel Bilgiler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow('Ad Soyad', _customer.name),
                          _buildInfoRow('Telefon', _customer.phone),
                          _buildInfoRow('E-posta', _customer.email),
                          _buildInfoRow(
                            'Kayıt Tarihi',
                            dateFormat.format(_customer.registrationDate),
                          ),
                          _buildInfoRow(
                            'Durum',
                            _customer.isActive ? 'Aktif' : 'Pasif',
                            valueColor:
                                _customer.isActive ? Colors.green : Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Abonelik Bilgileri Kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Abonelik Bilgileri',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'Abonelik Süresi',
                            '${_customer.subscriptionMonths} ay',
                          ),
                          _buildInfoRow(
                            'Ödeme Tipi',
                            _customer.paymentType == PaymentType.cash
                                ? 'Peşin'
                                : 'Taksitli',
                          ),
                          if (_customer.paymentType == PaymentType.installment)
                            _buildInfoRow(
                              'Taksit Durumu',
                              '${_customer.paidInstallments}/${_customer.totalInstallments}',
                              valueColor: _customer.paidInstallments ==
                                      _customer.totalInstallments
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 12),

                  // Taksit güncelleme butonları (sadece taksitli ödemede göster)
                  if (_customer.paymentType == PaymentType.installment)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_customer.paidInstallments <
                                  _customer.totalInstallments) {
                                _updatePaidInstallments(
                                    _customer.paidInstallments + 1);
                              } else {
                                ToastHelper.showInfoToast(
                                    context, 'Tüm taksitler ödenmiş');
                              }
                            },
                            icon: const Icon(Icons.add_circle),
                            label: const Text('Taksit Ödemesi Ekle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
