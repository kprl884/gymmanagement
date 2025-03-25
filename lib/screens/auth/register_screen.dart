import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth User sınıfı için import
import 'dart:async'; // TimeoutException için
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../services/log_service.dart';
import '../../utils/toast_helper.dart';
import '../../config/app_config.dart';
import '../../services/connectivity_service.dart';
import 'login_screen.dart';
import 'dart:io';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final UserService _userService = UserService();
  final LogService _logService = LogService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _logService.logError(
          'RegisterScreen', 'Bağlantı kontrolü hatası: $e', null);
      return false;
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifreler eşleşmiyor'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Basitleştirilmiş bağlantı kontrolü
      final isConnected = await _checkConnection();

      if (!isConnected) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ToastHelper.showErrorToast(context,
            'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edip tekrar deneyin.');
        return;
      }

      try {
        _logService.logInfo('RegisterScreen', 'Kayıt işlemi başlatılıyor...');

        // Kayıt işlemini çalıştır
        final userCredential = await _userService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        _logService.logInfo('RegisterScreen', 'Kayıt işlemi başarılı');

        if (!mounted) return;

        ToastHelper.showSuccessToast(
            context, 'Kayıt başarılı! Ana sayfaya yönlendiriliyorsunuz.');

        // Kayıt başarılı, kullanıcıyı ana sayfaya yönlendir
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } catch (e, stackTrace) {
        _logService.logError('RegisterScreen', e, stackTrace);

        if (!mounted) return;

        String errorMessage = 'Kayıt işlemi sırasında bir hata oluştu';

        if (e is TimeoutException) {
          errorMessage = e.message ?? 'Kayıt işlemi zaman aşımına uğradı';
        } else if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage = 'Bu e-posta adresi zaten kullanımda';
              break;
            case 'invalid-email':
              errorMessage = 'Geçersiz e-posta adresi';
              break;
            case 'weak-password':
              errorMessage = 'Şifre çok zayıf';
              break;
            case 'operation-not-allowed':
              errorMessage = 'E-posta/şifre girişi etkin değil';
              break;
            default:
              errorMessage = 'Hata kodu: ${e.code}';
              break;
          }
        } else if (e is Exception) {
          // Diğer Exception'ların mesajlarını doğrudan kullan
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }

        ToastHelper.showErrorToast(context, errorMessage);
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
        title: const Text('Kayıt Ol'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
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
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen adınızı ve soyadınızı girin';
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
                          return 'Lütfen e-posta adresinizi girin';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Geçerli bir e-posta adresi girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifrenizi girin';
                        }
                        if (value.length < 6) {
                          return 'Şifre en az 6 karakter olmalıdır';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Şifre Tekrar',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Lütfen şifrenizi tekrar girin';
                        }
                        if (value != _passwordController.text) {
                          return 'Şifreler eşleşmiyor';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Kayıt Ol',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Zaten hesabınız var mı?'),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Giriş Yap'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
