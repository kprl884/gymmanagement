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
        title: Text('${_customer.name} ${_customer.surname}'),
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
                          _buildInfoRow('Ad', _customer.name),
                          _buildInfoRow('Soyad', _customer.surname),
                          _buildInfoRow('Telefon', _customer.phone),
                          _buildInfoRow('E-posta', _customer.email),
                          _buildInfoRow('Yaş', _customer.age.toString()),
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

                  // Üyelik Bilgileri Kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Üyelik Bilgileri',
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
                            valueColor:
                                _customer.paymentType == PaymentType.cash
                                    ? Colors.green
                                    : Colors.orange,
                          ),
                          _buildInfoRow(
                            'Ödeme Durumu',
                            _customer.paymentType == PaymentType.cash
                                ? 'Tamamlandı'
                                : '${_customer.paidMonths.length}/${_customer.subscriptionMonths} ay ödendi',
                            valueColor: _customer.paidMonths.length ==
                                    _customer.subscriptionMonths
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ödenen aylar bölümü
                  if (_customer.paymentType == PaymentType.installment)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ödenen Aylar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),

                            // Ödenen ayları göster
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(
                                  _customer.subscriptionMonths, (index) {
                                // Kayıt tarihinden itibaren ayları hesapla
                                final month = DateTime(
                                  _customer.registrationDate.year,
                                  _customer.registrationDate.month + index,
                                  1,
                                );
                                final monthName =
                                    DateFormat('MMMM yyyy', 'tr_TR')
                                        .format(month);

                                // Bu ay ödenmiş mi kontrol et
                                bool isPaid = _customer.paidMonths.any(
                                    (paidMonth) =>
                                        paidMonth.year == month.year &&
                                        paidMonth.month == month.month);

                                return FilterChip(
                                  label: Text(monthName),
                                  selected: isPaid,
                                  onSelected: (bool selected) {
                                    _updatePaidMonth(month, selected);
                                  },
                                  selectedColor: Colors.green[100],
                                  checkmarkColor: Colors.green,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 12),
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

  // Ödenen ay güncelleme metodu
  Future<void> _updatePaidMonth(DateTime month, bool isPaid) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mevcut ödenen aylar listesini kopyala
      List<DateTime> updatedPaidMonths = List.from(_customer.paidMonths);

      if (isPaid) {
        // Ay ödendi olarak işaretlendiyse ve listede yoksa ekle
        if (!updatedPaidMonths.any((paidMonth) =>
            paidMonth.year == month.year && paidMonth.month == month.month)) {
          updatedPaidMonths.add(DateTime(month.year, month.month, 1));
        }
      } else {
        // Ay ödenmedi olarak işaretlendiyse ve listede varsa çıkar
        updatedPaidMonths.removeWhere((paidMonth) =>
            paidMonth.year == month.year && paidMonth.month == month.month);
      }

      // Firestore'da güncelle
      await _customerService.updatePaidMonths(_customer.id!, updatedPaidMonths);

      // Müşteri nesnesini güncelle
      setState(() {
        _customer = _customer.copyWith(paidMonths: updatedPaidMonths);
        _isLoading = false;
      });

      ToastHelper.showSuccessToast(context, 'Ödeme bilgisi güncellendi');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ToastHelper.showErrorToast(context, 'Güncelleme başarısız: $e');
    }
  }
}
