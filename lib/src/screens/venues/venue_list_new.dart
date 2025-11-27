import 'package:flutter/material.dart';
import 'venue_explore_screen.dart';

// Updated VenueListScreen that redirects to the new Explore-style screen
class VenueListScreen extends StatelessWidget {
  const VenueListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VenueExploreScreen();
  }
}
