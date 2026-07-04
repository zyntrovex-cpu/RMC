import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  bool isLoggedIn = false;
  bool isLoading = true;
  String? userToken;
  String? errorMessage;

  AuthService() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    userToken = prefs.getString('userToken');
    isLoggedIn = userToken != null;
    isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String mobile, String password) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final response = await ApiService.instance.login(mobile, password);

      if (response['success'] == true && response['data'] != null && response['data']['token'] != null) {
        userToken = response['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userToken', userToken!);

        ApiService.instance.setToken(userToken!);
        isLoggedIn = true;
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        errorMessage = response['message'] ?? 'Login failed';
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userToken');
      userToken = null;
      isLoggedIn = false;
      ApiService.instance.clearToken();
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
    }
  }
}
