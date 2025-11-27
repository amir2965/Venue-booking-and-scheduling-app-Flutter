class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.createdAt,
  });

  // Create a copy of this User with the given fields replaced
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert User to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'emailVerified': emailVerified,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Create User from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id']?.toString();
      final email = json['email']?.toString();

      if (id == null || id.isEmpty) {
        throw ArgumentError('User ID is required and cannot be null or empty');
      }

      // Allow profiles without email for certain types (like chat test users)
      // But convert null/undefined email to empty string for consistency
      final validEmail = email ?? '';

      return User(
        id: id,
        email: validEmail,
        displayName: json['displayName']?.toString(),
        photoUrl: json['photoUrl']?.toString(),
        emailVerified: json['emailVerified'] ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
      );
    } catch (e) {
      print('❌ Error parsing User from JSON: $e');
      print('📄 User JSON: $json');
      rethrow;
    }
  }
  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, photoUrl: $photoUrl, emailVerified: $emailVerified, createdAt: $createdAt)';
  }
}
