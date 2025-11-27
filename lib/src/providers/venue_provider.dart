import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/venue.dart';

// Mock data service for venues
class VenueService {
  // Mock data for venues
  List<Venue> getMockVenues() {
    return [
      // Billiards Venues
      Venue(
        id: '1',
        name: 'Downtown Billiards Club',
        address: '123 Main St, Downtown',
        city: 'New York',
        latitude: 40.7128,
        longitude: -74.0060,
        distanceInKm: 0.8,
        pricePerHour: 25.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1509316785289-025f5b846b35?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1588539543889-4909fd7d8f7e?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1565937166894-7b9f07c357ce?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1509316785289-025f5b846b35?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Premium billiards club with professional-grade tables and full-service bar. Perfect for casual games or serious players.',
        amenities: ['Bar', 'Food', 'Private Rooms', 'Professional Tables'],
        tableTypes: ['Pool', 'Snooker'],
        rating: 4.7,
        reviewCount: 128,
        isOpen: true,
        availabilitySlots: {
          'Today': [
            '10:00 AM',
            '11:00 AM',
            '2:00 PM',
            '3:00 PM',
            '4:00 PM',
            '8:00 PM'
          ],
          'Tomorrow': [
            '9:00 AM',
            '10:00 AM',
            '11:00 AM',
            '1:00 PM',
            '3:00 PM',
            '5:00 PM',
            '7:00 PM'
          ],
        },
      ),
      Venue(
        id: '2',
        name: 'Elite Cue & Brew',
        address: '456 Park Ave, Midtown',
        city: 'New York',
        latitude: 40.7580,
        longitude: -73.9855,
        distanceInKm: 1.2,
        pricePerHour: 35.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1588539543889-4909fd7d8f7e?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1509316785289-025f5b846b35?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1565937166894-7b9f07c357ce?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1588539543889-4909fd7d8f7e?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Upscale billiards lounge with craft beers on tap and gourmet snacks. Modern atmosphere with high-end tables.',
        amenities: ['Craft Beer', 'Gourmet Food', 'Air Conditioning', 'HD TVs'],
        tableTypes: ['Pool', 'Carom'],
        rating: 4.5,
        reviewCount: 96,
        isOpen: true,
        availabilitySlots: {
          'Today': ['2:00 PM', '3:00 PM', '7:00 PM', '8:00 PM', '9:00 PM'],
          'Tomorrow': [
            '10:00 AM',
            '1:00 PM',
            '2:00 PM',
            '5:00 PM',
            '6:00 PM',
            '8:00 PM'
          ],
        },
      ),
      // Bowling Venues
      Venue(
        id: '7',
        name: 'Strike Zone Bowling',
        address: '789 Bowling Blvd, South Bank',
        city: 'New York',
        latitude: 40.7150,
        longitude: -74.0100,
        distanceInKm: 1.5,
        pricePerHour: 40.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1544946503-7ad5ac882d5d?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1544946503-7ad5ac882d5d?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Modern 24-lane bowling alley with state-of-the-art scoring systems, arcade games, and full restaurant.',
        amenities: [
          '24 Lanes',
          'Restaurant',
          'Arcade',
          'Party Rooms',
          'Shoe Rental'
        ],
        tableTypes: ['Bowling'],
        rating: 4.6,
        reviewCount: 342,
        isOpen: true,
        availabilitySlots: {
          'Today': ['11:00 AM', '1:00 PM', '3:00 PM', '5:00 PM', '7:00 PM'],
          'Tomorrow': [
            '10:00 AM',
            '12:00 PM',
            '2:00 PM',
            '4:00 PM',
            '6:00 PM',
            '8:00 PM'
          ],
        },
      ),
      Venue(
        id: '8',
        name: 'Cosmic Bowling Center',
        address: '456 Galaxy Ave, Downtown',
        city: 'New York',
        latitude: 40.7200,
        longitude: -74.0050,
        distanceInKm: 0.9,
        pricePerHour: 35.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1544946503-7ad5ac882d5d?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1578662996442-48f60103fc96?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Cosmic bowling experience with blacklight lanes, neon decorations, and DJ nights every weekend.',
        amenities: [
          'Cosmic Bowling',
          'DJ Nights',
          'Bar',
          'Glow Decor',
          'Party Packages'
        ],
        tableTypes: ['Bowling'],
        rating: 4.3,
        reviewCount: 189,
        isOpen: true,
        availabilitySlots: {
          'Today': ['12:00 PM', '2:00 PM', '4:00 PM', '8:00 PM'],
          'Tomorrow': ['11:00 AM', '1:00 PM', '3:00 PM', '5:00 PM', '7:00 PM'],
        },
      ),
      // Mini Golf Venues
      Venue(
        id: '9',
        name: 'Adventure Mini Golf',
        address: '321 Fun Park Lane, Central Park',
        city: 'New York',
        latitude: 40.7589,
        longitude: -73.9851,
        distanceInKm: 2.1,
        pricePerHour: 15.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1553979459-d2229ba7433a?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1553979459-d2229ba7433a?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Outdoor mini golf course with 18 challenging holes, waterfalls, and pirate-themed obstacles.',
        amenities: [
          '18 Holes',
          'Outdoor Course',
          'Themed Obstacles',
          'Snack Bar',
          'Family Friendly'
        ],
        tableTypes: ['Mini Golf'],
        rating: 4.4,
        reviewCount: 267,
        isOpen: true,
        availabilitySlots: {
          'Today': ['9:00 AM', '11:00 AM', '1:00 PM', '3:00 PM', '5:00 PM'],
          'Tomorrow': [
            '9:00 AM',
            '10:00 AM',
            '12:00 PM',
            '2:00 PM',
            '4:00 PM',
            '6:00 PM'
          ],
        },
      ),
      Venue(
        id: '10',
        name: 'Indoor Mini Golf Kingdom',
        address: '654 Entertainment St, Times Square',
        city: 'New York',
        latitude: 40.7580,
        longitude: -73.9855,
        distanceInKm: 1.8,
        pricePerHour: 18.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1553979459-d2229ba7433a?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1534796636912-3b95b3ab5986?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Climate-controlled indoor mini golf with glow-in-the-dark courses and jungle adventure themes.',
        amenities: [
          'Indoor Course',
          'Glow in Dark',
          'Climate Control',
          'Party Rooms',
          'Gift Shop'
        ],
        tableTypes: ['Mini Golf'],
        rating: 4.2,
        reviewCount: 156,
        isOpen: true,
        availabilitySlots: {
          'Today': ['10:00 AM', '12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM'],
          'Tomorrow': [
            '9:00 AM',
            '11:00 AM',
            '1:00 PM',
            '3:00 PM',
            '5:00 PM',
            '7:00 PM'
          ],
        },
      ),
      // Table Tennis Venues
      Venue(
        id: '11',
        name: 'Ping Pong Paradise',
        address: '987 Sports Complex Ave, Brooklyn',
        city: 'New York',
        latitude: 40.6782,
        longitude: -73.9442,
        distanceInKm: 3.2,
        pricePerHour: 20.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1609087581580-d921a3a46ec9?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Professional table tennis facility with Olympic-standard tables and coaching available.',
        amenities: [
          'Olympic Tables',
          'Coaching',
          'Equipment Rental',
          'Tournaments',
          'Locker Rooms'
        ],
        tableTypes: ['Table Tennis'],
        rating: 4.8,
        reviewCount: 203,
        isOpen: true,
        availabilitySlots: {
          'Today': ['8:00 AM', '10:00 AM', '2:00 PM', '4:00 PM', '6:00 PM'],
          'Tomorrow': [
            '8:00 AM',
            '9:00 AM',
            '11:00 AM',
            '1:00 PM',
            '3:00 PM',
            '5:00 PM'
          ],
        },
      ),
      Venue(
        id: '12',
        name: 'Metropolitan Table Tennis Club',
        address: '147 Metropolitan Ave, Queens',
        city: 'New York',
        latitude: 40.7282,
        longitude: -73.9942,
        distanceInKm: 2.8,
        pricePerHour: 25.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1609087581580-d921a3a46ec9?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1609087581580-d921a3a46ec9?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Modern table tennis club with 12 tables, professional lighting, and membership programs.',
        amenities: [
          '12 Tables',
          'Professional Lighting',
          'Membership Available',
          'Refreshments',
          'Wi-Fi'
        ],
        tableTypes: ['Table Tennis'],
        rating: 4.5,
        reviewCount: 134,
        isOpen: false,
        availabilitySlots: {
          'Tomorrow': ['9:00 AM', '11:00 AM', '1:00 PM', '3:00 PM', '5:00 PM'],
          'Day After': [
            '8:00 AM',
            '10:00 AM',
            '12:00 PM',
            '2:00 PM',
            '4:00 PM',
            '6:00 PM'
          ],
        },
      ),
      // Darts Venues
      Venue(
        id: '13',
        name: 'Bulls Eye Sports Bar',
        address: '258 Dart Lane, Lower East Side',
        city: 'New York',
        latitude: 40.7144,
        longitude: -73.9857,
        distanceInKm: 1.3,
        pricePerHour: 15.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1541692641319-981cc79ee10e?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1574391884720-bbc13a7b6b04?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1541692641319-981cc79ee10e?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Traditional sports bar with 8 professional dart boards, craft beers, and weekly tournaments.',
        amenities: [
          '8 Dart Boards',
          'Craft Beer',
          'Weekly Tournaments',
          'Sports TV',
          'Bar Food'
        ],
        tableTypes: ['Darts'],
        rating: 4.3,
        reviewCount: 187,
        isOpen: true,
        availabilitySlots: {
          'Today': ['12:00 PM', '2:00 PM', '4:00 PM', '6:00 PM', '8:00 PM'],
          'Tomorrow': [
            '11:00 AM',
            '1:00 PM',
            '3:00 PM',
            '5:00 PM',
            '7:00 PM',
            '9:00 PM'
          ],
        },
      ),
      Venue(
        id: '14',
        name: 'Precision Darts Club',
        address: '369 Target St, Midtown East',
        city: 'New York',
        latitude: 40.7505,
        longitude: -73.9734,
        distanceInKm: 1.7,
        pricePerHour: 22.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1574391884720-bbc13a7b6b04?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1541692641319-981cc79ee10e?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1574391884720-bbc13a7b6b04?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Premium darts facility with electronic dart boards, professional setup, and competitive leagues.',
        amenities: [
          'Electronic Boards',
          'Professional Setup',
          'Competitive Leagues',
          'Lounge Area',
          'Equipment Sales'
        ],
        tableTypes: ['Darts'],
        rating: 4.7,
        reviewCount: 98,
        isOpen: true,
        availabilitySlots: {
          'Today': ['1:00 PM', '3:00 PM', '5:00 PM', '7:00 PM'],
          'Tomorrow': [
            '10:00 AM',
            '12:00 PM',
            '2:00 PM',
            '4:00 PM',
            '6:00 PM',
            '8:00 PM'
          ],
        },
      ),
      Venue(
        id: '3',
        name: 'Rack & Roll Billiards',
        address: '789 Broadway, East Village',
        city: 'New York',
        latitude: 40.7320,
        longitude: -73.9874,
        distanceInKm: 0.5,
        pricePerHour: 18.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1565937166894-7b9f07c357ce?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1509316785289-025f5b846b35?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1588539543889-4909fd7d8f7e?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1565937166894-7b9f07c357ce?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Casual, friendly billiards hall with affordable rates and weekly tournaments for players of all skill levels.',
        amenities: ['Snack Bar', 'Weekly Tournaments', 'Lessons Available'],
        tableTypes: ['Pool', 'Billiards'],
        rating: 4.2,
        reviewCount: 74,
        isOpen: true,
        availabilitySlots: {
          'Today': [
            '11:00 AM',
            '12:00 PM',
            '1:00 PM',
            '4:00 PM',
            '5:00 PM',
            '6:00 PM'
          ],
          'Tomorrow': [
            '12:00 PM',
            '2:00 PM',
            '3:00 PM',
            '4:00 PM',
            '7:00 PM',
            '9:00 PM'
          ],
        },
      ),
      Venue(
        id: '4',
        name: 'The Corner Pocket',
        address: '101 Greene St, SoHo',
        city: 'New York',
        latitude: 40.7248,
        longitude: -74.0018,
        distanceInKm: 1.7,
        pricePerHour: 22.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1606050059532-304983fa97b2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1565937166894-7b9f07c357ce?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1588539543889-4909fd7d8f7e?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1606050059532-304983fa97b2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Trendy SoHo spot with vintage pool tables and stylish decor. Popular with young professionals and billiards enthusiasts.',
        amenities: ['Full Bar', 'DJ Nights', 'Private Events'],
        tableTypes: ['Pool', 'American', 'English'],
        rating: 4.4,
        reviewCount: 105,
        isOpen: false,
        availabilitySlots: {
          'Tomorrow': [
            '11:00 AM',
            '12:00 PM',
            '2:00 PM',
            '4:00 PM',
            '6:00 PM',
            '8:00 PM'
          ],
          'Day After': [
            '10:00 AM',
            '1:00 PM',
            '3:00 PM',
            '5:00 PM',
            '7:00 PM',
            '9:00 PM'
          ],
        },
      ),
      Venue(
        id: '5',
        name: 'Shark\'s Billiards Academy',
        address: '222 7th Ave, Chelsea',
        city: 'New York',
        latitude: 40.7436,
        longitude: -73.9957,
        distanceInKm: 0.9,
        pricePerHour: 30.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1609181743786-e1b6dd523200?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1606050059532-304983fa97b2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1565937166894-7b9f07c357ce?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1609181743786-e1b6dd523200?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Professional billiards academy with certified instructors and competition-grade tables. Offers lessons for all skill levels.',
        amenities: [
          'Professional Instruction',
          'Equipment Store',
          'Practice Areas'
        ],
        tableTypes: ['Pool', 'Snooker', 'Carom', 'Russian Pyramid'],
        rating: 4.9,
        reviewCount: 156,
        isOpen: true,
        availabilitySlots: {
          'Today': ['9:00 AM', '10:00 AM', '1:00 PM', '2:00 PM', '5:00 PM'],
          'Tomorrow': [
            '9:00 AM',
            '11:00 AM',
            '1:00 PM',
            '3:00 PM',
            '4:00 PM',
            '6:00 PM'
          ],
        },
      ),
      Venue(
        id: '6',
        name: 'Classic Billiards Hall',
        address: '333 W 14th St, Meatpacking District',
        city: 'Los Angeles',
        latitude: 40.7397,
        longitude: -74.0067,
        distanceInKm: 2.1,
        pricePerHour: 20.0,
        imageUrls: [
          'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1609181743786-e1b6dd523200?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
          'https://images.unsplash.com/photo-1606050059532-304983fa97b2?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        ],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?ixlib=rb-1.2.1&auto=format&fit=crop&w=1350&q=80',
        description:
            'Old-school billiards hall with classic atmosphere and reasonable rates. Family-friendly environment with tables for all ages.',
        amenities: ['Family Friendly', 'Arcade Games', 'Snack Bar'],
        tableTypes: ['Pool', 'Billiards'],
        rating: 4.0,
        reviewCount: 82,
        isOpen: true,
        availabilitySlots: {
          'Today': [
            '12:00 PM',
            '1:00 PM',
            '3:00 PM',
            '4:00 PM',
            '7:00 PM',
            '8:00 PM'
          ],
          'Tomorrow': [
            '11:00 AM',
            '1:00 PM',
            '2:00 PM',
            '5:00 PM',
            '6:00 PM',
            '7:00 PM'
          ],
        },
      ),
    ];
  }

  // Get a venue by ID
  Venue? getVenueById(String id) {
    try {
      return getMockVenues().firstWhere((venue) => venue.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filter venues by city
  List<Venue> getVenuesByCity(String city) {
    if (city.isEmpty) return getMockVenues();
    return getMockVenues()
        .where((venue) => venue.city.toLowerCase() == city.toLowerCase())
        .toList();
  }

  // Filter venues by table type
  List<Venue> getVenuesByTableType(String tableType) {
    if (tableType.isEmpty) return getMockVenues();
    return getMockVenues()
        .where((venue) => venue.tableTypes.contains(tableType))
        .toList();
  }

  // Filter venues by price range
  List<Venue> getVenuesByPriceRange(double minPrice, double maxPrice) {
    return getMockVenues()
        .where((venue) =>
            venue.pricePerHour >= minPrice && venue.pricePerHour <= maxPrice)
        .toList();
  }

  // Combined filter for venues
  List<Venue> filterVenues({
    String city = '',
    String tableType = '',
    double minPrice = 0.0,
    double maxPrice = 100.0,
    bool? showOpenOnly,
    String searchTerm = '',
  }) {
    return getMockVenues().where((venue) {
      bool matchesCity =
          city.isEmpty || venue.city.toLowerCase() == city.toLowerCase();
      bool matchesTableType =
          tableType.isEmpty || venue.tableTypes.contains(tableType);
      bool matchesPriceRange =
          venue.pricePerHour >= minPrice && venue.pricePerHour <= maxPrice;
      bool matchesOpenStatus =
          showOpenOnly == null || venue.isOpen == showOpenOnly;
      bool matchesSearchTerm = searchTerm.isEmpty ||
          venue.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
          venue.description.toLowerCase().contains(searchTerm.toLowerCase()) ||
          venue.address.toLowerCase().contains(searchTerm.toLowerCase());

      return matchesCity &&
          matchesTableType &&
          matchesPriceRange &&
          matchesOpenStatus &&
          matchesSearchTerm;
    }).toList();
  }
}

// Provider for the venue service
final venueServiceProvider = Provider<VenueService>((ref) => VenueService());

// Provider for the list of venues
final venuesProvider = Provider<List<Venue>>((ref) {
  final venueService = ref.watch(venueServiceProvider);
  return venueService.getMockVenues();
});

// Provider for a single venue by id - using FutureProvider to return AsyncValue
final venueByIdProvider =
    FutureProvider.family<Venue?, String>((ref, id) async {
  final venueService = ref.watch(venueServiceProvider);
  return venueService.getVenueById(id);
});

// Provider for venue search term
final venueSearchProvider = StateProvider<String>((ref) => '');

// Provider for user's current location
final userLocationProvider = FutureProvider<Position>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services are disabled');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permissions are permanently denied');
  }

  return await Geolocator.getCurrentPosition();
});

