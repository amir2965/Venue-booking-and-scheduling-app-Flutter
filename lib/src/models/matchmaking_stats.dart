class MatchmakingStats {
  final int totalLikes;
  final int totalMatches;
  final int totalPasses;
  final double matchRate;
  final int totalActions;

  const MatchmakingStats({
    required this.totalLikes,
    required this.totalMatches,
    required this.totalPasses,
    required this.matchRate,
    required this.totalActions,
  });

  factory MatchmakingStats.fromJson(Map<String, dynamic> json) {
    return MatchmakingStats(
      totalLikes: json['totalLikes'] ?? 0,
      totalMatches: json['totalMatches'] ?? 0,
      totalPasses: json['totalPasses'] ?? 0,
      matchRate: (json['matchRate'] ?? 0.0).toDouble(),
      totalActions: json['totalActions'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLikes': totalLikes,
      'totalMatches': totalMatches,
      'totalPasses': totalPasses,
      'matchRate': matchRate,
      'totalActions': totalActions,
    };
  }

  @override
  String toString() {
    return 'MatchmakingStats(totalLikes: $totalLikes, totalMatches: $totalMatches, totalPasses: $totalPasses, matchRate: $matchRate%, totalActions: $totalActions)';
  }
}
