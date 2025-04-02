import 'package:flutter/material.dart';
import '../services/sms_service.dart';
import '../utils/toast_helper.dart';
import '../utils/multiple_click_handler.dart';

class SmsTestScreen extends StatefulWidget {
  const SmsTestScreen({Key? key}) : super(key: key);

  @override
  _SmsTestScreenState createState() => _SmsTestScreenState();
}

class _SmsTestScreenState extends State<SmsTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  final SmsService _smsService = SmsService();

  @override
  void initState() {
    super.initState();
    _phoneController.text = "05388677487"; // Pre-fill for testing
    _messageController.text =
        "Bu bir test SMS'idir. Spor salonundan bilgilendirme mesajı.";
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendSms() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _smsService.sendTestSms(
          _phoneController.text, _messageController.text);

      if (success) {
        ToastHelper.showSuccessToast(context, 'SMS gönderme işlemi başlatıldı');
      } else {
        ToastHelper.showErrorToast(
            context, 'SMS gönderilemedi. İzinleri kontrol edin.');
      }
    } catch (e) {
      ToastHelper.showErrorToast(context, 'Hata: $e');
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
        title: const Text('SMS Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası',
                  hintText: 'örn: 05XX XXX XX XX',
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
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Mesaj',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir mesaj girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SingleClickElevatedButton(
                onPressed: _isLoading ? () {} : () => _sendSms(),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SMS GÖNDER'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Not: SMS gönderimi için izinlerin verilmiş olması gerekir.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
