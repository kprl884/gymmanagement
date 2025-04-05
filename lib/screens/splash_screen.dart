import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen - initState çalıştı');

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Yönlendirmeyi düzelttik
    Future.delayed(const Duration(seconds: 3), () {
      debugPrint('SplashScreen - Yönlendirme başlıyor');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home_screen');
      }
    });
  }

  @override
  void dispose() {
    debugPrint('SplashScreen - dispose çalıştı');
    _controller.dispose();
    super.dispose();
  }

  Widget _buildLottieAnimation() {
    debugPrint('SplashScreen - Lottie animasyonu oluşturuluyor');
    try {
      return Lottie.asset(
        'assets/animations/gymanimation.json',
        controller: _controller,
        onLoaded: (composition) {
          debugPrint('Lottie animasyonu yüklendi');
          _controller.forward();
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Lottie yükleme hatası: $error');
          return const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          );
        },
        width: 200,
        height: 200,
      );
    } catch (e) {
      debugPrint('Lottie exception: $e');
      return const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SplashScreen - build çalıştı');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLottieAnimation(),
            const SizedBox(height: 20),
            const Text(
              'Gym Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
