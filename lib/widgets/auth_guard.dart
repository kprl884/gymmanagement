import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/session_timeout_service.dart';
import '../services/user_service.dart';
import '../utils/navigation.dart';

/// Kimlik doğrulaması gerektiren ekranlar için koruma widget'ı
class AuthGuard extends StatefulWidget {
  final Widget child;
  final bool requireAuth;
  final String redirectRoute;

  const AuthGuard({
    Key? key,
    required this.child,
    this.requireAuth = true,
    this.redirectRoute = '/login',
  }) : super(key: key);

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  final UserService _userService = UserService();
  final SessionTimeoutService _sessionService = SessionTimeoutService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  /// Kullanıcının oturum durumunu ve oturum zaman aşımını kontrol eder
  Future<void> _checkAuth() async {
    final isAuthenticated = _userService.currentUser != null;
    final needsAuth = widget.requireAuth;

    if (needsAuth && !isAuthenticated) {
      // Kullanıcının giriş yapması gerekiyor, login sayfasına yönlendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          widget.redirectRoute,
          (route) => false,
        );
      });
    } else if (!needsAuth && isAuthenticated) {
      // Kullanıcı zaten giriş yapmış, ana sayfaya yönlendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home_screen',
          (route) => false,
        );
      });
    } else if (needsAuth && isAuthenticated) {
      // Kullanıcı giriş yapmış ve korumalı içeriğe erişiyor, oturum zaman aşımını kontrol et
      await _sessionService.checkSession();
    }

    // Widget durumunu güncelle
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yükleme durumunda bekletme görüntüsü
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Kimlik doğrulama gerektiren ekranlarda oturum durumunu sürekli kontrol et
    if (widget.requireAuth) {
      return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            // Kullanıcı oturumu kapattıysa, login sayfasına yönlendir
            WidgetsBinding.instance.addPostFrameCallback((_) {
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                widget.redirectRoute,
                (route) => false,
              );
            });

            return const Scaffold(
              body: Center(
                child: Text('Oturumunuz sonlandı. Yönlendiriliyorsunuz...'),
              ),
            );
          }

          // Kimlik doğrulaması geçerli, içeriği göster
          return widget.child;
        },
      );
    }

    // Kimlik doğrulama gerektirmeyen içerikler için normal görüntüleme
    return widget.child;
  }
}
