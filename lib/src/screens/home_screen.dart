import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../models/player_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../theme/theme.dart';
import '../widgets/mongodb_status_indicator.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final hasCompletedProfileAsync =
        ref.watch(hasCompletedProfileSetupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billiards Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (profile) {
          // First, check if profile is null - should never happen now that we have ensureUserHasProfile
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Profile not found. Please set up your profile.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/profile-setup');
                    },
                    child: const Text('Set Up Profile'),
                  ),
                ],
              ),
            );
          }

          // Next, check if the profile is complete
          return hasCompletedProfileAsync.when(
            data: (isComplete) {
              if (!isComplete) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Please complete your profile setup to continue.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          context.go('/profile-setup');
                        },
                        child: const Text('Complete Profile Setup'),
                      ),
                    ],
                  ),
                );
              }

              // Profile exists and is complete, show the home content
              return _buildHomeContent(context, profile);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Error checking profile status: $error'),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, PlayerProfile profile) {
    // All users who reach the home screen have a profile, so never show the completion banner
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User Profile Card
          _buildProfileCard(context, profile),
          const SizedBox(height: 24),

          // Quick Actions Grid
          _buildQuickActionsGrid(context),
          const SizedBox(height: 24), // Stats and Progress Section
          _buildStatsSection(profile),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(profile),
          const SizedBox(height: 24),

          // Development Tools (only in debug mode)
          if (kDebugMode) _buildDevelopmentTools(),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, PlayerProfile profile) {
    // Debug log to see what profile data we have
    debugPrint('🏠 Home Screen Profile Card:');
    debugPrint('   firstName: ${profile.firstName}');
    debugPrint('   user.displayName: ${profile.user.displayName}');
    debugPrint('   username: ${profile.username}');
    debugPrint('   email: ${profile.user.email}');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryGreen, Color(0xFF1A8754)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.firstName ??
                            (profile.user.displayName ?? 'Player'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${profile.username}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        profile.skillTier,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // XP Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${(profile.skillLevel * 10).round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(profile.skillLevel * 20).round()} XP',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: profile.skillLevel / 5,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      {
        'icon': Icons.favorite,
        'title': 'Matchmaking',
        'route': '/matchmaking',
      },
      {
        'icon': Icons.chat,
        'title': 'My Matches',
        'route': '/matches',
      },
      {
        'icon': Icons.message,
        'title': 'Messages',
        'route': '/chats',
      },
      {
        'icon': Icons.sports_bar,
        'title': 'Book Venue',
        'route': '/venues',
      },
      {
        'icon': Icons.emoji_events,
        'title': 'Tournaments',
        'route': '/tournaments',
      },
      {
        'icon': Icons.school,
        'title': 'Training',
        'route': '/training',
      }, // Add Username Test for development purposes
      {
        'icon': Icons.verified_user,
        'title': 'Username Test',
        'route': '/test/username',
      },
      // Add Server Status for debugging
      {
        'icon': Icons.cloud,
        'title': 'Server Status',
        'route': '/server-status',
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: actions.map((action) {
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => context.go(action['route'] as String),
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action['icon'] as IconData,
                  size: 32,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 8),
                Text(
                  action['title'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsSection(PlayerProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.sports_score,
                  value: profile.matchesPlayed.toString(),
                  label: 'Matches',
                ),
                _buildStatItem(
                  icon: Icons.percent,
                  value: '${(profile.winRate * 100).round()}%',
                  label: 'Win Rate',
                ),
                _buildStatItem(
                  icon: Icons.emoji_events,
                  value: profile.achievements.length.toString(),
                  label: 'Achievements',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(PlayerProfile profile) {
    // This would typically be populated with real activity data
    final activities = [
      {
        'icon': Icons.sports_bar,
        'title': 'Booked a table at ${profile.preferredLocation}',
        'time': '2 hours ago',
      },
      {
        'icon': Icons.emoji_events,
        'title': 'Won a match against John Doe',
        'time': '1 day ago',
      },
      {
        'icon': Icons.school,
        'title': 'Completed Advanced Break Tutorial',
        'time': '2 days ago',
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...activities.map((activity) => _buildActivityItem(
                  icon: activity['icon'] as IconData,
                  title: activity['title'] as String,
                  time: activity['time'] as String,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevelopmentTools() {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text(
              'Development Tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: MongoDBStatusIndicator(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.code),
                    label: const Text('Server Status'),
                    onPressed: () {
                      context.push('/server-status');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Username Test'),
                    onPressed: () {
                      context.push('/test/username');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.storage),
              label: const Text('Web MongoDB Test'),
              onPressed: () {
                context.push('/test/web-mongodb');
              },
            ),
          ),
        ],
      ),
    );
  }
}
