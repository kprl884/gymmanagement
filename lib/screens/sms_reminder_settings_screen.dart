import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import '../services/sms_service.dart';
import '../services/customer_service.dart';
import '../utils/toast_helper.dart';
import '../models/customer.dart';
import 'package:intl/intl.dart';
import '../utils/multiple_click_handler.dart';
import '../screens/sms_test_screen.dart';

class SmsReminderSettingsScreen extends StatefulWidget {
  const SmsReminderSettingsScreen({Key? key}) : super(key: key);

  @override
  _SmsReminderSettingsScreenState createState() =>
      _SmsReminderSettingsScreenState();
}

class _SmsReminderSettingsScreenState extends State<SmsReminderSettingsScreen> {
  final SmsService _smsService = SmsService();
  final CustomerService _customerService = CustomerService();
  bool _isLoading = false;
  List<Customer> _activeCustomers = [];
  Customer? _selectedCustomer;
  List<SmsMessage> _smsMessages = [];

  @override
  void initState() {
    super.initState();
    _loadActiveCustomers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadActiveCustomers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customers = await _customerService.getAllCustomers();
      setState(() {
        _activeCustomers = customers.where((c) => c.isActive).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastHelper.showErrorToast(context, 'Müşteriler yüklenirken hata: $e');
      }
    }
  }

  Future<void> _checkSmsPayments() async {
    if (_selectedCustomer == null) {
      ToastHelper.showWarningToast(context, 'Lütfen bir müşteri seçin');
      return;
    }

    setState(() {
      _isLoading = true;
      _smsMessages = [];
    });

    try {
      // SMS izni kontrol et
      bool hasPermission = await _smsService.checkAndRequestSmsPermission();

      if (!hasPermission) {
        setState(() {
          _isLoading = false;
        });
        ToastHelper.showErrorToast(context, 'SMS okuma izni reddedildi');
        return;
      }

      // Müşteri SMS'lerini al
      var messages =
          await _smsService.getCustomerSmsMessages(_selectedCustomer!);

      // Ödeme ile ilgili SMS'leri filtrele
      var paymentMessages = _smsService.filterPaymentRelatedSms(messages);

      setState(() {
        _smsMessages = paymentMessages;
        _isLoading = false;
      });

      if (paymentMessages.isEmpty) {
        ToastHelper.showInfoToast(context, 'Ödeme ile ilgili SMS bulunamadı');
      } else {
        ToastHelper.showSuccessToast(
            context, '${paymentMessages.length} adet ödeme ilgili SMS bulundu');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ToastHelper.showErrorToast(context, 'SMS kontrolü sırasında hata: $e');
    }
  }

  DateTime? getDateFromSms(SmsMessage sms) {
    if (sms.date == null) return null;

    try {
      // Try to parse it as int directly
      if (sms.date is int) {
        return DateTime.fromMillisecondsSinceEpoch(sms.date as int);
      }

      // Try parsing it as a string to int
      return DateTime.fromMillisecondsSinceEpoch(
          int.parse(sms.date.toString()));
    } catch (e) {
      return null; // Return null if we can't parse the date
    }
  }

  // SMS test butonu işlevi
  Future<void> _sendTestSms() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String testPhone = "05388677487";
      final String testMessage =
          "Bu bir test SMS'idir. Spor salonundan bilgilendirme mesajı.";

      bool success = await _smsService.sendTestSms(testPhone, testMessage);

      if (success) {
        ToastHelper.showSuccessToast(context, 'Test SMS başarıyla gönderildi.');
      } else {
        ToastHelper.showErrorToast(context,
            'SMS gönderilemedi. İzinleri kontrol edin ve tekrar deneyin.');
      }
    } catch (e) {
      ToastHelper.showErrorToast(context, 'SMS gönderilirken hata: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Kontrol'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SMS Ödeme Kontrolü',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Bu ekran, müşterilerinizin SMS yoluyla yaptıkları ödemeleri '
                            'kontrol etmenizi sağlar.',
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<Customer>(
                            decoration: const InputDecoration(
                              labelText: 'Müşteri Seçin',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Müşteri seçin'),
                            value: _selectedCustomer,
                            items: _activeCustomers.map((customer) {
                              return DropdownMenuItem<Customer>(
                                value: customer,
                                child: Text(
                                    '${customer.name} ${customer.surname} (${customer.phone})'),
                              );
                            }).toList(),
                            onChanged: (Customer? value) {
                              setState(() {
                                _selectedCustomer = value;
                                _smsMessages = [];
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SingleClickElevatedButton(
                            onPressed: _checkSmsPayments,
                            child: const Text('SMS Ödemeleri Kontrol Et'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_smsMessages.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ödeme İlgili SMS\'ler',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _smsMessages.length,
                              itemBuilder: (context, index) {
                                final sms = _smsMessages[index];
                                final date = getDateFromSms(sms);
                                final formattedDate = date != null
                                    ? DateFormat('dd.MM.yyyy HH:mm')
                                        .format(date)
                                    : 'Bilinmeyen Tarih';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                        sms.address ?? 'Bilinmeyen Numara'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(formattedDate),
                                        const SizedBox(height: 4),
                                        Text(sms.body ?? 'İçerik yok'),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notlar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Bu özellik, müşterilerin banka ya da ödeme kurumu tarafından '
                            'gönderilen SMS\'lerini analiz ederek ödeme yapmış olabilecekleri '
                            'tespit etmeye çalışır. Kesin sonuç vermeyebilir.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SMS Test',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '05388677487 numarasına test SMS göndermek için aşağıdaki butonu kullanabilirsiniz.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SingleClickElevatedButton(
                                  onPressed: _sendTestSms,
                                  child: const Text('Hızlı Test SMS Gönder'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SingleClickElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const SmsTestScreen()),
                                  );
                                },
                                child: const Icon(Icons.open_in_new),
                              ),
                            ],
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
