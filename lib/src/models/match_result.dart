class MatchResult {
  final bool success;
  final String action;
  final bool isMatch;
  final String message;

  const MatchResult({
    required this.success,
    required this.action,
    required this.isMatch,
    required this.message,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      success: json['success'] ?? false,
      action: json['action'] ?? '',
      isMatch: json['isMatch'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'action': action,
      'isMatch': isMatch,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'MatchResult(success: $success, action: $action, isMatch: $isMatch, message: $message)';
  }
}
