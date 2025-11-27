import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Partner profile model
class Partner {
  final String id;
  final String name;
  final String avatarUrl;
  final String skillLevel; // Beginner, Intermediate, Advanced, Pro
  final List<String> availability; // Days of the week
  final int experiencePoints;
  final int maxExperiencePoints;

  Partner({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.skillLevel,
    required this.availability,
    required this.experiencePoints,
    this.maxExperiencePoints = 100,
  });
}

// Partner provider for data management
final partnersProvider =
    StateNotifierProvider<PartnersNotifier, List<Partner>>((ref) {
  return PartnersNotifier();
});

class PartnersNotifier extends StateNotifier<List<Partner>> {
  PartnersNotifier() : super([]) {
    // Initialize with dummy data for now
    _fetchPartners();
  }

  void _fetchPartners() {
    // This would eventually be replaced with an API call
    state = [
      Partner(
        id: '1',
        name: 'Alex Thompson',
        avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
        skillLevel: 'Intermediate',
        availability: ['Monday', 'Wednesday', 'Friday'],
        experiencePoints: 65,
      ),
      Partner(
        id: '2',
        name: 'Jamie Wilson',
        avatarUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
        skillLevel: 'Advanced',
        availability: ['Tuesday', 'Thursday', 'Saturday'],
        experiencePoints: 82,
      ),
      Partner(
        id: '3',
        name: 'Chris Parker',
        avatarUrl: 'https://randomuser.me/api/portraits/men/67.jpg',
        skillLevel: 'Beginner',
        availability: ['Wednesday', 'Sunday'],
        experiencePoints: 28,
      ),
      Partner(
        id: '4',
        name: 'Taylor Rodriguez',
        avatarUrl: 'https://randomuser.me/api/portraits/women/23.jpg',
        skillLevel: 'Pro',
        availability: ['Monday', 'Thursday', 'Saturday', 'Sunday'],
        experiencePoints: 95,
      ),
      Partner(
        id: '5',
        name: 'Jordan Lee',
        avatarUrl: 'https://randomuser.me/api/portraits/men/91.jpg',
        skillLevel: 'Intermediate',
        availability: ['Tuesday', 'Friday', 'Saturday'],
        experiencePoints: 58,
      ),
    ];
  }

  void sendPlayInvite(String partnerId) async {
    // In a real app, this would send an invite to the partner
    // For now, simulate a match with a notification
    _showMatchNotification(
        partnerId: partnerId,
        partnerName:
            state.firstWhere((partner) => partner.id == partnerId).name);
  }

  void _showMatchNotification(
      {required String partnerId, required String partnerName}) async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Navigate to chat when notification is tapped
        // This would be handled by your navigation system
      },
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'match_channel',
      'Match Notifications',
      channelDescription: 'Notifications for partner matches',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Match!',
      'You matched with $partnerName! Tap to chat.',
      platformChannelSpecifics,
    );
  }
}

// Main Partner Swipe Screen widget
class PartnerSwipeScreen extends ConsumerStatefulWidget {
  const PartnerSwipeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PartnerSwipeScreen> createState() => _PartnerSwipeScreenState();
}

class _PartnerSwipeScreenState extends ConsumerState<PartnerSwipeScreen> {
  final CardSwiperController controller = CardSwiperController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Safely load partners after the widget is properly mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch for partner updates from provider
    final partnersFromProvider = ref.watch(partnersProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Find a Partner',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.go('/'),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : partnersFromProvider.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Swipe right to send a play invite, left to skip',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: CardSwiper(
                        key: ValueKey(
                            'partner_swiper_${partnersFromProvider.length}'),
                        controller: controller,
                        cardsCount: partnersFromProvider.length,
                        onSwipe: (int previousIndex, int? currentIndex,
                            CardSwiperDirection direction) {
                          // Only process if we have a valid index
                          if (previousIndex >= 0 &&
                              previousIndex < partnersFromProvider.length) {
                            if (direction == CardSwiperDirection.right) {
                              ref
                                  .read(partnersProvider.notifier)
                                  .sendPlayInvite(
                                      partnersFromProvider[previousIndex].id);
                              _showMatchDialog(
                                  context, partnersFromProvider[previousIndex]);
                            }
                          }
                          return true;
                        },
                        numberOfCardsDisplayed: partnersFromProvider.length < 3
                            ? partnersFromProvider.length
                            : 3,
                        backCardOffset: const Offset(20, 20),
                        padding: const EdgeInsets.all(24.0),
                        cardBuilder: (BuildContext context, int index,
                            int totalCards, int visibleCardsCount) {
                          // Ensure we don't try to access an out-of-bounds index
                          if (index < 0 ||
                              index >= partnersFromProvider.length) {
                            return const SizedBox.shrink();
                          }
                          return PartnerCard(
                              partner: partnersFromProvider[index]);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 32.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            onTap: () {
                              if (partnersFromProvider.isNotEmpty) {
                                controller.swipeLeft();
                              }
                            },
                            icon: Icons.close,
                            backgroundColor: Colors.red[100]!,
                            iconColor: Colors.red,
                          ),
                          _buildActionButton(
                            onTap: () {
                              if (partnersFromProvider.isNotEmpty) {
                                controller.swipeRight();
                              }
                            },
                            icon: Icons.check,
                            backgroundColor: Colors.green[100]!,
                            iconColor: Colors.green,
                          ),
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
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No partners available right now',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for new players',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 32,
        ),
      ),
    );
  }

  void _showMatchDialog(BuildContext context, Partner partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('It\'s a Match!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(partner.avatarUrl),
            ),
            const SizedBox(height: 16),
            Text('You and ${partner.name} want to play together!'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToChat(context, partner);
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Send Message'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context, Partner partner) {
    // This would navigate to your chat screen
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Chat with ${partner.name} would open here'),
        duration: const Duration(seconds: 2),
      ),
    );

    // In a real implementation, you would use your router:
    // context.go('/chat/${partner.id}');
  }
}

// Partner Card UI
class PartnerCard extends StatelessWidget {
  final Partner partner;

  const PartnerCard({Key? key, required this.partner}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo
              Expanded(
                flex: 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      partner.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person,
                            size: 100, color: Colors.grey),
                      ),
                    ),
                    // Gradient overlay for better text visibility
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
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
                    ),
                    // Name overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Text(
                        partner.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Profile Info
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skill Level
                      Row(
                        children: [
                          Icon(
                            Icons.sports,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Skill Level: ${partner.skillLevel}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Availability
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.purple[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Available: ${partner.availability.join(", ")}',
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // XP Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Experience',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                '${partner.experiencePoints}/${partner.maxExperiencePoints}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: partner.experiencePoints /
                                  partner.maxExperiencePoints,
                              minHeight: 10,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getColorForSkillLevel(partner.skillLevel),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Color _getColorForSkillLevel(String skillLevel) {
    switch (skillLevel) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.blue;
      case 'Advanced':
        return Colors.purple;
      case 'Pro':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
