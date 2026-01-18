import 'package:mazl/core/models/couple_activity.dart';
import 'package:mazl/core/models/couple_event.dart';

import 'mock_data.dart';

/// Mock implementation of CoupleApiService for testing
class MockCoupleApiService {
  bool shouldFail = false;
  int callCount = 0;

  // Track method calls for verification
  final List<String> methodCalls = [];

  void reset() {
    shouldFail = false;
    callCount = 0;
    methodCalls.clear();
  }

  // ============ ACTIVITIES ============

  Future<List<CoupleActivity>> getActivities({
    int limit = 20,
    int offset = 0,
    String? category,
  }) async {
    methodCalls.add('getActivities');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) return [];

    var result = MockData.activities;
    if (category != null) {
      result = result.where((a) => a.category == category).toList();
    }
    return result.skip(offset).take(limit).toList();
  }

  Future<CoupleActivity?> getActivity(int id) async {
    methodCalls.add('getActivity:$id');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) return null;

    try {
      return MockData.activities.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveActivity(int activityId, {String? notes}) async {
    methodCalls.add('saveActivity:$activityId');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return !shouldFail;
  }

  Future<bool> passActivity(int activityId) async {
    methodCalls.add('passActivity:$activityId');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return !shouldFail;
  }

  Future<List<CoupleActivity>> getSavedActivities() async {
    methodCalls.add('getSavedActivities');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) return [];
    return MockData.savedActivities;
  }

  Future<bool> removeSavedActivity(int activityId) async {
    methodCalls.add('removeSavedActivity:$activityId');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return !shouldFail;
  }

  // ============ EVENTS ============

  Future<List<CoupleEvent>> getEvents({
    int limit = 20,
    int offset = 0,
    String? category,
  }) async {
    methodCalls.add('getEvents');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) return [];

    var result = MockData.events;
    if (category != null) {
      result = result.where((e) => e.category == category).toList();
    }
    return result.skip(offset).take(limit).toList();
  }

  Future<CoupleEvent?> getEvent(int id) async {
    methodCalls.add('getEvent:$id');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) return null;

    try {
      return MockData.events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> registerForEvent(int eventId) async {
    methodCalls.add('registerForEvent:$eventId');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return !shouldFail;
  }

  Future<bool> cancelEventRegistration(int eventId) async {
    methodCalls.add('cancelEventRegistration:$eventId');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return !shouldFail;
  }

  Future<List<CoupleEvent>> getRegisteredEvents() async {
    methodCalls.add('getRegisteredEvents');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) return [];
    return MockData.registeredEvents;
  }

  // ============ STATS ============

  Future<Map<String, dynamic>?> getStats() async {
    methodCalls.add('getStats');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) return null;
    return MockData.stats;
  }

  // ============ DATES ============

  Future<List<Map<String, dynamic>>> getDates() async {
    methodCalls.add('getDates');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) return [];
    return MockData.dates;
  }

  Future<bool> addDate({
    required String title,
    required String date,
    required String type,
    bool isRecurring = true,
    int remindDaysBefore = 7,
    String? notes,
  }) async {
    methodCalls.add('addDate:$title');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return !shouldFail;
  }

  // ============ BUCKET LIST ============

  Future<List<Map<String, dynamic>>> getBucketList() async {
    methodCalls.add('getBucketList');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) return [];
    return MockData.bucketList;
  }

  Future<bool> addBucketListItem({
    required String title,
    String? description,
    String? category,
    String? targetDate,
  }) async {
    methodCalls.add('addBucketListItem:$title');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return !shouldFail;
  }

  Future<bool> completeBucketListItem(int itemId) async {
    methodCalls.add('completeBucketListItem:$itemId');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return !shouldFail;
  }

  // ============ MEMORIES ============

  Future<List<Map<String, dynamic>>> getMemories() async {
    methodCalls.add('getMemories');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));

    if (shouldFail) return [];
    return MockData.memories;
  }

  Future<bool> addMemory({
    required String type,
    String? title,
    String? content,
    String? imageUrl,
    String? memoryDate,
    String? location,
  }) async {
    methodCalls.add('addMemory:$type');
    callCount++;
    await Future.delayed(const Duration(milliseconds: 10));
    return !shouldFail;
  }
}
