import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_status_service.dart';
import '../../main.dart';

// Define an enum to track the authentication action
enum AuthAction { none, login, signup }

// Provider to track the last authentication action
final authActionProvider = StateProvider<AuthAction>((ref) => AuthAction.none);

// Provider for the authentication service
final authServiceProvider = Provider<AuthService>((ref) {
  final authService = FirebaseAuthService();

  // Wrap the original signOut method to trigger app reload
  final wrappedAuthService = _WrappedAuthService(
    baseService: authService,
    onSignOut: () {
      // Generate new key to force app rebuild
      ref.read(appKeyProvider.notifier).state = UniqueKey();
    },
  );

  return wrappedAuthService;
});

// Wrapper class to intercept signOut calls
class _WrappedAuthService implements AuthService {
  final AuthService baseService;
  final void Function() onSignOut;

  _WrappedAuthService({
    required this.baseService,
    required this.onSignOut,
  });

  @override
  User? get currentUser => baseService.currentUser;

  @override
  Stream<User?> authStateChanges() => baseService.authStateChanges();

  @override
  Future<User?> getCurrentUser() => baseService.getCurrentUser();

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) =>
      baseService.signInWithEmailAndPassword(email, password);

  @override
  Future<User> createUserWithEmailAndPassword(String email, String password) =>
      baseService.createUserWithEmailAndPassword(email, password);

  @override
  Future<User> signInWithGoogle() => baseService.signInWithGoogle();
  @override
  Future<User> signInWithFacebook() => baseService.signInWithFacebook();

  @override
  Future<void> signOut() async {
    // Set user offline before signing out
    final user = currentUser;
    if (user != null) {
      try {
        final statusService = UserStatusService();
        await statusService.setUserOffline(user.id);
      } catch (e) {
        // Continue with logout even if status update fails
        print('Error setting user offline during logout: $e');
      }
    }

    await baseService.signOut();
    onSignOut();
  }

  @override
  Future<bool> updateUserDisplayName(String displayName) =>
      baseService.updateUserDisplayName(displayName);

  @override
  void setCurrentUser(User user) => baseService.setCurrentUser(user);

  @override
  void clearCurrentUser() => baseService.clearCurrentUser();
}

// Provider that exposes the current auth user
final authUserProvider = StreamProvider.autoDispose<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final stream = authService.authStateChanges();
  ref.onDispose(() {
    // Clean up any subscriptions when the provider is disposed
  });
  return stream;
});

// Provider to get the current auth user ID
final currentUserIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = await authService.getCurrentUser();
  return user?.id;
});

// Provider that checks if a user is authenticated
final isAuthenticatedProvider = Provider.autoDispose<bool>((ref) {
  final authState = ref.watch(authUserProvider);
  return authState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

// Providers for auth loading and error states
final authLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);
final authErrorProvider = StateProvider.autoDispose<String?>((ref) => null);

// Provider for user status service
final userStatusServiceProvider =
    Provider<UserStatusService>((ref) => UserStatusService());

// Provider to manage current user online status
final userStatusProvider =
    StateNotifierProvider.autoDispose<UserStatusNotifier, UserStatusState>(
        (ref) {
  final authService = ref.watch(authServiceProvider);
  final statusService = ref.watch(userStatusServiceProvider);
  return UserStatusNotifier(authService, statusService);
});

class UserStatusState {
  final bool isOnline;
  final bool isUpdating;
  final String? error;

  UserStatusState({
    this.isOnline = false,
    this.isUpdating = false,
    this.error,
  });

  UserStatusState copyWith({
    bool? isOnline,
    bool? isUpdating,
    String? error,
  }) {
    return UserStatusState(
      isOnline: isOnline ?? this.isOnline,
      isUpdating: isUpdating ?? this.isUpdating,
      error: error ?? this.error,
    );
  }
}

class UserStatusNotifier extends StateNotifier<UserStatusState> {
  final AuthService _authService;
  final UserStatusService _statusService;

  UserStatusNotifier(this._authService, this._statusService)
      : super(UserStatusState()) {
    _initializeStatus();
  }

  void _initializeStatus() async {
    final user = _authService.currentUser;
    if (user != null) {
      await setOnline();
      _statusService.startKeepAlive(user.id);
    }
  }

  Future<void> setOnline() async {
    final user = _authService.currentUser;
    if (user == null) return;

    state = state.copyWith(isUpdating: true);

    try {
      await _statusService.updateUserStatus(
        userId: user.id,
        isOnline: true,
        platform: 'mobile',
        version: '1.0.0',
      );
      state = state.copyWith(isOnline: true, isUpdating: false, error: null);
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
    }
  }

  Future<void> setOffline() async {
    final user = _authService.currentUser;
    if (user == null) return;

    state = state.copyWith(isUpdating: true);

    try {
      await _statusService.setUserOffline(user.id);
      state = state.copyWith(isOnline: false, isUpdating: false, error: null);
    } catch (e) {
      state = state.copyWith(isUpdating: false, error: e.toString());
    }
  }
}
