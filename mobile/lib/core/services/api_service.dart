import 'dart:convert';
import 'dart:io';
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

/// Helper functions for safe JSON parsing (handles strings and numbers)
int? _parseIntSafe(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _parseDoubleSafe(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
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
  final double? latitude;
  final double? longitude;
  final String? denomination;
  final String? kashrut;
  final String? shabbatObservance;
  final String? relationshipIntention;
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
    this.latitude,
    this.longitude,
    this.denomination,
    this.kashrut,
    this.shabbatObservance,
    this.relationshipIntention,
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
      id: _parseIntSafe(json['id']) ?? 0,
      userId: _parseIntSafe(json['user_id']) ?? 0,
      displayName: json['display_name'] as String?,
      age: _parseIntSafe(json['age']),
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      latitude: _parseDoubleSafe(json['latitude']),
      longitude: _parseDoubleSafe(json['longitude']),
      denomination: json['denomination'] as String?,
      kashrut: json['kashrut_level'] as String?,
      shabbatObservance: json['shabbat_observance'] as String?,
      relationshipIntention: json['relationship_intention'] as String?,
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      isVerified: json['is_verified'] == true,
      verificationLevel: json['verification_level'] as String?,
      distance: _parseDoubleSafe(json['distance']),
      ageMin: _parseIntSafe(json['age_min']),
      ageMax: _parseIntSafe(json['age_max']),
      distanceMax: _parseIntSafe(json['distance_max']),
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
      id: _parseIntSafe(json['id']) ?? 0,
      email: json['email'] as String,
      name: json['name'] as String?,
      picture: json['picture'] as String?,
      profile: json['profile'] != null ? Profile.fromJson(json['profile']) : null,
    );
  }
}

/// Profile photo model
class ProfilePhoto {
  final int id;
  final String url;
  final int position;
  final bool isPrimary;
  final DateTime? createdAt;

  ProfilePhoto({
    required this.id,
    required this.url,
    required this.position,
    this.isPrimary = false,
    this.createdAt,
  });

