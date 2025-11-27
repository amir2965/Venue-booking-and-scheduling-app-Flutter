import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/player_profile.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/mongodb_provider.dart';
import '../../providers/signup_flow_provider.dart';
import '../../utils/navigation_fixer.dart';
import '../../constants/venue_sports.dart';

// Profile setup provider
final profileSetupProvider =
    StateNotifierProvider.autoDispose<ProfileSetupNotifier, ProfileSetupState>(
        (ref) => ProfileSetupNotifier());

// State class for profile setup
class ProfileSetupState {
  final File? profileImage;
  final String firstName;
  final String lastName;
  final String username;
  final String? gender;
  final List<String> playModes;
  final List<String> preferredSports;
  final String? location;
  final String playStyle;
  final Map<String, List<String>> availability;
  final String bio;
  final bool showInPartnerMatching;
  final bool isFormValid;
  final DateTime? dateOfBirth;

  ProfileSetupState({
    this.profileImage,
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.gender,
    this.playModes = const [],
    this.preferredSports = const [],
    this.location,
    this.playStyle = 'Bowling',
    this.availability = const {},
    this.bio = '',
    this.showInPartnerMatching = true,
    this.isFormValid = false,
    this.dateOfBirth,
  });

  ProfileSetupState copyWith({
    File? profileImage,
    String? firstName,
    String? lastName,
    String? username,
    String? gender,
    List<String>? playModes,
    List<String>? preferredSports,
    String? location,
    String? playStyle,
    Map<String, List<String>>? availability,
    String? bio,
    bool? showInPartnerMatching,
    bool? isFormValid,
    DateTime? dateOfBirth,
  }) {
    return ProfileSetupState(
      profileImage: profileImage ?? this.profileImage,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      gender: gender ?? this.gender,
      playModes: playModes ?? this.playModes,
      preferredSports: preferredSports ?? this.preferredSports,
      location: location ?? this.location,
      playStyle: playStyle ?? this.playStyle,
      availability: availability ?? this.availability,
      bio: bio ?? this.bio,
      showInPartnerMatching:
          showInPartnerMatching ?? this.showInPartnerMatching,
      isFormValid: isFormValid ?? this.isFormValid,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
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

  void setFirstName(String name) {
    state = state.copyWith(firstName: name);
    validateForm();
  }

  void setLastName(String name) {
    state = state.copyWith(lastName: name);
    validateForm();
  }

  void setUsername(String username) {
    state = state.copyWith(username: username);
    validateForm();
  }

  void setGender(String? gender) {
    state = state.copyWith(gender: gender);
    validateForm();
  }

  void togglePlayMode(String mode) {
    // Allow only single selection - replace current selection with new one
    final currentModes = List<String>.from(state.playModes);
    if (currentModes.contains(mode)) {
      // If clicking the same mode, deselect it
      currentModes.clear();
    } else {
      // Replace with new selection
      currentModes.clear();
      currentModes.add(mode);
    }
    state = state.copyWith(playModes: currentModes);
    validateForm();
  }

  void toggleSport(String sport) {
    final currentSports = List<String>.from(state.preferredSports);
    if (currentSports.contains(sport)) {
      currentSports.remove(sport);
    } else {
      currentSports.add(sport);
    }
    state = state.copyWith(preferredSports: currentSports);
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

  void setBio(String bio) {
    state = state.copyWith(bio: bio);
    validateForm();
  }

  void toggleShowInMatching() {
    state = state.copyWith(showInPartnerMatching: !state.showInPartnerMatching);
    validateForm();
  }

  void setDateOfBirth(DateTime? dateOfBirth) {
    state = state.copyWith(dateOfBirth: dateOfBirth);
    validateForm();
  }

  void validateForm() {
    final isValid = state.firstName.isNotEmpty &&
        state.lastName.isNotEmpty &&
        state.username.isNotEmpty &&
        (state.location?.isNotEmpty ?? false) &&
        state.availability.isNotEmpty &&
        state.playModes.isNotEmpty &&
        state.preferredSports.isNotEmpty;

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

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final List<String> _skillLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Pro'
  ];
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

  // Australian cities for location dropdown
  final List<String> _australianCities = [
    'Brisbane',
    'Melbourne',
    'Sydney',
    'Perth',
    'Gold Coast',
    'Mackay',
    'Canberra',
    'Sunshine Coast',
  ];

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Setup animation controller for fade-in effects
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

    // Set default bio
    _bioController.text =
        "Looking forward to connecting with fellow billiards enthusiasts!";

    // Start the animation
    _animationController.forward();

    // Set the bio in the provider after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileSetupProvider.notifier).setBio(_bioController.text);

      // Initialize with date of birth from signup if available
      final signupDateOfBirth = ref.read(signupDateOfBirthProvider);
      if (signupDateOfBirth != null) {
        ref
            .read(profileSetupProvider.notifier)
            .setDateOfBirth(signupDateOfBirth);
        // Clear the signup provider as we've consumed the value
        ref.read(signupDateOfBirthProvider.notifier).state = null;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Helper method to pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (image != null) {
        // Show processing indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Processing image...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Set the image in the provider
        ref
            .read(profileSetupProvider.notifier)
            .setProfileImage(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not select image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show image source selector dialog
  void _showImageSourceSelector() {
    final hasImage = ref.read(profileSetupProvider).profileImage != null;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove photo',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    // Clear the profile image
                    ref
                        .read(profileSetupProvider.notifier)
                        .setProfileImage(null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile photo removed'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Show venue selection modal (removed - using dropdown instead)
  void _showVenueSelectionModal() {
    // This method is no longer used since we switched to a dropdown
  }

  String _getSkillTier(double skillLevel) {
    if (skillLevel < 1.0) return 'Beginner';
    if (skillLevel < 2.0) return 'Novice';
    if (skillLevel < 3.0) return 'Intermediate';
    if (skillLevel < 4.0) return 'Advanced';
    if (skillLevel < 4.5) return 'Expert';
    return 'Pro';
  }

  // Helper to set controller initial values when form loads
  void _setInitialValues(User user) {
    if (_firstNameController.text.isEmpty && user.displayName != null) {
      final names = user.displayName!.split(' ');
      final firstName = names.isNotEmpty ? names.first : '';
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      _firstNameController.text = firstName;
      _lastNameController.text = lastName;

      ref.read(profileSetupProvider.notifier).setFirstName(firstName);
      ref.read(profileSetupProvider.notifier).setLastName(lastName);
    }
  }

  // Helper method to build form sections
  Widget _buildFormSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // Helper method to build enhanced text fields
  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      onChanged: onChanged,
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
    );
  }

  // Helper method to build enhanced dropdown fields
  Widget _buildDropdownField(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    Function(String?)? onChanged,
  }) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // Helper method to build date of birth field
  Widget _buildDateOfBirthField(
    BuildContext context,
    ProfileSetupState profileSetup,
  ) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: profileSetup.dateOfBirth ??
              DateTime.now().subtract(const Duration(days: 365 * 20)),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          helpText: 'Select your date of birth',
          errorFormatText: 'Enter valid date',
          errorInvalidText: 'Enter date within valid range',
          fieldLabelText: 'Date of birth',
          fieldHintText: 'mm/dd/yyyy',
        );

        if (picked != null) {
          ref.read(profileSetupProvider.notifier).setDateOfBirth(picked);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(
              Icons.cake_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date of Birth *',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profileSetup.dateOfBirth != null
                        ? '${profileSetup.dateOfBirth!.day}/${profileSetup.dateOfBirth!.month}/${profileSetup.dateOfBirth!.year}'
                        : 'Select your date of birth',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: profileSetup.dateOfBirth != null
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build play mode selection
  Widget _buildPlayModeSelection(
      BuildContext context, ProfileSetupState profileSetup) {
    final theme = Theme.of(context);
    final playModes = [
      {
        'mode': 'Just for Fun',
        'description': 'Play for enjoyment',
        'icon': Icons.sentiment_very_satisfied
      },
      {
        'mode': 'Learn & Improve',
        'description': 'Develop your skills',
        'icon': Icons.school_outlined
      },
      {
        'mode': 'Competitive',
        'description': 'Serious competition',
        'icon': Icons.emoji_events_outlined
      },
      {
        'mode': 'Meet New People',
        'description': 'Social connections',
        'icon': Icons.people_outline
      },
      {
        'mode': 'Regular Player',
        'description': 'Play regularly',
        'icon': Icons.schedule_outlined
      },
    ];

    return Column(
      children: playModes.map((mode) {
        final isSelected = profileSetup.playModes.contains(mode['mode']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref
                    .read(profileSetupProvider.notifier)
                    .togglePlayMode(mode['mode'] as String);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      mode['icon'] as IconData,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode['mode'] as String,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            mode['description'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                      .withOpacity(0.8)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // Helper method to build sports selection
  Widget _buildSportsSelection(
      BuildContext context, ProfileSetupState profileSetup) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Preferred Sports',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VenueSports.allSports.map((sport) {
            final isSelected = profileSetup.preferredSports.contains(sport);
            return GestureDetector(
              onTap: () {
                ref.read(profileSetupProvider.notifier).toggleSport(sport);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
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
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    if (isSelected) const SizedBox(width: 4),
                    Text(
                      VenueSports.getSportEmoji(sport),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sport,
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (profileSetup.preferredSports.isEmpty)
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

  @override
  Widget build(BuildContext context) {
    final profileSetup = ref.watch(profileSetupProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios,
                          color: theme.colorScheme.onSurface),
                    ),
                    const Spacer(),
                    Text(
                      'Profile Setup',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Welcome Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.shadow
                                      .withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.sports_bar_rounded,
                                  size: 48,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Welcome to Billiards Hub!',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Let\'s set up your profile to connect you with fellow players and great venues.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Profile Image Section
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Profile Photo',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.3),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.2),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 60,
                                        backgroundColor:
                                            theme.colorScheme.primaryContainer,
                                        backgroundImage:
                                            profileSetup.profileImage != null
                                                ? FileImage(
                                                    profileSetup.profileImage!)
                                                : null,
                                        child: profileSetup.profileImage == null
                                            ? Icon(
                                                Icons.person_rounded,
                                                size: 60,
                                                color: theme.colorScheme
                                                    .onPrimaryContainer,
                                              )
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      right: 4,
                                      bottom: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.colorScheme.primary,
                                          border: Border.all(
                                            color: theme.colorScheme.surface,
                                            width: 3,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: () =>
                                              _showImagePicker(context),
                                          icon: Icon(
                                            Icons.camera_alt_rounded,
                                            color: theme.colorScheme.onPrimary,
                                            size: 20,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to add a photo',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Form Fields Section
                          _buildFormSection(
                            context,
                            title: 'Basic Information',
                            icon: Icons.person_outline_rounded,
                            children: [
                              _buildTextField(
                                context,
                                controller: _firstNameController,
                                label: 'First Name',
                                hint: 'Enter your first name',
                                icon: Icons.person_outline,
                                isRequired: true,
                                onChanged: (value) {
                                  ref
                                      .read(profileSetupProvider.notifier)
                                      .setFirstName(value);
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                context,
                                controller: _lastNameController,
                                label: 'Last Name',
                                hint: 'Enter your last name',
                                icon: Icons.person_outline,
                                isRequired: true,
                                onChanged: (value) {
                                  ref
                                      .read(profileSetupProvider.notifier)
                                      .setLastName(value);
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                context,
                                controller: _usernameController,
                                label: 'Username',
                                hint: 'Choose a unique username',
                                icon: Icons.alternate_email_outlined,
                                isRequired: true,
                                onChanged: (value) {
                                  ref
                                      .read(profileSetupProvider.notifier)
                                      .setUsername(value);
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDropdownField(
                                context,
                                label: 'Gender',
                                value: profileSetup.gender,
                                items: const [
                                  'Male',
                                  'Female',
                                  'Other',
                                  'Prefer not to say'
                                ],
                                icon: Icons.person_outline,
                                onChanged: (value) {
                                  ref
                                      .read(profileSetupProvider.notifier)
                                      .setGender(value);
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildDateOfBirthField(context, profileSetup),
                              const SizedBox(height: 16),
                              _buildDropdownField(
                                context,
                                label: 'Location',
                                value: profileSetup.location,
                                items: _australianCities,
                                icon: Icons.location_on_outlined,
                                onChanged: (value) {
                                  ref
                                      .read(profileSetupProvider.notifier)
                                      .setLocation(value);
                                },
                              ),
                            ],
                          ),

                          // Play Modes Section
                          _buildFormSection(
                            context,
                            title: 'Play Modes',
                            icon: Icons.sports_outlined,
                            children: [
                              Text(
                                'What are your reasons for playing? (Select all that apply)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPlayModeSelection(context, profileSetup),
                            ],
                          ),

                          // Sports Preferences Section
                          _buildFormSection(
                            context,
                            title: 'Sports Preferences',
                            icon: Icons.sports_baseball,
                            children: [
                              _buildSportsSelection(context, profileSetup),
                            ],
                          ),

                          // Bio Section
                          _buildFormSection(
                            context,
                            title: 'About You',
                            icon: Icons.edit_outlined,
                            children: [
                              _buildTextField(
                                context,
                                controller: _bioController,
                                label: 'Bio',
                                hint: 'Tell other players about yourself...',
                                icon: Icons.description_outlined,
                                maxLines: 3,
                                onChanged: (value) {
                                  ref
                                      .read(profileSetupProvider.notifier)
                                      .setBio(value);
                                },
                              ),
                            ],
                          ),

                          // Privacy Section
                          _buildFormSection(
                            context,
                            title: 'Privacy Settings',
                            icon: Icons.privacy_tip_outlined,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Show in Partner Matching',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Allow other players to find you when looking for a partner',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: profileSetup.showInPartnerMatching,
                                      onChanged: (value) {
                                        ref
                                            .read(profileSetupProvider.notifier)
                                            .toggleShowInMatching();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Complete Profile Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  await _submitProfile();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Complete Profile',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Submit the profile data
  Future<void> _submitProfile() async {
    try {
      final userAsyncValue = ref.read(authUserProvider);
      final user = userAsyncValue.value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the current state from the provider
      final state = ref.read(profileSetupProvider);

      // Set a default skill level since we're focusing on play modes
      double skillLevelValue = 2.0; // Default intermediate level

      // Create PlayerProfile object
      final profile = PlayerProfile(
        user: user.copyWith(
            displayName: state.firstName.isNotEmpty && state.lastName.isNotEmpty
                ? '${state.firstName} ${state.lastName}'
                : user.displayName),
        firstName: state.firstName.isNotEmpty
            ? state.firstName
            : (user.displayName?.split(' ').first ?? 'Player'),
        lastName: state.lastName.isNotEmpty
            ? state.lastName
            : ((user.displayName?.split(' ').length ?? 0) > 1
                ? user.displayName!.split(' ').sublist(1).join(' ')
                : ''),
        username: state.username.isNotEmpty
            ? state.username
            : user.displayName?.toLowerCase().replaceAll(' ', '_') ??
                user.email.split('@')[0].toLowerCase(),
        bio: state.bio.isNotEmpty
            ? state.bio
            : "Looking forward to connecting with fellow billiards enthusiasts!",
        skillLevel: skillLevelValue,
        preferredGameTypes:
            state.playModes.isNotEmpty ? state.playModes : ['Just for Fun'],
        preferredSports: state.preferredSports.isNotEmpty
            ? state.preferredSports
            : ['Bowling'],
        availability: state.availability,
        skillTier: 'Intermediate', // Default tier
        preferredLocation: state.location ?? '',
        experiencePoints: 10,
        matchesPlayed: 0,
        winRate: 0.0,
        achievements: [],
        dateOfBirth: state.dateOfBirth,
      );

      // Get MongoDB service and verify connectivity
      final mongodbService = ref.read(mongoDBServiceProvider);
      final isConnected = await mongodbService.checkConnectivity();
      if (!isConnected) {
        throw Exception(
            'Could not connect to MongoDB. Please check your connection.');
      }

      debugPrint(
          'MongoDB connection verified, checking for existing profile...');

      // Check if profile exists and update/create accordingly
      final existingProfile = await mongodbService.getProfile(user.id);
      if (existingProfile != null) {
        debugPrint('Profile already exists, updating...');
        final success = await mongodbService.updateProfile(profile);
        if (!success) throw Exception('Failed to update profile');
      } else {
        debugPrint('Creating new profile...');
        final success = await mongodbService.createProfile(profile);
        if (!success) throw Exception('Failed to create profile');
      }

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile setup complete!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Force refresh providers
      ref.invalidate(hasCompletedProfileSetupProvider);
      ref.invalidate(currentUserProfileProvider);
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to home using NavigationFixer for reliability
      if (!mounted) return;
      NavigationFixer.navigateToHomeAfterProfileUpdate(context, ref);
    } catch (e) {
      debugPrint('Error in profile setup: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Show image picker options
  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
