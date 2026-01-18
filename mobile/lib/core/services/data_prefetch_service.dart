import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service to prefetch and cache data for smooth navigation
class DataPrefetchService {
  static final DataPrefetchService _instance = DataPrefetchService._internal();
  factory DataPrefetchService() => _instance;
  DataPrefetchService._internal();

  final ApiService _apiService = ApiService();

  // Cached data
  List<Profile>? _discoverProfiles;
  List<Map<String, dynamic>>? _matches;
  List<Conversation>? _conversations;
  List<Event>? _events;
  UserProfile? _currentUser;

  // Loading states
  bool _isLoadingDiscover = false;
  bool _isLoadingMatches = false;
  bool _isLoadingConversations = false;
  bool _isLoadingEvents = false;
  bool _isLoadingUser = false;

  // Timestamps for cache invalidation
  DateTime? _discoverLoadedAt;
  DateTime? _matchesLoadedAt;
  DateTime? _conversationsLoadedAt;
  DateTime? _eventsLoadedAt;
  DateTime? _userLoadedAt;

  // Cache duration (5 minutes)
  static const _cacheDuration = Duration(minutes: 5);

  // Listeners for real-time updates
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  // Getters
  List<Profile>? get discoverProfiles => _discoverProfiles;
  List<Map<String, dynamic>>? get matches => _matches;
  List<Conversation>? get conversations => _conversations;
  List<Event>? get events => _events;
  UserProfile? get currentUser => _currentUser;

  bool get hasDiscoverData => _discoverProfiles != null;
  bool get hasMatchesData => _matches != null;
  bool get hasConversationsData => _conversations != null;
  bool get hasEventsData => _events != null;
  bool get hasUserData => _currentUser != null;

  /// Check if cache is still valid
  bool _isCacheValid(DateTime? loadedAt) {
    if (loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < _cacheDuration;
  }

  /// Prefetch all main data
  Future<void> prefetchAll() async {
    debugPrint('DataPrefetchService: Starting prefetch all...');

    // Load data sequentially to avoid socket exhaustion on iOS simulator
    // Each call has a small delay to prevent connection issues
    await fetchCurrentUser();
    await Future.delayed(const Duration(milliseconds: 100));
    await fetchDiscoverProfiles();
    await Future.delayed(const Duration(milliseconds: 100));
    await fetchMatches();
    await Future.delayed(const Duration(milliseconds: 100));
    await fetchConversations();
    await Future.delayed(const Duration(milliseconds: 100));
    await fetchEvents();

    debugPrint('DataPrefetchService: Prefetch complete!');
  }

  /// Fetch discover profiles
  Future<List<Profile>?> fetchDiscoverProfiles({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(_discoverLoadedAt) && _discoverProfiles != null) {
      return _discoverProfiles;
    }

    if (_isLoadingDiscover) return _discoverProfiles;
    _isLoadingDiscover = true;

    try {
      final response = await _apiService.getDiscoverProfiles();
      if (response.success && response.data != null) {
        _discoverProfiles = response.data;
        _discoverLoadedAt = DateTime.now();
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('DataPrefetchService: Error fetching discover: $e');
    } finally {
      _isLoadingDiscover = false;
    }

    return _discoverProfiles;
  }

  /// Fetch matches
  Future<List<Map<String, dynamic>>?> fetchMatches({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(_matchesLoadedAt) && _matches != null) {
      return _matches;
    }

    if (_isLoadingMatches) return _matches;
    _isLoadingMatches = true;

    try {
      final response = await _apiService.getMatches();
      if (response.success && response.data != null) {
        _matches = response.data;
        _matchesLoadedAt = DateTime.now();
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('DataPrefetchService: Error fetching matches: $e');
    } finally {
      _isLoadingMatches = false;
    }

    return _matches;
  }

  /// Fetch conversations
  Future<List<Conversation>?> fetchConversations({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(_conversationsLoadedAt) && _conversations != null) {
      return _conversations;
    }

    if (_isLoadingConversations) return _conversations;
    _isLoadingConversations = true;

    try {
      final response = await _apiService.getConversations();
      if (response.success && response.data != null) {
        _conversations = response.data;
        _conversationsLoadedAt = DateTime.now();
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('DataPrefetchService: Error fetching conversations: $e');
    } finally {
      _isLoadingConversations = false;
    }

    return _conversations;
  }

  /// Fetch events
  Future<List<Event>?> fetchEvents({bool forceRefresh = false, String? type}) async {
    // For filtered events, always fetch (but don't update main cache)
    if (type != null) {
      try {
        final response = await _apiService.getEvents(type: type);
        if (response.success && response.data != null) {
          return response.data;
        }
      } catch (e) {
        debugPrint('DataPrefetchService: Error fetching filtered events: $e');
      }
      return _events;
    }

    if (!forceRefresh && _isCacheValid(_eventsLoadedAt) && _events != null) {
      return _events;
    }

    if (_isLoadingEvents) return _events;
    _isLoadingEvents = true;

    try {
      final response = await _apiService.getEvents();
      if (response.success && response.data != null) {
        _events = response.data;
        _eventsLoadedAt = DateTime.now();
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('DataPrefetchService: Error fetching events: $e');
    } finally {
      _isLoadingEvents = false;
    }

    return _events;
  }

  /// Fetch current user
  Future<UserProfile?> fetchCurrentUser({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid(_userLoadedAt) && _currentUser != null) {
      return _currentUser;
    }

    if (_isLoadingUser) return _currentUser;
    _isLoadingUser = true;

    try {
      final response = await _apiService.getCurrentUser();
      if (response.success && response.data != null) {
        _currentUser = response.data;
        _userLoadedAt = DateTime.now();
        _notifyListeners();
      }
    } catch (e) {
      debugPrint('DataPrefetchService: Error fetching user: $e');
    } finally {
      _isLoadingUser = false;
    }

    return _currentUser;
  }

  /// Update cached data (e.g., after a swipe removes a profile)
  void removeDiscoverProfile(int index) {
    if (_discoverProfiles != null && index < _discoverProfiles!.length) {
      _discoverProfiles!.removeAt(index);
      _notifyListeners();
    }
  }

  /// Update conversations (e.g., after receiving a new message)
  void updateConversations(List<Conversation> conversations) {
    _conversations = conversations;
    _conversationsLoadedAt = DateTime.now();
    _notifyListeners();
  }

  /// Clear all cached data
  void clearAll() {
    _discoverProfiles = null;
    _matches = null;
    _conversations = null;
    _events = null;
    _currentUser = null;
    _discoverLoadedAt = null;
    _matchesLoadedAt = null;
    _conversationsLoadedAt = null;
    _eventsLoadedAt = null;
    _userLoadedAt = null;
    _notifyListeners();
  }

  /// Invalidate specific cache
  void invalidateDiscover() {
    _discoverLoadedAt = null;
  }

  void invalidateMatches() {
    _matchesLoadedAt = null;
  }

  void invalidateConversations() {
    _conversationsLoadedAt = null;
  }

  void invalidateEvents() {
    _eventsLoadedAt = null;
  }
}
