import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/student.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  static String? _token;

  static VoidCallback? onUnauthorized;

  static void setToken(String? token) => _token = token;
  static String? get token => _token;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static void logout() {
    _token = null;
    onUnauthorized?.call();
  }

  static Exception _exceptionFromResponse(http.Response res) {
    try {
      final body = res.body.isEmpty ? null : jsonDecode(res.body);
      if (body is Map && body['error'] is Map) {
        final msg = (body['error'] as Map)['message'];
        if (msg is String && msg.trim().isNotEmpty) return Exception(msg);
      }
      if (body is Map && body['detail'] is String) {
        return Exception(body['detail']);
      }
      if (body is Map && body['message'] is String) {
        return Exception(body['message']);
      }
    } catch (_) {}
    return Exception('Errore di rete (${res.statusCode})');
  }

  static Future<http.Response> _request(
    Future<http.Response> Function() fn,
  ) async {
    final res = await fn();
    if (res.statusCode == 401) {
      logout();
      throw Exception('Sessione scaduta, accedi di nuovo');
    }
    return res;
  }

  // --- AUTH ---
  static Future<String> login(String email, String password) async {
    final res = await _request(
      () => http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    final data = jsonDecode(res.body);
    return (data as Map)['token'] as String;
  }

  static Future<String> register(String email, String password) async {
    final res = await _request(
      () => http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    final data = jsonDecode(res.body);
    return (data as Map)['token'] as String;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await _request(
      () => http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    final data = jsonDecode(res.body);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> updateProfile(List<String> subjects, String style) async {
    final res = await _request(
      () => http.put(
        Uri.parse('$baseUrl/me/profile'),
        headers: _headers,
        body: jsonEncode({'study_subjects': subjects, 'learning_style': style}),
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
  }

  // --- SWIPE ---
  static Future<List<Student>> getRecommendations() async {
    final res = await _request(
      () => http.post(
        Uri.parse('$baseUrl/matches/recommendations'),
        headers: _headers,
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    final List data = jsonDecode(res.body);
    return data.map((e) => Student.fromJson(e)).toList();
  }

  static Future<bool> swipe(String targetId, bool like) async {
    final res = await _request(
      () => http.post(
        Uri.parse('$baseUrl/swipe'),
        headers: _headers,
        body: jsonEncode({
          'target_user_id': targetId,
          'direction': like ? 'like' : 'dislike',
        }),
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    final data = jsonDecode(res.body);
    return (data as Map)['is_match'] == true;
  }

  // --- MATCHES ---
  static Future<List<Map<String, dynamic>>> getMyMatches() async {
    final res = await _request(
      () => http.get(
        Uri.parse('$baseUrl/matches/me'),
        headers: _headers,
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (data is Map && data['matches'] is List) {
      return (data['matches'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  // --- MAPS ---
  static Future<List<Map<String, dynamic>>> getNearbyPlaces(
    double lat,
    double lon, {
    int radiusM = 1500,
  }) async {
    final res = await _request(
      () => http.post(
        Uri.parse('$baseUrl/maps/nearby'),
        headers: _headers,
        body: jsonEncode({'lat': lat, 'lon': lon, 'radius_m': radiusM}),
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    final data = jsonDecode(res.body);
    if (data is Map && data['places'] is List) {
      return List<Map<String, dynamic>>.from(data['places'] as List);
    }
    if (data is List) return List<Map<String, dynamic>>.from(data);
    return <Map<String, dynamic>>[];
  }
}