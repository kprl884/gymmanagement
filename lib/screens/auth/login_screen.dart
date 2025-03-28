import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import '../../services/log_service.dart';
import '../../utils/toast_helper.dart';
import 'register_screen.dart';
import '../home_screen.dart';
import '../../services/connectivity_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final UserService _userService = UserService();
  final LogService _logService = LogService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        _logService.logInfo('LoginScreen', 'Giriş işlemi başlatılıyor...');

        await _userService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        // Kullanıcı bilgilerini kontrol et
        final user = await _userService.getCurrentUserData();

        if (!mounted) return;

        if (user == null || !user.isActive) {
          // Kullanıcı pasif ise oturumu kapat
          await _userService.signOut();

          _logService.logWarning('LoginScreen',
              'Pasif hesap girişi denemesi: ${_emailController.text}');
          ToastHelper.showErrorToast(context,
              'Hesabınız pasif durumda. Lütfen yönetici ile iletişime geçin.');
        } else {
          _logService.logInfo('LoginScreen', 'Giriş başarılı: ${user.email}');

          // Loading state'i kapatmadan önce navigasyon işlemini başlat
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const HomeScreen(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
          return; // Navigasyon sonrası işlemleri durdur
        }
      } catch (e, stackTrace) {
        _logService.logError('LoginScreen', 'Giriş hatası: $e', stackTrace);

        if (!mounted) return;

        String errorMessage = _getLoginErrorMessage(e);
        ToastHelper.showErrorToast(context, errorMessage);
      } finally {
        // Sadece navigasyon yapılmadıysa loading state'i kapat
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _getLoginErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
        case 'wrong-password':
          return 'Hatalı şifre';
        case 'invalid-email':
          return 'Geçersiz e-posta adresi';
        case 'user-disabled':
          return 'Bu hesap devre dışı bırakılmış';
        case 'too-many-requests':
          return 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin.';
        default:
          return 'Hata kodu: ${error.code}';
      }
    }
    return 'Giriş yapılırken bir hata oluştu: $error';
  }

  void _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen e-posta adresinizi girin'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.sendPasswordResetEmail(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Şifre sıfırlama bağlantısı e-posta adresinize gönderildi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      String errorMessage =
          'Şifre sıfırlama bağlantısı gönderilirken bir hata oluştu';

      if (e.toString().contains('user-not-found')) {
        errorMessage = 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Geçersiz e-posta adresi';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Spor Salonu Yönetimi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
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
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text('Şifremi Unuttum'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Hesabınız yok mu?'),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('Kayıt Ol'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            await _userService.signInAnonymously();

                            if (!mounted) return;

                            Navigator.of(context).pushReplacementNamed('/home');
                          } catch (e) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Anonim giriş hatası: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                        ),
                        child: const Text('Anonim Giriş (Test)'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
