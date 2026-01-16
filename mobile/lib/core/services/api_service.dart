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
      id: json['id'] as int,
      matchId: json['matchId'] as int? ?? 0,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
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
      userId: json['user_id'] as int,
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
      id: json['id'] as int,
      senderId: json['sender_id'] as int,
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
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventType: json['event_type'] as String?,
      location: json['location'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      date: DateTime.parse(json['date']),
      time: json['time'] as String?,
      endTime: json['end_time'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
      maxAttendees: json['max_attendees'] as int?,
      attendeeCount: json['attendee_count'] as int? ?? 0,
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
