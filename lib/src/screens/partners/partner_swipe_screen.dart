import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart';
import '../../providers/player_provider.dart';
import '../../theme/theme.dart';
import '../../models/player_profile.dart';
import '../../constants/venue_sports.dart';

class PartnerSwipeScreen extends ConsumerStatefulWidget {
  const PartnerSwipeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PartnerSwipeScreen> createState() => _PartnerSwipeScreenState();
}

class _PartnerSwipeScreenState extends ConsumerState<PartnerSwipeScreen> {
  final SwiperController _swiperController = SwiperController();
  late ConfettiController _confettiController;
  PlayerProfile? _currentProfile;
  bool _showMatch = false;
  bool _isLoading = true;

  // Define missing mockMatchIds list
  final List<String> mockMatchIds = [
    'player1',
    'player2',
    'player5',
    'player8',
    'user123',
    'user456',
    'user789',
    'player42',
    'cuemaster'
  ];

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    // Initialize liked and disliked profiles from persistent storage
    _initializeUserPreferences();

    // Simulate loading delay for a smoother user experience
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  // Initialize user preferences from persistent service
  Future<void> _initializeUserPreferences() async {
    final playerService = ref.read(playerProfileServiceProvider);
    // Get liked profiles from persistent storage
    final likedProfiles = await playerService.getLikedProfiles();
    if (likedProfiles.isNotEmpty) {
      ref.read(likedProfilesProvider.notifier).state = likedProfiles;
    }

    // Load match preferences from shared preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final prefsJson = prefs.getString('match_preferences');

    if (prefsJson != null) {
      try {
        final Map<String, dynamic> data = json.decode(prefsJson);

        // Extract game types
        List<String>? gameTypes;
        if (data.containsKey('preferredGameTypes')) {
          gameTypes = List<String>.from(data['preferredGameTypes']);
        }

        // Extract days
        List<String>? days;
        if (data.containsKey('preferredDays')) {
          days = List<String>.from(data['preferredDays']);
        }

        // Update the provider
        ref.read(matchPreferencesProvider.notifier).state = MatchPreferences(
          preferredGameTypes: gameTypes,
          preferredDays: days,
          preferredLocation: data['preferredLocation'],
          minSkillLevel: data['minSkillLevel']?.toDouble(),
          maxSkillLevel: data['maxSkillLevel']?.toDouble(),
        );
      } catch (e) {
        print('Error loading match preferences: $e');
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onSwipeRight(PlayerProfile profile) async {
    // Use the PlayerProfileService to like the profile and check for a match
    final service = ref.read(playerProfileServiceProvider);

    // Add to liked profiles state
    final currentLiked = ref.read(likedProfilesProvider);
    if (!currentLiked.contains(profile.user.id)) {
      ref.read(likedProfilesProvider.notifier).state = [
        ...currentLiked,
        profile
      ];
    }

    // Call the service to like the profile and check if it's a match
    final isMatch = await service.likeProfile(profile.user.id);

    // If there's a match, show the match overlay
    if (isMatch) {
      _currentProfile = profile;
      setState(() {
        _showMatch = true;
      });
      _confettiController.play();
    }
  }

  void _onSwipeLeft(PlayerProfile profile) {
    // Add to disliked profiles
    final currentDisliked = ref.read(dislikedProfilesProvider);
    ref.read(dislikedProfilesProvider.notifier).state = [
      ...currentDisliked,
      profile
    ];
  }

  @override
  Widget build(BuildContext context) {
    final potentialMatches = ref.watch(filteredPotentialMatchesProvider);
    final currentPrefs = ref.watch(matchPreferencesProvider);

    // Check if any filters are active
    final bool filtersActive =
        currentPrefs.preferredGameTypes?.isNotEmpty == true ||
            currentPrefs.preferredDays?.isNotEmpty == true ||
            currentPrefs.preferredLocation != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Partners'),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter',
                onPressed: () {
                  _showFilterModal(context);
                },
              ),
              if (filtersActive)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main swipe content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : potentialMatches.isEmpty
                  ? _buildEmptyState()
                  : _buildSwiper(potentialMatches),

          // Match overlay
          if (_showMatch && _currentProfile != null)
            _buildMatchOverlay(_currentProfile!),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          const Text(
            'No matches found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Try adjusting your filters to see more potential partners',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              _showFilterModal(context);
            },
            icon: const Icon(Icons.tune),
            label: const Text('Adjust Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwiper(List<PlayerProfile> profiles) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Swiper(
              itemBuilder: (context, index) {
                return _buildPlayerCard(profiles[index]);
              },
              itemCount: profiles.length,
              controller: _swiperController,
              layout: SwiperLayout.STACK,
              itemWidth: MediaQuery.of(context).size.width * 0.85,
              itemHeight: MediaQuery.of(context).size.height * 0.7,
              onIndexChanged: (index) {
                // You can implement actions when the card changes
              },
              onTap: (index) {
                _showPlayerDetails(profiles[index]);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dislike button
              GestureDetector(
                onTap: () {
                  if (profiles.isNotEmpty) {
                    _onSwipeLeft(profiles[0]);
                    _swiperController.next();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Info button
              GestureDetector(
                onTap: () {
                  if (profiles.isNotEmpty) {
                    _showPlayerDetails(profiles[0]);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Like button
              GestureDetector(
                onTap: () {
                  if (profiles.isNotEmpty) {
                    _onSwipeRight(profiles[0]);
                    _swiperController.next();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppTheme.primaryGreen,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(PlayerProfile profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          // Player image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: profile.user.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(profile.user.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profile.user.photoUrl == null
                ? Center(
                    child: Icon(
                      Icons.person,
                      size: 100,
                      color: Colors.grey[400],
                    ),
                  )
                : null,
          ),

          // Player info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.user.displayName ?? 'Unknown Player',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.skillTier,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.preferredGameTypes.map((game) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          game,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      profile.bio!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Tap for more info hint
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap for details',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerDetails(PlayerProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Player header
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: profile.user.photoUrl != null
                                  ? NetworkImage(profile.user.photoUrl!)
                                  : null,
                              child: profile.user.photoUrl == null
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.user.displayName ??
                                        'Unknown Player',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGreen
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                              profile.skillLevel
                                                  .toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        profile.skillTier,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      const Divider(),

                      // Bio
                      if (profile.bio.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'About',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                profile.bio,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Stats
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stats',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
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
                                  '${((profile.winRate) * 100).round()}%',
                                  'Win Rate',
                                ),
                                _buildStatItem(
                                  Icons.star_border,
                                  profile.achievements.length.toString(),
                                  'Achievements',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Game preferences
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Preferred Games',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.preferredGameTypes.map((game) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.primaryGreen
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    game,
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      // Availability
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Availability',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...profile.availability.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: entry.value.map((time) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              time,
                                              style: TextStyle(
                                                color: Colors.grey[800],
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                      // Location
                      if (profile.preferredLocation != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Preferred Location',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: AppTheme.primaryGreen,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        profile.preferredLocation!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Achievements section
                      if (profile.achievements.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Achievements',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...profile.achievements
                                  .map((achievement) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(achievement),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                            ],
                          ),
                        ),

                      const SizedBox(height: 100), // Space for buttons
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _onSwipeLeft(profile);
                        _swiperController.next();
                      },
                      icon: const Icon(Icons.close),
                      label: const Text('Pass'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _onSwipeRight(profile);
                        _swiperController.next();
                      },
                      icon: const Icon(Icons.favorite),
                      label: const Text('Like'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchOverlay(PlayerProfile profile) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showMatch = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.85),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "It's a Match!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Current user
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 65,
                    backgroundImage: ref.watch(currentUserProfileProvider).when(
                          data: (userProfile) =>
                              userProfile?.user.photoUrl != null
                                  ? NetworkImage(userProfile!.user.photoUrl!)
                                  : null,
                          loading: () => null,
                          error: (_, __) => null,
                        ),
                    child: ref.watch(currentUserProfileProvider).when(
                          data: (userProfile) =>
                              userProfile?.user.photoUrl == null
                                  ? const Icon(Icons.person, size: 65)
                                  : null,
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Icon(Icons.error),
                        ),
                  ),
                ),

                const SizedBox(width: 16),

                // Matched user
                CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 65,
                    backgroundImage: profile.user.photoUrl != null
                        ? NetworkImage(profile.user.photoUrl!)
                        : null,
                    child: profile.user.photoUrl == null
                        ? const Icon(Icons.person, size: 65)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'You and ${profile.user.displayName} have liked each other!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showMatch = false;
                });
                // In a real app, this would navigate to a chat screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat feature coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Send a Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _showMatch = false;
                });

                // Navigate to matches screen
                context.go('/partners');
              },
              child: const Text(
                'See all matches',
                style: TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context) {
    // Get current preferences from the provider
    final currentPrefs = ref.read(matchPreferencesProvider);

    // Create controllers for our form fields
    final minSkillController = TextEditingController(
        text: currentPrefs.minSkillLevel?.toString() ?? '1.0');
    final maxSkillController = TextEditingController(
        text: currentPrefs.maxSkillLevel?.toString() ?? '5.0');

    // Create temporary state for our form
    final Set<String> selectedGameTypes =
        Set<String>.from(currentPrefs.preferredGameTypes ?? []);
    final Set<String> selectedDays =
        Set<String>.from(currentPrefs.preferredDays ?? []);
    String? selectedLocation = currentPrefs.preferredLocation;

    // Define the available options
    final List<String> gameTypes = VenueSports.allSports;

    final List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    final List<String> locations = [
      'Any Location',
      'Downtown Billiards Club',
      'Elite Cue & Brew',
      'Rack & Roll Billiards',
      'Cue Masters',
      'Pocket Shots Bar & Billiards',
      'Break Point Billiards',
      'Corner Pocket Hall',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filter Partners',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Filter form
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Game Types
                        Text(
                          'Game Types',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: gameTypes.map((game) {
                            final isSelected = selectedGameTypes.contains(game);
                            return FilterChip(
                              label: Text(game),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedGameTypes.add(game);
                                  } else {
                                    selectedGameTypes.remove(game);
                                  }
                                });
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor:
                                  AppTheme.primaryGreen.withOpacity(0.2),
                              checkmarkColor: AppTheme.primaryGreen,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Availability
                        Text(
                          'Available Days',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: daysOfWeek.map((day) {
                            final isSelected = selectedDays.contains(day);
                            return FilterChip(
                              label: Text(day),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedDays.add(day);
                                  } else {
                                    selectedDays.remove(day);
                                  }
                                });
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor:
                                  AppTheme.primaryGreen.withOpacity(0.2),
                              checkmarkColor: AppTheme.primaryGreen,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Skill Level Range
                        Text(
                          'Skill Level Range',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: minSkillController,
                                decoration: const InputDecoration(
                                  labelText: 'Min Skill',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: maxSkillController,
                                decoration: const InputDecoration(
                                  labelText: 'Max Skill',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Location
                        Text(
                          'Preferred Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedLocation ?? 'Any Location',
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: locations.map((location) {
                            return DropdownMenuItem(
                              value: location,
                              child: Text(location),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedLocation = value;
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Reset filters to default
                              setState(() {
                                selectedGameTypes.clear();
                                selectedDays.clear();
                                selectedLocation = 'Any Location';
                                minSkillController.text = '1.0';
                                maxSkillController.text = '5.0';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              // Get values from controllers
                              final minSkill =
                                  double.tryParse(minSkillController.text) ??
                                      1.0;
                              final maxSkill =
                                  double.tryParse(maxSkillController.text) ??
                                      5.0;

                              // Update the match preferences in the provider
                              ref
                                  .read(matchPreferencesProvider.notifier)
                                  .state = MatchPreferences(
                                preferredGameTypes: selectedGameTypes.isNotEmpty
                                    ? selectedGameTypes.toList()
                                    : null,
                                preferredDays: selectedDays.isNotEmpty
                                    ? selectedDays.toList()
                                    : null,
                                preferredLocation:
                                    selectedLocation != 'Any Location'
                                        ? selectedLocation
                                        : null,
                                minSkillLevel: minSkill,
                                maxSkillLevel: maxSkill,
                              );

                              // Save preferences to shared preferences
                              _saveFilterPreferences(
                                gameTypes: selectedGameTypes.toList(),
                                days: selectedDays.toList(),
                                location: selectedLocation != 'Any Location'
                                    ? selectedLocation
                                    : null,
                                minSkill: minSkill,
                                maxSkill: maxSkill,
                              );

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Save filter preferences to shared preferences
  Future<void> _saveFilterPreferences({
    required List<String> gameTypes,
    required List<String> days,
    String? location,
    required double minSkill,
    required double maxSkill,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> data = {
        'preferredGameTypes': gameTypes,
        'preferredDays': days,
        'preferredLocation': location,
        'minSkillLevel': minSkill,
        'maxSkillLevel': maxSkill,
      };

      await prefs.setString('match_preferences', json.encode(data));
    } catch (e) {
      print('Error saving match preferences: $e');
    }
  }
}
