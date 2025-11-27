import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && !_hasNavigated) {
        _navigateToNextScreen();
      }
    });

    _controller.forward();
  }

  void _navigateToNextScreen() async {
    if (!_hasNavigated) {
      setState(() {
        _hasNavigated = true;
      });

      try {
        // Wait a bit for auth state to initialize
        await Future.delayed(const Duration(milliseconds: 500));

        // Check authentication state
        final authState = ref.read(authUserProvider);

        // Handle loading state
        if (authState.isLoading) {
          debugPrint('Auth state still loading, waiting...');
          await Future.delayed(const Duration(milliseconds: 1000));
          final retryAuthState = ref.read(authUserProvider);
          if (retryAuthState.isLoading) {
            debugPrint(
                'Auth state still loading after retry, going to onboarding');
            if (mounted) context.go('/onboarding');
            return;
          }
        }

        final user = authState.value;

        if (user != null) {
          debugPrint('User authenticated: ${user.email}');
          // User is authenticated, check if profile is complete
          try {
            final hasCompletedProfile =
                await ref.read(hasCompletedProfileSetupProvider.future);
            debugPrint('Profile completion status: $hasCompletedProfile');
            if (hasCompletedProfile) {
              debugPrint(
                  'User authenticated with complete profile - going to home');
              if (mounted) context.go('/home');
            } else {
              debugPrint(
                  'User authenticated but profile incomplete - going to profile setup');
              if (mounted) context.go('/profile-setup');
            }
          } catch (e) {
            debugPrint('Error checking profile completion: $e');
            // If there's an error with profile check, go to profile setup to be safe
            if (mounted) context.go('/profile-setup');
          }
        } else {
          // User not authenticated, go to onboarding
          debugPrint('User not authenticated - going to onboarding');
          if (mounted) context.go('/onboarding');
        }
      } catch (e) {
        debugPrint('Error in splash navigation: $e');
        // Fallback to onboarding if there's any error
        if (mounted) context.go('/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with animations
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.sports_bar,
                        size: 80,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  )
                      .animate()
                      .scale(
                        duration: 800.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1.0, 1.0),
                      )
                      .then()
                      .shimmer(
                        duration: 1200.ms,
                        color: Colors.white.withOpacity(0.8),
                      ),

                  const SizedBox(height: 40),

                  // App name with animation
                  Text(
                    'Billiards Hub',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(
                      begin: 0.5,
                      end: 0,
                      curve: Curves.easeOutQuad,
                      duration: 600.ms,
                      delay: 400.ms),

                  const SizedBox(height: 20),

                  // Tagline with animation
                  Text(
                    'Your Ultimate Billiards Companion',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ).animate().fadeIn(duration: 600.ms, delay: 800.ms),

                  const SizedBox(height: 60),

                  // Loading indicator
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.9),
                    ),
                    strokeWidth: 3,
                  ).animate().fadeIn(duration: 400.ms, delay: 1200.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
