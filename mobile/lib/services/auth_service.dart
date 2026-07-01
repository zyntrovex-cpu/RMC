import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _property;

  String? get token    => _token;
  Map<String, dynamic>? get user     => _user;
  Map<String, dynamic>? get property => _property;
  bool   get isLoggedIn => _token != null;

  Future<void> init() async {
    _token    = await _storage.read(key: 'token');
    final u   = await _storage.read(key: 'user');
    final p   = await _storage.read(key: 'property');
    if (u != null) _user     = jsonDecode(u);
    if (p != null) _property = jsonDecode(p);
    notifyListeners();
  }

  Future<void> saveSession(String token, Map<String, dynamic> user,
      Map<String, dynamic>? property) async {
    _token    = token;
    _user     = user;
    _property = property;
    await _storage.write(key: 'token',    value: token);
    await _storage.write(key: 'user',     value: jsonEncode(user));
    if (property != null)
      await _storage.write(key: 'property', value: jsonEncode(property));
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null; _user = null; _property = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  Future<void> updateProperty(Map<String, dynamic> property) async {
    _property = property;
    await _storage.write(key: 'property', value: jsonEncode(property));
    notifyListeners();
  }
}
