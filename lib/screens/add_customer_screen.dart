import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../utils/toast_helper.dart';
import '../utils/multiple_click_handler.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({Key? key}) : super(key: key);

  @override
  _AddCustomerScreenState createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  final _monthlyFeeController = TextEditingController();

  // Dropdown için değişkenler
  int _selectedSubscriptionMonths = 1;
  CustomerType _selectedCustomerType = CustomerType.civilian;

  // Dropdown için seçenekler
  final List<int> _subscriptionOptions =
      List.generate(12, (i) => i + 1); // 1'den 12'ye kadar

  PaymentType _paymentType = PaymentType.cash;
  bool _isLoading = false;
  final CustomerService _customerService = CustomerService();

  // Ödenen aylar için kontrol listesi
  List<bool> _paidMonthsChecklist = List.generate(1, (index) => false);

  @override
  void initState() {
    super.initState();
    _updatePaidMonthsChecklist();
    _updateMonthlyFee();
  }

  void _updatePaidMonthsChecklist() {
    setState(() {
      // Abonelik süresine göre ödenen aylar listesini güncelle
      _paidMonthsChecklist =
          List.generate(_selectedSubscriptionMonths, (index) => false);
    });
  }

  void _updateMonthlyFee() {
    setState(() {
      // Müşteri tipine göre aylık ücreti güncelle
      _monthlyFeeController.text =
          _selectedCustomerType == CustomerType.student ? '700' : '800';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    _monthlyFeeController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Kayıt tarihini al
        final registrationDate = DateTime.now();

        // Ödenen ayları hesapla
        List<DateTime> paidMonths = [];

        if (_paymentType == PaymentType.installment) {
          // Taksitli ödemede, işaretlenen ayları ekle
          for (int i = 0; i < _paidMonthsChecklist.length; i++) {
            if (_paidMonthsChecklist[i]) {
              // Kayıt tarihinden itibaren i ay sonrası
              final paidMonth = DateTime(
                registrationDate.year,
                registrationDate.month + i,
                1, // Ayın ilk günü
              );
              paidMonths.add(paidMonth);
            }
          }
        } else {
          // Peşin ödemede tüm aylar ödenmiş sayılır
          for (int i = 0; i < _selectedSubscriptionMonths; i++) {
            final paidMonth = DateTime(
              registrationDate.year,
              registrationDate.month + i,
              1, // Ayın ilk günü
            );
            paidMonths.add(paidMonth);
          }
        }

        final customer = Customer(
          name: _nameController.text,
          surname: _surnameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          age: int.parse(_ageController.text),
          registrationDate: registrationDate,
          subscriptionMonths: _selectedSubscriptionMonths,
          paymentType: _paymentType,
          paidMonths: paidMonths,
          status: MembershipStatus.active,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          customerType: _selectedCustomerType,
          monthlyFee: double.parse(_monthlyFeeController.text),
        );

        await _customerService.addCustomer(customer);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ToastHelper.showSuccessToast(context, 'Müşteri başarıyla eklendi');
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ToastHelper.showErrorToast(context, 'Müşteri eklenirken hata: $e');
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
                            const Divider(),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Ad',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen adı girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _surnameController,
                              decoration: const InputDecoration(
                                labelText: 'Soyad',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen soyadı girin';
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
                                  return 'Lütfen e-posta adresi girin';
                                }
                                if (!value.contains('@')) {
                                  return 'Geçerli bir e-posta adresi girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: 'Yaş',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.cake),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen yaş girin';
                                }
                                final age = int.tryParse(value);
                                if (age == null || age < 1 || age > 120) {
                                  return 'Geçerli bir yaş girin';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Notlar',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.note),
                              ),
                              keyboardType: TextInputType.multiline,
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

                            // Müşteri Tipi Seçimi
                            DropdownButtonFormField<CustomerType>(
                              decoration: const InputDecoration(
                                labelText: 'Müşteri Tipi',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              value: _selectedCustomerType,
                              items:
                                  CustomerType.values.map((CustomerType type) {
                                return DropdownMenuItem<CustomerType>(
                                  value: type,
                                  child: Text(
                                    type == CustomerType.student
                                        ? 'Öğrenci'
                                        : 'Sivil',
                                  ),
                                );
                              }).toList(),
                              onChanged: (CustomerType? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCustomerType = newValue;
                                    _updateMonthlyFee();
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // Aylık Ücret
                            TextFormField(
                              controller: _monthlyFeeController,
                              decoration: const InputDecoration(
                                labelText: 'Aylık Ücret (TL)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Lütfen aylık ücret girin';
                                }
                                final fee = double.tryParse(value);
                                if (fee == null || fee <= 0) {
                                  return 'Geçerli bir ücret girin';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Abonelik Süresi Dropdown
                            DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                labelText: 'Abonelik Süresi',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_month),
                              ),
                              value: _selectedSubscriptionMonths,
                              items: _subscriptionOptions.map((int months) {
                                return DropdownMenuItem<int>(
                                  value: months,
                                  child: Text('$months ay'),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedSubscriptionMonths = newValue;
                                    _updatePaidMonthsChecklist();
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            // Ödeme Tipi Seçimi
                            DropdownButtonFormField<PaymentType>(
                              decoration: const InputDecoration(
                                labelText: 'Ödeme Tipi',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.payment),
                              ),
                              value: _paymentType,
                              items: PaymentType.values.map((PaymentType type) {
                                return DropdownMenuItem<PaymentType>(
                                  value: type,
                                  child: Text(
                                    type == PaymentType.cash
                                        ? 'Peşin'
                                        : 'Taksitli',
                                  ),
                                );
                              }).toList(),
                              onChanged: (PaymentType? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _paymentType = newValue;
                                  });
                                }
                              },
                            ),

                            if (_paymentType == PaymentType.installment) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Ödenen Aylar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _paidMonthsChecklist.length,
                                itemBuilder: (context, index) {
                                  return CheckboxListTile(
                                    title: Text(
                                      '${index + 1}. Ay (${DateFormat('MMMM yyyy', 'tr_TR').format(DateTime(DateTime.now().year, DateTime.now().month + index))})',
                                    ),
                                    value: _paidMonthsChecklist[index],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _paidMonthsChecklist[index] = value!;
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SingleClickElevatedButton(
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
