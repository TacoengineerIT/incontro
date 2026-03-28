import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/place.dart';
import '../models/student.dart';
import '../models/user_profile.dart';

class ApiService {
  static const String baseUrl = 'https://incontrobackend-production.up.railway.app';
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

  // --- POSIZIONE ---
  static Future<void> updateLocation(double lat, double lon) async {
    await http.put(
      Uri.parse('$baseUrl/me/location'),
      headers: _headers,
      body: jsonEncode({'lat': lat, 'lon': lon}),
    );
  }

  // --- SESSIONE STUDIO ---
  static Future<void> startStudySession(
      String locationName, double lat, double lon) async {
    await http.post(
      Uri.parse('$baseUrl/me/study-session'),
      headers: _headers,
      body: jsonEncode({
        'location_name': locationName,
        'lat': lat,
        'lon': lon,
      }),
    );
  }

  static Future<void> stopStudySession() async {
    await http.delete(
      Uri.parse('$baseUrl/me/study-session'),
      headers: _headers,
    );
  }

  // --- USERNAME ---
  static Future<UserProfile> updateUsername(String username) async {
    final res = await _request(
      () => http.put(
        Uri.parse('$baseUrl/me/username'),
        headers: _headers,
        body: jsonEncode({'username': username}),
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<List<UserProfile>> searchUsers(String query) async {
    final uri = Uri.parse('$baseUrl/users/search')
        .replace(queryParameters: {'q': query});
    final res = await _request(() => http.get(uri, headers: _headers));
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    final data = jsonDecode(res.body) as List;
    return data.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<UserProfile> getUserByUsername(String username) async {
    final res = await _request(
      () => http.get(
        Uri.parse('$baseUrl/users/$username'),
        headers: _headers,
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // --- AVATAR ---
  static Future<void> updateAvatar(String base64Image) async {
    final res = await _request(
      () => http.put(
        Uri.parse('$baseUrl/me/avatar'),
        headers: _headers,
        body: jsonEncode({'avatar_base64': base64Image}),
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
  }

  // --- FOLLOWER ---
  static Future<void> followUser(String username) async {
    final res = await _request(
      () => http.post(
        Uri.parse('$baseUrl/users/$username/follow'),
        headers: _headers,
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
  }

  static Future<void> unfollowUser(String username) async {
    final res = await _request(
      () => http.delete(
        Uri.parse('$baseUrl/users/$username/follow'),
        headers: _headers,
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
  }

  static Future<List<UserProfile>> getFollowers(String username) async {
    final res = await _request(
      () => http.get(
        Uri.parse('$baseUrl/users/$username/followers'),
        headers: _headers,
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    final data = jsonDecode(res.body) as List;
    return data.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<UserProfile>> getFollowing(String username) async {
    final res = await _request(
      () => http.get(
        Uri.parse('$baseUrl/users/$username/following'),
        headers: _headers,
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    final data = jsonDecode(res.body) as List;
    return data.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
  }

  // --- STORIES ---
  static Future<void> postStory(String base64Image, String? caption) async {
    final res = await _request(
      () => http.post(
        Uri.parse('$baseUrl/me/story'),
        headers: _headers,
        body: jsonEncode({
          'image_base64': base64Image,
          'caption': caption,
        }),
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
  }

  static Future<List<Map<String, dynamic>>> getStoriesFeed() async {
    final res = await _request(
      () => http.get(
        Uri.parse('$baseUrl/stories/feed'),
        headers: _headers,
      ),
    );
    if (res.statusCode != 200) throw _exceptionFromResponse(res);
    final data = jsonDecode(res.body) as List;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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

  static Future<List<dynamic>> getMatches() async {
    final res = await http.get(
      Uri.parse('$baseUrl/matches/me'),
      headers: _headers,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Impossibile caricare i match');
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

  static Future<List<Place>> getPlacesByCity(String city) async {
    final uri = Uri.parse('$baseUrl/maps/places')
        .replace(queryParameters: {'city': city, 'limit': '30'});
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['places'] as List;
      return data.map((e) => Place.fromJson(e)).toList();
    }
    return [];
  }

  static Future<List<Place>> getPlacesByBbox({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/maps/places/bbox').replace(
        queryParameters: {
          'min_lat': minLat.toString(),
          'max_lat': maxLat.toString(),
          'min_lon': minLon.toString(),
          'max_lon': maxLon.toString(),
          'limit': '30',
        },
      ),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['places'] as List;
      return data.map((e) => Place.fromJson(e)).toList();
    }
    return [];
  }
}
