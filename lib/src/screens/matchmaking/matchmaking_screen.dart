import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../models/player_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matchmaking_provider.dart';
import '../../providers/matchmaking_filters_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/matchmaking_service.dart';
import '../../services/notification_monitor_service.dart';
import '../../theme/theme.dart';
import '../../constants/venue_sports.dart';
import '../../widgets/bottom_navigation.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with TickerProviderStateMixin {
  late AnimationController _swipeController;
  late AnimationController _scaleController;
  late AnimationController _matchController;
  late Animation<double> _swipeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _matchScaleAnimation;

  Offset _dragOffset = Offset.zero;
  bool _showMatchAnimation = false;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _matchController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _swipeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
    _matchScaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _matchController, curve: Curves.elasticOut),
    );

    // Load potential matches when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _scaleController.dispose();
    _matchController.dispose();
    super.dispose();
  }

  void _loadMatches() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      ref.read(potentialMatchesProvider.notifier).loadPotentialMatches(user.id);
    }
  }

  Future<void> _handleSwipe(MatchAction action, PlayerProfile profile) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() {
      _dragOffset = Offset.zero;
    });

    try {
      final result = await ref
          .read(potentialMatchesProvider.notifier)
          .recordAction(user.id, profile.user.id, action);

      if (result.isMatch) {
        _showMatchDialog(profile);

        // Refresh notifications to check for new match notifications
        ref.read(unreadCountProvider.notifier).loadUnreadCount(user.id);

        // Check for new notifications immediately
        final notificationMonitor = ref.read(notificationMonitorProvider);
        notificationMonitor.checkNow();
      }

      // Move to next profile
      final currentIndex = ref.read(currentSwipeIndexProvider);
      ref.read(currentSwipeIndexProvider.notifier).state = currentIndex + 1;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showMatchDialog(PlayerProfile profile) {
    setState(() {
      _showMatchAnimation = true;
    });
    _matchController.forward();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MatchDialog(profile: profile),
    ).then((_) {
      setState(() {
        _showMatchAnimation = false;
      });
      _matchController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final potentialMatches = ref.watch(potentialMatchesProvider);
    final currentIndex = ref.watch(currentSwipeIndexProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.explore,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Discover Players',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF28A745),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF28A745),
                Color(0xFF20A039),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune, size: 18),
            ),
            onPressed: () => _showFiltersDialog(),
            tooltip: 'Filters',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh, size: 18),
            ),
            onPressed: _loadMatches,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          potentialMatches.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load matches',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString().contains('Network')
                          ? 'Please check your internet connection'
                          : 'Server temporarily unavailable',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final user =
                                ref.read(authServiceProvider).currentUser;
                            if (user != null) {
                              ref
                                  .read(potentialMatchesProvider.notifier)
                                  .clearErrorAndRetry(user.id);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            final user =
                                ref.read(authServiceProvider).currentUser;
                            if (user != null) {
                              ref
                                  .read(potentialMatchesProvider.notifier)
                                  .refresh(user.id);
                            }
                          },
                          child: const Text('Force Refresh'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            data: (profiles) {
              if (profiles.isEmpty) {
                return _buildEmptyState();
              }

              if (currentIndex >= profiles.length) {
                return _buildNoMoreProfilesState();
              }

              return Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the content
                children: [
                  Expanded(
                    child: _buildSwipeStack(profiles, currentIndex),
                  ),
                  _buildActionButtons(profiles[currentIndex]),
                  const SizedBox(height: 20) // Add some space at the bottom
                ],
              );
            },
          ),
          if (_showMatchAnimation)
            AnimatedBuilder(
              animation: _matchScaleAnimation,
              builder: (context, child) {
                return Center(
                  child: Transform.scale(
                    scale: _matchScaleAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar:
          const AppBottomNavigation(currentRoute: '/matchmaking'),
    );
  }

  Widget _buildSwipeStack(List<PlayerProfile> profiles, int currentIndex) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(16, 64, 16, 8), // Increased top padding
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background cards (show up to 3 cards in stack)
          for (int i = math.min(currentIndex + 2, profiles.length - 1);
              i >= currentIndex;
              i--)
            _buildProfileCard(
              profiles[i],
              i - currentIndex,
              i == currentIndex,
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(PlayerProfile profile, int stackIndex, bool isTop) {
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.92;
    final cardHeight =
        screenSize.height * 0.68; // Increased from 0.62 to provide more space

    return AnimatedBuilder(
      animation: Listenable.merge([_swipeAnimation, _scaleAnimation]),
      builder: (context, child) {
        double scale = 1.0 - (stackIndex * 0.04);
        double yOffset = stackIndex * 6.0;

        if (isTop) {
          scale *= _scaleAnimation.value;

          if (_swipeController.isAnimating) {
            final swipeOffset = _swipeAnimation.value *
                (_dragOffset.dx > 0 ? screenSize.width : -screenSize.width);
            return Transform.translate(
              offset:
                  Offset(swipeOffset, _dragOffset.dy * _swipeAnimation.value),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          }
        }

        return Transform.translate(
          offset: Offset(
            isTop ? _dragOffset.dx : 0,
            yOffset + (isTop ? _dragOffset.dy : 0),
          ),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showProfileDetails(profile),
        onPanStart: isTop ? _onPanStart : null,
        onPanUpdate: isTop ? _onPanUpdate : null,
        onPanEnd: isTop ? (details) => _onPanEnd(details, profile) : null,
        child: Container(
          width: cardWidth,
          height: cardHeight,
          child: _SwipeableProfileCard(
            profile: profile,
            dragOffset: isTop ? _dragOffset : Offset.zero,
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _scaleController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details, PlayerProfile profile) {
    _scaleController.reverse();

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.3;

    if (_dragOffset.dx.abs() > threshold) {
      final action = _dragOffset.dx > 0 ? MatchAction.like : MatchAction.pass;
      _swipeController.forward().then((_) {
        _swipeController.reset();
        _handleSwipe(action, profile);
      });
    } else {
      setState(() {
        _dragOffset = Offset.zero;
      });
    }
  }

  Widget _buildActionButtons(PlayerProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 8), // Reduced vertical padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.close,
            color: Colors.red,
            size: 56,
            onPressed: () => _handleSwipe(MatchAction.pass, profile),
            label: 'Pass',
          ),
          _ActionButton(
            icon: Icons.info_outline,
            color: Colors.blue,
            size: 48,
            onPressed: () => _showProfileDetails(profile),
            label: 'Info',
          ),
          _ActionButton(
            icon: Icons.favorite,
            color: const Color(0xFF28A745),
            size: 64,
            onPressed: () => _handleSwipe(MatchAction.like, profile),
            label: 'Like',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF5E3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 50,
                color: const Color(0xFF28A745),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No players found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try refreshing or adjusting your filters to find more players',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF28A745).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final user = ref.read(authServiceProvider).currentUser;
                      if (user != null) {
                        ref
                            .read(potentialMatchesProvider.notifier)
                            .refresh(user.id);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Reset filters to show more profiles
                    ref
                        .read(matchmakingFiltersProvider.notifier)
                        .resetFilters();
                    final user = ref.read(authServiceProvider).currentUser;
                    if (user != null) {
                      ref
                          .read(potentialMatchesProvider.notifier)
                          .refresh(user.id);
                    }
                  },
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Reset Filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF28A745),
                    side: const BorderSide(color: Color(0xFF28A745)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMoreProfilesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF5E3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 50,
                color: const Color(0xFF28A745),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'ve seen all available players.\nCheck back later for new matches!',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(currentSwipeIndexProvider.notifier).state = 0;
                    _loadMatches();
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Start Over'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF28A745),
                    side: const BorderSide(color: Color(0xFF28A745)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF28A745).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/matches'),
                    icon: const Icon(Icons.favorite),
                    label: const Text('View Matches'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MatchmakingFilterSheet(),
    );
  }

  void _showProfileDetails(PlayerProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProfileDetailsSheet(profile: profile),
    );
  }
}

class _SwipeableProfileCard extends StatelessWidget {
  final PlayerProfile profile;
  final Offset dragOffset;

  const _SwipeableProfileCard({
    required this.profile,
    required this.dragOffset,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final likeOpacity = (dragOffset.dx / (screenWidth * 0.3)).clamp(0.0, 1.0);
    final passOpacity = (-dragOffset.dx / (screenWidth * 0.3)).clamp(0.0, 1.0);
    final rotation = (dragOffset.dx / screenWidth) * 0.2;

    return Transform.rotate(
      angle: rotation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A000000),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  // Image section
                  Expanded(
                    flex:
                        7, // Reduced from 8 to give more space to info section
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Profile image or placeholder
                          if (profile.profileImageUrl != null)
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                                image: DecorationImage(
                                  image: NetworkImage(profile.profileImageUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Center(
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDFF5E3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: const Color(0xFF28A745),
                                ),
                              ),
                            ),
                          // Subtle gradient overlay for text readability
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.1),
                                ],
                                stops: const [0.7, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Information section
                  Expanded(
                    flex:
                        3, // Increased from 2 to provide more space for user details
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16), // Reduced padding
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize:
                            MainAxisSize.min, // Added to minimize space usage
                        children: [
                          // Name and skill rating row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${profile.firstName} ${profile.lastName}',
                                      style: const TextStyle(
                                        color: Color(0xFF222222),
                                        fontSize: 20, // Reduced font size
                                        fontWeight: FontWeight.w600,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          '@${profile.username}',
                                          style: const TextStyle(
                                            color: Color(0xFF555555),
                                            fontSize: 14, // Reduced font size
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        // Show age if dateOfBirth is available
                                        if (profile.dateOfBirth != null)
                                          Text(
                                            ' • ${profile.age} yrs',
                                            style: const TextStyle(
                                              color: Color(0xFF555555),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, // Reduced padding
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDFF5E3),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.sports,
                                      color: Color(0xFF28A745),
                                      size: 14, // Reduced icon size
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      profile.preferredGameTypes.isNotEmpty
                                          ? profile.preferredGameTypes.first
                                          : 'Casual',
                                      style: const TextStyle(
                                        color: Color(0xFF28A745),
                                        fontSize: 12, // Reduced font size
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8), // Reduced spacing
                          // Tags and location row
                          Flexible(
                            // Made this flexible to prevent overflow
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8, // Reduced padding
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDFF5E3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    profile.preferredGameTypes.isNotEmpty
                                        ? profile.preferredGameTypes.first
                                        : 'General',
                                    style: const TextStyle(
                                      color: Color(0xFF28A745),
                                      fontSize: 11, // Reduced font size
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (profile.preferredLocation != null) ...[
                                  const SizedBox(width: 6), // Reduced spacing
                                  Icon(
                                    Icons.location_on,
                                    color: const Color(0xFF555555),
                                    size: 14, // Reduced icon size
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      profile.preferredLocation!,
                                      style: const TextStyle(
                                        color: Color(0xFF555555),
                                        fontSize: 12, // Reduced font size
                                        fontWeight: FontWeight.w400,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Bio section
                          if (profile.bio.isNotEmpty) ...[
                            const SizedBox(height: 6), // Reduced spacing
                            Flexible(
                              // Made this flexible to prevent overflow
                              child: Text(
                                profile.bio,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 12, // Reduced font size
                                  fontWeight: FontWeight.w400,
                                  height: 1.3, // Reduced line height
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Like overlay with enhanced styling
            if (likeOpacity > 0)
              Positioned(
                top: 50,
                right: 25,
                child: Opacity(
                  opacity: likeOpacity,
                  child: Transform.rotate(
                    angle: 0.25,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28A745),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF28A745).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'LIKE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Pass overlay with enhanced styling
            if (passOpacity > 0)
              Positioned(
                top: 50,
                left: 25,
                child: Opacity(
                  opacity: passOpacity,
                  child: Transform.rotate(
                    angle: -0.25,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'PASS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Tap indicator with softer styling
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tap for details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;
  final String? label;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 60,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.4,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: TextStyle(
              color: const Color(0xFF555555),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _MatchDialog extends StatefulWidget {
  final PlayerProfile profile;

  const _MatchDialog({required this.profile});

  @override
  _MatchDialogState createState() => _MatchDialogState();
}

class _MatchDialogState extends State<_MatchDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1A000000),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF5E3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFF28A745),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'It\'s a Match!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You and ${widget.profile.firstName} liked each other!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF555555),
                            side: const BorderSide(color: Color(0xFFDDDDDD)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Keep Playing'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);

                            // Show SnackBar using a simple delay to ensure dialog is closed
                            Timer(const Duration(milliseconds: 100), () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Match saved! You can find ${widget.profile.firstName} in your matches.',
                                  ),
                                  backgroundColor: const Color(0xFF28A745),
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: 'View Matches',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      context.go('/matches');
                                    },
                                  ),
                                ),
                              );
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF28A745),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Send Message'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileDetailsSheet extends ConsumerWidget {
  final PlayerProfile profile;

  const _ProfileDetailsSheet({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: () {}, // Prevent tap events from propagating
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with photo and basic info
                        _buildProfileHeader(),
                        const SizedBox(height: 24),

                        // Bio section
                        if (profile.bio.isNotEmpty) ...[
                          _buildSectionHeader('About', Icons.person_outline),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Text(
                              profile.bio,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Player Stats
                        _buildSectionHeader(
                            'Player Stats', Icons.sports_esports),
                        const SizedBox(height: 12),
                        _buildStatsGrid(),
                        const SizedBox(height: 24),

                        // Sports
                        if (_getSportsFromProfile(profile).isNotEmpty) ...[
                          _buildSectionHeader('Sports', Icons.sports_handball),
                          const SizedBox(height: 12),
                          _buildSportsGrid(profile),
                          const SizedBox(height: 24),
                        ],

                        // Game Preferences (Play Modes)
                        if (_getPlayModesFromProfile(profile).isNotEmpty) ...[
                          _buildSectionHeader('Play Modes', Icons.gamepad),
                          const SizedBox(height: 12),
                          _buildPlayModesGrid(profile),
                          const SizedBox(height: 24),
                        ],

                        // Additional Details
                        _buildSectionHeader('Details', Icons.info_outline),
                        const SizedBox(height: 12),
                        _buildDetailsCard(),
                        const SizedBox(height: 32),

                        // Action buttons
                        _buildActionButtons(context, ref),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[200],
            backgroundImage: profile.profileImageUrl != null
                ? NetworkImage(profile.profileImageUrl!)
                : null,
            child: profile.profileImageUrl == null
                ? Icon(Icons.person, size: 40, color: Colors.grey[600])
                : null,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${profile.firstName} ${profile.lastName}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${profile.username}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile.preferredGameTypes.isNotEmpty
                          ? profile.preferredGameTypes.join(', ')
                          : 'Casual Player',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Experience',
                  '${profile.experiencePoints} XP',
                  Icons.emoji_events,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Matches',
                  '${profile.matchesPlayed}',
                  Icons.games,
                  Colors.blue,
                ),
              ),
            ],
          ),
          if (profile.preferredLocation != null) ...[
            const SizedBox(height: 16),
            _buildStatItem(
              'Location',
              profile.preferredLocation!,
              Icons.location_on,
              Colors.red,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSportsFromProfile(PlayerProfile profile) {
    // Check if the profile has preferredSports field
    if (profile.preferredSports.isNotEmpty) {
      return profile.preferredSports
          .where((sport) => VenueSports.allSports.contains(sport))
          .toList();
    }

    // Fallback: filter from preferredGameTypes
    return profile.preferredGameTypes
        .where((gameType) => VenueSports.allSports.contains(gameType))
        .toList();
  }

  List<String> _getPlayModesFromProfile(PlayerProfile profile) {
    return profile.preferredGameTypes
        .where((gameType) => !VenueSports.allSports.contains(gameType))
        .toList();
  }

  Widget _buildSportsGrid(PlayerProfile profile) {
    final sports = _getSportsFromProfile(profile);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sports.map((sport) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.3),
            ),
          ),
          child: Row(
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
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayModesGrid(PlayerProfile profile) {
    final playModes = _getPlayModesFromProfile(profile);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: playModes.map((playMode) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.secondaryBlue.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎮', // Generic game icon for play modes
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 6),
              Text(
                playMode,
                style: TextStyle(
                  color: AppTheme.secondaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.person,
            label: 'Username',
            value: '@${profile.username}',
          ),
          const Divider(height: 24),
          if (profile.dateOfBirth != null)
            _DetailRow(
              icon: Icons.cake,
              label: 'Age',
              value: '${profile.age} years',
            ),
          if (profile.dateOfBirth != null) const Divider(height: 24),
          _DetailRow(
            icon: Icons.sports_outlined,
            label: 'Play Modes',
            value: profile.preferredGameTypes.isNotEmpty
                ? profile.preferredGameTypes.join(', ')
                : 'Casual',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              // Trigger like action
              final user = ref.read(authServiceProvider).currentUser;
              if (user != null) {
                try {
                  final result = await ref
                      .read(potentialMatchesProvider.notifier)
                      .recordAction(user.id, profile.user.id, MatchAction.like);

                  if (result.isMatch) {
                    // Show match dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => _MatchDialog(profile: profile),
                    );
                  }

                  // Move to next profile
                  final currentIndex = ref.read(currentSwipeIndexProvider);
                  ref.read(currentSwipeIndexProvider.notifier).state =
                      currentIndex + 1;
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.favorite),
            label: const Text('Like'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// Filter bottom sheet implementation
class _MatchmakingFilterSheet extends ConsumerStatefulWidget {
  const _MatchmakingFilterSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<_MatchmakingFilterSheet> createState() =>
      _MatchmakingFilterSheetState();
}

class _MatchmakingFilterSheetState
    extends ConsumerState<_MatchmakingFilterSheet> {
  static final List<String> _availableGameTypes = VenueSports.allSports;

  static final List<String> _availablePlayModes = VenueSports.playStyles;

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(matchmakingFiltersProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.filter_list, color: AppTheme.primaryGreen),
              const SizedBox(width: 10),
              const Text(
                'Filter Players',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (filters.hasFilters)
                TextButton(
                  onPressed: () {
                    ref.read(matchmakingFiltersProvider.notifier).state =
                        const MatchmakingFilters();
                  },
                  child: Text(
                    'Reset All',
                    style: TextStyle(color: AppTheme.primaryGreen),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Age Range Filter
                  _buildSectionTitle('Age Range'),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      RangeSlider(
                        values: filters.ageRange,
                        min: 18,
                        max: 65,
                        divisions: 47,
                        activeColor: AppTheme.primaryGreen,
                        labels: RangeLabels(
                          '${filters.ageRange.start.round()}',
                          '${filters.ageRange.end.round()}',
                        ),
                        onChanged: (values) {
                          ref.read(matchmakingFiltersProvider.notifier).state =
                              filters.copyWith(ageRange: values);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${filters.ageRange.start.round()} years'),
                            Text('${filters.ageRange.end.round()} years'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Max Distance Filter
                  _buildSectionTitle('Maximum Distance'),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Slider(
                        value: filters.maxDistance,
                        min: 1,
                        max: 50,
                        divisions: 10,
                        activeColor: AppTheme.primaryGreen,
                        label: '${filters.maxDistance.round()} km',
                        onChanged: (value) {
                          ref.read(matchmakingFiltersProvider.notifier).state =
                              filters.copyWith(maxDistance: value);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('1 km'),
                            Text('${filters.maxDistance.round()} km'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sports Filter
                  _buildSectionTitle('Sports'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableGameTypes.map((gameType) {
                      final isSelected = filters.gameTypes.contains(gameType);
                      return _buildFilterPill(
                        gameType,
                        isSelected,
                        (selected) {
                          List<String> updatedGameTypes = [
                            ...filters.gameTypes
                          ];
                          if (selected) {
                            updatedGameTypes.add(gameType);
                          } else {
                            updatedGameTypes.remove(gameType);
                          }
                          ref.read(matchmakingFiltersProvider.notifier).state =
                              filters.copyWith(gameTypes: updatedGameTypes);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Play Modes Filter
                  _buildSectionTitle('Play Modes'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availablePlayModes.map((mode) {
                      final isSelected = filters.playModes.contains(mode);
                      return _buildFilterPill(
                        mode,
                        isSelected,
                        (selected) {
                          List<String> updatedModes = [...filters.playModes];
                          if (selected) {
                            updatedModes.add(mode);
                          } else {
                            updatedModes.remove(mode);
                          }
                          ref.read(matchmakingFiltersProvider.notifier).state =
                              filters.copyWith(playModes: updatedModes);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Online Only Filter
                  _buildSectionTitle('Online Status'),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Show Online Players Only'),
                    value: filters.onlineOnly,
                    activeColor: AppTheme.primaryGreen,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    onChanged: (value) {
                      ref.read(matchmakingFiltersProvider.notifier).state =
                          filters.copyWith(onlineOnly: value);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Apply the filters
                    final user = ref.read(authServiceProvider).currentUser;
                    if (user != null) {
                      ref
                          .read(potentialMatchesProvider.notifier)
                          .loadPotentialMatches(user.id);

                      // Show confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            filters.hasFilters
                                ? 'Filters applied successfully'
                                : 'All filters cleared',
                          ),
                          backgroundColor: AppTheme.primaryGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFilterPill(String label, bool isSelected, Function(bool) onTap) {
    return GestureDetector(
      onTap: () => onTap(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
