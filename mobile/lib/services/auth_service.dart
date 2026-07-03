import 'package:flutter/material.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  static final _storage = <String, dynamic>{};

  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _property;

  String? get token    => _token;
  Map<String, dynamic>? get user     => _user;
  Map<String, dynamic>? get property => _property;
  bool   get isLoggedIn => _token != null;

  Future<void> init() async {
    _token    = _storage['token'] as String?;
    final u   = _storage['user'];
    final p   = _storage['property'];
    if (u != null) {
      if (u is String) {
        _user = jsonDecode(u) as Map<String, dynamic>;
      } else {
        _user = Map<String, dynamic>.from(u as Map);
      }
    }
    if (p != null) {
      if (p is String) {
        _property = jsonDecode(p) as Map<String, dynamic>;
      } else {
        _property = Map<String, dynamic>.from(p as Map);
      }
    }
    notifyListeners();
  }

  Future<void> saveSession(String token, Map<String, dynamic> user,
      Map<String, dynamic>? property) async {
    _token    = token;
    _user     = user;
    _property = property;
    _storage['token']    = token;
    _storage['user']     = jsonEncode(user);
    if (property != null)
      _storage['property'] = jsonEncode(property);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null; _user = null; _property = null;
    _storage.clear();
    notifyListeners();
  }

  Future<void> updateProperty(Map<String, dynamic> property) async {
    _property = property;
    _storage['property'] = jsonEncode(property);
    notifyListeners();
  }
}
