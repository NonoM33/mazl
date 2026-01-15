import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// API Configuration
class ApiConfig {
  static const String baseUrl = 'https://api.mazl.app';
  // For local development:
  // static const String baseUrl = 'http://localhost:3000';
}

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({required this.success, this.data, this.error});

  factory ApiResponse.success(T data) => ApiResponse(success: true, data: data);
  factory ApiResponse.failure(String error) => ApiResponse(success: false, error: error);
}

/// Profile model
class Profile {
  final int id;
  final int userId;
  final String? displayName;
  final int? age;
  final String? gender;
  final String? bio;
  final String? location;
  final String? denomination;
  final String? kashrut;
  final String? shabbatObservance;
  final List<String> photos;
  final bool isVerified;
  final String? verificationLevel;
  final double? distance;
  final int? ageMin;
  final int? ageMax;
  final int? distanceMax;
  final String? lookingFor;

  Profile({
    required this.id,
    required this.userId,
    this.displayName,
    this.age,
    this.gender,
    this.bio,
    this.location,
    this.denomination,
    this.kashrut,
    this.shabbatObservance,
    this.photos = const [],
    this.isVerified = false,
    this.verificationLevel,
    this.distance,
    this.ageMin,
    this.ageMax,
    this.distanceMax,
    this.lookingFor,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      displayName: json['display_name'] as String?,
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      denomination: json['denomination'] as String?,
      kashrut: json['kashrut_level'] as String?,
      shabbatObservance: json['shabbat_observance'] as String?,
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      isVerified: json['is_verified'] == true,
      verificationLevel: json['verification_level'] as String?,
      distance: (json['distance'] as num?)?.toDouble(),
      ageMin: json['age_min'] as int?,
      ageMax: json['age_max'] as int?,
      distanceMax: json['distance_max'] as int?,
      lookingFor: json['looking_for'] as String?,
    );
  }
}

/// Current user profile with more details
class UserProfile {
  final int id;
  final String email;
  final String? name;
  final String? picture;
  final Profile? profile;

  UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.picture,
    this.profile,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String?,
      picture: json['picture'] as String?,
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    );
  }
}

/// API Service for backend communication
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final AuthService _authService = AuthService();

  /// Get authorization headers
  Map<String, String> get _headers {
    final token = _authService.currentUser?.jwtToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET request
  Future<http.Response> _get(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    debugPrint('API GET: $url');
    return http.get(url, headers: _headers);
  }

  /// POST request
  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    debugPrint('API POST: $url');
    return http.post(url, headers: _headers, body: jsonEncode(body));
  }

  /// PUT request
  Future<http.Response> _put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    debugPrint('API PUT: $url');
    return http.put(url, headers: _headers, body: jsonEncode(body));
  }

  /// Get current user profile
  Future<ApiResponse<UserProfile>> getCurrentUser() async {
    try {
      final response = await _get('/api/auth/me');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get user');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(UserProfile.fromJson(data['user']));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get profiles for discovery
  Future<ApiResponse<List<Profile>>> getDiscoverProfiles({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _get('/api/discover?limit=$limit&offset=$offset');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get profiles');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      final profiles = (data['profiles'] as List)
          .map((p) => Profile.fromJson(p))
          .toList();

      return ApiResponse.success(profiles);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Send swipe action (like, pass, super_like)
  Future<ApiResponse<Map<String, dynamic>>> sendSwipe({
    required int targetUserId,
    required String action, // 'like', 'pass', 'super_like'
  }) async {
    try {
      final response = await _post('/api/swipes', {
        'target_user_id': targetUserId,
        'action': action,
      });

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to send swipe');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(data);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Update user profile
  Future<ApiResponse<Profile>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _put('/api/profile', profileData);

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to update profile');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(Profile.fromJson(data['profile']));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get matches
  Future<ApiResponse<List<Map<String, dynamic>>>> getMatches() async {
    try {
      final response = await _get('/api/matches');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get matches');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      final matches = (data['matches'] as List).cast<Map<String, dynamic>>();
      return ApiResponse.success(matches);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }
}
