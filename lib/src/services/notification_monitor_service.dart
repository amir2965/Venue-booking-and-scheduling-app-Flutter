import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';

class NotificationMonitorService {
  final Ref _ref;
  Timer? _notificationTimer;
  String? _currentUserId;
  final Set<String> _shownNotificationIds = {}; // Track shown notifications

  static const String _shownNotificationsKey = 'shown_notification_ids';

  NotificationMonitorService(this._ref);

  /// Start monitoring notifications for the current user
  void startMonitoring() async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    // If user changed, clear shown notifications and load from storage
    if (user.id != _currentUserId) {
      await _loadShownNotifications(user.id);
    }

    _currentUserId = user.id;

    // Check for notifications immediately
    _checkForNewNotifications();

    // Set up periodic checking every 10 seconds for more real-time notifications
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkForNewNotifications(),
    );
  }

  /// Stop monitoring notifications
  void stopMonitoring() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
    _currentUserId = null;
    _shownNotificationIds.clear(); // Clear shown notifications when stopping
  }

  /// Check for new notifications and show them if user is online
  Future<void> _checkForNewNotifications() async {
    if (_currentUserId == null) return;

    try {
      // Get current unread count
      final currentCount = await _ref
          .read(notificationServiceProvider)
          .getUnreadCount(_currentUserId!);

      // Load latest notifications to check for new ones
      final notifications = await _ref
          .read(notificationServiceProvider)
          .getNotifications(_currentUserId!, unreadOnly: true, limit: 5);

      // Find notifications that haven't been shown yet
      final newNotifications = notifications
          .where((notification) =>
              !_shownNotificationIds.contains(notification.id))
          .toList();

      // Show the most recent new notification as in-app notification
      if (newNotifications.isNotEmpty) {
        final latestNotification = newNotifications.first;

        // Only show if it's a match notification and created recently (within last 30 minutes)
        final now = DateTime.now();
        final notificationAge = now.difference(latestNotification.createdAt);

        if (latestNotification.type == 'match' &&
            notificationAge.inMinutes <= 30) {
          // Show in-app notification
          _ref.read(inAppNotificationProvider.notifier).state =
              latestNotification;

          // Mark this notification as shown
          _shownNotificationIds.add(latestNotification.id);
          _saveShownNotifications();

          // Clean up old shown notification IDs (keep only last 50)
          if (_shownNotificationIds.length > 50) {
            final oldIds =
                _shownNotificationIds.take(_shownNotificationIds.length - 50);
            _shownNotificationIds.removeAll(oldIds);
            _saveShownNotifications();
          }
        }
      }

      // Update unread count in UI using the available method
      final unreadNotifier = _ref.read(unreadCountProvider.notifier);
      unreadNotifier.updateCount(currentCount);
    } catch (e) {
      debugPrint('Error checking for new notifications: $e');
    }
  }

  /// Force check for notifications (called when user performs actions)
  Future<void> checkNow() async {
    await _checkForNewNotifications();
  }

  /// Load notifications when user opens the app
  Future<void> loadInitialNotifications() async {
    if (_currentUserId == null) return;

    try {
      // Load unread count
      final count = await _ref
          .read(notificationServiceProvider)
          .getUnreadCount(_currentUserId!);

      final unreadNotifier = _ref.read(unreadCountProvider.notifier);
      unreadNotifier.updateCount(count);

      // Load recent notifications to check for unseen match notifications
      final notifications = await _ref
          .read(notificationServiceProvider)
          .getNotifications(_currentUserId!, unreadOnly: true, limit: 10);

      // Check if there are any recent match notifications that should be shown
      // but only if they haven't been shown before
      final now = DateTime.now();
      for (final notification in notifications) {
        final age = now.difference(notification.createdAt);

        // Show match notifications that are less than 1 hour old AND haven't been shown before
        if (notification.type == 'match' &&
            age.inHours < 1 &&
            !_shownNotificationIds.contains(notification.id)) {
          _ref.read(inAppNotificationProvider.notifier).state = notification;
          _shownNotificationIds.add(notification.id); // Mark as shown
          _saveShownNotifications();
          break; // Only show one at a time
        }
      }
    } catch (e) {
      debugPrint('Error loading initial notifications: $e');
    }
  }

  /// Mark a notification as dismissed (won't show again)
  void markNotificationAsDismissed(String notificationId) {
    _shownNotificationIds.add(notificationId);
    _saveShownNotifications();
  }

  /// Load shown notification IDs from persistent storage
  Future<void> _loadShownNotifications(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_shownNotificationsKey}_$userId';
      final savedIds = prefs.getStringList(key) ?? [];

      _shownNotificationIds.clear();
      _shownNotificationIds.addAll(savedIds);

      // Keep only recent IDs (last 100) to prevent unlimited growth
      if (_shownNotificationIds.length > 100) {
        final idsToKeep =
            _shownNotificationIds.skip(_shownNotificationIds.length - 100);
        _shownNotificationIds.clear();
        _shownNotificationIds.addAll(idsToKeep);
        await _saveShownNotifications();
      }
    } catch (e) {
      debugPrint('Error loading shown notifications: $e');
      _shownNotificationIds.clear();
    }
  }

  /// Save shown notification IDs to persistent storage
  Future<void> _saveShownNotifications() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_shownNotificationsKey}_$_currentUserId';
      await prefs.setStringList(key, _shownNotificationIds.toList());
    } catch (e) {
      debugPrint('Error saving shown notifications: $e');
    }
  }
}

// Provider for the notification monitor service
final notificationMonitorProvider = Provider<NotificationMonitorService>((ref) {
  return NotificationMonitorService(ref);
});

// Provider to track if notification monitoring is active
final notificationMonitoringActiveProvider =
    StateProvider<bool>((ref) => false);
