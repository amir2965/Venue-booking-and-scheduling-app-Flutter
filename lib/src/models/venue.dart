class Venue {
  final String id;
  final String name;
  final String address;
  final String city;
  final List<String> imageUrls;
  final String thumbnailUrl;
  final String description;
  final List<String> amenities;
  final List<String> tableTypes;
  final double pricePerHour;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final Map<String, List<String>> availabilitySlots;
  final double latitude;
  final double longitude;
  final double distanceInKm;
  final int maxPlayers;
  final String hostName;
  final String? hostImageUrl;
  final int hostYearsOfHosting;
  final List<String> features;

  Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.imageUrls,
    required this.thumbnailUrl,
    required this.description,
    required this.amenities,
    required this.tableTypes,
    required this.pricePerHour,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    required this.availabilitySlots,
    required this.latitude,
    required this.longitude,
    this.distanceInKm = 0.0,
    this.maxPlayers = 8,
    this.hostName = 'Host',
    this.hostImageUrl,
    this.hostYearsOfHosting = 2,
    this.features = const [],
  });

  // Create a skeleton venue for loading states
  factory Venue.skeleton() {
    return Venue(
      id: 'skeleton',
      name: 'Loading...',
      address: 'Loading...',
      city: 'Loading...',
      imageUrls: [''],
      thumbnailUrl: '',
      description: 'Loading...',
      amenities: ['Loading...'],
      tableTypes: ['Loading...'],
      pricePerHour: 0,
      rating: 0,
      reviewCount: 0,
      isOpen: false,
      availabilitySlots: {},
      latitude: 0,
      longitude: 0,
      maxPlayers: 8,
      hostName: 'Host',
      hostImageUrl: null,
      hostYearsOfHosting: 2,
      features: ['Loading...'],
    );
  }

  // Convert Venue to a Map<String, dynamic> for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'imageUrls': imageUrls,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'amenities': amenities,
      'tableTypes': tableTypes,
      'pricePerHour': pricePerHour,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOpen': isOpen,
      'availabilitySlots':
          availabilitySlots.map((key, value) => MapEntry(key, value)),
      'latitude': latitude,
      'longitude': longitude,
      'distanceInKm': distanceInKm,
      'maxPlayers': maxPlayers,
      'hostName': hostName,
      'hostImageUrl': hostImageUrl,
      'hostYearsOfHosting': hostYearsOfHosting,
      'features': features,
    };
  }

  // Create a Venue from a Map<String, dynamic> from Firestore
  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      thumbnailUrl: json['thumbnailUrl'] as String,
      description: json['description'] as String,
      amenities: List<String>.from(json['amenities'] ?? []),
      tableTypes: List<String>.from(json['tableTypes'] ?? []),
      pricePerHour: (json['pricePerHour'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      isOpen: json['isOpen'] as bool,
      availabilitySlots: _convertAvailabilitySlots(json['availabilitySlots']),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceInKm: json['distanceInKm'] != null
          ? (json['distanceInKm'] as num).toDouble()
          : 0.0,
      maxPlayers: json['maxPlayers'] as int? ?? 8,
      hostName: json['hostName'] as String? ?? 'Host',
      hostImageUrl: json['hostImageUrl'] as String?,
      hostYearsOfHosting: json['hostYearsOfHosting'] as int? ?? 2,
      features: List<String>.from(json['features'] ?? []),
    );
  }

  // Helper method to convert availability slots from Firestore
  static Map<String, List<String>> _convertAvailabilitySlots(
      dynamic slotsData) {
    final Map<String, List<String>> result = {};

    if (slotsData != null && slotsData is Map) {
      slotsData.forEach((key, value) {
        if (value is List) {
          result[key.toString()] = List<String>.from(value);
        }
      });
    }

    return result;
  }
}
