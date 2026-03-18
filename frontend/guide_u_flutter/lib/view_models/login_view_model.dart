import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginViewModel extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  bool _loggedIn = false;

  bool get loading => _loading;
  String? get error => _error;
  bool get loggedIn => _loggedIn;

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
      // After OAuth, user is redirected back. Listen for session changes elsewhere.
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return;
    }
    _setLoading(false);
  }

  void checkSession() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _loggedIn = true;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
