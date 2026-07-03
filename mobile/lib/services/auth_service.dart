import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  static final _storage = <String, String>{};

  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _property;

  String? get token    => _token;
  Map<String, dynamic>? get user     => _user;
  Map<String, dynamic>? get property => _property;
  bool   get isLoggedIn => _token != null;

  Future<void> init() async {
    _token    = _storage['token'];
    final u   = _storage['user'];
    final p   = _storage['property'];
    if (u != null) _user     = Map<String, dynamic>.from(u as Map);
    if (p != null) _property = Map<String, dynamic>.from(p as Map);
    notifyListeners();
  }

  Future<void> saveSession(String token, Map<String, dynamic> user,
      Map<String, dynamic>? property) async {
    _token    = token;
    _user     = user;
    _property = property;
    _storage['token']    = token;
    _storage['user']     = user.toString();
    if (property != null)
      _storage['property'] = property.toString();
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null; _user = null; _property = null;
    _storage.clear();
    notifyListeners();
  }

  Future<void> updateProperty(Map<String, dynamic> property) async {
    _property = property;
    _storage['property'] = property.toString();
    notifyListeners();
  }
}
