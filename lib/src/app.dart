import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/player_profile.dart';
import 'providers/auth_provider.dart';
import 'providers/player_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/profile_setup_screen_new.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/partners/partner_match_screen.dart';
import 'screens/partners/partner_swipe_screen.dart';
import 'screens/server_status_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/test/username_test_screen.dart';
import 'screens/test/web_mongodb_test_screen.dart';
import 'screens/venues/venue_detail_screen.dart';
import 'screens/venues/venue_list_screen.dart';
import 'screens/venues/wishlist_screen.dart';
import 'screens/matchmaking/matchmaking_screen.dart';
import 'screens/matches/matches_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'widgets/in_app_notification_overlay.dart';
import 'widgets/notification_lifecycle_manager.dart';
import 'theme/theme.dart';

// Theme provider to track and switch between light and dark themes
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Router configuration with authentication
final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);

  return GoRouter(
    refreshListenable: router,
    redirect: router._redirect,
    routes: router._routes,
    initialLocation: '/',
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Listen for both auth and profile changes to ensure proper redirection
    _ref.listen(authUserProvider, (_, __) => notifyListeners());
    _ref.listen(currentUserProfileProvider, (_, __) => notifyListeners());
    _ref.listen(
      hasCompletedProfileSetupProvider,
      (_, __) => notifyListeners(),
    );
  }
  String? _redirect(BuildContext context, GoRouterState state) {
    final isAuth = _ref.read(isAuthenticatedProvider);
    final isSplash = state.matchedLocation == '/';
    final isOnboarding = state.matchedLocation == '/onboarding';
    final isLoginRoute = state.matchedLocation == '/login';
    final isSignupRoute = state.matchedLocation == '/signup';
    final isProfileSetupRoute = state.matchedLocation == '/profile-setup';

    debugPrint('Router redirect check for route: ${state.matchedLocation}');

    // Allow access to splash and onboarding without auth
    if (isSplash || isOnboarding) return null;

    // If not authenticated, only allow access to login and signup
    if (!isAuth) {
      if (isLoginRoute || isSignupRoute) return null;
      return '/login';
    }

    // Check if the user has completed their profile setup
    final hasCompletedProfileAsync =
        _ref.watch(hasCompletedProfileSetupProvider);

    // Avoid redirects while loading to prevent flicker
    if (hasCompletedProfileAsync.isLoading) {
      debugPrint('Profile setup provider loading - waiting...');
      return null;
    } // Handle error case
    if (hasCompletedProfileAsync.hasError) {
      debugPrint(
          'Error in profile completion check: ${hasCompletedProfileAsync.error}');
      if (!isProfileSetupRoute && !isLoginRoute && !isSignupRoute) {
        return '/profile-setup';
      }
      return null;
    }
    final hasCompletedProfile = hasCompletedProfileAsync.value ?? false;
    debugPrint(
        'Profile completion status: $hasCompletedProfile'); // Allow signup screen always
    if (isSignupRoute) {
      debugPrint('Currently in signup flow');
      return null;
    }

    // After signup, force profile setup if incomplete
    if (!hasCompletedProfile && !isProfileSetupRoute) {
      debugPrint('Profile incomplete - redirecting to setup');
      return '/profile-setup';
    }

    // Prevent going back to profile setup if complete
    if (isProfileSetupRoute && hasCompletedProfile) {
      debugPrint('Profile already complete - redirecting to home');
      return '/home';
    }

    // Don't allow access to profile setup if already completed
    if (isProfileSetupRoute && hasCompletedProfile) {
      debugPrint('Profile already complete - redirecting to home');
      return '/home';
    }

    // If profile is complete and user is on auth pages, redirect to home
    if (hasCompletedProfile && (isLoginRoute || isSignupRoute)) {
      debugPrint('Profile complete, redirecting from auth to home');
      return '/home';
    }

    // If profile is complete, allow access to any non-auth page
    if (hasCompletedProfile) {
      debugPrint('Profile complete - allowing access to current page');
      return null;
    }

    return null;
  }

  List<RouteBase> get _routes => [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/profile-setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const HomeScreen(), // Updated to use new HomeScreen
        ),
        GoRoute(
          path: '/venues',
          builder: (context, state) => const VenueListScreen(),
        ),
        GoRoute(
          path: '/venues/wishlist',
          builder: (context, state) => const WishlistScreen(),
        ),
        GoRoute(
          path: '/venues/:id',
          builder: (context, state) => VenueDetailScreen(
            venueId: state.pathParameters['id'] ?? '',
          ),
        ),
        GoRoute(
          path: '/partners',
          builder: (context, state) => const PartnerMatchScreen(),
        ),
        GoRoute(
          path: '/partners/swipe',
          builder: (context, state) => const PartnerSwipeScreen(),
        ),
        GoRoute(
          path: '/matchmaking',
          builder: (context, state) => const MatchmakingScreen(),
        ),
        GoRoute(
          path: '/matches',
          builder: (context, state) => const MatchesScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/chats',
          builder: (context, state) => const ChatListScreen(),
        ),
        GoRoute(
          path: '/chat/:chatId',
          builder: (context, state) => ChatScreen(
            chatId: state.pathParameters['chatId'] ?? '',
            initialUserName: state.uri.queryParameters['userName'],
          ),
        ),
        GoRoute(
          path: '/test/username',
          builder: (context, state) => const UsernameTestScreen(),
        ),
        GoRoute(
          path: '/test/web-mongodb',
          builder: (context, state) => const WebMongoDBTestScreen(),
        ),
        GoRoute(
          path: '/server-status',
          builder: (context, state) => const ServerStatusScreen(),
        ),
      ];
}

