import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/session_timeout_service.dart';

/// Kullanıcı aktivitesini izleyen wrapper widget
class ActivityDetector extends StatefulWidget {
  final Widget child;

  const ActivityDetector({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ActivityDetector> createState() => _ActivityDetectorState();
}

class _ActivityDetectorState extends State<ActivityDetector>
    with WidgetsBindingObserver {
  final SessionTimeoutService _sessionService = SessionTimeoutService();
  StreamSubscription<dynamic>? _sizeChangeSub;
  final ValueNotifier<Size> _screenSize = ValueNotifier<Size>(Size.zero);

  @override
  void initState() {
    super.initState();
    // Uygulama yaşam döngüsü değişikliklerini dinle
    WidgetsBinding.instance.addObserver(this);

    if (kIsWeb) {
      // Web için ekran boyutu değişimlerini dinle
      _listenToScreenSizeChanges();
    }
  }

  @override
  void dispose() {
    // Observer'ı kaldır
    WidgetsBinding.instance.removeObserver(this);
    _sizeChangeSub?.cancel();
    _screenSize.dispose();
    super.dispose();
  }

  /// Web platformunda ekran boyutu değişikliklerini dinler
  void _listenToScreenSizeChanges() {
    // İlk boyutu al
    _updateScreenSize();

    // Ekran boyutu değişikliklerini dinle
    // ignore: undefined_prefixed_name
    final mediaQueryChanges = WidgetsBinding.instance.window.onMetricsChanged;

    _sizeChangeSub =
        Stream.periodic(const Duration(seconds: 1), (_) => mediaQueryChanges)
            .listen((_) {
      final newSize = MediaQuery.of(context).size;
      if (_screenSize.value != newSize) {
        _screenSize.value = newSize;
        _updateActivity();
      }
    });
  }

  /// Mevcut ekran boyutunu kaydeder
  void _updateScreenSize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _screenSize.value = MediaQuery.of(context).size;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama ön plana çıktığında oturum kontrolü yap
    if (state == AppLifecycleState.resumed) {
      _sessionService.checkSession();
      _updateActivity();
    } else if (state == AppLifecycleState.paused) {
      // Uygulama arka plana alındığında aktivite zamanını güncelle
      _updateActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listener ile kullanıcı etkileşimlerini yakalıyoruz
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _updateActivity();
        return false;
      },
      child: Listener(
        onPointerDown: (_) => _updateActivity(),
        onPointerMove: (_) => _updateActivity(),
        onPointerUp: (_) => _updateActivity(),
        // GestureDetector ile ekstra etkileşimleri yakalıyoruz
        child: GestureDetector(
          onTap: _updateActivity,
          onScaleUpdate: (_) => _updateActivity(),
          // Focus node ile klavye/giriş etkileşimlerini izliyoruz
          child: Focus(
            onKeyEvent: (_, __) {
              _updateActivity();
              return KeyEventResult.ignored;
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }

  // Kullanıcı aktivitesini güncellemek için yardımcı metod
  void _updateActivity() {
    _sessionService.userActivity();
  }
}
