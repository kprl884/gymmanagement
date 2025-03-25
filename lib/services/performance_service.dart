import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'log_service.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  final FirebasePerformance _performance = FirebasePerformance.instance;
  final LogService _logService = LogService();

  factory PerformanceService() {
    return _instance;
  }

  PerformanceService._internal();

  // Bir işlemin süresini ölçmek için
  Future<T> measureOperation<T>({
    required String name,
    required Future<T> Function() operation,
    Map<String, String>? attributes,
  }) async {
    final Trace trace = _performance.newTrace(name);

    if (attributes != null) {
      attributes.forEach((key, value) {
        trace.putAttribute(key, value);
      });
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    await trace.start();

    try {
      final result = await operation();

      stopwatch.stop();
      await trace.stop();

      final duration = stopwatch.elapsedMilliseconds;

      // 1 saniyeden uzun süren işlemleri logla
      if (duration > 1000) {
        _logService.logWarning(
            'Performance', 'Uzun süren işlem: $name - $duration ms');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      await trace.stop();

      trace.putAttribute('error', e.toString());
      rethrow;
    }
  }

  // Widget build süresini ölçmek için
  void measureBuildTime(String widgetName, int milliseconds) {
    if (milliseconds > 16) {
      // 60 FPS için bir frame süresi
      _logService.logWarning(
          'UI Performance', '$widgetName build süresi: $milliseconds ms');
    }
  }
}
