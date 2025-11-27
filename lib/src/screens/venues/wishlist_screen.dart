import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/venue.dart';
import '../../models/wishlist.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/venue_provider.dart';
import '../../widgets/venue_bottom_navigation.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  final String userId = 'user123'; // TODO: Get from auth provider

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishlistsProvider.notifier).loadWishlists(userId);
    });
  }

  Widget _buildWishlistCard(Wishlist wishlist, List<Venue> allVenues,
      {double width = 180}) {
    final wishlistVenues = allVenues
        .where((venue) => wishlist.venueIds.contains(venue.id))
        .toList();

    // Get the last venue added to the wishlist (most recent in the list)
    final lastVenue = wishlistVenues.isNotEmpty ? wishlistVenues.last : null;

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 8, bottom: 12),
      child: GestureDetector(
        onTap: () {
          // Navigate to wishlist details
          context.push('/venues/wishlist/${wishlist.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Square image or placeholder with shadow
            Stack(
              children: [
                Container(
                  height: width, // Square aspect ratio
                  width: width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: lastVenue != null
                        ? Image.network(
                            lastVenue.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.favorite,
                                  size: 50,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.favorite,
                              size: 50,
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                ),
                // Menu button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _showDeleteConfirmation(wishlist),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.grey[700],
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Wishlist information below image (similar to venue style)
            const SizedBox(height: 8),

            // Wishlist name
            Text(
              wishlist.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Number of saved venues
            Text(
              '${wishlist.venueIds.length} Saved',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Wishlist wishlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Wishlist'),
        content: Text('Are you sure you want to delete "${wishlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              print('UI: Attempting to delete wishlist ${wishlist.id}');
              final success =
                  await ref.read(wishlistsProvider.notifier).deleteWishlist(
                        wishlistId: wishlist.id,
                        userId: userId,
                      );

              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted "${wishlist.name}" successfully'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete "${wishlist.name}"'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlistsAsync = ref.watch(wishlistsProvider);
    final allVenues = ref.watch(venuesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Wishlists',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: wishlistsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF28A745),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading wishlists',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  ref.read(wishlistsProvider.notifier).loadWishlists(userId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28A745),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (wishlists) {
          if (wishlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Wishlists Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start exploring venues and save your favorites\nto create your first wishlist',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/venues'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Explore Venues',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75, // Adjusted to prevent overflow
                crossAxisSpacing:
                    0, // Space between columns (handled by margin in card)
                mainAxisSpacing:
                    0, // Space between rows (handled by margin in card)
              ),
              itemCount: wishlists.length,
              itemBuilder: (context, index) {
                final screenWidth = MediaQuery.of(context).size.width;
                // Account for: 16px left padding + 16px right padding + 8px margin between cards
                final cardWidth = (screenWidth - 40) / 2;
                return _buildWishlistCard(wishlists[index], allVenues,
                    width: cardWidth);
              },
            ),
          );
        },
      ),
      bottomNavigationBar:
          const VenueBottomNavigation(currentRoute: '/venues/wishlist'),
    );
  }
}
