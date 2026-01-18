import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../models/couple_activity.dart';
import '../models/couple_event.dart';

class CoupleApiService {
  final ApiService _apiService = ApiService();

  // ============ ACTIVITIES ============

  Future<List<CoupleActivity>> getActivities({
    int limit = 20,
    int offset = 0,
    String? category,
  }) async {
    try {
      String endpoint = '/api/couple/activities?limit=$limit&offset=$offset';
      if (category != null) endpoint += '&category=$category';

      final response = await _apiService.get(endpoint);
      if (response['success'] == true && response['activities'] != null) {
        return (response['activities'] as List)
            .map((json) => CoupleActivity.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('CoupleApiService: Error getting activities: $e');
      return [];
    }
  }

  Future<CoupleActivity?> getActivity(int id) async {
    try {
      final response = await _apiService.get('/api/couple/activities/$id');
      if (response['success'] == true && response['activity'] != null) {
        return CoupleActivity.fromJson(response['activity']);
      }
      return null;
    } catch (e) {
      debugPrint('CoupleApiService: Error getting activity: $e');
      return null;
    }
  }

  Future<bool> saveActivity(int activityId, {String? notes}) async {
    try {
      final body = notes != null ? {'notes': notes} : <String, dynamic>{};
      final response = await _apiService.post('/api/couple/activities/$activityId/save', body);
      return response['success'] == true;
    } catch (e) {
      debugPrint('CoupleApiService: Error saving activity: $e');
      return false;
    }
  }

  Future<bool> passActivity(int activityId) async {
    try {
      final response = await _apiService.post('/api/couple/activities/$activityId/pass', {});
      return response['success'] == true;
    } catch (e) {
      debugPrint('CoupleApiService: Error passing activity: $e');
      return false;
    }
  }

  Future<List<CoupleActivity>> getSavedActivities() async {
    try {
      final response = await _apiService.get('/api/couple/saved');
      if (response['success'] == true && response['activities'] != null) {
        return (response['activities'] as List)
            .map((json) => CoupleActivity.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('CoupleApiService: Error getting saved activities: $e');
      return [];
    }
  }

  Future<bool> removeSavedActivity(int activityId) async {
    try {
      final response = await _apiService.delete('/api/couple/saved/$activityId');
      return response['success'] == true;
    } catch (e) {
      debugPrint('CoupleApiService: Error removing saved activity: $e');
      return false;
    }
  }

  // ============ EVENTS ============

  Future<List<CoupleEvent>> getEvents({
    int limit = 20,
    int offset = 0,
    String? category,
  }) async {
    try {
      String endpoint = '/api/couple/events?limit=$limit&offset=$offset';
      if (category != null) endpoint += '&category=$category';

      final response = await _apiService.get(endpoint);
      if (response['success'] == true && response['events'] != null) {
        return (response['events'] as List)
            .map((json) => CoupleEvent.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('CoupleApiService: Error getting events: $e');
      return [];
    }
  }

  Future<CoupleEvent?> getEvent(int id) async {
    try {
      final response = await _apiService.get('/api/couple/events/$id');
      if (response['success'] == true && response['event'] != null) {
        return CoupleEvent.fromJson(response['event']);
      }
      return null;
    } catch (e) {
      debugPrint('CoupleApiService: Error getting event: $e');
      return null;
    }
  }

  Future<bool> registerForEvent(int eventId) async {
    try {
      final response = await _apiService.post('/api/couple/events/$eventId/register', {});
      return response['success'] == true;
    } catch (e) {
      debugPrint('CoupleApiService: Error registering for event: $e');
      return false;
    }
  }

  Future<bool> cancelEventRegistration(int eventId) async {
    try {
      final response = await _apiService.delete('/api/couple/events/$eventId/register');
      return response['success'] == true;
    } catch (e) {
      debugPrint('CoupleApiService: Error cancelling registration: $e');
      return false;
    }
  }

  Future<List<CoupleEvent>> getRegisteredEvents() async {
    try {
      final response = await _apiService.get('/api/couple/events/registered');
      if (response['success'] == true && response['events'] != null) {
        return (response['events'] as List)
            .map((json) => CoupleEvent.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('CoupleApiService: Error getting registered events: $e');
      return [];
    }
  }

  // ============ STATS ============

  Future<Map<String, dynamic>?> getStats() async {
    try {
      final response = await _apiService.get('/api/couple/stats');
      if (response['success'] == true) {
        return {
          'stats': response['stats'],
          'achievements': response['achievements'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('CoupleApiService: Error getting stats: $e');
      return null;
    }
  }

  // ============ DATES ============

  Future<List<Map<String, dynamic>>> getDates() async {
    try {
      final response = await _apiService.get('/api/couple/dates');
      if (response['success'] == true && response['dates'] != null) {
        return (response['dates'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('CoupleApiService: Error getting dates: $e');
      return [];
    }
  }

  Future<bool> addDate({
    required String title,
    required String date,
    required String type,
    bool isRecurring = true,
    int remindDaysBefore = 7,
    String? notes,
  }) async {
    try {
      final response = await _apiService.post('/api/couple/dates', {
        'title': title,
        'date': date,
        'type': type,
        'isRecurring': isRecurring,
        'remindDaysBefore': remindDaysBefore,
        if (notes != null) 'notes': notes,
      });
      return response['success'] == true;
    } catch (e) {
      debugPrint('CoupleApiService: Error adding date: $e');
      return false;
    }
  }

  // ============ BUCKET LIST ============

  Future<List<Map<String, dynamic>>> getBucketList() async {
    try {
      final response = await _apiService.get('/api/couple/bucket-list');
      if (response['success'] == true && response['items'] != null) {
        return (response['items'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('CoupleApiService: Error getting bucket list: $e');
      return [];
    }
  }

  Future<bool> addBucketListItem({
    required String title,
    String? description,
    String? category,
    String? targetDate,
  }) async {
    try {
      final response = await _apiService.post('/api/couple/bucket-list', {
        'title': title,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (targetDate != null) 'targetDate': targetDate,
      });
      return response['success'] == true;
    } catch (e) {
      debugPrint('CoupleApiService: Error adding bucket list item: $e');
      return false;
    }
  }

  Future<bool> completeBucketListItem(int itemId) async {
    try {
      final response = await _apiService.post('/api/couple/bucket-list/$itemId/complete', {});
      return response['success'] == true;
    } catch (e) {
      debugPrint('CoupleApiService: Error completing bucket list item: $e');
      return false;
    }
  }

  // ============ MEMORIES ============

  Future<List<Map<String, dynamic>>> getMemories() async {
    try {
      final response = await _apiService.get('/api/couple/memories');
      if (response['success'] == true && response['memories'] != null) {
        return (response['memories'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('CoupleApiService: Error getting memories: $e');
      return [];
    }
  }

  Future<bool> addMemory({
    required String type,
    String? title,
    String? content,
    String? imageUrl,
    String? memoryDate,
    String? location,
  }) async {
    try {
      final response = await _apiService.post('/api/couple/memories', {
        'type': type,
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (memoryDate != null) 'memoryDate': memoryDate,
        if (location != null) 'location': location,
      });
      return response['success'] == true;
    } catch (e) {
      debugPrint('CoupleApiService: Error adding memory: $e');
      return false;
    }
  }
}
