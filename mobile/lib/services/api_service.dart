import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  static const String baseUrl = 'http://192.168.1.5/RMC/RMC/backend';

  String? _token;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  static ApiService get instance => _instance;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> login(String mobile, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resident-auth?action=login'),
        headers: _getHeaders(),
        body: jsonEncode({'mobile': mobile, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'message': 'Login failed: ${response.statusCode}'};
      }
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=dashboard'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'message': 'Failed to load dashboard'};
      }
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=profile'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'message': 'Failed to load profile'};
      }
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  Future<List<dynamic>> getChallans() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=my-challans'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getVisitorPasses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=my-visitor-passes'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createVisitorPass(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resident?action=create-visitor-pass'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'message': 'Failed to create visitor pass'};
      }
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  Future<List<dynamic>> getComplaints() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=my-complaints'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> submitComplaint(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resident?action=submit-complaint'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'message': 'Failed to submit complaint'};
      }
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }

  Future<List<dynamic>> getNocs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=my-noc-requests'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> requestNoc(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/resident?action=request-noc'),
        headers: _getHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'message': 'Failed to request NOC'};
      }
    } catch (e) {
      return {'message': 'Connection error: $e'};
    }
  }
}