  factory ProfilePhoto.fromJson(Map<String, dynamic> json) {
    return ProfilePhoto(
      id: _parseIntSafe(json['id']) ?? 0,
      url: json['url'] as String,
      position: _parseIntSafe(json['position']) ?? 0,
      isPrimary: json['is_primary'] == true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
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

  /// DELETE request
  Future<http.Response> _delete(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    debugPrint('API DELETE: $url');
    return http.delete(url, headers: _headers);
  }

  /// Public POST request (returns parsed JSON)
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final response = await _post(endpoint, body);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Public GET request (returns parsed JSON)
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await _get(endpoint);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Public DELETE request (returns parsed JSON)
  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await _delete(endpoint);
    return jsonDecode(response.body) as Map<String, dynamic>;
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

      // Backend sends user and profile at root level, merge them for UserProfile
      final userData = data['user'] as Map<String, dynamic>;
      userData['profile'] = data['profile']; // Add profile to user data

      return ApiResponse.success(UserProfile.fromJson(userData));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get profile by user ID
  Future<ApiResponse<Profile>> getProfileById(int userId) async {
    try {
      final response = await _get('/api/profile/$userId');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get profile');
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

  /// Get daily picks (curated profiles for the day)
  Future<ApiResponse<List<Profile>>> getDailyPicks() async {
    try {
      final response = await _get('/api/daily-picks');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get daily picks');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      final profiles = (data['picks'] as List?)
          ?.map((p) => Profile.fromJson(p))
          .toList() ?? [];

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

  // ============ PROFILE PHOTOS ============

  /// Get profile photos
  Future<ApiResponse<List<ProfilePhoto>>> getProfilePhotos() async {
    try {
      final response = await _get('/api/profile/photos');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get photos');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      final photos = (data['photos'] as List)
          .map((p) => ProfilePhoto.fromJson(p))
          .toList();

      return ApiResponse.success(photos);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Upload profile photo from file
  Future<ApiResponse<ProfilePhoto>> uploadProfilePhoto(String filePath, {bool isPrimary = false}) async {
    try {
      final token = _authService.currentUser?.jwtToken;
      final url = Uri.parse('${ApiConfig.baseUrl}/api/profile/photos');

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));
      request.fields['is_primary'] = isPrimary.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to upload photo');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(ProfilePhoto.fromJson(data['photo']));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Delete profile photo
  Future<ApiResponse<void>> deleteProfilePhoto(int photoId) async {
    try {
      final response = await _delete('/api/profile/photos/$photoId');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to delete photo');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Reorder profile photos
  Future<ApiResponse<List<ProfilePhoto>>> reorderProfilePhotos(List<int> photoIds) async {
    try {
      final response = await _put('/api/profile/photos/reorder', {'photoIds': photoIds});

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to reorder photos');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      final photos = (data['photos'] as List)
          .map((p) => ProfilePhoto.fromJson(p))
          .toList();

      return ApiResponse.success(photos);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Set photo as primary
  Future<ApiResponse<List<ProfilePhoto>>> setPhotoPrimary(int photoId) async {
    try {
      final response = await _put('/api/profile/photos/$photoId/primary', {});

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to set primary photo');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      final photos = (data['photos'] as List)
          .map((p) => ProfilePhoto.fromJson(p))
          .toList();

      return ApiResponse.success(photos);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ MATCHES ============

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

  // ============ CONVERSATIONS ============

  /// Get user's conversations
  Future<ApiResponse<List<Conversation>>> getConversations() async {
    try {
      final response = await _get('/api/conversations');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get conversations');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      final conversations = (data['conversations'] as List)
          .map((c) => Conversation.fromJson(c))
          .toList();

      return ApiResponse.success(conversations);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get messages for a conversation
  Future<ApiResponse<List<Message>>> getMessages(int conversationId, {int limit = 50, int offset = 0}) async {
    try {
      final response = await _get('/api/conversations/$conversationId/messages?limit=$limit&offset=$offset');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get messages');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      final messages = (data['messages'] as List)
          .map((m) => Message.fromJson(m))
          .toList();

      return ApiResponse.success(messages);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Send a message
  Future<ApiResponse<Message>> sendMessage(int conversationId, String content) async {
    try {
      final response = await _post('/api/conversations/$conversationId/messages', {
        'content': content,
      });

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to send message');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(Message.fromJson(data['message']));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Send an image message
  Future<ApiResponse<Message>> sendImageMessage(int conversationId, File imageFile) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/conversations/$conversationId/messages/image');
      final request = http.MultipartRequest('POST', uri);

      // Add auth header
      final token = _authService.currentUser?.jwtToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add image file
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        return ApiResponse.failure('Failed to send image');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(Message.fromJson(data['message']));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Mark messages as read
  Future<ApiResponse<void>> markMessagesAsRead(int conversationId) async {
    try {
      final response = await _put('/api/conversations/$conversationId/read', {});

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to mark as read');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ EVENTS ============

  /// Get events
  Future<ApiResponse<List<Event>>> getEvents({String? type, String? fromDate}) async {
    try {
      String endpoint = '/api/events';
      final params = <String>[];
      if (type != null) params.add('type=$type');
      if (fromDate != null) params.add('from=$fromDate');
      if (params.isNotEmpty) endpoint += '?${params.join('&')}';

      final response = await _get(endpoint);

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get events');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      final events = (data['events'] as List)
          .map((e) => Event.fromJson(e))
          .toList();

      return ApiResponse.success(events);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get event by ID
  Future<ApiResponse<Event>> getEvent(int eventId) async {
    try {
      final response = await _get('/api/events/$eventId');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get event');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(Event.fromJson(data['event']));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// RSVP to event
  Future<ApiResponse<void>> rsvpEvent(int eventId, {String status = 'going'}) async {
    try {
      final response = await _post('/api/events/$eventId/rsvp', {'status': status});

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to RSVP');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Cancel RSVP
  Future<ApiResponse<void>> cancelRsvp(int eventId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/events/$eventId/rsvp');
      final response = await http.delete(url, headers: _headers);

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to cancel RSVP');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ COUPLE MODE ============

  /// Send a couple mode request to a user
  Future<ApiResponse<Map<String, dynamic>>> sendCoupleRequest(int targetUserId) async {
    try {
      final response = await _post('/api/couple/request', {
        'target_user_id': targetUserId,
      });

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to send couple request');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(data);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Respond to a couple request (accept or reject)
  Future<ApiResponse<Map<String, dynamic>>> respondToCoupleRequest({
    required int requestId,
    required bool accept,
  }) async {
    try {
      final response = await _put('/api/couple/request/$requestId', {
        'action': accept ? 'accept' : 'reject',
      });

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to respond to couple request');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(data);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Cancel a pending couple request
  Future<ApiResponse<void>> cancelCoupleRequest(int requestId) async {
    try {
      final response = await _delete('/api/couple/request/$requestId');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to cancel couple request');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get all couple requests (sent and received)
  Future<ApiResponse<Map<String, dynamic>>> getCoupleRequests() async {
    try {
      final response = await _get('/api/couple/requests');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get couple requests');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(data);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Archive all conversations except with partner
  Future<ApiResponse<void>> archiveAllConversationsExcept(
    int partnerUserId, {
    required String message,
  }) async {
    try {
      final response = await _post('/api/couple/archive-conversations', {
        'partner_user_id': partnerUserId,
        'message': message,
      });

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to archive conversations');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Exit couple mode
  Future<ApiResponse<void>> exitCoupleMode() async {
    try {
      final response = await _delete('/api/couple');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to exit couple mode');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get couple data
  Future<ApiResponse<Map<String, dynamic>>> getCoupleData() async {
    try {
      final response = await _get('/api/couple');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get couple data');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(data);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Check if a user is already in couple mode
  Future<ApiResponse<bool>> isUserInCoupleMode(int userId) async {
    try {
      final response = await _get('/api/couple/check/$userId');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to check couple mode');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(data['in_couple_mode'] == true);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ BLOCKING ============

  /// Block a user
  Future<ApiResponse<void>> blockUser(int userId, {String? reason}) async {
    try {
      final response = await _post('/api/users/$userId/block', {
        if (reason != null) 'reason': reason,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        return ApiResponse.failure('Failed to block user');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Unblock a user
  Future<ApiResponse<void>> unblockUser(int userId) async {
    try {
      final response = await _delete('/api/users/$userId/block');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to unblock user');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get list of blocked users
  Future<ApiResponse<List<BlockedUser>>> getBlockedUsers() async {
    try {
      final response = await _get('/api/users/blocked');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get blocked users');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      final blockedList = (data['blocked_users'] as List<dynamic>?)
          ?.map((json) => BlockedUser.fromJson(json))
          .toList() ?? [];

      return ApiResponse.success(blockedList);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ REPORTING ============

  /// Report a user
  Future<ApiResponse<void>> reportUser({
    required int userId,
    required String category,
    String? comment,
    bool blockUser = false,
  }) async {
    try {
      final response = await _post('/api/users/$userId/report', {
        'category': category,
        if (comment != null) 'comment': comment,
        'block_user': blockUser,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        return ApiResponse.failure('Failed to report user');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ VERIFICATION ============

  /// Start photo verification process
  Future<ApiResponse<Map<String, dynamic>>> startVerification() async {
    try {
      final response = await _post('/api/verification/start', {});

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to start verification');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(data);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Submit verification selfie
  Future<ApiResponse<Map<String, dynamic>>> submitVerification(String selfieBase64, String gestureId) async {
    try {
      final response = await _post('/api/verification/submit', {
        'selfie': selfieBase64,
        'gesture_id': gestureId,
      });

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to submit verification');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(data);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get verification status
  Future<ApiResponse<Map<String, dynamic>>> getVerificationStatus() async {
    try {
      final response = await _get('/api/verification/status');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get verification status');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(data);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ LIKES ============

  /// Get received likes (blurred for free users)
  Future<ApiResponse<LikesData>> getReceivedLikes() async {
    try {
      final response = await _get('/api/likes/received');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get received likes');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(LikesData.fromJson(data));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get count of received likes
  Future<ApiResponse<int>> getReceivedLikesCount() async {
    try {
      final response = await _get('/api/likes/received/count');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get likes count');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(_parseIntSafe(data['count']) ?? 0);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ PROFILE PROMPTS ============

  /// Get available prompts list
  Future<ApiResponse<List<PromptTemplate>>> getAvailablePrompts() async {
    try {
      final response = await _get('/api/prompts');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get prompts');
      }

      final data = jsonDecode(response.body);
      final prompts = (data['prompts'] as List<dynamic>?)
          ?.map((json) => PromptTemplate.fromJson(json))
          .toList() ?? [];

      return ApiResponse.success(prompts);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get my profile prompts
  Future<ApiResponse<List<ProfilePrompt>>> getMyPrompts() async {
    try {
      final response = await _get('/api/profile/prompts');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get my prompts');
      }

      final data = jsonDecode(response.body);
      final prompts = (data['prompts'] as List<dynamic>?)
          ?.map((json) => ProfilePrompt.fromJson(json))
          .toList() ?? [];

      return ApiResponse.success(prompts);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Add a prompt to profile
  Future<ApiResponse<ProfilePrompt>> addPrompt({
    required String promptId,
    required String answer,
    required int position,
  }) async {
    try {
      final response = await _post('/api/profile/prompts', {
        'prompt_id': promptId,
        'answer': answer,
        'position': position,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        return ApiResponse.failure('Failed to add prompt');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(ProfilePrompt.fromJson(data['prompt']));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Update a prompt
  Future<ApiResponse<ProfilePrompt>> updatePrompt(int promptId, String answer) async {
    try {
      final response = await _put('/api/profile/prompts/$promptId', {
        'answer': answer,
      });

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to update prompt');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(ProfilePrompt.fromJson(data['prompt']));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Delete a prompt
  Future<ApiResponse<void>> deletePrompt(int promptId) async {
    try {
      final response = await _delete('/api/profile/prompts/$promptId');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to delete prompt');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Like a profile via prompt
  Future<ApiResponse<Map<String, dynamic>>> likeViaPrompt({
    required int targetUserId,
    required int promptId,
  }) async {
    try {
      final response = await _post('/api/swipes/like-prompt', {
        'target_user_id': targetUserId,
        'prompt_id': promptId,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        return ApiResponse.failure('Failed to like via prompt');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(data);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ BOOST ============

  /// Get boost status
  Future<ApiResponse<BoostStatus>> getBoostStatus() async {
    try {
      final response = await _get('/api/boost/status');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get boost status');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(BoostStatus.fromJson(data));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Activate boost
  Future<ApiResponse<BoostStatus>> activateBoost() async {
    try {
      final response = await _post('/api/boost/activate', {});

      if (response.statusCode != 200 && response.statusCode != 201) {
        final data = jsonDecode(response.body);
        return ApiResponse.failure(data['error'] ?? 'Failed to activate boost');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(BoostStatus.fromJson(data));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ PROFILE VISITORS ============

  /// Get profile visitors
  Future<ApiResponse<VisitorsData>> getProfileVisitors() async {
    try {
      final response = await _get('/api/profile/visitors');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get visitors');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(VisitorsData.fromJson(data));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get visitors count (for badge)
  Future<ApiResponse<int>> getVisitorsCount() async {
    try {
      final response = await _get('/api/profile/visitors/count');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get visitors count');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(_parseIntSafe(data['count']) ?? 0);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ COUPLE ANNIVERSARY ============

  /// Get couple anniversary data
  Future<ApiResponse<CoupleAnniversaryData>> getCoupleAnniversary() async {
    try {
      final response = await _get('/api/couple/anniversary');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get anniversary data');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(CoupleAnniversaryData.fromJson(data));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get upcoming milestones
  Future<ApiResponse<List<CoupleMilestone>>> getUpcomingMilestones() async {
    try {
      final response = await _get('/api/couple/milestones');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get milestones');
      }

      final data = jsonDecode(response.body);
      final milestones = (data['milestones'] as List<dynamic>?)
              ?.map((m) => CoupleMilestone.fromJson(m))
              .toList() ??
          [];

      return ApiResponse.success(milestones);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Generate shareable anniversary card
  Future<ApiResponse<String>> generateAnniversaryCard() async {
    try {
      final response = await _post('/api/couple/anniversary/card', {});

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to generate card');
      }

      final data = jsonDecode(response.body);
      return ApiResponse.success(data['card_url'] as String? ?? '');
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  // ============ SUCCESS STORIES ============

  /// Get success stories
  Future<ApiResponse<List<SuccessStory>>> getSuccessStories({int page = 1}) async {
    try {
      final response = await _get('/api/success-stories?page=$page');

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get success stories');
      }

      final data = jsonDecode(response.body);
      final stories = (data['stories'] as List<dynamic>?)
              ?.map((s) => SuccessStory.fromJson(s))
              .toList() ??
          [];

      return ApiResponse.success(stories);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Submit a success story
  Future<ApiResponse<void>> submitSuccessStory({
    required String story,
    required List<String> photoUrls,
    String? status, // 'dating', 'engaged', 'married'
    DateTime? statusDate,
  }) async {
    try {
      final response = await _post('/api/success-stories', {
        'story': story,
        'photos': photoUrls,
        if (status != null) 'status': status,
        if (statusDate != null) 'status_date': statusDate.toIso8601String(),
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        return ApiResponse.failure('Failed to submit success story');
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        return ApiResponse.failure(data['error'] ?? 'Unknown error');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Like a success story
  Future<ApiResponse<void>> likeSuccessStory(int storyId) async {
    try {
      final response = await _post('/api/success-stories/$storyId/like', {});

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to like story');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }

  /// Get own success story
  Future<ApiResponse<SuccessStory?>> getMySuccessStory() async {
    try {
      final response = await _get('/api/couple/success-story');

      if (response.statusCode == 404) {
        return ApiResponse.success(null);
      }

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to get success story');
      }

      final data = jsonDecode(response.body);
      if (data['story'] == null) {
        return ApiResponse.success(null);
      }

      return ApiResponse.success(SuccessStory.fromJson(data['story']));
    } catch (e) {
      debugPrint('API Error: $e');
      return ApiResponse.failure(e.toString());
    }
  }
}

// ============ MODELS ============

/// Conversation model
class Conversation {
  final int id;
  final int matchId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final ConversationUser? otherUser;

  Conversation({
    required this.id,
    required this.matchId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.otherUser,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: _parseIntSafe(json['id']) ?? 0,
      matchId: _parseIntSafe(json['matchId']) ?? 0,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      unreadCount: _parseIntSafe(json['unreadCount']) ?? 0,
      otherUser: json['otherUser'] != null
          ? ConversationUser.fromJson(json['otherUser'])
          : null,
    );
  }
}

/// Conversation user model
class ConversationUser {
  final int userId;
  final String? displayName;
  final String? picture;
  final bool isVerified;

  ConversationUser({
    required this.userId,
    this.displayName,
    this.picture,
    this.isVerified = false,
  });

  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      userId: _parseIntSafe(json['user_id']) ?? 0,
      displayName: json['display_name'] as String?,
      picture: json['picture'] as String?,
      isVerified: json['is_verified'] == true,
    );
  }
}

/// Message model
class Message {
  final int id;
  final int senderId;
  final String content;
  final String? imageUrl;
  final String messageType; // 'text' or 'image'
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    this.imageUrl,
    this.messageType = 'text',
    this.isRead = false,
    required this.createdAt,
  });

  bool get isImage => messageType == 'image' || imageUrl != null;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: _parseIntSafe(json['id']) ?? 0,
      senderId: _parseIntSafe(json['sender_id']) ?? 0,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      isRead: json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Event model
class Event {
  final int id;
  final String title;
  final String? description;
  final String? eventType;
  final String? location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime date;
  final String? time;
  final String? endTime;
  final double price;
  final String currency;
  final int? maxAttendees;
  final int attendeeCount;
  final String? imageUrl;
  final bool isPublished;
  final String? userRsvpStatus;

  Event({
    required this.id,
    required this.title,
    this.description,
    this.eventType,
    this.location,
    this.address,
    this.latitude,
    this.longitude,
    required this.date,
    this.time,
    this.endTime,
    this.price = 0,
    this.currency = 'EUR',
    this.maxAttendees,
    this.attendeeCount = 0,
    this.imageUrl,
    this.isPublished = false,
    this.userRsvpStatus,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: _parseIntSafe(json['id']) ?? 0,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventType: json['event_type'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      latitude: _parseDoubleSafe(json['latitude']),
      longitude: _parseDoubleSafe(json['longitude']),
      date: DateTime.parse(json['date']),
      time: json['time'] as String?,
      endTime: json['end_time'] as String?,
      price: _parseDoubleSafe(json['price']) ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
      maxAttendees: _parseIntSafe(json['max_attendees']),
      attendeeCount: _parseIntSafe(json['attendee_count']) ?? 0,
      imageUrl: json['image_url'] as String?,
      isPublished: json['is_published'] == true,
      userRsvpStatus: json['user_rsvp_status'] as String?,
    );
  }

  String get formattedPrice {
    if (price == 0) return 'Gratuit';
    return '${price.toStringAsFixed(0)} $currency';
  }

  String get spotsLeft {
    if (maxAttendees == null) return 'Places illimitées';
    final left = maxAttendees! - attendeeCount;
    if (left <= 0) return 'Complet';
    return '$left places restantes';
  }
}

/// Blocked user model
class BlockedUser {
  final int id;
  final int userId;
  final String? displayName;
  final String? picture;
  final DateTime blockedAt;

  BlockedUser({
    required this.id,
    required this.userId,
    this.displayName,
    this.picture,
    required this.blockedAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: _parseIntSafe(json['id']) ?? 0,
      userId: _parseIntSafe(json['user_id']) ?? 0,
      displayName: json['display_name'] as String?,
      picture: json['picture'] as String?,
      blockedAt: json['blocked_at'] != null
          ? DateTime.parse(json['blocked_at'])
          : DateTime.now(),
    );
  }
}

/// Report categories
class ReportCategory {
  final String id;
  final String label;
  final String description;
  final String severity;

  const ReportCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.severity,
  });

  static const List<ReportCategory> categories = [
    ReportCategory(
      id: 'fake_profile',
      label: 'Faux profil',
      description: 'Photos volées, identité fausse',
      severity: 'high',
    ),
    ReportCategory(
      id: 'inappropriate_photos',
      label: 'Photos inappropriées',
      description: 'Contenu sexuel, violent ou choquant',
      severity: 'high',
    ),
    ReportCategory(
      id: 'harassment',
      label: 'Harcèlement',
      description: 'Messages insistants, menaces, insultes',
      severity: 'critical',
    ),
    ReportCategory(
      id: 'spam',
      label: 'Spam / Arnaque',
      description: 'Publicité, demande d\'argent, liens suspects',
      severity: 'high',
    ),
    ReportCategory(
      id: 'underage',
      label: 'Mineur',
      description: 'La personne semble avoir moins de 18 ans',
      severity: 'critical',
    ),
    ReportCategory(
      id: 'offline_behavior',
      label: 'Comportement hors app',
      description: 'Comportement inapproprié lors d\'une rencontre',
      severity: 'medium',
    ),
    ReportCategory(
      id: 'other',
      label: 'Autre',
      description: 'Autre raison (précisez)',
      severity: 'low',
    ),
  ];
}

/// Likes data model
class LikesData {
  final int count;
  final bool isPremium;
  final List<LikeProfile> likes;

  LikesData({
    required this.count,
    required this.isPremium,
    required this.likes,
  });

  // Alias for count
  int get totalCount => count;

  factory LikesData.fromJson(Map<String, dynamic> json) {
    return LikesData(
      count: _parseIntSafe(json['count']) ?? 0,
      isPremium: json['is_premium'] == true,
      likes: (json['likes'] as List<dynamic>?)
          ?.map((e) => LikeProfile.fromJson(e))
          .toList() ?? [],
    );
  }

  String get displayCount {
    if (count <= 10) return '$count';
    if (count <= 25) return '10+';
    if (count <= 50) return '25+';
    if (count <= 99) return '50+';
    return '99+';
  }
}

/// Like profile model
class LikeProfile {
  final int userId;
  final String? displayName;
  final String? picture;
  final int? age;
  final bool isVerified;
  final DateTime likedAt;
  final double? distance;

  LikeProfile({
    required this.userId,
    this.displayName,
    this.picture,
    this.age,
    this.isVerified = false,
    required this.likedAt,
    this.distance,
  });

  // Alias for picture
  String? get photoUrl => picture;

  factory LikeProfile.fromJson(Map<String, dynamic> json) {
    return LikeProfile(
      userId: _parseIntSafe(json['user_id']) ?? 0,
      displayName: json['display_name'] as String?,
      picture: json['picture'] as String?,
      age: _parseIntSafe(json['age']),
      isVerified: json['is_verified'] == true,
      likedAt: json['liked_at'] != null
          ? DateTime.parse(json['liked_at'])
          : DateTime.now(),
      distance: _parseDoubleSafe(json['distance']),
    );
  }
}

/// Prompt template model
class PromptTemplate {
  final String id;
  final String text;
  final String? category;

  PromptTemplate({
    required this.id,
    required this.text,
    this.category,
  });

  factory PromptTemplate.fromJson(Map<String, dynamic> json) {
    return PromptTemplate(
      id: json['id'] as String,
      text: json['text'] as String,
      category: json['category'] as String?,
    );
  }

  /// Default prompts list (used if API unavailable)
  static const List<Map<String, String>> defaultPrompts = [
    // Personnalité
    {'id': 'perfect_sunday', 'text': 'Mon dimanche parfait...', 'category': 'personality'},
    {'id': 'fun_fact', 'text': 'Un fait surprenant sur moi...', 'category': 'personality'},
    {'id': 'life_goal', 'text': 'Un de mes objectifs dans la vie...', 'category': 'personality'},
    {'id': 'pet_peeve', 'text': 'Ce qui m\'énerve le plus...', 'category': 'personality'},
    {'id': 'proud_of', 'text': 'Je suis fier(e) de...', 'category': 'personality'},
    {'id': 'looking_for', 'text': 'Je cherche quelqu\'un qui...', 'category': 'personality'},
    // Lifestyle
    {'id': 'ideal_vacation', 'text': 'Mes vacances idéales...', 'category': 'lifestyle'},
    {'id': 'favorite_food', 'text': 'Mon plat préféré...', 'category': 'lifestyle'},
    {'id': 'hidden_talent', 'text': 'Mon talent caché...', 'category': 'lifestyle'},
    {'id': 'binge_watching', 'text': 'En ce moment je regarde...', 'category': 'lifestyle'},
    // Judaïsme
    {'id': 'shabbat_ideal', 'text': 'Mon Shabbat idéal...', 'category': 'jewish'},
    {'id': 'family_tradition', 'text': 'Une tradition familiale que j\'adore...', 'category': 'jewish'},
    {'id': 'favorite_holiday', 'text': 'Ma fête juive préférée...', 'category': 'jewish'},
    {'id': 'friday_night', 'text': 'Le vendredi soir chez moi...', 'category': 'jewish'},
    {'id': 'israel_memory', 'text': 'Mon meilleur souvenir en Israël...', 'category': 'jewish'},
    {'id': 'jewish_value', 'text': 'Une valeur juive qui me guide...', 'category': 'jewish'},
    // Conversation starters
    {'id': 'debate_me', 'text': 'Débats moi sur...', 'category': 'conversation'},
    {'id': 'teach_me', 'text': 'Apprends-moi quelque chose sur...', 'category': 'conversation'},
    {'id': 'together_we_could', 'text': 'Ensemble on pourrait...', 'category': 'conversation'},
    {'id': 'first_date', 'text': 'Premier date idéal...', 'category': 'conversation'},
  ];
}

/// Profile prompt model
class ProfilePrompt {
  final int id;
  final String promptId;
  final String promptText;
  final String answer;
  final int position;

  ProfilePrompt({
    required this.id,
    required this.promptId,
    required this.promptText,
    required this.answer,
    required this.position,
  });

  factory ProfilePrompt.fromJson(Map<String, dynamic> json) {
    return ProfilePrompt(
      id: _parseIntSafe(json['id']) ?? 0,
      promptId: json['prompt_id'] as String,
      promptText: json['prompt_text'] as String? ?? '',
      answer: json['answer'] as String,
      position: _parseIntSafe(json['position']) ?? 1,
    );
  }
}

/// Relationship intention
class RelationshipIntention {
  final String id;
  final String label;
  final String icon;
  final String description;

  const RelationshipIntention({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });

  static const List<RelationshipIntention> intentions = [
    RelationshipIntention(
      id: 'marriage',
      label: 'Mariage',
      icon: 'ring',
      description: 'Je cherche mon/ma futur(e) mari/femme',
    ),
    RelationshipIntention(
      id: 'serious',
      label: 'Relation sérieuse',
      icon: 'heart',
      description: 'Je cherche une relation durable',
    ),
    RelationshipIntention(
      id: 'open',
      label: 'Ouvert(e) à tout',
      icon: 'sparkles',
      description: 'On verra où ça nous mène',
    ),
    RelationshipIntention(
      id: 'friends_first',
      label: 'Amitié d\'abord',
      icon: 'users',
      description: 'Commençons par apprendre à se connaître',
    ),
  ];
}

/// Compatibility score between two users
class CompatibilityScore {
  final int score; // 0-100
  final bool isSuperCompatible; // score > 85
  final List<CompatibilityFactor> factors;

  CompatibilityScore({
    required this.score,
    required this.isSuperCompatible,
    required this.factors,
  });

  factory CompatibilityScore.fromJson(Map<String, dynamic> json) {
    final score = _parseIntSafe(json['score']) ?? 0;
    return CompatibilityScore(
      score: score,
      isSuperCompatible: score >= 85,
      factors: (json['factors'] as List<dynamic>?)
              ?.map((f) => CompatibilityFactor.fromJson(f))
              .toList() ??
          [],
    );
  }

  /// Calculate compatibility locally (fallback if API not available)
  static CompatibilityScore calculate({
    required Profile myProfile,
    required Profile otherProfile,
  }) {
    final factors = <CompatibilityFactor>[];
    int totalScore = 0;
    int factorCount = 0;

    // 1. Relationship intention match (30 points)
    if (myProfile.relationshipIntention != null &&
        otherProfile.relationshipIntention != null) {
      factorCount++;
      if (myProfile.relationshipIntention == otherProfile.relationshipIntention) {
        totalScore += 30;
        factors.add(CompatibilityFactor(
          name: 'Intentions',
          score: 100,
          description: 'Vous cherchez la meme chose',
          icon: 'heart',
        ));
      } else {
        factors.add(CompatibilityFactor(
          name: 'Intentions',
          score: 40,
          description: 'Intentions differentes',
          icon: 'heart',
        ));
        totalScore += 12;
      }
    }

    // 2. Jewish practice alignment (25 points)
    if (myProfile.denomination != null && otherProfile.denomination != null) {
      factorCount++;
      final denom1 = myProfile.denomination!.toLowerCase();
      final denom2 = otherProfile.denomination!.toLowerCase();
      if (denom1 == denom2) {
        totalScore += 25;
        factors.add(CompatibilityFactor(
          name: 'Pratique',
          score: 100,
          description: 'Meme denomination',
          icon: 'star',
        ));
      } else {
        // Partial match for similar denominations
        final similarGroups = [
          ['orthodox', 'modern orthodox', 'habad'],
          ['massorti', 'traditionaliste'],
          ['laique'],
        ];
        bool similar = false;
        for (final group in similarGroups) {
          if (group.contains(denom1) && group.contains(denom2)) {
            similar = true;
            break;
          }
        }
        if (similar) {
          totalScore += 18;
          factors.add(CompatibilityFactor(
            name: 'Pratique',
            score: 70,
            description: 'Pratique similaire',
            icon: 'star',
          ));
        } else {
          totalScore += 8;
          factors.add(CompatibilityFactor(
            name: 'Pratique',
            score: 30,
            description: 'Pratique differente',
            icon: 'star',
          ));
        }
      }
    }

    // 3. Age compatibility (20 points)
    if (myProfile.age != null && otherProfile.age != null) {
      factorCount++;
      final ageDiff = (myProfile.age! - otherProfile.age!).abs();
      if (ageDiff <= 3) {
        totalScore += 20;
        factors.add(CompatibilityFactor(
          name: 'Age',
          score: 100,
          description: 'Age tres proche',
          icon: 'calendar',
        ));
      } else if (ageDiff <= 5) {
        totalScore += 16;
        factors.add(CompatibilityFactor(
          name: 'Age',
          score: 80,
          description: 'Age proche',
          icon: 'calendar',
        ));
      } else if (ageDiff <= 10) {
        totalScore += 10;
        factors.add(CompatibilityFactor(
          name: 'Age',
          score: 50,
          description: 'Difference d\'age moderee',
          icon: 'calendar',
        ));
      } else {
        totalScore += 4;
        factors.add(CompatibilityFactor(
          name: 'Age',
          score: 20,
          description: 'Grande difference d\'age',
          icon: 'calendar',
        ));
      }
    }

    // 4. Location/Distance (25 points)
    if (otherProfile.distance != null) {
      factorCount++;
      final dist = otherProfile.distance!;
      if (dist <= 10) {
        totalScore += 25;
        factors.add(CompatibilityFactor(
          name: 'Distance',
          score: 100,
          description: 'Tres proche (< 10km)',
          icon: 'map-pin',
        ));
      } else if (dist <= 25) {
        totalScore += 20;
        factors.add(CompatibilityFactor(
          name: 'Distance',
          score: 80,
          description: 'Proche (< 25km)',
          icon: 'map-pin',
        ));
      } else if (dist <= 50) {
        totalScore += 12;
        factors.add(CompatibilityFactor(
          name: 'Distance',
          score: 50,
          description: 'Distance moderee',
          icon: 'map-pin',
        ));
      } else {
        totalScore += 5;
        factors.add(CompatibilityFactor(
          name: 'Distance',
          score: 20,
          description: 'Assez loin',
          icon: 'map-pin',
        ));
      }
    }

    // Normalize score if we have factors
    final finalScore = factorCount > 0 ? (totalScore * 100 ~/ (factorCount * 25)) : 50;
    final clampedScore = finalScore.clamp(0, 100);

    return CompatibilityScore(
      score: clampedScore,
      isSuperCompatible: clampedScore >= 85,
      factors: factors,
    );
  }
}

/// Individual compatibility factor
class CompatibilityFactor {
  final String name;
  final int score; // 0-100
  final String description;
  final String icon;

  CompatibilityFactor({
    required this.name,
    required this.score,
    required this.description,
    required this.icon,
  });

  factory CompatibilityFactor.fromJson(Map<String, dynamic> json) {
    return CompatibilityFactor(
      name: json['name'] as String? ?? '',
      score: _parseIntSafe(json['score']) ?? 0,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'star',
    );
  }
}

/// Profile boost status
class BoostStatus {
  final bool isActive;
  final DateTime? expiresAt;
  final int? remainingBoosts; // null if unlimited (premium)
  final int viewsDuringBoost;
  final int likesDuringBoost;

  BoostStatus({
    required this.isActive,
    this.expiresAt,
    this.remainingBoosts,
    this.viewsDuringBoost = 0,
    this.likesDuringBoost = 0,
  });

  int get minutesRemaining {
    if (!isActive || expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inMinutes.clamp(0, 999);
  }

  factory BoostStatus.fromJson(Map<String, dynamic> json) {
    return BoostStatus(
      isActive: json['is_active'] == true,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'])
          : null,
      remainingBoosts: _parseIntSafe(json['remaining_boosts']),
      viewsDuringBoost: _parseIntSafe(json['views_during_boost']) ?? 0,
      likesDuringBoost: _parseIntSafe(json['likes_during_boost']) ?? 0,
    );
  }
}

/// Profile visitor
class ProfileVisitor {
  final int userId;
  final String? displayName;
  final String? photoUrl;
  final int? age;
  final bool isVerified;
  final DateTime visitedAt;
  final bool isBlurred; // true for free users

  ProfileVisitor({
    required this.userId,
    this.displayName,
    this.photoUrl,
    this.age,
    this.isVerified = false,
    required this.visitedAt,
    this.isBlurred = true,
  });

  factory ProfileVisitor.fromJson(Map<String, dynamic> json) {
    return ProfileVisitor(
      userId: _parseIntSafe(json['user_id']) ?? 0,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      age: _parseIntSafe(json['age']),
      isVerified: json['is_verified'] == true,
      visitedAt: DateTime.tryParse(json['visited_at'] ?? '') ?? DateTime.now(),
      isBlurred: json['is_blurred'] == true,
    );
  }
}

/// Visitors data (includes premium status)
class VisitorsData {
  final List<ProfileVisitor> visitors;
  final int totalCount;
  final bool isPremium;

  VisitorsData({
    required this.visitors,
    required this.totalCount,
    required this.isPremium,
  });

  factory VisitorsData.fromJson(Map<String, dynamic> json) {
    return VisitorsData(
      visitors: (json['visitors'] as List<dynamic>?)
              ?.map((v) => ProfileVisitor.fromJson(v))
              .toList() ??
          [],
      totalCount: _parseIntSafe(json['total_count']) ?? 0,
      isPremium: json['is_premium'] == true,
    );
  }
}

/// Couple anniversary data
class CoupleAnniversaryData {
  final DateTime matchDate;
  final int daysTogether;
  final String partnerName;
  final String? partnerPhotoUrl;
  final String? myPhotoUrl;
  final CoupleMilestone? currentMilestone;
  final CoupleMilestone? nextMilestone;
  final bool isAnniversaryToday;

  CoupleAnniversaryData({
    required this.matchDate,
    required this.daysTogether,
    required this.partnerName,
    this.partnerPhotoUrl,
    this.myPhotoUrl,
    this.currentMilestone,
    this.nextMilestone,
    this.isAnniversaryToday = false,
  });

  factory CoupleAnniversaryData.fromJson(Map<String, dynamic> json) {
    return CoupleAnniversaryData(
      matchDate: DateTime.tryParse(json['match_date'] ?? '') ?? DateTime.now(),
      daysTogether: _parseIntSafe(json['days_together']) ?? 0,
      partnerName: json['partner_name'] as String? ?? '',
      partnerPhotoUrl: json['partner_photo_url'] as String?,
      myPhotoUrl: json['my_photo_url'] as String?,
      currentMilestone: json['current_milestone'] != null
          ? CoupleMilestone.fromJson(json['current_milestone'])
          : null,
      nextMilestone: json['next_milestone'] != null
          ? CoupleMilestone.fromJson(json['next_milestone'])
          : null,
      isAnniversaryToday: json['is_anniversary_today'] == true,
    );
  }
}

/// Couple milestone
class CoupleMilestone {
  final int days;
  final String label;
  final String icon;
  final bool isSpecial;
  final DateTime? date;
  final int? daysUntil;
  final bool isReached;

  CoupleMilestone({
    required this.days,
    required this.label,
    required this.icon,
    this.isSpecial = false,
    this.date,
    this.daysUntil,
    this.isReached = false,
  });

  factory CoupleMilestone.fromJson(Map<String, dynamic> json) {
    return CoupleMilestone(
      days: _parseIntSafe(json['days']) ?? 0,
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? 'heart',
      isSpecial: json['is_special'] == true,
      date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
      daysUntil: _parseIntSafe(json['days_until']),
      isReached: json['is_reached'] == true,
    );
  }

  /// Predefined milestones
  static List<CoupleMilestone> get defaultMilestones => [
        CoupleMilestone(days: 7, label: '1 semaine', icon: 'seedling'),
        CoupleMilestone(days: 30, label: '1 mois', icon: 'heart'),
        CoupleMilestone(days: 90, label: '3 mois', icon: 'star'),
        CoupleMilestone(days: 180, label: '6 mois', icon: 'fire'),
        CoupleMilestone(days: 365, label: '1 an', icon: 'crown', isSpecial: true),
        CoupleMilestone(days: 730, label: '2 ans', icon: 'diamond', isSpecial: true),
      ];
}

/// Success story
class SuccessStory {
  final int id;
  final String couple1Name;
  final String couple2Name;
  final String? couple1PhotoUrl;
  final String? couple2PhotoUrl;
  final String story;
  final List<String> photoUrls;
  final String status; // 'dating', 'engaged', 'married'
  final DateTime? statusDate;
  final DateTime matchDate;
  final DateTime submittedAt;
  final int likesCount;
  final bool isLikedByMe;
  final bool isApproved;

  SuccessStory({
    required this.id,
    required this.couple1Name,
    required this.couple2Name,
    this.couple1PhotoUrl,
    this.couple2PhotoUrl,
    required this.story,
    this.photoUrls = const [],
    this.status = 'dating',
    this.statusDate,
    required this.matchDate,
    required this.submittedAt,
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.isApproved = false,
  });

  String get statusLabel {
    switch (status) {
      case 'engaged':
        return 'Fiances';
      case 'married':
        return 'Maries';
      default:
        return 'En couple';
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'engaged':
        return '💍';
      case 'married':
        return '👰';
      default:
        return '❤️';
    }
  }

  factory SuccessStory.fromJson(Map<String, dynamic> json) {
    return SuccessStory(
      id: _parseIntSafe(json['id']) ?? 0,
      couple1Name: json['couple1_name'] as String? ?? '',
      couple2Name: json['couple2_name'] as String? ?? '',
      couple1PhotoUrl: json['couple1_photo_url'] as String?,
      couple2PhotoUrl: json['couple2_photo_url'] as String?,
      story: json['story'] as String? ?? '',
      photoUrls: (json['photo_urls'] as List<dynamic>?)
              ?.map((p) => p as String)
              .toList() ??
          [],
      status: json['status'] as String? ?? 'dating',
      statusDate: json['status_date'] != null
          ? DateTime.tryParse(json['status_date'])
          : null,
      matchDate: DateTime.tryParse(json['match_date'] ?? '') ?? DateTime.now(),
      submittedAt:
          DateTime.tryParse(json['submitted_at'] ?? '') ?? DateTime.now(),
      likesCount: _parseIntSafe(json['likes_count']) ?? 0,
      isLikedByMe: json['is_liked_by_me'] == true,
      isApproved: json['is_approved'] == true,
    );
  }
}
