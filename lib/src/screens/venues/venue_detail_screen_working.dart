import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/venue.dart';
import '../../providers/venue_provider.dart';

class VenueDetailScreen extends ConsumerStatefulWidget {
  final String venueId;

  const VenueDetailScreen({
    Key? key,
    required this.venueId,
  }) : super(key: key);

  @override
  ConsumerState<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends ConsumerState<VenueDetailScreen> {
  late PageController _imagePageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _showFullDescription(BuildContext context, String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'About this place',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Description
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeakHoursChart() {
    // Mock data for demonstration - in production this would come from API
    final now = DateTime.now();
    final currentHour = now.hour;

    // Peak hours data (0-2: Red/Packed, 3-5: Yellow/Moderate, 6-10: Green/Quiet)
    final Map<int, int> peakData = {
      6: 2, // 6 AM - Quiet
      7: 2, // 7 AM - Quiet
      8: 4, // 8 AM - Moderate
      9: 3, // 9 AM - Quiet
      10: 3, // 10 AM - Quiet
      11: 4, // 11 AM - Moderate
      12: 6, // 12 PM - Moderate
      13: 7, // 1 PM - Moderate
      14: 5, // 2 PM - Moderate
      15: 4, // 3 PM - Moderate
      16: 3, // 4 PM - Quiet
      17: 5, // 5 PM - Moderate
      18: 8, // 6 PM - Packed
      19: 9, // 7 PM - Packed
      20: 10, // 8 PM - Packed
      21: 9, // 9 PM - Packed
      22: 7, // 10 PM - Moderate
      23: 5, // 11 PM - Moderate
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's date
          Text(
            'Today, ${DateFormat('MMMM d').format(now)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          // Peak hours chart
          Row(
            children: [
              // Time labels column
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    const SizedBox(height: 8), // Align with first bar
                    ...List.generate(6, (index) {
                      final hour =
                          6 + (index * 3); // 6AM, 9AM, 12PM, 3PM, 6PM, 9PM
                      final timeFormat = hour <= 12
                          ? '${hour == 12 ? 12 : hour}${hour == 12 ? 'PM' : 'AM'}'
                          : '${hour - 12}PM';
                      return Container(
                        height: 30,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          timeFormat,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Chart bars
              Expanded(
                child: SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(18, (index) {
                      final hour = 6 + index; // Start from 6 AM
                      final intensity = peakData[hour] ?? 1;
                      final isCurrentHour = hour == currentHour;

                      // Color based on intensity (1-3: Green, 4-7: Yellow, 8-10: Red)
                      Color barColor;
                      if (intensity <= 3) {
                        barColor = Colors.green; // Quiet
                      } else if (intensity <= 7) {
                        barColor = Colors.orange; // Moderate
                      } else {
                        barColor = Colors.red; // Packed
                      }

                      // Current hour gets special styling
                      if (isCurrentHour) {
                        barColor = barColor.withOpacity(1.0);
                      } else {
                        barColor = barColor.withOpacity(0.7);
                      }

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Current time indicator
                              if (isCurrentHour) ...[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ] else
                                const SizedBox(height: 12),

                              // Bar
                              Container(
                                width: double.infinity,
                                height:
                                    (intensity * 15).toDouble(), // Scale height
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(2),
                                  ),
                                  border: isCurrentHour
                                      ? Border.all(
                                          color: Colors.black87, width: 1.5)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('🟢', 'Quiet', Colors.green),
              _buildLegendItem('🟡', 'Moderate', Colors.orange),
              _buildLegendItem('🔴', 'Packed', Colors.red),
            ],
          ),

          const SizedBox(height: 8),

          // Current status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getCurrentStatusColor(currentHour, peakData)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getCurrentStatusColor(currentHour, peakData)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getCurrentStatusColor(currentHour, peakData),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Right now: ${_getCurrentStatusText(currentHour, peakData)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getCurrentStatusColor(currentHour, peakData),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String emoji, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$emoji $label',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPeakTimeItem(String timeOfDay, String status, Color color) {
    return Column(
      children: [
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              status,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          timeOfDay,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getCurrentStatusColor(int currentHour, Map<int, int> peakData) {
    final intensity = peakData[currentHour] ?? 1;
    if (intensity <= 3) return Colors.green;
    if (intensity <= 7) return Colors.orange;
    return Colors.red;
  }

  String _getCurrentStatusText(int currentHour, Map<int, int> peakData) {
    final intensity = peakData[currentHour] ?? 1;
    if (intensity <= 3) return 'Quiet';
    if (intensity <= 7) return 'Moderate';
    return 'Packed';
  }

  @override
  Widget build(BuildContext context) {
    final venueAsyncValue = ref.watch(venueByIdProvider(widget.venueId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: venueAsyncValue.when(
        data: (venue) {
          if (venue == null) {
            return const Center(child: Text('Venue not found'));
          }
          return _buildVenueDetail(context, venue);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading venue: $error'),
        ),
      ),
      bottomNavigationBar: venueAsyncValue.when(
        data: (venue) {
          if (venue == null) return null;
          return _buildBottomBar(context, venue);
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildVenueDetail(BuildContext context, Venue venue) {
    final imageUrls =
        venue.imageUrls.isNotEmpty ? venue.imageUrls : [venue.thumbnailUrl];
    final shortDescription = venue.description.length > 60
        ? '${venue.description.substring(0, 60)}...'
        : venue.description;

    return Stack(
      children: [
        // Background image carousel (bottom layer) - FULLY INTERACTIVE
        PageView.builder(
          controller: _imagePageController,
          itemCount: imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              clipBehavior: Clip.none,
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
            );
          },
        ),

        // White content container positioned 100px from top (50px below back button)
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 15,
                  offset: const Offset(0, -3),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Main content container
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: Column(
                    children: [
                      // Scrollable content area
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24,
                              24), // Reduced top padding for smaller drag handler
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // HIGH VISIBILITY TEST - Venue Peak Hours Section
                              Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PEAK HOURS',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Best times to visit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildPeakTimeItem(
                                            'Morning', 'Quiet', Colors.green),
                                        _buildPeakTimeItem('Afternoon',
                                            'Moderate', Colors.orange),
                                        _buildPeakTimeItem(
                                            'Evening', 'Packed', Colors.red),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Venue title (centered)
                              Center(
                                child: Text(
                                  venue.name,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Address
                              Center(
                                child: Text(
                                  venue.address,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Maximum players
                              Center(
                                child: Text(
                                  'Up to ${venue.maxPlayers} players',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Rating, Guest favourite, Reviews
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Rating
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.amber, size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          venue.rating.toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const Text(' | ',
                                        style: TextStyle(color: Colors.grey)),

                                    // Guest favourite
                                    const Text(
                                      'Guest favourite',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    const Text(' | ',
                                        style: TextStyle(color: Colors.grey)),

                                    // Reviews
                                    Text(
                                      '${venue.reviewCount} Reviews',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Host information
                              Row(
                                children: [
                                  // Host profile picture
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: venue.hostImageUrl != null
                                        ? NetworkImage(venue.hostImageUrl!)
                                        : null,
                                    onBackgroundImageError:
                                        venue.hostImageUrl != null
                                            ? (_, __) {}
                                            : null,
                                    child: venue.hostImageUrl == null
                                        ? Icon(Icons.person,
                                            color: Colors.grey[600])
                                        : null,
                                  ),

                                  const SizedBox(width: 16),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hosted by ${venue.hostName}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${venue.hostYearsOfHosting} years hosting',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Features and Accessibility
                              const Text(
                                'What this place offers',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 16),

                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: venue.features
                                    .map((feature) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.grey[300]!),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            feature,
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ))
                                    .toList(),
                              ),

                              const SizedBox(height: 24),

                              // Description
                              const Text(
                                'About this place',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                shortDescription,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),

                              const SizedBox(height: 12),

                              GestureDetector(
                                onTap: () => _showFullDescription(
                                    context, venue.description),
                                child: const Text(
                                  'Show more',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Address and Map
                              const Text(
                                'Where you\'ll be',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Map placeholder with rounded corners
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    children: [
                                      // Map placeholder - you can replace this with actual map
                                      Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.map,
                                                  size: 40, color: Colors.grey),
                                              SizedBox(height: 8),
                                              Text(
                                                'Interactive Map',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Text(
                                venue.address,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(
                                  height: 100), // Space for bottom navigation
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Drag handler positioned ON TOP EDGE of dialog box - visible and accessible
                Positioned(
                  top:
                      5, // Position just inside the dialog to ensure visibility
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
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

        // Back button overlay
        Positioned(
          top: 50,
          left: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.go('/venues'),
            ),
          ),
        ),

        // Image counter overlay
        Positioned(
          top: MediaQuery.of(context).size.height * 0.35,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${imageUrls.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, Venue venue) {
    return Container(
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
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${venue.pricePerHour.toStringAsFixed(2)} / hour',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    venue.isOpen ? 'Available Now' : 'Currently Closed',
                    style: TextStyle(
                      color: venue.isOpen ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: venue.isOpen
                    ? () {
                        // Show booking dialog
                        _showBookingDialog(context, venue);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  'Reserve',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDialog(BuildContext context, Venue venue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BookingBottomSheet(venue: venue),
    );
  }
}

class BookingBottomSheet extends StatefulWidget {
  final Venue venue;

  const BookingBottomSheet({Key? key, required this.venue}) : super(key: key);

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay.now();
  int durationHours = 1;
  int selectedTableIndex = 0;

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.venue.pricePerHour * durationHours;
    final tableCount = widget.venue.tableTypes.length * 2;

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header drag indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Title
          const Text(
            'Make a Reservation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selection
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (context, index) {
                        final date = DateTime.now().add(Duration(days: index));
                        final isSelected = date.year == selectedDate.year &&
                            date.month == selectedDate.month &&
                            date.day == selectedDate.day;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDate = date;
                            });
                          },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black87 : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE').format(date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Time Selection
                  const Text(
                    'Start Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) {
                        setState(() {
                          startTime = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(
                            startTime.format(context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Duration Selection
                  const Text(
                    'Duration (hours)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        final hours = index + 1;
                        final isSelected = durationHours == hours;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              durationHours = hours;
                            });
                          },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black87 : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$hours h',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Table Selection
                  const Text(
                    'Select Table',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tableCount,
                      itemBuilder: (context, index) {
                        final isSelected = selectedTableIndex == index;
                        final tableTypeIndex =
                            index % widget.venue.tableTypes.length;
                        final tableType =
                            widget.venue.tableTypes[tableTypeIndex];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedTableIndex = index;
                            });
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black87 : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sports_baseball, // Pool table icon
                                  size: 32,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Table ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  tableType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Bottom section with price and book button
          Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Price:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle booking logic here
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking confirmed!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
  }
}
