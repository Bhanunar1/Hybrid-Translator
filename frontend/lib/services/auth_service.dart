import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

// ── User Model ─────────────────────────────────────────────────────────────────
class User {
  final int id;
  final String email;
  final String fullName;
  final bool isAdmin;
  final String? preferredSourceLang;
  final String? preferredTargetLang;
  final String? createdAt;
  final String? bio;
  final String? dob;
  final String? nationality;
  final String? homeCountry;
  final String? currentDestination;
  final String? travelHistory;
  final String? profileImageUrl;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isAdmin,
    this.preferredSourceLang,
    this.preferredTargetLang,
    this.createdAt,
    this.bio,
    this.dob,
    this.nationality,
    this.homeCountry,
    this.currentDestination,
    this.travelHistory,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'] ?? '',
        fullName: json['full_name'] ?? 'Traveler',
        isAdmin: json['is_admin'],
        preferredSourceLang: json['preferred_source_lang'],
        preferredTargetLang: json['preferred_target_lang'],
        createdAt: json['created_at'],
        bio: json['bio'],
        dob: json['dob'],
        nationality: json['nationality'],
        homeCountry: json['home_country'],
        currentDestination: json['current_destination'],
        travelHistory: json['travel_history'],
        profileImageUrl: json['profile_image_url'],
      );
}

// ── Stats Model ─────────────────────────────────────────────────────────────────
class UserStats {
  final int totalTranslations;
  final int cloudTranslations;
  final int offlineTranslations;
  final String? favoriteLang;
  final double? avgLatencyMs;
  final String? memberSince;

  UserStats({
    required this.totalTranslations,
    required this.cloudTranslations,
    required this.offlineTranslations,
    this.favoriteLang,
    this.avgLatencyMs,
    this.memberSince,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        totalTranslations: json['total_translations'] ?? 0,
        cloudTranslations: json['cloud_translations'] ?? 0,
        offlineTranslations: json['offline_translations'] ?? 0,
        favoriteLang: json['favorite_target_lang'],
        avgLatencyMs: (json['avg_latency_ms'] as num?)?.toDouble(),
        memberSince: json['member_since'],
      );
}

// ── Auth Service ───────────────────────────────────────────────────────────────
class AuthService extends ChangeNotifier {
  static const String _baseUrl = AppConstants.apiBaseUrl;

  User? _currentUser;
  UserStats? _stats;
  String? _token;
  bool _isLoading = false;
  String? _lastError;

  User? get currentUser => _currentUser;
  UserStats? get stats => _stats;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get lastError => _lastError;

  AuthService() {
    _loadStoredToken();
  }

  // ── Internal Helpers ─────────────────────────────────────────────────────────
  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  Future<void> _loadStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      await fetchMe();
    }
    notifyListeners();
  }

  // ── Login ────────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/token'),
        body: {'username': email, 'password': password},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await fetchMe();
        await fetchStats();
        return true;
      } else {
        final body = jsonDecode(response.body);
        _lastError = body['detail'] ?? 'Login failed';
        return false;
      }
    } catch (e) {
      _lastError = 'Cannot connect to server. Is the backend running?';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Profile Image ───────────────────────────────────────────────────────────
  Future<bool> uploadProfileImage(dynamic imageFile) async {
    if (_token == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload-profile-image'));
      request.headers.addAll({'Authorization': 'Bearer $_token'});
      
      if (imageFile is String) {
        request.files.add(await http.MultipartFile.fromPath('file', imageFile));
      } else {
        request.files.add(http.MultipartFile.fromBytes('file', imageFile, filename: 'profile.jpg'));
      }

      var streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        await fetchMe();
        return true;
      }
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // ── Register ─────────────────────────────────────────────────────────────────
  Future<({bool success, String? error})> register(
    String email,
    String password,
    String fullName,
    String phone,
  ) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'full_name': fullName,
              'phone': phone,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return (success: true, error: null);
      } else {
        final body = jsonDecode(response.body);
        final err = body['detail'] ?? 'Registration failed';
        return (success: false, error: err.toString());
      }
    } catch (e) {
      return (success: false, error: 'Cannot connect to server.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch profile ─────────────────────────────────────────────────────────────
  Future<void> fetchMe() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(jsonDecode(response.body));
      } else {
        await logout();
      }
    } catch (_) {}
    notifyListeners();
  }

  // ── Fetch stats ───────────────────────────────────────────────────────────────
  Future<void> fetchStats() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/stats/me'),
        headers: _authHeaders,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _stats = UserStats.fromJson(jsonDecode(response.body));
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Update preferences ────────────────────────────────────────────────────────
  Future<bool> updatePreferences({
    String? sourceLang,
    String? targetLang,
    String? fullName,
    String? phone,
    String? bio,
    String? dob,
    String? nationality,
    String? homeCountry,
    String? currentDestination,
    String? travelHistory,
  }) async {
    if (_token == null) return false;
    try {
      final body = <String, dynamic>{};
      if (sourceLang != null) body['preferred_source_lang'] = sourceLang;
      if (targetLang != null) body['preferred_target_lang'] = targetLang;
      if (fullName != null) body['full_name'] = fullName;
      if (phone != null) body['phone'] = phone;
      if (bio != null) body['bio'] = bio;
      if (dob != null) body['dob'] = dob;
      if (nationality != null) body['nationality'] = nationality;
      if (homeCountry != null) body['home_country'] = homeCountry;
      if (currentDestination != null) body['current_destination'] = currentDestination;
      if (travelHistory != null) body['travel_history'] = travelHistory;

      final response = await http.put(
        Uri.parse('$_baseUrl/users/me'),
        headers: _authHeaders,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        await fetchMe();
        return true;
      }
    } catch (e) {
      debugPrint('Update Error: $e');
    }
    return false;
  }

  // ── Logout ────────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _stats = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }

  // ── Account Management ───────────────────────────────────────────────────────
  Future<bool> verifyPassword(String password) async {
    if (_token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/me/verify-password'),
        headers: _authHeaders,
        body: jsonEncode({'password': password}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    if (_token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/me'),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        await logout();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
