import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'log_service.dart';

enum ConnectivityStatus {
  online,
  offline,
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final LogService _logService = LogService();

  // Bağlantı durumu stream'i
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  ConnectivityStatus _lastStatus = ConnectivityStatus.online;
  ConnectivityStatus get lastStatus => _lastStatus;

  Timer? _periodicTimer;

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal() {
    // Başlangıçta bağlantı durumunu kontrol et
    _init();
  }

  Future<void> _init() async {
    try {
      // İlk bağlantı durumunu kontrol et
      await _checkConnectivity();

      // Periyodik olarak bağlantıyı kontrol et
      _periodicTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _checkConnectivity();
      });
    } catch (e) {
      _logService.logError(
          'ConnectivityService', 'Bağlantı durumu başlatılamadı: $e', null);
      // Varsayılan olarak çevrimiçi kabul et
      _lastStatus = ConnectivityStatus.online;
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final status = result.isNotEmpty && result[0].rawAddress.isNotEmpty
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;

      if (status != _lastStatus) {
        _lastStatus = status;
        _statusController.add(status);

        _logService.logInfo('Connectivity',
            'Bağlantı durumu değişti: ${status == ConnectivityStatus.online ? "Çevrimiçi" : "Çevrimdışı"}');
      }
    } on SocketException catch (_) {
      if (_lastStatus != ConnectivityStatus.offline) {
        _lastStatus = ConnectivityStatus.offline;
        _statusController.add(ConnectivityStatus.offline);

        _logService.logInfo(
            'Connectivity', 'Bağlantı durumu değişti: Çevrimdışı');
      }
    } catch (e) {
      _logService.logError(
          'ConnectivityService', 'Bağlantı kontrolü hatası: $e', null);
    }
  }

  // Bağlantı durumunu gösteren banner widget'ı
  static Widget buildConnectivityBanner(BuildContext context) {
    final connectivityService = ConnectivityService();

    return StreamBuilder<ConnectivityStatus>(
      stream: connectivityService.statusStream,
      builder: (context, snapshot) {
        if (snapshot.data == ConnectivityStatus.offline) {
          return Container(
            width: double.infinity,
            color: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Text(
              'İnternet bağlantısı yok. Bazı özellikler sınırlı olabilir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void dispose() {
    _periodicTimer?.cancel();
    _statusController.close();
  }

  // Ağ bağlantısını kontrol eden yeni metot
  Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      _logService.logError(
          'ConnectivityService', 'Bağlantı kontrolü hatası: $e', null);
      return false;
    }
  }
}