// Provider for nearby venues (within 10km radius)
final nearbyVenuesProvider = FutureProvider<List<Venue>>((ref) async {
  final venueService = ref.watch(venueServiceProvider);
  final locationAsync = ref.watch(userLocationProvider);

  return locationAsync.when(
    data: (location) {
      final allVenues = venueService.getMockVenues();

      // Calculate distance for each venue and sort by proximity
      final venuesWithDistance = allVenues.map((venue) {
        final distance = Geolocator.distanceBetween(
          location.latitude,
          location.longitude,
          venue.latitude,
          venue.longitude,
        );
        return {
          'venue': venue,
          'distance': distance,
        };
      }).toList();

      // Sort by distance
      venuesWithDistance.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      // Return nearest 5 venues
      return venuesWithDistance
          .take(5)
          .map((e) => e['venue'] as Venue)
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// State for venue filters
class VenueFilters {
  final String city;
  final String tableType;
  final double minPrice;
  final double maxPrice;
  final bool? showOpenOnly;
  final String searchTerm;

  VenueFilters({
    this.city = '',
    this.tableType = '',
    this.minPrice = 0.0,
    this.maxPrice = 100.0,
    this.showOpenOnly,
    this.searchTerm = '',
  });

  VenueFilters copyWith({
    String? city,
    String? tableType,
    double? minPrice,
    double? maxPrice,
    bool? showOpenOnly,
    String? searchTerm,
  }) {
    return VenueFilters(
      city: city ?? this.city,
      tableType: tableType ?? this.tableType,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      showOpenOnly: showOpenOnly,
      searchTerm: searchTerm ?? this.searchTerm,
    );
  }
}

// Provider for venue filters state
final venueFiltersProvider =
    StateProvider<VenueFilters>((ref) => VenueFilters());

// Provider for filtered venues
final filteredVenuesProvider = Provider<List<Venue>>((ref) {
  final filters = ref.watch(venueFiltersProvider);
  final venueService = ref.watch(venueServiceProvider);

  return venueService.filterVenues(
    city: filters.city,
    tableType: filters.tableType,
    minPrice: filters.minPrice,
    maxPrice: filters.maxPrice,
    showOpenOnly: filters.showOpenOnly,
    searchTerm: filters.searchTerm,
  );
});
