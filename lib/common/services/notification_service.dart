import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize notification service
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');

      // Get FCM token
      String? token = await _messaging.getToken();
      print('FCM Token: $token');

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleMessage);
    }
  }

  /// Handle incoming messages
  void _handleMessage(RemoteMessage message) {
    print('Received message: ${message.notification?.title}');
    // TODO: Show local notification or handle the message
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Subscribe to general updates
  Future<void> subscribeToUpdates() async {
    await subscribeToTopic('updates');
  }

  /// Unsubscribe from general updates
  Future<void> unsubscribeFromUpdates() async {
    await unsubscribeFromTopic('updates');
  }
}
