import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart'; // Import player provider
import '../../theme/theme.dart';
import '../../widgets/animated_gradient_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  // Helper method to check if the user already has a profile
  Future<bool> _checkForExistingProfile() async {
    debugPrint('Checking if user has completed profile setup');

    try {
      final profileService = ref.read(playerProfileServiceProvider);
      final profile = await profileService.getCurrentUserProfile();

      if (profile == null) {
        debugPrint('Profile check: No profile found');
        return false;
      }

      debugPrint('Profile check details:');
      debugPrint('  Name: ${profile.firstName ?? profile.user.displayName}');
      debugPrint('  Location: ${profile.preferredLocation}');
      debugPrint('  Game types: ${profile.preferredGameTypes.join(', ')}');
      debugPrint('  Availability slots: ${profile.availability.length}');

      // Ensure the provider reflects the correct profile completion status
      ref.invalidate(hasCompletedProfileSetupProvider);
      final hasCompletedProfile =
          await ref.read(hasCompletedProfileSetupProvider.future);

      debugPrint('Profile completion check result: $hasCompletedProfile');
      return hasCompletedProfile;
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || !mounted) {
      return;
    }

    ref.read(authErrorProvider.notifier).state = null;
    ref.read(authLoadingProvider.notifier).state = true;

    try {
      ref.read(authActionProvider.notifier).state = AuthAction.login;

      debugPrint(
          'Starting login process with email: ${_emailController.text.trim()}');

      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      debugPrint('Firebase authentication successful');

      if (!mounted) return;

      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(hasCompletedProfileSetupProvider);
      debugPrint('Attempting to fetch user profile from MongoDB');
      final profileService = ref.read(playerProfileServiceProvider);
      final profile = await profileService.getCurrentUserProfile();

      if (profile != null) {
        debugPrint('Profile fetch result: found');
        debugPrint('Profile details:');
        debugPrint('  Name: ${profile.firstName ?? profile.user.displayName}');
        debugPrint('  Location: ${profile.preferredLocation}');
        debugPrint('  Game types: ${profile.preferredGameTypes.join(', ')}');

        ref.invalidate(hasCompletedProfileSetupProvider);
        final hasCompletedProfile =
            await ref.read(hasCompletedProfileSetupProvider.future);

        if (hasCompletedProfile) {
          if (GoRouter.of(context)
                  .routerDelegate
                  .currentConfiguration
                  .fullPath !=
              '/home') {
            debugPrint('Redirecting to home screen');
            context.go('/home');
          }
        } else {
          if (GoRouter.of(context)
                  .routerDelegate
                  .currentConfiguration
                  .fullPath !=
              '/profile-setup') {
            debugPrint('Redirecting to profile setup screen');
            context.go('/profile-setup');
          }
        }
      } else {
        debugPrint('Profile fetch result: not found');
        if (GoRouter.of(context).routerDelegate.currentConfiguration.fullPath !=
            '/profile-setup') {
          context.go('/profile-setup');
        }
      }
    } catch (e) {
      debugPrint('Login error: $e');
      ref.read(authErrorProvider.notifier).state = e.toString();
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;

    // Clear any previous error
    if (!mounted) return;
    ref.read(authErrorProvider.notifier).state = null;

    // Set loading state
    if (!mounted) return;
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      // Set the auth action to login
      ref.read(authActionProvider.notifier).state = AuthAction.login;

      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();

      if (!mounted) return;

      // Force refresh of profile data after login
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(hasCompletedProfileSetupProvider);

      // Add debug logging
      debugPrint('Google sign-in successful');

      // Always go to home after successful login - router will handle redirects if needed
      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      ref.read(authErrorProvider.notifier).state = error.toString();
      debugPrint('Google sign-in error: $error');
    } finally {
      if (!mounted) return;
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _signInWithFacebook() async {
    if (!mounted) return;

    // Clear any previous error
    if (!mounted) return;
    ref.read(authErrorProvider.notifier).state = null;

    // Set loading state
    if (!mounted) return;
    ref.read(authLoadingProvider.notifier).state = true;
    try {
      // Set the auth action to login
      ref.read(authActionProvider.notifier).state = AuthAction.login;

      final authService = ref.read(authServiceProvider);
      await authService.signInWithFacebook();

      if (!mounted) return;

      // Force refresh of profile data after login
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(hasCompletedProfileSetupProvider);

      // Add debug logging
      debugPrint('Facebook sign-in successful');

      // Always go to home after successful login - router will handle redirects if needed
      context.go('/home');
    } catch (error) {
      if (!mounted) return;
      ref.read(authErrorProvider.notifier).state = error.toString();
      debugPrint('Facebook sign-in error: $error');
    } finally {
      if (!mounted) return;
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  void _navigateToSignup() {
    context.go('/signup');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final errorMessage = ref.watch(authErrorProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and app name
                  const Icon(
                    Icons.sports_bar,
                    size: 64,
                    color: AppTheme.primaryGreen,
                  ).animate().scale(
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 16),

                  Text(
                    'Billiards Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to continue',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                  const SizedBox(height: 40),

                  // Login form card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          spreadRadius: 5,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email field
                          _buildAnimatedTextField(
                            controller: _emailController,
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.emailAddress,
                            delay: 100.ms,
                          ),

                          const SizedBox(height: 20),

                          // Password field
                          _buildAnimatedTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            delay: 200.ms,
                          ),

                          const SizedBox(height: 16),

                          // Remember me and forgot password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: AppTheme.primaryGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  // Forgot password logic
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryGreen,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Forgot Password?'),
                              ),
                            ],
                          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                          const SizedBox(height: 24),

                          // Error message
                          if (errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red.shade400,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      errorMessage,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().shake(),

                          if (errorMessage != null) const SizedBox(height: 24),

                          // Login button
                          SizedBox(
                            height: 56,
                            child: AnimatedGradientButton(
                              onPressed: _login,
                              text: 'Sign In',
                              isLoading: isLoading,
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 300.ms).slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutQuad,
                      ),

                  const SizedBox(height: 32),

                  // OR divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

                  const SizedBox(height: 32),

                  // Social sign in options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google
                      _buildSocialButton(
                        onPressed: _signInWithGoogle,
                        backgroundColor: Colors.white,
                        borderColor: Colors.grey.shade300,
                        icon: Icons.g_mobiledata,
                        iconColor: Colors.red,
                        delay: 600.ms,
                      ),

                      const SizedBox(width: 16),

                      // Facebook
                      _buildSocialButton(
                        onPressed: _signInWithFacebook,
                        backgroundColor: Colors.white,
                        borderColor: Colors.grey.shade300,
                        icon: Icons.facebook,
                        iconColor: Colors.blue.shade700,
                        delay: 700.ms,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Sign up prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToSignup,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    Duration delay = Duration.zero,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(
          prefixIcon,
          color: Colors.grey.shade600,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: delay).slideX(
          begin: 0.2,
          end: 0,
          duration: 500.ms,
          delay: delay,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required Duration delay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: 32),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(),
      ),
    ).animate().scale(
          duration: 400.ms,
          delay: delay,
          curve: Curves.easeOutBack,
        );
  }
}
