import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../models/player_profile.dart';
import '../../providers/player_provider.dart';
import '../../theme/theme.dart';

class PartnerMatchScreen extends ConsumerWidget {
  const PartnerMatchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(userMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Matches'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: () {
              context.go('/partners/swipe');
            },
            tooltip: 'Find Partners',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go('/home');
            },
            tooltip: 'Home',
          ),
        ],
      ),
      body: matchesAsync.when(
        data: (matches) => matches.isEmpty
            ? _buildEmptyState(context, ref)
            : _buildMatchesList(context, matches),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error loading matches: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/partners/swipe');
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No matches yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start swiping to find billiards partners',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/partners/swipe');
            },
            icon: const Icon(Icons.swipe),
            label: const Text('Find Partners'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList(BuildContext context, List<PlayerProfile> matches) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return _buildMatchCard(context, match);
      },
    );
  }

  Widget _buildMatchCard(BuildContext context, PlayerProfile match) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // In a real app, this would navigate to a chat screen
          _showChatComingSoonDialog(context, match);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile image
              CircleAvatar(
                radius: 32,
                backgroundImage: match.user.photoUrl != null
                    ? NetworkImage(match.user.photoUrl!)
                    : null,
                child: match.user.photoUrl == null
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
              const SizedBox(width: 16),

              // Match details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.user.displayName ?? 'Unknown Player',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${match.skillTier} • ${match.preferredGameTypes.join(", ")}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 18,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          match.skillLevel.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.emoji_events,
                          size: 18,
                          color: Colors.amber[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${match.matchesPlayed} matches',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Chat button
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _showChatComingSoonDialog(context, match);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatComingSoonDialog(BuildContext context, PlayerProfile match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chat Coming Soon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Chat with ${match.user.displayName} will be available in the next update!'),
            const SizedBox(height: 16),
            const Text(
              'In the meantime, you can:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.check_circle,
                    color: AppTheme.primaryGreen, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child:
                      Text('Arrange a game through the venue booking feature'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.check_circle,
                    color: AppTheme.primaryGreen, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Continue matching with more partners'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/venues');
            },
            child: const Text('Book a Table'),
          ),
        ],
      ),
    );
  }
}
