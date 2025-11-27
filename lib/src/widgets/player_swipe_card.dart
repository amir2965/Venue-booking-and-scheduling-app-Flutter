import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/player_profile.dart';
import '../constants/venue_sports.dart';

class PlayerSwipeCard extends StatelessWidget {
  final PlayerProfile profile;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const PlayerSwipeCard({
    Key? key,
    required this.profile,
    required this.onLike,
    required this.onDislike,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile photo
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Profile image
                  profile.user.photoUrl != null
                      ? Image.network(
                          profile.user.photoUrl!,
                          fit: BoxFit.cover,
                          // Use a placeholder if image fails to load
                          errorBuilder: (ctx, obj, st) => Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),

                  // Skill level indicator in top right
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            profile.skillLevel.toStringAsFixed(1),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Preferred game types and skill tier at bottom of photo
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${profile.user.displayName ?? "Player"}, ${profile.skillTier}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Container(
                                width: constraints.maxWidth,
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.start,
                                  children:
                                      _getSportsToDisplay(profile).map((sport) {
                                    final String sportEmoji =
                                        VenueSports.getSportEmoji(sport);
                                    return Container(
                                      constraints: BoxConstraints(
                                        maxWidth: math.min(
                                            constraints.maxWidth * 0.45, 150.0),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary
                                            .withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            sportEmoji,
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              sport,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Profile details
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bio
                    Text(
                      profile.bio,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Sports section
                    ..._buildSportsSection(profile, theme),

                    // Play Modes (filtered to show only actual play modes, not sports)
                    ..._buildPlayModesSection(profile, theme),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            context,
                            Icons.sports_basketball,
                            'Games',
                            profile.matchesPlayed.toString(),
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            context,
                            Icons.emoji_events,
                            'Win Rate',
                            '${(profile.winRate * 100).toInt()}%',
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            context,
                            Icons.location_on,
                            'Location',
                            profile.preferredLocation ?? 'Any',
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // XP progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'XP: ${profile.experiencePoints}',
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              'Level ${(profile.experiencePoints / 1000).floor() + 1}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: profile.levelProgressPercentage / 100,
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                            color: theme.colorScheme.primary,
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    context,
                    Icons.close,
                    Colors.red,
                    onDislike,
                  ),
                  _buildActionButton(
                    context,
                    Icons.favorite,
                    Colors.green,
                    onLike,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    int maxLines = 2,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: 30,
        ),
      ),
    );
  }

  List<String> _getSportsToDisplay(PlayerProfile profile) {
    // If user has preferredSports data, use it
    if (profile.preferredSports.isNotEmpty) {
      // Filter to ensure only valid sports from VenueSports.allSports are shown
      return profile.preferredSports
          .where((sport) => VenueSports.allSports.contains(sport))
          .toList();
    }

    // For older users without preferredSports, filter preferredGameTypes to show only actual sports
    final sportsFromGameTypes = profile.preferredGameTypes
        .where((gameType) => VenueSports.allSports.contains(gameType))
        .toList();

    // If no sports found in preferredGameTypes, show default sports based on old data patterns
    if (sportsFromGameTypes.isEmpty) {
      // Check for billiards-related terms in preferredGameTypes to determine default sports
      final hasPoolTerms = profile.preferredGameTypes.any((gameType) =>
          gameType.toLowerCase().contains('ball') ||
          gameType.toLowerCase().contains('pool') ||
          gameType.toLowerCase().contains('billiard'));

      return hasPoolTerms ? ['Billiards'] : ['Bowling']; // Default fallback
    }

    return sportsFromGameTypes;
  }

  List<Widget> _buildSportsSection(PlayerProfile profile, ThemeData theme) {
    final sports = _getSportsToDisplay(profile);

    if (sports.isEmpty) return [];

    return [
      Text(
        'Sports',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: sports.map((sport) {
          final String sportEmoji = VenueSports.getSportEmoji(sport);
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sportEmoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  sport,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildPlayModesSection(PlayerProfile profile, ThemeData theme) {
    final validPlayModes = [
      'Just for Fun',
      'Learn & Improve',
      'Competitive',
      'Meet New People',
      'Regular Player'
    ];
    final playModes = profile.preferredGameTypes
        .where((gameType) => validPlayModes.contains(gameType))
        .toList();

    if (playModes.isEmpty) return [];

    return [
      Text(
        'Play Modes',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: playModes.map((gameType) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Text(
              gameType,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 12),
    ];
  }
}
