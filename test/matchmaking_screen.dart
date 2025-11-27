import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../models/player_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/matchmaking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/matchmaking_service.dart';
import '../../theme/theme.dart';

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
  bool _isDragging = false;
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
      _isDragging = false;
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
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.explore,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Discover Players',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen,
                AppTheme.primaryGreen.withOpacity(0.8),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune, size: 20),
            ),
            onPressed: () => _showFiltersDialog(),
            tooltip: 'Filters',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh, size: 20),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Failed to load matches'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadMatches,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (profiles) {
              if (profiles.isEmpty) {
                return _buildEmptyState();
              }

              if (currentIndex >= profiles.length) {
                return _buildNoMoreProfilesState();
              }

              return _buildSwipeStack(profiles, currentIndex);
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
      bottomNavigationBar: potentialMatches.maybeWhen(
        data: (profiles) => currentIndex < profiles.length
            ? _buildActionButtons(profiles[currentIndex])
            : null,
        orElse: () => null,
      ),
    );
  }

  Widget _buildSwipeStack(List<PlayerProfile> profiles, int currentIndex) {
    return Center(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
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
      ),
    );
  }

  Widget _buildProfileCard(PlayerProfile profile, int stackIndex, bool isTop) {
    final screenSize = MediaQuery.of(context).size;
    final cardWidth = screenSize.width * 0.9;
    final cardHeight = screenSize.height * 0.65;

    return AnimatedBuilder(
      animation: Listenable.merge([_swipeAnimation, _scaleAnimation]),
      builder: (context, child) {
        double scale = 1.0 - (stackIndex * 0.05);
        double yOffset = stackIndex * 8.0;

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
    setState(() {
      _isDragging = true;
    });
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
        _isDragging = false;
      });
    }
  }

  Widget _buildActionButtons(PlayerProfile profile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
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
              color: AppTheme.primaryGreen,
              size: 64,
              onPressed: () => _handleSwipe(MatchAction.like, profile),
              label: 'Like',
            ),
          ],
        ),
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
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No players found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new players to match with',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadMatches,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
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
                color: AppTheme.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 60,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ve seen all available players.\nCheck back later for new matches!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => context.go('/matches'),
                  icon: const Icon(Icons.favorite),
                  label: const Text('View Matches'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
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

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filters'),
        content: const Text('Filter options coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfileDetails(PlayerProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
    final rotation = (dragOffset.dx / screenWidth) * 0.4;

    return Transform.rotate(
      angle: rotation,
      child: Card(
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      flex: 7,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          image: profile.profileImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(profile.profileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: profile.profileImageUrl == null
                            ? Center(
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryGreen.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${profile.firstName} ${profile.lastName}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '@${profile.username}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                        profile.skillLevel.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    profile.skillTier,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (profile.preferredLocation != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      profile.preferredLocation!,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (profile.bio.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                profile.bio,
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
                  ],
                ),
              ),
            ),
            // Like overlay
            if (likeOpacity > 0)
              Positioned(
                top: 60,
                right: 30,
                child: Opacity(
                  opacity: likeOpacity,
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryGreen,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                      ),
                      child: Text(
                        'LIKE',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Pass overlay
            if (passOpacity > 0)
              Positioned(
                top: 60,
                left: 30,
                child: Opacity(
                  opacity: passOpacity,
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.red,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red.withOpacity(0.1),
                      ),
                      child: const Text(
                        'PASS',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Tap to view profile indicator
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
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
                    const SizedBox(width: 6),
                    const Text(
                      'Tap for details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
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
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.45,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'It\'s a Match!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You and ${widget.profile.firstName} liked each other!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Keep Playing'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to matches screen to start conversation
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Match saved! You can find ${widget.profile.firstName} in your matches.',
                                ),
                                backgroundColor: AppTheme.primaryGreen,
                                duration: const Duration(seconds: 3),
                                action: SnackBarAction(
                                  label: 'View Matches',
                                  textColor: Colors.white,
                                  onPressed: () {
                                    // Dismiss the SnackBar first
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();

                                    // Use addPostFrameCallback to ensure context is still valid
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (context.mounted) {
                                        context.go('/matches');
                                      }
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
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
        return Container(
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
                      _buildSectionHeader('Player Stats', Icons.sports_esports),
                      const SizedBox(height: 12),
                      _buildStatsGrid(),
                      const SizedBox(height: 24),

                      // Game Preferences
                      if (profile.preferredGameTypes.isNotEmpty) ...[
                        _buildSectionHeader('Game Types', Icons.gamepad),
                        const SizedBox(height: 12),
                        _buildGameTypesGrid(),
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
                      '${profile.skillLevel.toStringAsFixed(1)} ${profile.skillTier}',
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

  Widget _buildGameTypesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: profile.preferredGameTypes.map((gameType) {
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
          child: Text(
            gameType,
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
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
          _DetailRow(
            icon: Icons.star_rate,
            label: 'Skill Rating',
            value: profile.skillLevel.toStringAsFixed(1),
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.military_tech,
            label: 'Tier',
            value: profile.skillTier,
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
