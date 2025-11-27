import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/notification_monitor_service.dart';

class NotificationLifecycleManager extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationLifecycleManager({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<NotificationLifecycleManager> createState() =>
      _NotificationLifecycleManagerState();
}

class _NotificationLifecycleManagerState
    extends ConsumerState<NotificationLifecycleManager>
    with WidgetsBindingObserver {
  NotificationMonitorService? _monitorService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start monitoring when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNotificationMonitoring();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopNotificationMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - start monitoring and load notifications
        _startNotificationMonitoring();
        _loadInitialNotifications();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App went to background - stop monitoring to save battery
        _stopNotificationMonitoring();
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        break;
    }
  }

  void _startNotificationMonitoring() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      _monitorService = ref.read(notificationMonitorProvider);
      _monitorService?.startMonitoring();
      ref.read(notificationMonitoringActiveProvider.notifier).state = true;
    }
  }

  void _stopNotificationMonitoring() {
    _monitorService?.stopMonitoring();
    _monitorService = null;
    ref.read(notificationMonitoringActiveProvider.notifier).state = false;
  }

  void _loadInitialNotifications() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      _monitorService?.loadInitialNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth changes to start/stop monitoring
    ref.listen(authUserProvider, (previous, next) {
      if (next != null && previous == null) {
        // User logged in
        _startNotificationMonitoring();
        _loadInitialNotifications();
      } else if (next == null && previous != null) {
        // User logged out
        _stopNotificationMonitoring();
      }
    });

    return widget.child;
  }
}
