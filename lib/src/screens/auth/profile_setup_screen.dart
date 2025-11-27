import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/player_profile.dart';
import '../../providers/player_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_upload_service.dart';
import '../../theme/theme.dart';
import '../../dialogs/image_upload_dialog.dart';
import '../../widgets/profile_image_widget.dart';
import '../../constants/venue_sports.dart';

// Profile setup provider
final profileSetupProvider =
    StateNotifierProvider.autoDispose<ProfileSetupNotifier, ProfileSetupState>(
        (ref) => ProfileSetupNotifier());

// State class definition
class ProfileSetupState {
  final File? profileImage;
  final Map<String, String>? profileImageUrls;
  final String username;
  final String firstName;
  final String? gender;
  final List<String> playModes; // Changed from skillLevel to playModes
  final String? location;
  final String playStyle;
  final Map<String, List<String>> availability;
  final String bio;
  final bool showInPartnerMatching;
  final bool isFormValid;
  final DateTime? dateOfBirth;
  final bool isImageUploading;

  ProfileSetupState({
    this.profileImage,
    this.profileImageUrls,
    this.username = '',
    this.firstName = '',
    this.gender,
    this.playModes = const [],
    this.location,
    this.playStyle = 'Casual',
    this.availability = const {},
    this.bio = '',
    this.showInPartnerMatching = true,
    this.isFormValid = false,
    this.dateOfBirth,
    this.isImageUploading = false,
  });

  ProfileSetupState copyWith({
    File? profileImage,
    Map<String, String>? profileImageUrls,
    String? username,
    String? firstName,
    String? gender,
    List<String>? playModes,
    String? location,
    String? playStyle,
    Map<String, List<String>>? availability,
    String? bio,
    bool? showInPartnerMatching,
    bool? isFormValid,
    DateTime? dateOfBirth,
    bool? isImageUploading,
  }) {
    return ProfileSetupState(
      profileImage: profileImage ?? this.profileImage,
      profileImageUrls: profileImageUrls ?? this.profileImageUrls,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      gender: gender ?? this.gender,
      playModes: playModes ?? this.playModes,
      location: location ?? this.location,
      playStyle: playStyle ?? this.playStyle,
      availability: availability ?? this.availability,
      bio: bio ?? this.bio,
      showInPartnerMatching:
          showInPartnerMatching ?? this.showInPartnerMatching,
      isFormValid: isFormValid ?? this.isFormValid,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isImageUploading: isImageUploading ?? this.isImageUploading,
    );
  }
}

// Notifier class to manage state
class ProfileSetupNotifier extends StateNotifier<ProfileSetupState> {
  ProfileSetupNotifier() : super(ProfileSetupState());

  void setProfileImage(File? image) {
    state = state.copyWith(profileImage: image);
    validateForm();
  }

  void setProfileImageUrls(Map<String, String>? urls) {
    state = state.copyWith(profileImageUrls: urls);
    validateForm();
  }

  void setImageUploading(bool uploading) {
    state = state.copyWith(isImageUploading: uploading);
  }

  Future<void> uploadProfileImage(File imageFile, String userId) async {
    try {
      setImageUploading(true);

      // Validate image first
      final isValid = await ImageUploadService.validateImage(imageFile);
      if (!isValid) {
        throw Exception('Invalid image. Please select a valid image file.');
      }

      // Upload image and get URLs using Firebase Storage
      final imageUrls = await ImageUploadService.uploadProfileImage(
        imageFile: imageFile,
        userId: userId,
      );

      // Update state with URLs
      setProfileImageUrls(imageUrls);
      setProfileImage(imageFile);
    } catch (e) {
      // Handle error - don't throw so UI can handle gracefully
      rethrow;
    } finally {
      setImageUploading(false);
    }
  }

  void setUsername(String username) {
    state = state.copyWith(username: username);
    validateForm();
  }

  void setFirstName(String name) {
    state = state.copyWith(firstName: name);
    validateForm();
  }

  void setGender(String? gender) {
    state = state.copyWith(gender: gender);
    validateForm();
  }

  void togglePlayMode(String mode) {
    final currentModes = List<String>.from(state.playModes);
    if (currentModes.contains(mode)) {
      currentModes.remove(mode);
    } else {
      currentModes.add(mode);
    }
    state = state.copyWith(playModes: currentModes);
    validateForm();
  }

  void setLocation(String? location) {
    state = state.copyWith(location: location);
    validateForm();
  }

  void setPlayStyle(String style) {
    state = state.copyWith(playStyle: style);
    validateForm();
  }

  void setBio(String bio) {
    state = state.copyWith(bio: bio);
    validateForm();
  }

  void toggleShowInMatching() {
    state = state.copyWith(showInPartnerMatching: !state.showInPartnerMatching);
    validateForm();
  }

  void toggleAvailability(String day, String timeSlot) {
    final currentAvailability =
        Map<String, List<String>>.from(state.availability);

    if (!currentAvailability.containsKey(day)) {
      currentAvailability[day] = [timeSlot];
    } else {
      final timeSlots = List<String>.from(currentAvailability[day]!);
      if (timeSlots.contains(timeSlot)) {
        timeSlots.remove(timeSlot);
      } else {
        timeSlots.add(timeSlot);
      }

      if (timeSlots.isEmpty) {
        currentAvailability.remove(day);
      } else {
        currentAvailability[day] = timeSlots;
      }
    }

    state = state.copyWith(availability: currentAvailability);
    validateForm();
  }

