import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;

  AuthService() {
    _loadToken();
  }

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _isAuthenticated = _token != null && _token!.isNotEmpty;
    notifyListeners();
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> checkTokenValidity() async {
    if (_token == null) return false;
    return true;
  }
}