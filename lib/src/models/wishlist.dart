class Wishlist {
  final String id;
  final String name;
  final String userId;
  final List<String> venueIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wishlist({
    required this.id,
    required this.name,
    required this.userId,
    required this.venueIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      userId: json['userId'] ?? '',
      venueIds: List<String>.from(json['venueIds'] ?? []),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userId': userId,
      'venueIds': venueIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Wishlist copyWith({
    String? id,
    String? name,
    String? userId,
    List<String>? venueIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wishlist(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      venueIds: venueIds ?? this.venueIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
