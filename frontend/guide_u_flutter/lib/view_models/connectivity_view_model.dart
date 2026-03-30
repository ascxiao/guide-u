import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityViewModel extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool get isOnline => _isOnline;
  late final StreamSubscription<dynamic> _subscription;

  ConnectivityViewModel() {
    _init();
  }

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final online = _isOnlineFromConnectivityResult(result);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });

    _connectivity.checkConnectivity().then((result) {
      final online = _isOnlineFromConnectivityResult(result);
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  bool _isOnlineFromConnectivityResult(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }

    if (result is List<ConnectivityResult>) {
      return result.any((entry) => entry != ConnectivityResult.none);
    }

    return true;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
