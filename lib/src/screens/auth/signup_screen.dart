import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/signup_flow_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/animated_gradient_button.dart';
import 'profile_setup_screen.dart'; // Import for profileSetupProvider

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _dateOfBirth;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if date of birth is provided and user is at least 18
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your date of birth'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calculate age
    final today = DateTime.now();
    int age = today.year - _dateOfBirth!.year;
    if (today.month < _dateOfBirth!.month ||
        (today.month == _dateOfBirth!.month && today.day < _dateOfBirth!.day)) {
      age--;
    }

    // Check if user is at least 18
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be at least 18 years old to sign up'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    try {
      debugPrint('Starting signup process...');

      // Clear error and set loading state
      ref.read(authErrorProvider.notifier).state = null;
      ref.read(authLoadingProvider.notifier).state = true;

      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final displayName = email.split('@')[0];

      // Create user account
      final auth = ref.read(authServiceProvider);
      await auth.createUserWithEmailAndPassword(email, password);
      debugPrint('User account created successfully'); // Update display name
      await auth.updateUserDisplayName(displayName);
      debugPrint('Display name updated successfully');

      // Store date of birth for profile setup
      ref.read(signupDateOfBirthProvider.notifier).state = _dateOfBirth;
      ref.read(profileSetupProvider.notifier).setDateOfBirth(_dateOfBirth);

      if (!mounted) return;

      // Navigate to profile setup
      context.go('/profile-setup');
    } catch (error) {
      ref.read(authErrorProvider.notifier).state = error.toString();
    } finally {
      if (mounted) {
        ref.read(authLoadingProvider.notifier).state = false;
      }
    }
  }

  // Helper methods for date validation
  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  bool _isUserAdult(DateTime birthDate) {
    return _calculateAge(birthDate) >= 18;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final errorMessage = ref.watch(authErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.primaryGreen,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo
                  const Icon(
                    Icons.sports_bar,
                    size: 48,
                    color: AppTheme.primaryGreen,
                  ).animate().scale(
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Join Billiards Hub',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Create your account to get started',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                  const SizedBox(height: 32),

                  // Signup form card
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
                            delay: 200.ms,
                          ),

                          const SizedBox(height: 20),

                          // Password field
                          _buildAnimatedTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            hintText: 'Create a password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
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
                            delay: 300.ms,
                          ),

                          const SizedBox(height: 20),

                          // Confirm Password field
                          _buildAnimatedTextField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm Password',
                            hintText: 'Confirm your password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_isConfirmPasswordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            delay: 400.ms,
                          ),

                          const SizedBox(height: 20),

                          // Date of Birth field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date of Birth',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _dateOfBirth ??
                                        DateTime.now().subtract(
                                            const Duration(days: 365 * 18)),
                                    firstDate: DateTime(1940),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: AppTheme.primaryGreen,
                                            onPrimary: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null &&
                                      picked != _dateOfBirth) {
                                    setState(() {
                                      _dateOfBirth = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: Colors.grey.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        _dateOfBirth == null
                                            ? 'Select your date of birth'
                                            : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                                        style: TextStyle(
                                          color: _dateOfBirth == null
                                              ? Colors.grey.shade600
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_dateOfBirth != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: _isUserAdult(_dateOfBirth!)
                                      ? Text(
                                          'You are ${_calculateAge(_dateOfBirth!)} years old',
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 12,
                                          ),
                                        )
                                      : Text(
                                          'You must be at least 18 years old to sign up',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                ),
                            ],
                          ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                          const SizedBox(height: 20),

                          // Terms and conditions
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'I agree to the Terms of Service and Privacy Policy',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

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

                          // Sign up button
                          SizedBox(
                            height: 56,
                            child: AnimatedGradientButton(
                              onPressed: _signup,
                              text: 'Create Account',
                              isLoading: isLoading,
                              gradientColors: [
                                AppTheme.primaryGreen,
                                AppTheme.secondaryBlue,
                                AppTheme.accentOrange.withOpacity(0.8),
                                AppTheme.primaryGreen,
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 300.ms).slideY(
                        begin: 0.3,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutQuad,
                      ),

                  const SizedBox(height: 24),

                  // Sign in prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
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
}
