import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({Key? key}) : super(key: key);

  @override
  _AddCustomerScreenState createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int _membershipDuration = 1;
  bool _isInstallment = false;
  Map<String, bool> _installments = {};
  bool _isLoading = false;

  final List<int> _durationOptions = List.generate(12, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _updateInstallmentMonths();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _updateInstallmentMonths() {
    final Map<String, bool> newInstallments = {};
    final DateFormat formatter = DateFormat('MMMM yyyy');

    for (int i = 0; i < _membershipDuration; i++) {
      final DateTime monthDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + i,
        _selectedDate.day,
      );
      final String monthKey = formatter.format(monthDate);

      // Mevcut ödeme durumunu koru veya yeni ay için false ata
      newInstallments[monthKey] = _installments[monthKey] ?? false;
    }

    setState(() {
      _installments = newInstallments;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateInstallmentMonths();
      });
    }
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final customer = Customer(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          age: int.parse(_ageController.text.trim()),
          registrationDate: _selectedDate,
          membershipDuration: _membershipDuration,
          isInstallment: _isInstallment,
          installments: _installments,
        );

        await FirebaseFirestore.instance
            .collection('customers')
            .add(customer.toFirestore());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müşteri başarıyla kaydedildi')),
        );

        _resetForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _ageController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _membershipDuration = 1;
      _isInstallment = false;
      _updateInstallmentMonths();
    });
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen adınızı girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Soyad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen soyadınızı girin';
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
                        hintText: '05XXXXXXXXX',
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen telefon numaranızı girin';
                        }
                        if (!value.startsWith('05') || value.length != 11) {
                          return 'Geçerli bir telefon numarası girin (05XXXXXXXXX)';
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
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen yaşınızı girin';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 18 || age > 100) {
                          return 'Yaş 18-100 arasında olmalıdır';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Kayıt Tarihi',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                DateFormat('dd/MM/yyyy').format(_selectedDate),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Üyelik Süresi (Ay)',
                        border: OutlineInputBorder(),
                      ),
                      value: _membershipDuration,
                      items: _durationOptions.map((int duration) {
                        return DropdownMenuItem<int>(
                          value: duration,
                          child: Text('$duration ay'),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _membershipDuration = newValue;
                            _updateInstallmentMonths();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ödeme Tipi:',
                      style: TextStyle(fontSize: 16),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Peşin'),
                            value: false,
                            groupValue: _isInstallment,
                            onChanged: (bool? value) {
                              if (value != null) {
                                setState(() {
                                  _isInstallment = value;
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Taksitli'),
                            value: true,
                            groupValue: _isInstallment,
                            onChanged: (bool? value) {
                              if (value != null) {
                                setState(() {
                                  _isInstallment = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_isInstallment) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Taksit Ödemeleri:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...(_installments.entries.toList()
                            ..sort((a, b) => DateFormat('MMMM yyyy')
                                .parse(a.key)
                                .compareTo(
                                    DateFormat('MMMM yyyy').parse(b.key))))
                          .map(
                        (entry) => CheckboxListTile(
                          title: Text(entry.key),
                          value: entry.value,
                          onChanged: (bool? value) {
                            if (value != null) {
                              setState(() {
                                _installments[entry.key] = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isInstallment)
                        FormField<bool>(
                          validator: (_) {
                            if (_isInstallment &&
                                !_installments.values.contains(true)) {
                              return 'En az bir taksit ödemesi seçilmelidir';
                            }
                            return null;
                          },
                          builder: (state) {
                            if (state.hasError) {
                              return Text(
                                state.errorText!,
                                style: const TextStyle(color: Colors.red),
                              );
                            }
                            return Container();
                          },
                        ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveCustomer,
                        child: const Text(
                          'Müşteriyi Kaydet',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
