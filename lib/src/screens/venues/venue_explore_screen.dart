import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/venue.dart';
import '../../providers/venue_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../constants/venue_sports.dart';
import '../../widgets/venue_bottom_navigation.dart';

class VenueExploreScreen extends ConsumerStatefulWidget {
  const VenueExploreScreen({super.key});

  @override
  ConsumerState<VenueExploreScreen> createState() => _VenueExploreScreenState();
}

class _VenueExploreScreenState extends ConsumerState<VenueExploreScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSport = '';
  String _selectedCategory = 'All'; // New: Track selected main category
  final String userId = 'user123'; // TODO: Get from auth provider

  // Scroll controller to track scroll position
  late ScrollController _scrollController;
  // Animation controller for smooth icon transitions
  late AnimationController _animationController;
  // Scroll controllers for sports filter synchronization
  late ScrollController _sportsFilterIconsController;
  late ScrollController _sportsFilterTitlesController;
  // Scroll controller for category pills
  late ScrollController _categoryScrollController;

  // Cache the last known wishlists to prevent blinking
  List<dynamic> _cachedWishlists = [];

  // Get filtered activities based on selected category
  List<String> get _filteredActivities {
    if (_selectedCategory == 'All') {
      return VenueSports.allSports;
    }
    return VenueSports.getActivitiesForCategory(_selectedCategory);
  }

  @override
  void initState() {
    super.initState();
    // Initialize scroll controller
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScroll);

    // Initialize sports filter scroll controllers
    _sportsFilterIconsController = ScrollController();
    _sportsFilterTitlesController = ScrollController();
    _categoryScrollController = ScrollController();

    // Add listeners to synchronize scrolling
    _sportsFilterIconsController.addListener(_syncTitlesFromIcons);
    _sportsFilterTitlesController.addListener(_syncIconsFromTitles);

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Load user's wishlists when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishlistsProvider.notifier).loadWishlists(userId);
    });
  }

  void _handleScroll() {
    final previousValue = _animationController.value;

    // Start animating when user scrolls down (after 10 pixels)
    if (_scrollController.offset > 10) {
      _animationController.value = _scrollController.offset / 50;
      if (_animationController.value > 1) {
        _animationController.value = 1;
      }
    } else {
      _animationController.value = 0;
    }

    // Force synchronization when crossing the threshold where icons become visible/hidden
    final currentValue = _animationController.value;
    if ((previousValue >= 0.8 && currentValue < 0.8) ||
        (previousValue < 0.8 && currentValue >= 0.8)) {
      _forceSynchronization();
    }
  }

  void _syncTitlesFromIcons() {
    if (_sportsFilterTitlesController.hasClients &&
        _sportsFilterIconsController.hasClients) {
      if (_sportsFilterTitlesController.offset !=
          _sportsFilterIconsController.offset) {
        _sportsFilterTitlesController
            .jumpTo(_sportsFilterIconsController.offset);
      }
    }
  }

  void _syncIconsFromTitles() {
    if (_sportsFilterIconsController.hasClients &&
        _sportsFilterTitlesController.hasClients) {
      if (_sportsFilterIconsController.offset !=
          _sportsFilterTitlesController.offset) {
        _sportsFilterIconsController
            .jumpTo(_sportsFilterTitlesController.offset);
      }
    }
  }

  // Force synchronization when animation state changes
  void _forceSynchronization() {
    if (_sportsFilterIconsController.hasClients &&
        _sportsFilterTitlesController.hasClients) {
      // Always sync both controllers to the titles controller position
      // since titles are always visible
      final targetOffset = _sportsFilterTitlesController.offset;
      if (_sportsFilterIconsController.offset != targetOffset) {
        _sportsFilterIconsController.jumpTo(targetOffset);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _sportsFilterIconsController.removeListener(_syncTitlesFromIcons);
    _sportsFilterTitlesController.removeListener(_syncIconsFromTitles);
    _sportsFilterIconsController.dispose();
    _sportsFilterTitlesController.dispose();
    _categoryScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showWishlistDialog(Venue venue) {
    print('DEBUG: _showWishlistDialog called for venue: ${venue.name}');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      barrierDismissible: true,
      builder: (context) {
        print('DEBUG: Building dialog');
        return _buildWishlistDialog(venue);
      },
    );
  }

  Widget _buildWishlistDialog(Venue venue) {
    print('DEBUG: _buildWishlistDialog called');

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Save to Wishlist',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content with wishlist integration
              Consumer(
                builder: (context, ref, child) {
                  final wishlistsAsync = ref.watch(wishlistsProvider);

                  return wishlistsAsync.when(
                    loading: () => Container(
                      padding: const EdgeInsets.all(40),
                      child: const CircularProgressIndicator(
                        color: Color(0xFF28A745),
                      ),
                    ),
                    error: (error, stack) => Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('Error loading wishlists: $error'),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(wishlistsProvider.notifier)
                                  .loadWishlists(userId);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (wishlists) => Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add "${venue.name}" to wishlist:',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Check if venue is already in any wishlist
                          Builder(builder: (context) {
                            final availableWishlists = wishlists
                                .where((wishlist) =>
                                    !wishlist.venueIds.contains(venue.id))
                                .toList();

                            // Show available wishlists (ones that don't contain this venue)
                            return Column(
                              children: [
                                if (availableWishlists.isNotEmpty) ...[
                                  Container(
                                    constraints:
                                        const BoxConstraints(maxHeight: 200),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: availableWishlists.length,
                                      itemBuilder: (context, index) {
                                        final wishlist =
                                            availableWishlists[index];

                                        return ListTile(
                                          title: Text(wishlist.name),
                                          subtitle: Text(
                                              '${wishlist.venueIds.length} venues'),
                                          trailing: const Icon(
                                              Icons.add_circle_outline,
                                              color: Colors.grey),
                                          onTap: () async {
                                            // Close dialog immediately when user selects a wishlist
                                            Navigator.of(context).pop();

                                            final success = await ref
                                                .read(
                                                    wishlistsProvider.notifier)
                                                .addVenueToWishlist(
                                                  wishlistId: wishlist.id,
                                                  venueId: venue.id,
                                                  userId: userId,
                                                );

                                            if (success) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Added "${venue.name}" to ${wishlist.name}'),
                                                  backgroundColor:
                                                      const Color(0xFF28A745),
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Failed to add "${venue.name}" to ${wishlist.name}'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const Divider(),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline,
                                            color: Colors.orange.shade600),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'No available wishlists. Create a new one to save this venue.',
                                            style: TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Create new wishlist button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _showCreateWishlistDialog(venue),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create New Wishlist'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF28A745),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateWishlistDialog(Venue venue) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Wishlist'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Enter wishlist name',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, child) => ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final wishlist =
                    await ref.read(wishlistsProvider.notifier).createWishlist(
                          name: nameController.text.trim(),
                          userId: userId,
                        );

                if (wishlist != null) {
                  Navigator.of(context).pop(); // Close create dialog
                  Navigator.of(context).pop(); // Close main dialog

                  // Add venue to the new wishlist
                  final success = await ref
                      .read(wishlistsProvider.notifier)
                      .addVenueToWishlist(
                        wishlistId: wishlist.id,
                        venueId: venue.id,
                        userId: userId,
                      );

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Created "${wishlist.name}" and added "${venue.name}"'),
                        backgroundColor: const Color(0xFF28A745),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF28A745),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create & Add'),
            ),
          ),
        ],
      ),
    );
  }

  bool _isVenueInWishlists(String venueId, List<dynamic> wishlists) {
    return wishlists.any((wishlist) => wishlist.venueIds.contains(venueId));
  }

  List<String> _getWishlistsContainingVenue(
      String venueId, List<dynamic> wishlists) {
    return wishlists
        .where((wishlist) => wishlist.venueIds.contains(venueId))
        .map((wishlist) => wishlist.id as String)
        .toList();
  }

  Future<void> _handleHeartButtonTap(
      Venue venue, List<dynamic> wishlists) async {
    print('DEBUG: Heart button tapped for venue: ${venue.name}');

    final isInWishlist = _isVenueInWishlists(venue.id, wishlists);

    if (isInWishlist) {
      // Remove from all wishlists containing this venue
      final wishlistIds = _getWishlistsContainingVenue(venue.id, wishlists);
      print('DEBUG: Removing venue from ${wishlistIds.length} wishlist(s)');

      bool allRemoved = true;
      for (final wishlistId in wishlistIds) {
        final success =
            await ref.read(wishlistsProvider.notifier).removeVenueFromWishlist(
                  wishlistId: wishlistId,
                  venueId: venue.id,
                  userId: userId,
                );
        if (!success) allRemoved = false;
      }

      if (allRemoved && wishlistIds.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${venue.name}" from wishlist'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Only show dialog if venue is not in any wishlist
      final existingWishlistIds =
          _getWishlistsContainingVenue(venue.id, wishlists);
      if (existingWishlistIds.isEmpty) {
        // Show dialog to add to wishlist (only if not in any wishlist)
        _showWishlistDialog(venue);
      }
      // If venue is already in a wishlist, do nothing (no dialog, no message)
    }
  }

  // Build category pill for filtering
  Widget _buildCategoryPill(String category, String icon,
      {List<int>? gradient}) {
    final isSelected = _selectedCategory == category;
    final colors =
        gradient ?? [0xFF64B5F6, 0xFF2196F3]; // Default blue gradient

    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCategory = category;
              _selectedSport =
                  ''; // Reset activity selection when changing category
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        Color(colors[0]),
                        Color(colors[1]),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey[300]!,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Color(colors[1]).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: onSeeAll,
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (onSeeAll != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVenueCard(Venue venue, {double width = 180}) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 16, bottom: 12),
      child: GestureDetector(
        onTap: () {
          context.push('/venues/${venue.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Square image with favorite button and shadow
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
                    child: Image.network(
                      venue.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final wishlistsAsync = ref.watch(wishlistsProvider);

                      // Update cache when we have data, otherwise use cached data
                      List<dynamic> wishlists;
                      if (wishlistsAsync.hasValue) {
                        _cachedWishlists = wishlistsAsync.value!;
                        wishlists = _cachedWishlists;
                      } else {
                        wishlists =
                            _cachedWishlists; // Use cached data during loading
                      }

                      final isInWishlist =
                          _isVenueInWishlists(venue.id, wishlists);

                      return GestureDetector(
                        onTap: () => _handleHeartButtonTap(venue, wishlists),
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
                            isInWishlist
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isInWishlist ? Colors.red : Colors.grey[700],
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Closed badge
                if (!venue.isOpen)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Closed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Venue information below image (Airbnb style)
            const SizedBox(height: 8),

            // Venue name
            Text(
              venue.name,
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

            // Fee per hour
            Text(
              '\$${venue.pricePerHour.toInt()} per hour',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 4),

            // Star rating
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.black87,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${venue.rating}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${venue.reviewCount})',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalVenueList(List<Venue> venues) {
    return Container(
      height: 280, // Adjusted for even smaller images + text content
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: venues.length,
        itemBuilder: (context, index) {
          return _buildVenueCard(venues[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allVenues = ref.watch(venuesProvider);
    final nearbyVenues = ref.watch(nearbyVenuesProvider);

    // Filter venues based on selected sport
    final filteredVenues = _selectedSport.isEmpty
        ? allVenues
        : allVenues
            .where((venue) => venue.tableTypes.any((type) =>
                type.toLowerCase().contains(_selectedSport.toLowerCase()) ||
                _selectedSport.toLowerCase().contains(type.toLowerCase())))
            .toList();

    // Get top-rated venues
    final topRatedVenues = [...allVenues]
      ..sort((a, b) => b.rating.compareTo(a.rating));

    // Get trending venues (most reviewed recently)
    final trendingVenues = [...allVenues]
      ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F7), // Same warm white as search bar
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Fixed app bar with search bar and sport filter
          SliverAppBar(
            expandedHeight:
                228, // Category pills (48) + spacing (12) + icons (70) + spacing (10) + buffer
            toolbarHeight: 85, // Increased from 72 to provide more space at top
            collapsedHeight:
                90, // Reduced to minimize space between search bar and titles when scrolled
            floating: false,
            pinned: true,
            backgroundColor: const Color(
                0xFFF2F7F2), // Subtle light green tint, professional but noticeable
            surfaceTintColor:
                const Color(0xFFF2F7F2), // Match the background color
            scrolledUnderElevation: 2,
            elevation: 0,
            shadowColor: const Color(
                0xFFD8E5D8), // Darker version of header color for subtle shadow
            automaticallyImplyLeading: false,
            title: Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(
                    0xFFF2F7F2), // Subtle light green tint, professional but noticeable
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      onChanged: (value) {
                        ref.read(venueFiltersProvider.notifier).state =
                            ref.read(venueFiltersProvider).copyWith(
                                  searchTerm: value,
                                );
                      },
                    ),
                    // Centered search icon positioned before text
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: Colors.black, // Solid black
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Start your search',
                                style: TextStyle(
                                  color: Colors.black, // Solid black
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Use flexibleSpace to create a custom layout within the SliverAppBar
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                children: [
                  // Spacer to push content below the search bar
                  const SizedBox(height: 88),

                  // Category Pills Row (Animated to hide when scrolled)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // Calculate height and opacity based on scroll
                      final double categoryHeight =
                          48 * (1 - _animationController.value);
                      final double opacity = 1.0 -
                          (_animationController.value * 2.5).clamp(0.0, 1.0);

                      // Hide completely when scrolled down
                      if (_animationController.value >= 0.4) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        height: categoryHeight,
                        child: Opacity(
                          opacity: opacity,
                          child: ListView(
                            controller: _categoryScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              _buildCategoryPill('All', '🌟'),
                              ...VenueSports.mainCategories.entries
                                  .map((entry) {
                                return _buildCategoryPill(
                                  entry.key,
                                  entry.value['icon'] as String,
                                  gradient:
                                      entry.value['gradient'] as List<int>,
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Spacing between category pills and activity icons
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final double spacerHeight =
                          12 * (1 - _animationController.value);

                      if (_animationController.value >= 0.8) {
                        return const SizedBox.shrink();
                      }

                      return SizedBox(height: spacerHeight);
                    },
                  ),

                  // Activity filter icons (within the hover area)
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // Calculate container height based on animation value
                      final double containerHeight =
                          70 * (1 - _animationController.value);

                      // If fully scrolled, reduce height but keep the space for titles
                      if (_animationController.value >= 0.8) {
                        return const SizedBox(height: 10);
                      }

                      // Force synchronization when icons become visible
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _forceSynchronization();
                      });

                      return Container(
                        height: containerHeight,
                        width: MediaQuery.of(context).size.width,
                        child: ListView.builder(
                          controller: _sportsFilterIconsController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: _filteredActivities.length,
                          itemBuilder: (context, index) {
                            final sport = _filteredActivities[index];
                            final icon = VenueSports.sportIcons[sport] ?? '🎯';
                            final isSelected = _selectedSport == sport;

                            return Container(
                              width: 85,
                              margin: const EdgeInsets.only(right: 16),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedSport = isSelected ? '' : sport;
                                  });
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    // Icon container only (title stays in bottom bar)
                                    Container(
                                      width: 60,
                                      height:
                                          60 * (1 - _animationController.value),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: Opacity(
                                        opacity:
                                            1.0 - _animationController.value,
                                        child: Center(
                                          child: Text(
                                            icon,
                                            style:
                                                const TextStyle(fontSize: 24),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Bottom property for sport filter titles (always stationary with top margin when icons visible)
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(46),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  // Add top margin when icons are visible to create space between icons and titles
                  final double topMargin =
                      10 * (1 - _animationController.value);

                  return Container(
                    margin: EdgeInsets.only(top: topMargin),
                    padding: const EdgeInsets.only(bottom: 6, top: 0),
                    height: 36,
                    child: ListView.builder(
                      controller: _sportsFilterTitlesController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _filteredActivities.length,
                      itemBuilder: (context, index) {
                        final sport = _filteredActivities[index];
                        final isSelected = _selectedSport == sport;

                        return Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 16),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSport = isSelected ? '' : sport;
                              });
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  sport,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 2,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // Popular Venues in South Bank Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Popular Venues in South Bank',
              onSeeAll: () => context.push('/venues/category/popular'),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalVenueList(
              nearbyVenues.when(
                data: (venues) => venues.take(5).toList(),
                loading: () => List.generate(
                  3,
                  (index) => Venue.skeleton(),
                ),
                error: (error, stack) => [],
              ),
            ),
          ),

          // Top-Rated Venues Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Top-Rated Venues',
              onSeeAll: () => context.push('/venues/category/top-rated'),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalVenueList(
              topRatedVenues.take(5).toList(),
            ),
          ),

          // Trending Venues Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'Trending Venues',
              onSeeAll: () => context.push('/venues/category/trending'),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalVenueList(
              trendingVenues.take(5).toList(),
            ),
          ),

          // Filtered Venues (based on selected sport)
          if (_selectedSport.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                'Venues for $_selectedSport',
                onSeeAll: () => context.push('/venues/sport/$_selectedSport'),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildHorizontalVenueList(
                filteredVenues.take(5).toList(),
              ),
            ),
          ],

          // All Venues Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              'All Venues',
              onSeeAll: () => context.push('/venues/category/all'),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalVenueList(
              allVenues.take(5).toList(),
            ),
          ),

          // Add some padding at the bottom for the navigation bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      bottomNavigationBar: const VenueBottomNavigation(
        currentRoute: '/venues', // Explore screen
      ),
    );
  }
}