class BilliardsHubApp extends ConsumerWidget {
  const BilliardsHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return NotificationLifecycleManager(
      child: MaterialApp.router(
        title: 'Sports Hub',
        debugShowCheckedModeBanner: false,
        themeMode: themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: router,
        builder: (context, child) {
          return InAppNotificationOverlay(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class PlaceholderHome extends ConsumerWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserProfileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Hub'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final themeMode = ref.watch(themeProvider);
              return IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () {
                  ref.read(themeProvider.notifier).state =
                      themeMode == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Sign out and navigate to login
              context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User profile card
            currentUserProfileAsync.when(
              data: (profile) => profile != null
                  ? _buildUserProfileCard(context, profile)
                  : const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error loading profile: $error'),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Welcome to Sports Hub!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Your ultimate venue sports companion',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),

            // Feature buttons section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureButton(
                    context: context,
                    icon: Icons.calendar_today,
                    label: 'Book',
                    color: AppTheme.primaryGreen,
                  ),
                  _buildFeatureButton(
                    context: context,
                    icon: Icons.people,
                    label: 'Match',
                    color: AppTheme.secondaryBlue,
                  ),
                  _buildFeatureButton(
                    context: context,
                    icon: Icons.emoji_events,
                    label: 'Tournaments',
                    color: AppTheme.accentOrange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Matches section
            _buildMatchesSection(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(BuildContext context, PlayerProfile profile) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withOpacity(0.8),
            AppTheme.secondaryBlue.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                backgroundImage: profile.user.photoUrl != null
                    ? NetworkImage(profile.user.photoUrl!)
                    : null,
                child: profile.user.photoUrl == null
                    ? const Icon(Icons.person,
                        size: 40, color: AppTheme.primaryGreen)
                    : null,
              ),
              const SizedBox(width: 16),

              // User details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.user.displayName ?? 'Player',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                profile.skillLevel.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          profile.skillTier,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Edit profile button
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () {
                  // Show edit profile dialog or navigate to edit profile screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit Profile feature coming soon!'),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // XP and level progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP: ${profile.experiencePoints}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(profile.experiencePoints / 1000).floor()} / ${(profile.experiencePoints / 1000).floor() + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: profile.levelProgressPercentage / 100,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  color: Colors.white,
                  minHeight: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.emoji_events,
                '${profile.matchesPlayed}',
                'Matches',
              ),
              _buildStatItem(
                Icons.analytics,
                '${(profile.winRate * 100).toInt()}%',
                'Win Rate',
              ),
              _buildStatItem(
                Icons.star_border,
                '${profile.achievements.length}',
                'Achievements',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesSection(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(userMatchesProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Matches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go('/partners');
                },
                child: const Text('View All'),
              ),
            ],
          ),
          matchesAsync.when(
            data: (matches) {
              if (matches.isEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No matches yet. Start swiping to find partners!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                children: matches.take(2).map((match) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundImage: match.user.photoUrl != null
                          ? NetworkImage(match.user.photoUrl!)
                          : null,
                      child: match.user.photoUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(match.user.displayName ?? 'Player'),
                    subtitle: Text(match.preferredGameTypes.join(', ')),
                    trailing: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Chat feature coming soon!'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Chat'),
                    ),
                    onTap: () {
                      context.go('/partners');
                    },
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading matches: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        // Add navigation based on button label
        if (label == 'Book') {
          context.go('/venues');
        } else if (label == 'Match') {
          context.go('/partners');
        } else if (label == 'Tournaments') {
          // For future implementation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tournaments feature coming soon!')),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