  void setDateOfBirth(DateTime? dateOfBirth) {
    state = state.copyWith(dateOfBirth: dateOfBirth);
    validateForm();
  }

  void validateForm() {
    final isValid = state.username.isNotEmpty &&
        state.firstName.isNotEmpty &&
        state.playModes.isNotEmpty; // Require at least one sport

    state = state.copyWith(isFormValid: isValid);
  }
}

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _debounceTimer;
  bool _isCheckingUsername = false;
  bool _isUsernameAvailable = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<String> _preferredSports = VenueSports.allSports;
  final List<String> _playStyles = [
    'Casual',
    'Competitive',
    'Training',
    'Tournament'
  ];
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final List<String> _timeSlots = ['Morning', 'Afternoon', 'Evening', 'Night'];
  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkForExistingProfile();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkForExistingProfile() async {
    try {
      final profileService = ref.read(playerProfileServiceProvider);
      final userProfile = await profileService.getCurrentUserProfile();
      final hasCompletedProfile =
          await ref.read(hasCompletedProfileSetupProvider.future);

      if (hasCompletedProfile && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have a profile set up'),
            duration: Duration(seconds: 1),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      debugPrint('Error checking for existing profile: $e');
    }
  }

  void _showImageUploadDialog() {
    showImageUploadDialog(
      context: context,
      onImageSourceSelected: _handleImageSource,
    );
  }

  Future<void> _handleImageSource(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        await _handleImageSelected(File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleImageSelected(File imageFile) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    try {
      await ref
          .read(profileSetupProvider.notifier)
          .uploadProfileImage(imageFile, user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to upload image: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _checkUsernameAvailability(String username) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    setState(() => _isCheckingUsername = true);

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      try {
        final profileService = ref.read(playerProfileServiceProvider);
        final isAvailable = await profileService.isUsernameAvailable(username);

        if (mounted) {
          setState(() {
            _isUsernameAvailable = isAvailable;
            _isCheckingUsername = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _isUsernameAvailable = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _animationController.dispose();
    _nameController.dispose();
    _firstNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileSetupProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1A0A),
              Color(0xFF1A2B1A),
              Color(0xFF2A3B2A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileImageSection(profileState),
                      const SizedBox(height: 40),
                      _buildFormFields(profileState),
                      const SizedBox(height: 40),
                      _buildCompleteProfileButton(profileState),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Complete Your Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your photo and details to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection(ProfileSetupState state) {
    return Column(
      children: [
        EditableProfileImage(
          imageUrls: state.profileImageUrls,
          userName: state.firstName.isNotEmpty ? state.firstName : null,
          size: 140,
          onEditTap: _showImageUploadDialog,
          isLoading: state.isImageUploading,
        ),
        const SizedBox(height: 16),
        Text(
          state.profileImageUrls?.isNotEmpty == true
              ? 'Tap to change photo'
              : 'Tap to add photo',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.primaryGreen.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(ProfileSetupState state) {
    return Column(
      children: [
        _buildTextField(
          controller: _firstNameController,
          label: 'First Name',
          hint: 'Enter your first name',
          onChanged: (value) {
            ref.read(profileSetupProvider.notifier).setFirstName(value);
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _nameController,
          label: 'Username',
          hint: 'Choose a unique username',
          onChanged: (value) {
            ref.read(profileSetupProvider.notifier).setUsername(value);
          },
        ),
        const SizedBox(height: 20),
        _buildPlayModeSelection(state),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _bioController,
          label: 'Bio (Optional)',
          hint: 'Tell others about yourself',
          maxLines: 3,
          onChanged: (value) {
            ref.read(profileSetupProvider.notifier).setBio(value);
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayModeSelection(ProfileSetupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Sports (Select all that apply)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _preferredSports.map((sport) {
            final isSelected = state.playModes.contains(sport);
            return GestureDetector(
              onTap: () {
                ref.read(profileSetupProvider.notifier).togglePlayMode(sport);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                    if (isSelected) const SizedBox(width: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          VenueSports.getSportEmoji(sport),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          sport,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (state.playModes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one sport',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.withOpacity(0.8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompleteProfileButton(ProfileSetupState state) {
    final isEnabled = state.firstName.isNotEmpty &&
        state.username.isNotEmpty &&
        state.playModes.isNotEmpty;

    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? _completeProfile : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? AppTheme.primaryGreen : Colors.grey.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isEnabled ? 8 : 0,
          shadowColor: isEnabled
              ? AppTheme.primaryGreen.withOpacity(0.3)
              : Colors.transparent,
        ),
        child: Text(
          'Complete Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _completeProfile() async {
    final state = ref.read(profileSetupProvider);
    final user = ref.read(authServiceProvider).currentUser;

    if (user == null) return;

    try {
      // Create profile with selected sports as preferred game types
      final profile = PlayerProfile(
        user: user,
        firstName: state.firstName,
        lastName: '', // Can be added later
        username: state.username,
        bio: state.bio,
        skillLevel: 1.0,
        skillTier: 'Beginner',
        preferredGameTypes: state.playModes, // Use selected sports
        profileImageUrls: state.profileImageUrls,
        availability: {},
      );

      // Save profile
      final profileService = ref.read(playerProfileServiceProvider);
      await profileService.updatePlayerProfile(profile);

      // Navigate to main app
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create profile: ${e.toString()}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }
}
