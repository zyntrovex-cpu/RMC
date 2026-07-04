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
        final decoded = jsonDecode(response.body);
        return decoded ?? {'success': false, 'message': 'Invalid response'};
      } else {
        return {'success': false, 'message': 'Login failed: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=dashboard'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded ?? {'success': false, 'message': 'Invalid response'};
      } else {
        return {'success': false, 'message': 'Failed to load dashboard'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=profile'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded ?? {'success': false, 'message': 'Invalid response'};
      } else {
        return {'success': false, 'message': 'Failed to load profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getChallans() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=my-challans'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded ?? {'success': false, 'message': 'Invalid response', 'data': []};
      } else {
        return {'success': false, 'message': 'Failed to load challans', 'data': []};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'data': []};
    }
  }

  Future<Map<String, dynamic>> getVisitorPasses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=my-visitor-passes'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded ?? {'success': false, 'message': 'Invalid response', 'data': []};
      } else {
        return {'success': false, 'message': 'Failed to load visitor passes', 'data': []};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'data': []};
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
        final decoded = jsonDecode(response.body);
        return decoded ?? {'success': false, 'message': 'Invalid response'};
      } else {
        return {'success': false, 'message': 'Failed to create visitor pass'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getComplaints() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=my-complaints'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded ?? {'success': false, 'message': 'Invalid response', 'data': []};
      } else {
        return {'success': false, 'message': 'Failed to load complaints', 'data': []};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'data': []};
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
        final decoded = jsonDecode(response.body);
        return decoded ?? {'success': false, 'message': 'Invalid response'};
      } else {
        return {'success': false, 'message': 'Failed to submit complaint'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getNocs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/resident?action=my-noc-requests'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded ?? {'success': false, 'message': 'Invalid response', 'data': []};
      } else {
        return {'success': false, 'message': 'Failed to load NOC requests', 'data': []};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e', 'data': []};
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
        final decoded = jsonDecode(response.body);
        return decoded ?? {'success': false, 'message': 'Invalid response'};
      } else {
        return {'success': false, 'message': 'Failed to request NOC'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
