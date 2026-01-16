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
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: _parseIntSafe(json['id']) ?? 0,
      senderId: _parseIntSafe(json['sender_id']) ?? 0,
      content: json['content'] as String,
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
