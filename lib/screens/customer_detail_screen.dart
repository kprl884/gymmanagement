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
  bool _isLoading = false;
  final CustomerService _customerService = CustomerService();

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  Future<void> _editCustomer() async {
    final nameController = TextEditingController(text: _customer.name);
    final emailController = TextEditingController(text: _customer.email);
    final phoneController = TextEditingController(text: _customer.phone ?? '');
    final notesController = TextEditingController(text: _customer.notes ?? '');

    MembershipStatus status = _customer.status;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteri Bilgilerini Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ad Soyad'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'E-posta'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Telefon'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Üyelik Durumu
              DropdownButtonFormField<MembershipStatus>(
                value: status,
                decoration: const InputDecoration(labelText: 'Üyelik Durumu'),
                items: MembershipStatus.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_getStatusText(s)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    status = value;
                  }
                },
              ),

              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notlar'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'name': nameController.text,
                'email': emailController.text,
                'phone': phoneController.text,
                'status': status,
                'notes': notesController.text,
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
        // Müşteri bilgilerini güncelle
        final updatedCustomer = _customer.copyWith(
          name: result['name'],
          email: result['email'],
          phone: result['phone'],
          status: result['status'],
          notes: result['notes'],
        );

        final success = await _customerService.updateCustomer(updatedCustomer);

        setState(() {
          _isLoading = false;
          if (success) {
            _customer = updatedCustomer;
            ToastHelper.showSuccessToast(
                context, 'Müşteri bilgileri güncellendi');
          } else {
            ToastHelper.showErrorToast(context, 'Güncelleme başarısız oldu');
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ToastHelper.showErrorToast(context, 'Hata: $e');
      }
    }
  }

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteriyi Sil'),
        content: const Text(
            'Bu müşteriyi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _customerService.deleteCustomer(_customer.id);

        if (success) {
          ToastHelper.showSuccessToast(context, 'Müşteri silindi');
          Navigator.pop(context, true); // Listeyi yenilemek için true döndür
        } else {
          setState(() {
            _isLoading = false;
          });
          ToastHelper.showErrorToast(context, 'Silme işlemi başarısız oldu');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ToastHelper.showErrorToast(context, 'Hata: $e');
      }
    }
  }

  Future<void> _extendMembership() async {
    int additionalMonths = 1;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üyelik Süresini Uzat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Kaç ay uzatmak istiyorsunuz?'),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: additionalMonths,
              items: List.generate(12, (i) => i + 1)
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text('$m ay'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  additionalMonths = value;
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, additionalMonths),
            child: const Text('Uzat'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Mevcut bitiş tarihini al veya bugünden başlat
        final DateTime startDate = _customer.membershipEndDate != null &&
                _customer.membershipEndDate!.isAfter(DateTime.now())
            ? _customer.membershipEndDate!
            : DateTime.now();

        // Yeni bitiş tarihini hesapla
        final DateTime newEndDate = DateTime(
          startDate.year,
          startDate.month + result,
          startDate.day,
        );

        // Müşteriyi güncelle
        final updatedCustomer = _customer.copyWith(
          membershipEndDate: newEndDate,
          status: MembershipStatus.active, // Üyelik uzatıldığında aktif yap
        );

        final success = await _customerService.updateCustomer(updatedCustomer);

        setState(() {
          _isLoading = false;
          if (success) {
            _customer = updatedCustomer;
            ToastHelper.showSuccessToast(context, 'Üyelik süresi uzatıldı');
          } else {
            ToastHelper.showErrorToast(context, 'Üyelik uzatma başarısız oldu');
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ToastHelper.showErrorToast(context, 'Hata: $e');
      }
    }
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

  String? _getRemainingDaysText(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;

    if (difference < 0) {
      return 'Süresi dolmuş';
    } else if (difference == 0) {
      return 'Bugün bitiyor';
    } else {
      return '$difference gün kaldı';
    }
  }

  Widget _buildInfoRow(String label, String value, [String? additionalInfo]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
          if (additionalInfo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: additionalInfo.contains('dolmuş')
                    ? Colors.red[100]
                    : additionalInfo.contains('gün kaldı') &&
                            int.tryParse(additionalInfo.split(' ')[0]) !=
                                null &&
                            int.parse(additionalInfo.split(' ')[0]) <= 7
                        ? Colors.orange[100]
                        : Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                additionalInfo,
                style: TextStyle(
                  fontSize: 12,
                  color: additionalInfo.contains('dolmuş')
                      ? Colors.red[900]
                      : additionalInfo.contains('gün kaldı') &&
                              int.tryParse(additionalInfo.split(' ')[0]) !=
                                  null &&
                              int.parse(additionalInfo.split(' ')[0]) <= 7
                          ? Colors.orange[900]
                          : Colors.green[900],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_customer.name),
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
                  // Müşteri bilgileri kartı
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Müşteri Bilgileri',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow('Ad Soyad', _customer.name),
                          _buildInfoRow('E-posta', _customer.email),
                          _buildInfoRow(
                              'Telefon', _customer.phone ?? 'Belirtilmemiş'),
                          _buildInfoRow(
                            'Kayıt Tarihi',
                            DateFormat('dd/MM/yyyy')
                                .format(_customer.registrationDate),
                          ),
                          _buildInfoRow(
                            'Üyelik Durumu',
                            _getStatusText(_customer.status),
                          ),
                          if (_customer.membershipStartDate != null)
                            _buildInfoRow(
                              'Üyelik Başlangıç',
                              DateFormat('dd/MM/yyyy')
                                  .format(_customer.membershipStartDate!),
                            ),
                          if (_customer.membershipEndDate != null)
                            _buildInfoRow(
                              'Üyelik Bitiş',
                              DateFormat('dd/MM/yyyy')
                                  .format(_customer.membershipEndDate!),
                              _getRemainingDaysText(
                                  _customer.membershipEndDate!),
                            ),
                          if (_customer.notes != null &&
                              _customer.notes!.isNotEmpty)
                            _buildInfoRow('Notlar', _customer.notes!),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Üyelik işlemleri
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Üyelik İşlemleri',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: const Text('Üyelik Süresini Uzat'),
                            onTap: _extendMembership,
                          ),
                          ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: const Text('Fitness Planı Ata'),
                            onTap: () {
                              // Fitness planı atama ekranına git
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.assessment),
                            title: const Text('Ölçüm Kaydet'),
                            onTap: () {
                              // Ölçüm kaydetme ekranına git
                            },
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
}
