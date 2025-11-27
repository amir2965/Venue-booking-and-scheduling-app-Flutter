import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/notification_monitor_service.dart';
import '../providers/notification_provider.dart';

class InAppNotificationOverlay extends ConsumerWidget {
  final Widget child;

  const InAppNotificationOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inAppNotification = ref.watch(inAppNotificationProvider);

    return Stack(
      alignment: Alignment.topCenter, // Use non-directional alignment
      children: [
        child,
        if (inAppNotification != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: InAppNotificationCard(
              notification: inAppNotification,
              onDismiss: () {
                // Mark as dismissed in the monitoring service
                ref
                    .read(notificationMonitorProvider)
                    .markNotificationAsDismissed(inAppNotification.id);
                // Clear from UI
                ref.read(inAppNotificationProvider.notifier).state = null;
              },
            ),
          ),
      ],
    );
  }
}

class InAppNotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;

  const InAppNotificationCard({
    Key? key,
    required this.notification,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<InAppNotificationCard> createState() => _InAppNotificationCardState();
}

class _InAppNotificationCardState extends State<InAppNotificationCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    // Start animation
    _slideController.forward();
    _fadeController.forward();

    // Auto dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    _dismissTimer?.cancel();

    if (!mounted) return;

    if (_slideController.isCompleted || _slideController.isAnimating) {
      await _slideController.reverse();
    }
    if (_fadeController.isCompleted || _fadeController.isAnimating) {
      await _fadeController.reverse();
    }
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: _getGradientForType(widget.notification.type),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconForType(widget.notification.type),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getTitleForType(widget.notification.type),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.notification.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Gradient _getGradientForType(String type) {
    switch (type) {
      case 'match':
        return const LinearGradient(
          colors: [Color(0xFF00C851), Color(0xFF007E33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'message':
        return const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'like':
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF757575), Color(0xFF424242)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'match':
        return Icons.favorite;
      case 'message':
        return Icons.message;
      case 'like':
        return Icons.thumb_up;
      default:
        return Icons.notifications;
    }
  }

  String _getTitleForType(String type) {
    switch (type) {
      case 'match':
        return 'It\'s a Match!';
      case 'message':
        return 'New Message';
      case 'like':
        return 'Someone Liked You!';
      default:
        return 'Notification';
    }
  }
}

// Extension to easily wrap any widget with notification overlay
extension WidgetExtensions on Widget {
  Widget withNotificationOverlay() {
    return InAppNotificationOverlay(child: this);
  }
}
