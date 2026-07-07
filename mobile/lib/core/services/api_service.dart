import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import 'auth_service.dart';

// Data-model classes extracted out of this file into `lib/core/models/`.
// Imported so `ApiService` method signatures resolve the model types, and
// re-exported so every existing `import '.../api_service.dart'` keeps seeing
// the models without any change at the call sites (barrel re-export).
import '../models/profile.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/event.dart';
import '../models/blocked_user.dart';
import '../models/likes.dart';
import '../models/profile_prompt.dart';
import '../models/boost_status.dart';
import '../models/visitors.dart';
import '../models/couple_anniversary.dart';
import '../models/success_story.dart';

export '../models/profile.dart';
export '../models/conversation.dart';
export '../models/message.dart';
export '../models/event.dart';
export '../models/blocked_user.dart';
export '../models/report_category.dart';
export '../models/likes.dart';
export '../models/profile_prompt.dart';
export '../models/relationship_intention.dart';
export '../models/compatibility_score.dart';
export '../models/boost_status.dart';
export '../models/visitors.dart';
export '../models/couple_anniversary.dart';
export '../models/success_story.dart';

/// API Configuration
///
/// The base URL is resolved per-environment from `--dart-define` via [Env].
/// See `lib/core/config/env.dart` for launch instructions.
class ApiConfig {
  static const String baseUrl = Env.apiBaseUrl;

  /// Maximum time to wait for any single network request before failing fast.
  /// Prevents an unresponsive backend from leaving the UI on an infinite spinner.
  static const Duration requestTimeout = Duration(seconds: 15);
}

/// Kind of failure surfaced by a failed [ApiResponse].
///
/// Lets callers differentiate transient network problems (timeout, no
/// connectivity, server unreachable) from application-level errors without
/// parsing message strings. Existing call sites that only read [ApiResponse.error]
/// keep working unchanged.
enum ApiErrorKind { timeout, network, server, unknown }

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final ApiErrorKind? errorKind;

  ApiResponse({required this.success, this.data, this.error, this.errorKind});

  factory ApiResponse.success(T data) => ApiResponse(success: true, data: data);
  factory ApiResponse.failure(String error, [ApiErrorKind kind = ApiErrorKind.unknown]) =>
      ApiResponse(success: false, error: error, errorKind: kind);
}

/// Translates a caught network exception into a user-facing [ApiResponse.failure].
///
/// Centralises the timeout vs. connectivity vs. generic distinction so every
/// endpoint reports clear, differentiated messages instead of a raw
/// `e.toString()`.
ApiResponse<T> _networkFailure<T>(Object error) {
  if (error is TimeoutException) {
    return ApiResponse.failure(
      'Délai d\'attente dépassé, vérifie ta connexion.',
      ApiErrorKind.timeout,
    );
  }
  if (error is SocketException) {
    return ApiResponse.failure(
      'Pas de connexion internet ou serveur injoignable.',
      ApiErrorKind.network,
    );
  }
  if (error is http.ClientException) {
    return ApiResponse.failure(
      'Serveur injoignable, réessaie plus tard.',
      ApiErrorKind.network,
    );
  }
  return ApiResponse.failure(error.toString(), ApiErrorKind.unknown);
}

/// Helper function for safe JSON parsing (handles strings and numbers)
int? _parseIntSafe(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
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
    return http.get(url, headers: _headers).timeout(ApiConfig.requestTimeout);
  }

  /// POST request
  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    debugPrint('API POST: $url');
    return http
        .post(url, headers: _headers, body: jsonEncode(body))
        .timeout(ApiConfig.requestTimeout);
  }

  /// PUT request
  Future<http.Response> _put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    debugPrint('API PUT: $url');
    return http
        .put(url, headers: _headers, body: jsonEncode(body))
        .timeout(ApiConfig.requestTimeout);
  }

  /// DELETE request
  Future<http.Response> _delete(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    debugPrint('API DELETE: $url');
    return http.delete(url, headers: _headers).timeout(ApiConfig.requestTimeout);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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

      final streamedResponse = await request.send().timeout(ApiConfig.requestTimeout);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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

      final streamedResponse = await request.send().timeout(ApiConfig.requestTimeout);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
    }
  }

  /// Cancel RSVP
  Future<ApiResponse<void>> cancelRsvp(int eventId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/events/$eventId/rsvp');
      final response =
          await http.delete(url, headers: _headers).timeout(ApiConfig.requestTimeout);

      if (response.statusCode != 200) {
        return ApiResponse.failure('Failed to cancel RSVP');
      }

      return ApiResponse.success(null);
    } catch (e) {
      debugPrint('API Error: $e');
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
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
      return _networkFailure(e);
    }
  }
}

