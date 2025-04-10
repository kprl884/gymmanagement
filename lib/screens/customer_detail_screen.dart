import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../utils/toast_helper.dart';
import '../services/notification_service.dart';

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
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  bool _isEditing = false;

  // Form kontrolcüleri
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _notesController;
  late int _subscriptionMonths;
  late PaymentType _paymentType;
  late MembershipStatus _status;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;

    // Kontrolcüleri başlat
    _nameController = TextEditingController(text: _customer.name);
    _surnameController = TextEditingController(text: _customer.surname);
    _phoneController = TextEditingController(text: _customer.phone);
    _emailController = TextEditingController(text: _customer.email);
    _ageController = TextEditingController(text: _customer.age.toString());
    _notesController = TextEditingController(text: _customer.notes ?? '');
    _subscriptionMonths = _customer.subscriptionMonths;
    _paymentType = _customer.paymentType;
    _status = _customer.status;
  }

  @override
  void dispose() {
    // Kontrolcüleri temizle
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_customer.name} ${_customer.surname}'),
        actions: [
          // Düzenleme modunu aç/kapat
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
          // Düzenleme modunda kaydet butonu
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCustomer,
            ),
          // Silme butonu
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _isEditing ? _buildEditForm() : _buildCustomerDetails(),
            ),
    );
  }

  Widget _buildCustomerDetails() {
    return Column(
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
                  'Kişisel Bilgiler',
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
                if (_customer.notes != null && _customer.notes!.isNotEmpty)
                  _buildInfoRow('Notlar', _customer.notes!),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Üyelik bilgileri kartı
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
                    'Kayıt Tarihi',
                    DateFormat('dd.MM.yyyy')
                        .format(_customer.registrationDate)),
                _buildInfoRow(
                    'Üyelik Durumu', _getStatusText(_customer.status)),
                _buildInfoRow(
                    'Ödeme Tipi',
                    _customer.paymentType == PaymentType.cash
                        ? 'Peşin'
                        : 'Taksitli'),
                _buildInfoRow(
                    'Abonelik Süresi', '${_customer.subscriptionMonths} ay'),
                if (_customer.paymentType == PaymentType.installment)
                  _buildInfoRow('Ödenen Taksitler',
                      '${_customer.paidMonths.length}/${_customer.subscriptionMonths}'),
                if (_customer.lastVisitDate != null)
                  _buildInfoRow(
                      'Son Ziyaret',
                      DateFormat('dd.MM.yyyy')
                          .format(_customer.lastVisitDate!)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Taksit durumu kartı
        if (_customer.paymentType == PaymentType.installment)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Taksit Durumu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInstallmentStatus(),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Ödeme geçmişi kartı
        if (_customer.paymentType == PaymentType.installment)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ödeme Geçmişi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  if (_customer.status != MembershipStatus.active)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Üyelik ${_getStatusText(_customer.status).toLowerCase()} olduğu için yeni ödeme alınamaz.',
                        style: TextStyle(
                          color: Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ..._buildPaymentHistory(),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Ödeme hatırlatma SMS butonu
        ElevatedButton(
          onPressed: _isLoading ? null : () => _sendPaymentReminderSms(),
          child: Text('Ödeme Hatırlatma SMS\'i Gönder'),
        ),
      ],
    );
  }

  Widget _buildInstallmentStatus() {
    // Ödenen ve ödenmeyen taksitleri göster
    final paidCount = _customer.paidMonths.length;
    final totalCount = _customer.subscriptionMonths;
    final unpaidCount = totalCount - paidCount;

    return Column(
      children: [
        // İlerleme çubuğu
        LinearProgressIndicator(
          value: paidCount / totalCount,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            paidCount == totalCount ? Colors.green : Colors.orange,
          ),
          minHeight: 10,
        ),
        const SizedBox(height: 16),

        // Taksit durumu özeti
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatusItem('Toplam', totalCount.toString(), Colors.blue),
            _buildStatusItem('Ödenen', paidCount.toString(), Colors.green),
            _buildStatusItem('Kalan', unpaidCount.toString(), Colors.orange),
          ],
        ),

        const SizedBox(height: 16),

        // Taksit listesi
        ...List.generate(totalCount, (index) {
          final installmentNumber = index + 1;
          final isPaid = index < paidCount;

          // Ödeme tarihi hesapla (kayıt tarihinden itibaren aylık)
          final dueDate = DateTime(
            _customer.registrationDate.year,
            _customer.registrationDate.month + index,
            _customer.registrationDate.day,
          );

          // Müşteri aktif değilse ödeme yapılamaz
          final canPay = _customer.status == MembershipStatus.active;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isPaid ? Colors.green : Colors.grey,
              child: Icon(
                isPaid ? Icons.check : Icons.hourglass_empty,
                color: Colors.white,
              ),
            ),
            title: Text('$installmentNumber. Taksit'),
            subtitle: Text('Vade: ${DateFormat('dd.MM.yyyy').format(dueDate)}'),
            trailing: isPaid
                ? const Icon(Icons.done_all, color: Colors.green)
                : TextButton(
                    onPressed:
                        canPay ? () => _recordSpecificPayment(index) : null,
                    child: const Text('Öde'),
                  ),
          );
        }),
      ],
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPaymentHistory() {
    if (_customer.paidMonths.isEmpty) {
      return [const Text('Henüz ödeme kaydı yok.')];
    }

    // Ödeme tarihlerini sırala (en yeni en üstte)
    final sortedPayments = List<DateTime>.from(_customer.paidMonths)
      ..sort((a, b) => b.compareTo(a));

    return sortedPayments.map((date) {
      return ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.payment, color: Colors.white, size: 16),
        ),
        title: Text('${sortedPayments.indexOf(date) + 1}. Taksit Ödemesi'),
        subtitle: Text(DateFormat('dd.MM.yyyy').format(date)),
      );
    }).toList();
  }

  Widget _buildInfoRow(String label, String value) {
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

  Future<void> _recordPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Yeni ödeme tarihi olarak bugünü ekle
      final updatedPaidMonths = List<DateTime>.from(_customer.paidMonths)
        ..add(DateTime.now());

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

  Future<void> _recordSpecificPayment(int installmentIndex) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Ödeme tarihlerini sırala
      final sortedPayments = List<DateTime>.from(_customer.paidMonths)
        ..sort((a, b) => a.compareTo(b));

      // Yeni ödeme tarihi olarak bugünü ekle
      final updatedPaidMonths = sortedPayments..add(DateTime.now());

      // Firestore'da güncelle
      await _customerService.updatePaidMonths(_customer.id!, updatedPaidMonths);

      // Müşteri nesnesini güncelle
      setState(() {
        _customer = _customer.copyWith(paidMonths: updatedPaidMonths);
        _isLoading = false;
      });

      ToastHelper.showSuccessToast(
          context, '${installmentIndex + 1}. taksit ödemesi kaydedildi');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ToastHelper.showErrorToast(context, 'Ödeme kaydedilemedi: $e');
    }
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Müşteriyi güncelle
        final updatedCustomer = Customer(
          id: _customer.id, // Mevcut ID'yi koru!
          name: _nameController.text,
          surname: _surnameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          age: int.parse(_ageController.text),
          registrationDate:
              _customer.registrationDate, // Orijinal kayıt tarihini koru
          subscriptionMonths: _subscriptionMonths,
          paymentType: _paymentType,
          paidMonths: _customer.paidMonths, // Mevcut ödeme bilgilerini koru
          status: _status,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          lastVisitDate: _customer.lastVisitDate,
          isActive: _customer.isActive,
          profileImageUrl: _customer.profileImageUrl,
          assignedPlans: _customer.assignedPlans,
          measurements: _customer.measurements,
          assignedTrainer: _customer.assignedTrainer,
          customerType: _customer.customerType,
          monthlyFee: _customer.monthlyFee,
        );

        await _customerService.updateCustomer(updatedCustomer);

        if (mounted) {
          // İşlem başarılı olduğunda güncelle
          setState(() {
            _customer = updatedCustomer;
            _isLoading = false;
            _isEditing = false; // Düzenleme modundan çık
          });

          // Başarı mesajını göster
          ToastHelper.showSuccessToast(
              context, 'Müşteri başarıyla güncellendi');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ToastHelper.showErrorToast(
              context, 'Müşteri güncellenirken hata: $e');
        }
      }
    }
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kişisel bilgiler kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kişisel Bilgiler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Ad'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ad boş olamaz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8.0), // Dikey boşluk
                  TextFormField(
                    controller: _surnameController,
                    decoration: const InputDecoration(labelText: 'Soyad'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Soyad boş olamaz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8.0), // Dikey boşluk
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Telefon'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Telefon boş olamaz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8.0), // Dikey boşluk
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta boş olamaz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8.0), // Dikey boşluk
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(labelText: 'Yaş'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Yaş boş olamaz';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Geçerli bir yaş giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8.0), // Dikey boşluk
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notlar'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Üyelik bilgileri kartı
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
                  DropdownButtonFormField<MembershipStatus>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Üyelik Durumu',
                    ),
                    items: MembershipStatus.values.map((status) {
                      return DropdownMenuItem<MembershipStatus>(
                        value: status,
                        child: Text(_getStatusText(status)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _status = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8.0), // Dikey boşluk
                  DropdownButtonFormField<PaymentType>(
                    value: _paymentType,
                    decoration: const InputDecoration(
                      labelText: 'Ödeme Tipi',
                    ),
                    items: PaymentType.values.map((type) {
                      return DropdownMenuItem<PaymentType>(
                        value: type,
                        child: Text(
                            type == PaymentType.cash ? 'Peşin' : 'Taksitli'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _paymentType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8.0), // Dikey boşluk
                  DropdownButtonFormField<int>(
                    value: _subscriptionMonths,
                    decoration: const InputDecoration(
                      labelText: 'Abonelik Süresi (Ay)',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12,
                            (index) => index + 1) // This generates 1-12 months
                        .map((month) => DropdownMenuItem<int>(
                              value: month,
                              child: Text('$month ay'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        if (value != null) {
                          _subscriptionMonths = value;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Silme onayı diyaloğu
  Future<void> _showDeleteConfirmation() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Müşteri Sil'),
        content: Text(
            '${_customer.name} ${_customer.surname} müşterisini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCustomer();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Müşteri silme işlemi
  Future<void> _deleteCustomer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_customer.id == null) {
        throw Exception('Müşteri ID bulunamadı');
      }

      await _customerService.deleteCustomer(_customer.id!);

      ToastHelper.showSuccessToast(
          context, '${_customer.name} ${_customer.surname} müşterisi silindi');

      // Müşteri listesi sayfasına geri dön
      Navigator.pop(context, true); // Silme işlemi başarılı olduğunu belirt
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ToastHelper.showErrorToast(context, 'Müşteri silinemedi: $e');
    }
  }

  // SMS gönderme metodu
  Future<void> _sendPaymentReminderSms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success =
          await _notificationService.sendPaymentReminderSms(_customer);

      if (success) {
        ToastHelper.showSuccessToast(
            context, 'Ödeme hatırlatma SMS\'i gönderildi.');
      } else {
        ToastHelper.showErrorToast(context,
            'SMS gönderilemedi. Telefon numarası veya izinleri kontrol edin.');
      }
    } catch (e) {
      ToastHelper.showErrorToast(context, 'Hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
