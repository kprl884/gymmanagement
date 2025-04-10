import 'package:flutter/material.dart';
import '../services/session_timeout_service.dart';

/// Sayfa geçişlerini izleyen ve kullanıcı aktivitesi olarak işleyen observer
class ActivityRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  final SessionTimeoutService _sessionService;

  ActivityRouteObserver(this._sessionService);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateActivity();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateActivity();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _updateActivity();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _updateActivity();
  }

  /// Route değişikliğinde kullanıcı aktivitesini günceller
  void _updateActivity() {
    _sessionService.userActivity();
  }
}
