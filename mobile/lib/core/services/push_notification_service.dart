import 'package:onesignal_flutter/onesignal_flutter.dart';

class PushNotificationService {
  static const String _appId = '0bad7c7f-4a93-4a6d-84e7-ed77a48532cf';

  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Enable verbose logging for debugging (remove in production)
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize OneSignal
    OneSignal.initialize(_appId);

    // Request push notification permission
    await OneSignal.Notifications.requestPermission(true);

    // Handle notification opened
    OneSignal.Notifications.addClickListener((event) {
      final data = event.notification.additionalData;
      if (data != null) {
        _handleNotificationData(data);
      }
    });

    // Handle notification received in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Display the notification
      event.notification.display();
    });

    _initialized = true;
  }

  /// Login user to OneSignal (call after user authentication)
  Future<void> loginUser(int userId) async {
    await OneSignal.login('user_$userId');
  }

  /// Logout user from OneSignal (call on user logout)
  Future<void> logoutUser() async {
    await OneSignal.logout();
  }

  /// Set user tags for segmentation
  Future<void> setUserTags(Map<String, String> tags) async {
    await OneSignal.User.addTags(tags);
  }

  /// Remove user tags
  Future<void> removeUserTags(List<String> keys) async {
    await OneSignal.User.removeTags(keys);
  }

  /// Handle notification data for deep linking
  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'new_match':
        // Navigate to matches screen
        break;
      case 'new_message':
        // Navigate to chat screen
        break;
      case 'event_reminder':
        final eventId = data['eventId'];
        if (eventId != null) {
          // Navigate to event detail
        }
        break;
      case 'couple_question':
        // Navigate to couple dashboard
        break;
      default:
        break;
    }
  }
}
