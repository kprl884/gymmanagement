import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../utils/toast_helper.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({Key? key}) : super(key: key);

  @override
  _AddCustomerScreenState createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _subscriptionMonthsController = TextEditingController(text: '1');
  final _paidInstallmentsController = TextEditingController(text: '0');
  final _totalInstallmentsController = TextEditingController(text: '1');

  PaymentType _paymentType = PaymentType.cash;
  bool _isLoading = false;
  final CustomerService _customerService = CustomerService();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _subscriptionMonthsController.dispose();
    _paidInstallmentsController.dispose();
    _totalInstallmentsController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Ödeme tipine göre taksit bilgilerini ayarla
        int paidInstallments = 0;
        int totalInstallments = 1;

        if (_paymentType == PaymentType.installment) {
          paidInstallments = int.parse(_paidInstallmentsController.text);
          totalInstallments = int.parse(_totalInstallmentsController.text);
        } else {
          // Peşin ödemede tüm taksitler ödenmiş sayılır
          paidInstallments = 1;
          totalInstallments = 1;
        }

        final customer = Customer(
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          registrationDate: DateTime.now(),
          subscriptionMonths: int.parse(_subscriptionMonthsController.text),
          paymentType: _paymentType,
          paidInstallments: paidInstallments,
          totalInstallments: totalInstallments,
          status: MembershipStatus.active,
        );

        await _customerService.addCustomer(customer);

        if (!mounted) return;

        ToastHelper.showSuccessToast(context, 'Müşteri başarıyla eklendi');
        Navigator.pop(context, true); // Başarılı olduğunu bildir
      } catch (e) {
        if (!mounted) return;
        ToastHelper.showErrorToast(context, 'Müşteri eklenirken hata: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Müşteri Ekle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Ad Soyad',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen ad soyad girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefon',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen telefon numarası girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'E-posta',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen e-posta girin';
                                }
                                if (!value.contains('@')) {
                                  return 'Geçerli bir e-posta adresi girin';
                                }
                                return null;
                              },
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _subscriptionMonthsController,
                              decoration: const InputDecoration(
                                labelText: 'Abonelik Süresi (Ay)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_month),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen abonelik süresini girin';
                                }
                                final months = int.tryParse(value);
                                if (months == null || months < 1) {
                                  return 'Geçerli bir süre girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Ödeme Tipi Seçimi
                            const Text(
                              'Ödeme Tipi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<PaymentType>(
                                    title: const Text('Peşin'),
                                    value: PaymentType.cash,
                                    groupValue: _paymentType,
                                    onChanged: (PaymentType? value) {
                                      setState(() {
                                        _paymentType = value!;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<PaymentType>(
                                    title: const Text('Taksitli'),
                                    value: PaymentType.installment,
                                    groupValue: _paymentType,
                                    onChanged: (PaymentType? value) {
                                      setState(() {
                                        _paymentType = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // Taksit Bilgileri (Sadece taksitli ödemede göster)
                            if (_paymentType == PaymentType.installment) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _paidInstallmentsController,
                                      decoration: const InputDecoration(
                                        labelText: 'Ödenen Taksit',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Gerekli';
                                        }
                                        final paid = int.tryParse(value);
                                        final total = int.tryParse(
                                            _totalInstallmentsController.text);
                                        if (paid == null ||
                                            paid < 0 ||
                                            (total != null && paid > total)) {
                                          return 'Geçersiz';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _totalInstallmentsController,
                                      decoration: const InputDecoration(
                                        labelText: 'Toplam Taksit',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Gerekli';
                                        }
                                        final total = int.tryParse(value);
                                        if (total == null || total < 1) {
                                          return 'Geçersiz';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _saveCustomer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'KAYDET',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
