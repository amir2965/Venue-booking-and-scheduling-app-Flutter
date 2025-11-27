import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A class to hold all matchmaking filter options
class MatchmakingFilters {
  final RangeValues ageRange;
  final double maxDistance;
  final List<String> gameTypes;
  final List<String> playModes;
  final bool onlineOnly;

  const MatchmakingFilters({
    this.ageRange = const RangeValues(18, 65),
    this.maxDistance = 50,
    this.gameTypes = const [],
    this.playModes = const [],
    this.onlineOnly = false,
  });

  MatchmakingFilters copyWith({
    RangeValues? ageRange,
    double? maxDistance,
    List<String>? gameTypes,
    List<String>? playModes,
    bool? onlineOnly,
  }) {
    return MatchmakingFilters(
      ageRange: ageRange ?? this.ageRange,
      maxDistance: maxDistance ?? this.maxDistance,
      gameTypes: gameTypes ?? this.gameTypes,
      playModes: playModes ?? this.playModes,
      onlineOnly: onlineOnly ?? this.onlineOnly,
    );
  }

  bool get hasFilters {
    return ageRange.start > 18 ||
        ageRange.end < 65 ||
        maxDistance < 50 ||
        gameTypes.isNotEmpty ||
        playModes.isNotEmpty ||
        onlineOnly;
  }
}

class MatchmakingFiltersNotifier extends StateNotifier<MatchmakingFilters> {
  MatchmakingFiltersNotifier() : super(const MatchmakingFilters());

  void updateFilters(MatchmakingFilters newFilters) {
    state = newFilters;
  }

  void resetFilters() {
    state = const MatchmakingFilters();
  }

  void updateAgeRange(RangeValues range) {
    state = state.copyWith(ageRange: range);
  }

  void updateMaxDistance(double distance) {
    state = state.copyWith(maxDistance: distance);
  }

  void updateGameTypes(List<String> gameTypes) {
    state = state.copyWith(gameTypes: gameTypes);
  }

  void updatePlayModes(List<String> playModes) {
    state = state.copyWith(playModes: playModes);
  }

  void updateOnlineOnly(bool onlineOnly) {
    state = state.copyWith(onlineOnly: onlineOnly);
  }
}

// Provider for matchmaking filters
final matchmakingFiltersProvider =
    StateNotifierProvider<MatchmakingFiltersNotifier, MatchmakingFilters>(
        (ref) {
  return MatchmakingFiltersNotifier();
});
