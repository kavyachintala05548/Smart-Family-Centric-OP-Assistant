import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _envUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String defaultAndroidBaseUrl = _envUrl;
  static String baseUrl = _envUrl;
  static String? token;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');
    } catch (_) {}
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');
      return token;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveToken(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', value);
      token = value;
    } catch (_) {}
  }

  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      token = null;
    } catch (_) {}
  }

  static Future<String> getBaseUrl() async => baseUrl;

  static Future<void> saveBaseUrl(String url) async {
    baseUrl = url;
  }

  static Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  static dynamic _handle(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    dynamic data;
    try {
      data = jsonDecode(body);
    } catch (_) {
      data = {'detail': body};
    }
    if (response.statusCode >= 400) {
      final message = data is Map && data.containsKey('detail')
          ? data['detail']
          : 'Request failed with status ${response.statusCode}';
      throw Exception(message is List ? message.toString() : message);
    }
    return data;
  }

  static Future<dynamic> _send(String label, Future<http.Response> Function() request) async {
    if (token == null) await init();
    http.Response response;
    try {
      debugPrint('API $label -> $baseUrl');
      response = await request().timeout(const Duration(seconds: 20));
      debugPrint('API $label <- ${response.statusCode}');
    } catch (e) {
      debugPrint('API ERROR TYPE: ${e.runtimeType}');
      debugPrint('API ERROR DETAIL: $e');
      if (e is TimeoutException) {
        throw Exception('Server took too long to respond (timeout).');
      }
      throw Exception('Cannot connect to the server at $baseUrl ($e)');
    }
    return _handle(response);
  }

  static Future<dynamic> get(String path) =>
      _send('GET $path', () => http.get(Uri.parse('$baseUrl$path'), headers: _headers()));

  static Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send('POST $path', () => http.post(Uri.parse('$baseUrl$path'),
          headers: _headers(), body: jsonEncode(body)));

  static Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send('PUT $path', () => http.put(Uri.parse('$baseUrl$path'),
          headers: _headers(), body: jsonEncode(body)));

  static Future<dynamic> delete(String path) =>
      _send('DELETE $path', () => http.delete(Uri.parse('$baseUrl$path'), headers: _headers()));
}