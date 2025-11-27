import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationsNotifier(ref.read(notificationServiceProvider));
});

final unreadCountProvider =
    StateNotifierProvider<UnreadCountNotifier, AsyncValue<int>>((ref) {
  return UnreadCountNotifier(ref.read(notificationServiceProvider));
});

// Provider for showing in-app notifications
final inAppNotificationProvider =
    StateProvider<NotificationModel?>((ref) => null);

// Provider for tracking if user is online/active in the app
final userOnlineStatusProvider = StateProvider<bool>((ref) => false);

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final NotificationService _notificationService;

  NotificationsNotifier(this._notificationService)
      : super(const AsyncValue.loading());

  Future<void> loadNotifications(String userId,
      {bool unreadOnly = false}) async {
    try {
      state = const AsyncValue.loading();
      final notifications = await _notificationService.getNotifications(
        userId,
        unreadOnly: unreadOnly,
      );
      state = AsyncValue.data(notifications);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update the state to mark the notification as read
      state.whenData((notifications) {
        final updatedNotifications = notifications.map((notification) {
          if (notification.id == notificationId) {
            return NotificationModel(
              id: notification.id,
              userId: notification.userId,
              type: notification.type,
              relatedUserId: notification.relatedUserId,
              message: notification.message,
              isRead: true,
              createdAt: notification.createdAt,
            );
          }
          return notification;
        }).toList();

        state = AsyncValue.data(updatedNotifications);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);

      // Update the state to mark all notifications as read
      state.whenData((notifications) {
        final updatedNotifications = notifications.map((notification) {
          return NotificationModel(
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            relatedUserId: notification.relatedUserId,
            message: notification.message,
            isRead: true,
            createdAt: notification.createdAt,
          );
        }).toList();

        state = AsyncValue.data(updatedNotifications);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> createMatchNotifications({
    required String firstUserId,
    required String secondUserId,
    required String firstUserName,
    required String secondUserName,
  }) async {
    try {
      final success = await _notificationService.createMatchNotifications(
        firstUserId: firstUserId,
        secondUserId: secondUserId,
        firstUserName: firstUserName,
        secondUserName: secondUserName,
      );

      // If successful, refresh notifications for both users if they're currently loaded
      if (success) {
        // We can't know which user's notifications are currently loaded,
        // so the UI will need to refresh notifications when appropriate
      }

      return success;
    } catch (error) {
      print('Error creating match notifications: $error');
      return false;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final success =
          await _notificationService.deleteNotification(notificationId);
      if (success) {
        // Remove from local state
        state.whenData((notifications) {
          final updatedNotifications = notifications
              .where((notification) => notification.id != notificationId)
              .toList();
          state = AsyncValue.data(updatedNotifications);
        });
      }
    } catch (error) {
      print('Error deleting notification: $error');
    }
  }
}

class UnreadCountNotifier extends StateNotifier<AsyncValue<int>> {
  final NotificationService _notificationService;

  UnreadCountNotifier(this._notificationService)
      : super(const AsyncValue.loading());

  Future<void> loadUnreadCount(String userId) async {
    try {
      state = const AsyncValue.loading();
      final count = await _notificationService.getUnreadCount(userId);
      state = AsyncValue.data(count);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void decrementCount() {
    state.whenData((count) {
      if (count > 0) {
        state = AsyncValue.data(count - 1);
      }
    });
  }

  void resetCount() {
    state = const AsyncValue.data(0);
  }

  void updateCount(int newCount) {
    state = AsyncValue.data(newCount);
  }
}
