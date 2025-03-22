import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({Key? key, required this.customer})
      : super(key: key);

  @override
  _CustomerDetailScreenState createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Customer _customer;
  bool _isLoading = false;
  Map<String, bool> _installments = {};

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _installments = Map<String, bool>.from(_customer.installments);
  }

  Future<void> _updateInstallments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(_customer.id)
          .update({'installments': _installments});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödemeler güncellendi')),
      );
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

  Future<void> _deleteCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteriyi Sil'),
        content: const Text('Bu müşteriyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(_customer.id)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müşteri silindi')),
        );
        Navigator.pop(context);
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

  Future<void> _editCustomer() async {
    final firstNameController =
        TextEditingController(text: _customer.firstName);
    final lastNameController = TextEditingController(text: _customer.lastName);
    final phoneController = TextEditingController(text: _customer.phoneNumber);
    final ageController = TextEditingController(text: _customer.age.toString());

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteri Bilgilerini Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'Ad'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Soyad'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Telefon'),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Yaş'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'firstName': firstNameController.text,
                'lastName': lastNameController.text,
                'phoneNumber': phoneController.text,
                'age': int.tryParse(ageController.text) ?? _customer.age,
              });
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(_customer.id)
            .update(result);

        setState(() {
          _customer = Customer(
            id: _customer.id,
            firstName: result['firstName'],
            lastName: result['lastName'],
            phoneNumber: result['phoneNumber'],
            age: result['age'],
            registrationDate: _customer.registrationDate,
            membershipDuration: _customer.membershipDuration,
            isInstallment: _customer.isInstallment,
            installments: _customer.installments,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Müşteri bilgileri güncellendi')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_customer.firstName} ${_customer.lastName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCustomer,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCustomer,
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kişisel Bilgiler',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Divider(),
                          _buildInfoRow('Ad Soyad',
                              '${_customer.firstName} ${_customer.lastName}'),
                          _buildInfoRow('Telefon', _customer.phoneNumber),
                          _buildInfoRow('Yaş', _customer.age.toString()),
                          _buildInfoRow(
                            'Kayıt Tarihi',
                            DateFormat('dd/MM/yyyy')
                                .format(_customer.registrationDate),
                          ),
                          _buildInfoRow(
                            'Üyelik Süresi',
                            '${_customer.membershipDuration} ay',
                          ),
                          _buildInfoRow(
                            'Ödeme Tipi',
                            _customer.isInstallment ? 'Taksitli' : 'Peşin',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_customer.isInstallment) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Taksit Ödemeleri',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Divider(),
                            ...(_installments.entries.toList()
                                  ..sort((a, b) => DateFormat('MMMM yyyy')
                                      .parse(a.key)
                                      .compareTo(DateFormat('MMMM yyyy')
                                          .parse(b.key))))
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
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _updateInstallments,
                                child: const Text('Ödemeleri Güncelle'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
