import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();

  factory CrashlyticsService() {
    return _instance;
  }

  CrashlyticsService._internal();

  // Initialize Crashlytics
  Future<void> initialize() async {
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    }
  }

  // Log error to Crashlytics
  void recordError(dynamic exception, StackTrace? stack, {bool fatal = false}) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.recordError(
        exception,
        stack,
        fatal: fatal,
      );
    }
  }

  // Log custom keys for better debugging
  void setCustomKey(String key, dynamic value) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    }
  }

  // Log user identifier for better user tracking
  void setUserIdentifier(String userId) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);
    }
  }

  // Log message to Crashlytics
  void log(String message) {
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  // Force a crash for testing
  void forceCrash() {
    FirebaseCrashlytics.instance.crash();
  }
}
