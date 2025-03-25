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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime? _membershipStartDate = DateTime.now();
  DateTime? _membershipEndDate;
  int _membershipDuration = 1; // Ay cinsinden
  MembershipStatus _status = MembershipStatus.active;

  bool _isLoading = false;
  final CustomerService _customerService = CustomerService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateMembershipEndDate() {
    if (_membershipStartDate != null) {
      setState(() {
        _membershipEndDate = DateTime(
          _membershipStartDate!.year,
          _membershipStartDate!.month + _membershipDuration,
          _membershipStartDate!.day,
        );
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _membershipStartDate ?? DateTime.now()
          : _membershipEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate:
          isStartDate ? DateTime(2020) : _membershipStartDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _membershipStartDate = picked;
          _updateMembershipEndDate();
        } else {
          _membershipEndDate = picked;
          // Eğer bitiş tarihi manuel seçildiyse, süreyi hesapla
          if (_membershipStartDate != null) {
            final months = (picked.year - _membershipStartDate!.year) * 12 +
                picked.month -
                _membershipStartDate!.month;
            _membershipDuration = months > 0 ? months : 1;
          }
        }
      });
    }
  }

  Future<void> _addCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final customer = Customer(
          id: '', // Firestore tarafından otomatik oluşturulacak
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          registrationDate: _selectedDate,
          membershipStartDate: _membershipStartDate,
          membershipEndDate: _membershipEndDate,
          status: _status,
          notes: _notesController.text.trim(),
        );

        final customerId = await _customerService.addCustomer(customer);

        if (!mounted) return;

        if (customerId != null) {
          ToastHelper.showSuccessToast(context, 'Müşteri başarıyla eklendi');
          Navigator.pop(context, true); // Başarılı ekleme ile geri dön
        } else {
          ToastHelper.showErrorToast(
              context, 'Müşteri eklenirken bir hata oluştu');
        }
      } catch (e) {
        if (!mounted) return;
        ToastHelper.showErrorToast(context, 'Hata: $e');
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
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen ad soyad giriniz';
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
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen e-posta giriniz';
                        }
                        if (!value.contains('@')) {
                          return 'Geçerli bir e-posta giriniz';
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
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Üyelik Başlangıç Tarihi
                    ListTile(
                      title: const Text('Üyelik Başlangıç Tarihi'),
                      subtitle: Text(
                        _membershipStartDate != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(_membershipStartDate!)
                            : 'Seçilmedi',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    ),

                    // Üyelik Süresi
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Üyelik Süresi (Ay):'),
                        ),
                        DropdownButton<int>(
                          value: _membershipDuration,
                          items: List.generate(24, (index) => index + 1)
                              .map((month) => DropdownMenuItem(
                                    value: month,
                                    child: Text('$month ay'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _membershipDuration = value;
                                _updateMembershipEndDate();
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    // Üyelik Bitiş Tarihi
                    ListTile(
                      title: const Text('Üyelik Bitiş Tarihi'),
                      subtitle: Text(
                        _membershipEndDate != null
                            ? DateFormat('dd/MM/yyyy')
                                .format(_membershipEndDate!)
                            : 'Hesaplanıyor...',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                    ),

                    // Üyelik Durumu
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Üyelik Durumu:'),
                        ),
                        DropdownButton<MembershipStatus>(
                          value: _status,
                          items: MembershipStatus.values
                              .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(_getStatusText(status)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _status = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notlar',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addCustomer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Müşteri Ekle'),
                    ),
                  ],
                ),
              ),
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
}
