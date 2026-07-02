import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override String toString() => message;
}

class ApiService extends ChangeNotifier {
  // ▼▼▼ CHANGE THIS TO YOUR PC's IP (run "ipconfig" in cmd, find IPv4 Address) ▼▼▼
  static const _pcIp = '192.168.56.1';
  // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
  static const _base = 'http://$_pcIp/RMC/RMC/backend';

  String? _token;

  void setToken(String? t) { _token = t; }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> get(String path) async {
    final r = await http.get(Uri.parse('$_base$path'), headers: _headers);
    return _parse(r);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final r = await http.post(Uri.parse('$_base$path'),
        headers: _headers, body: jsonEncode(body));
    return _parse(r);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final r = await http.put(Uri.parse('$_base$path'),
        headers: _headers, body: jsonEncode(body));
    return _parse(r);
  }

  Map<String, dynamic> _parse(http.Response r) {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    throw ApiException(body['message'] ?? 'Server error', r.statusCode);
  }

  // Auth
  Future<Map<String, dynamic>> login(String mobile, String password) =>
      post('/resident-auth?action=login', {'mobile': mobile, 'password': password});

  Future<Map<String, dynamic>> checkPlot(String sector, String plotNo) =>
      post('/resident-auth?action=check-plot', {'sector_code': sector, 'plot_no': plotNo});

  Future<Map<String, dynamic>> sendOtp(String mobile, int propertyId) =>
      post('/resident-auth?action=send-otp', {'mobile': mobile, 'property_id': propertyId});

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) =>
      post('/resident-auth?action=register', data);

  Future<Map<String, dynamic>> forgotPassword(String mobile) =>
      post('/resident-auth?action=forgot-password', {'mobile': mobile});

  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> data) =>
      post('/resident-auth?action=reset-password', data);

  // Resident
  Future<Map<String, dynamic>> getDashboard() => get('/resident?action=dashboard');
  Future<Map<String, dynamic>> getProfile()   => get('/resident?action=profile');

  // Challans
  Future<Map<String, dynamic>> getChallans() => get('/resident?action=my-challans');

  // Visitor passes
  Future<Map<String, dynamic>> getVisitorPasses() => get('/resident?action=my-visitor-passes');
  Future<Map<String, dynamic>> createVisitorPass(Map<String, dynamic> data) =>
      post('/resident?action=create-visitor-pass', data);
  Future<Map<String, dynamic>> cancelVisitorPass(int id) =>
      post('/resident?action=cancel-visitor-pass', {'pass_id': id});

  // NOC
  Future<Map<String, dynamic>> getNocRequests() => get('/resident?action=my-noc-requests');
  Future<Map<String, dynamic>> requestNoc(String purpose) =>
      post('/resident?action=request-noc', {'purpose': purpose});

  // Complaints
  Future<Map<String, dynamic>> getComplaints() => get('/resident?action=my-complaints');
  Future<Map<String, dynamic>> submitComplaint(Map<String, dynamic> data) =>
      post('/resident?action=submit-complaint', data);
}
