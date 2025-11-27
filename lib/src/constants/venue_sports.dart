class VenueSports {
  // All activities organized by main category
  static const List<String> allSports = [
    // Games & Sports
    'Bowling',
    'Billiards',
    'Snooker',
    'Table Tennis',
    'Darts',
    'Mini Golf',
    'Shuffleboard',
    'Foosball',
    'Air Hockey',
    // Adventure & Action
    'Trampoline',
    'Climbing',
    'Laser Tag',
    'Paintball',
    'Ninja Warrior',
    'Archery Tag',
    'VR Arena',
    // Escape & Mystery
    'Escape Rooms',
    'Horror Experiences',
    'Puzzle Rooms',
    // Social & Fun
    'Karaoke',
    'Private Cinema',
    'Board Games',
    'Console Gaming',
    'PC Gaming',
    'LAN Parties',
    'Music Jam',
    'Dance Studio',
  ];

  // Activity-specific icons for UI
  static const Map<String, String> sportIcons = {
    // Games & Sports
    'Bowling': '🎳',
    'Billiards': '🎱',
    'Snooker': '🔴',
    'Table Tennis': '🏓',
    'Darts': '🎯',
    'Mini Golf': '⛳',
    'Shuffleboard': '🏒',
    'Foosball': '⚽',
    'Air Hockey': '🏑',
    // Adventure & Action
    'Trampoline': '🤸',
    'Climbing': '🧗',
    'Laser Tag': '🔫',
    'Paintball': '🎨',
    'Ninja Warrior': '🥷',
    'Archery Tag': '🏹',
    'VR Arena': '🥽',
    // Escape & Mystery
    'Escape Rooms': '🔐',
    'Horror Experiences': '👻',
    'Puzzle Rooms': '🧩',
    // Social & Fun
    'Karaoke': '🎤',
    'Private Cinema': '🎬',
    'Board Games': '🎲',
    'Console Gaming': '🎮',
    'PC Gaming': '💻',
    'LAN Parties': '🖥️',
    'Music Jam': '🎸',
    'Dance Studio': '💃',
  };

  // Main category definitions with enhanced metadata
  static const Map<String, Map<String, dynamic>> mainCategories = {
    'Games & Sports': {
      'icon': '🎯',
      'color': 0xFF2196F3, // Blue
      'gradient': [0xFF1976D2, 0xFF2196F3],
      'description': 'Classic indoor games and recreational sports',
      'activities': [
        'Bowling',
        'Billiards',
        'Snooker',
        'Table Tennis',
        'Darts',
        'Mini Golf',
        'Shuffleboard',
        'Foosball',
        'Air Hockey',
      ],
    },
    'Adventure & Action': {
      'icon': '🚀',
      'color': 0xFFFF5722, // Deep Orange
      'gradient': [0xFFE64A19, 0xFFFF5722],
      'description': 'High-energy activities and physical challenges',
      'activities': [
        'Trampoline',
        'Climbing',
        'Laser Tag',
        'Paintball',
        'Ninja Warrior',
        'Archery Tag',
        'VR Arena',
      ],
    },
    'Escape & Mystery': {
      'icon': '🔮',
      'color': 0xFF9C27B0, // Purple
      'gradient': [0xFF7B1FA2, 0xFF9C27B0],
      'description': 'Mind-bending puzzles and thrilling experiences',
      'activities': [
        'Escape Rooms',
        'Horror Experiences',
        'Puzzle Rooms',
      ],
    },
    'Social & Fun': {
      'icon': '🎉',
      'color': 0xFFFF9800, // Orange
      'gradient': [0xFFF57C00, 0xFFFF9800],
      'description': 'Entertainment spaces for groups and parties',
      'activities': [
        'Karaoke',
        'Private Cinema',
        'Board Games',
        'Console Gaming',
        'PC Gaming',
        'LAN Parties',
        'Music Jam',
        'Dance Studio',
      ],
    },
  };

  // Sport categories for better organization (legacy support)
  static const Map<String, List<String>> sportCategories = {
    'Games & Sports': [
      'Bowling',
      'Billiards',
      'Snooker',
      'Table Tennis',
      'Darts',
      'Mini Golf',
      'Shuffleboard',
      'Foosball',
      'Air Hockey',
    ],
    'Adventure & Action': [
      'Trampoline',
      'Climbing',
      'Laser Tag',
      'Paintball',
      'Ninja Warrior',
      'Archery Tag',
      'VR Arena',
    ],
    'Escape & Mystery': [
      'Escape Rooms',
      'Horror Experiences',
      'Puzzle Rooms',
    ],
    'Social & Fun': [
      'Karaoke',
      'Private Cinema',
      'Board Games',
      'Console Gaming',
      'PC Gaming',
      'LAN Parties',
      'Music Jam',
      'Dance Studio',
    ],
  };

  // Venue types associated with each activity
  static const Map<String, List<String>> venueTypes = {
    // Games & Sports
    'Bowling': ['Bowling Alley', 'Recreation Center', 'Sports Complex'],
    'Billiards': ['Pool Hall', 'Sports Bar', 'Recreation Center'],
    'Snooker': ['Snooker Club', 'Sports Center', 'Gentleman\'s Club'],
    'Table Tennis': ['Recreation Center', 'Community Center', 'Sports Club'],
    'Darts': ['Pub', 'Sports Bar', 'Club', 'Recreation Center'],
    'Mini Golf': [
      'Mini Golf Course',
      'Family Entertainment Center',
      'Amusement Park'
    ],
    'Shuffleboard': ['Recreation Center', 'Community Center', 'Bar'],
    'Foosball': ['Game Room', 'Bar', 'Recreation Center'],
    'Air Hockey': [
      'Arcade',
      'Family Entertainment Center',
      'Recreation Center'
    ],
    // Adventure & Action
    'Trampoline': [
      'Trampoline Park',
      'Indoor Adventure Park',
      'Fitness Center'
    ],
    'Climbing': ['Climbing Gym', 'Bouldering Center', 'Adventure Park'],
    'Laser Tag': ['Laser Tag Arena', 'Entertainment Center', 'Gaming Complex'],
    'Paintball': ['Paintball Arena', 'Outdoor Complex', 'Adventure Park'],
    'Ninja Warrior': ['Ninja Warrior Gym', 'Obstacle Course', 'Fitness Center'],
    'Archery Tag': ['Archery Arena', 'Sports Complex', 'Adventure Park'],
    'VR Arena': ['VR Gaming Center', 'Tech Hub', 'Entertainment Complex'],
    // Escape & Mystery
    'Escape Rooms': [
      'Escape Room Venue',
      'Entertainment Center',
      'Mystery Experience'
    ],
    'Horror Experiences': [
      'Horror House',
      'Haunted Attraction',
      'Immersive Theater'
    ],
    'Puzzle Rooms': ['Puzzle Center', 'Brain Games Venue', 'Mystery Room'],
    // Social & Fun
    'Karaoke': [
      'Karaoke Lounge',
      'Private Karaoke Rooms',
      'Entertainment Center'
    ],
    'Private Cinema': [
      'Private Theater',
      'Cinema Rooms',
      'Entertainment Complex'
    ],
    'Board Games': ['Board Game Café', 'Game Lounge', 'Hobby Center'],
    'Console Gaming': ['Gaming Lounge', 'Console Café', 'Entertainment Center'],
    'PC Gaming': ['PC Bang', 'Gaming Café', 'Esports Center'],
    'LAN Parties': ['LAN Center', 'Gaming Arena', 'Esports Venue'],
    'Music Jam': ['Music Studio', 'Rehearsal Space', 'Jam Room'],
    'Dance Studio': ['Dance Studio', 'Fitness Center', 'Performance Space'],
  };

  // Skill levels that apply to all activities
  static const List<String> skillLevels = [
    'Beginner',
    'Novice',
    'Intermediate',
    'Advanced',
    'Expert',
    'Professional'
  ];

  // Play styles for different activities
  static const List<String> playStyles = [
    'Casual',
    'Competitive',
    'Training',
    'Tournament',
    'Social',
    'Party',
    'Team Building',
  ];

  // Helper methods
  static String getSportEmoji(String sport) {
    return sportIcons[sport] ?? '🏆';
  }

  static List<String> getVenueTypes(String sport) {
    return venueTypes[sport] ?? ['Entertainment Venue'];
  }

  static String? getCategoryForActivity(String activity) {
    for (var entry in mainCategories.entries) {
      final activities = entry.value['activities'] as List<String>;
      if (activities.contains(activity)) {
        return entry.key;
      }
    }
    return null;
  }

  static Map<String, dynamic>? getCategoryMetadata(String categoryName) {
    return mainCategories[categoryName];
  }

  static List<String> getActivitiesForCategory(String categoryName) {
    final category = mainCategories[categoryName];
    return category != null ? List<String>.from(category['activities']) : [];
  }
}
