import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/couple_activity.dart';

/// Local service to manage saved activities (until backend is ready)
class SavedActivitiesService {
  static final SavedActivitiesService _instance = SavedActivitiesService._internal();
  factory SavedActivitiesService() => _instance;
  SavedActivitiesService._internal();

  static const _storageKey = 'saved_activities';

  // In-memory cache
  final List<CoupleActivity> _savedActivities = [];
  bool _initialized = false;

  /// Get all saved activities
  List<CoupleActivity> get savedActivities => List.unmodifiable(_savedActivities);

  /// Initialize the service (load from storage)
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _savedActivities.clear();
        _savedActivities.addAll(
          jsonList.map((json) => CoupleActivity.fromJson(json)).toList(),
        );
      }
      _initialized = true;
    } catch (e) {
      debugPrint('SavedActivitiesService: Error loading: $e');
    }
  }

  /// Save an activity
  Future<bool> saveActivity(CoupleActivity activity) async {
    await initialize();

    // Check if already saved
    if (_savedActivities.any((a) => a.id == activity.id)) {
      return true; // Already saved
    }

    // Add with savedAt timestamp
    final savedActivity = CoupleActivity(
      id: activity.id,
      title: activity.title,
      description: activity.description,
      category: activity.category,
      subcategory: activity.subcategory,
      imageUrl: activity.imageUrl,
      priceCents: activity.priceCents,
      location: activity.location,
      address: activity.address,
      city: activity.city,
      rating: activity.rating,
      reviewCount: activity.reviewCount,
      isKosher: activity.isKosher,
      isPartner: activity.isPartner,
      partnerName: activity.partnerName,
      discountPercent: activity.discountPercent,
      discountCode: activity.discountCode,
      bookingUrl: activity.bookingUrl,
      phone: activity.phone,
      website: activity.website,
      durationMinutes: activity.durationMinutes,
      tags: activity.tags,
      savedAt: DateTime.now(),
      userNotes: activity.userNotes,
    );

    _savedActivities.insert(0, savedActivity);
    await _persist();

    debugPrint('SavedActivitiesService: Saved "${activity.title}"');
    return true;
  }

  /// Remove a saved activity
  Future<bool> removeActivity(int activityId) async {
    await initialize();

    final index = _savedActivities.indexWhere((a) => a.id == activityId);
    if (index != -1) {
      _savedActivities.removeAt(index);
      await _persist();
      debugPrint('SavedActivitiesService: Removed activity $activityId');
      return true;
    }
    return false;
  }

  /// Check if an activity is saved
  bool isActivitySaved(int activityId) {
    return _savedActivities.any((a) => a.id == activityId);
  }

  /// Get a saved activity by ID
  CoupleActivity? getActivity(int activityId) {
    try {
      return _savedActivities.firstWhere((a) => a.id == activityId);
    } catch (_) {
      return null;
    }
  }

  /// Persist to storage
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _savedActivities.map((a) => a.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('SavedActivitiesService: Error persisting: $e');
    }
  }

  /// Clear all saved activities
  Future<void> clear() async {
    _savedActivities.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
