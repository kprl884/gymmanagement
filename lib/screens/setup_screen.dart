import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../utils/toast_helper.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;

  Future<void> _setupAdmin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.ensureAdminExists();
      ToastHelper.showSuccessToast(context, 'Admin hesabı oluşturuldu');

      // Ana ekrana yönlendir
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ToastHelper.showErrorToast(context, 'Admin hesabı oluşturulamadı: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uygulama Kurulumu'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Uygulamayı kullanmaya başlamak için admin hesabı oluşturun',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _setupAdmin,
                    child: const Text('Admin Hesabı Oluştur'),
                  ),
                ],
              ),
      ),
    );
  }
}
