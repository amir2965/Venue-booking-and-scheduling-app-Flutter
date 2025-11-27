import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VenueBottomNavigation extends StatelessWidget {
  final String currentRoute;

  const VenueBottomNavigation({
    Key? key,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _VenueBottomNavItem(
              icon: Icons.explore,
              label: 'Explore',
              isActive: currentRoute == '/venues' ||
                  currentRoute.startsWith('/venues'),
              onTap: () => context.go('/venues'),
            ),
            _VenueBottomNavItem(
              icon: Icons.favorite_border,
              label: 'Wishlist',
              isActive: currentRoute == '/venues/wishlist',
              onTap: () => context.go('/venues/wishlist'),
            ),
            _VenueBottomNavItem(
              icon: Icons.chat_bubble_outline,
              label: 'Messages',
              isActive: currentRoute == '/venues/messages',
              onTap: () => context.go('/venues/messages'),
            ),
            _VenueBottomNavItem(
              icon: Icons.sports_tennis,
              label: 'Plays',
              isActive: currentRoute == '/venues/plays',
              onTap: () => context.go('/venues/plays'),
            ),
            _VenueBottomNavItem(
              icon: Icons.person,
              label: 'Profile',
              isActive: currentRoute == '/profile',
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _VenueBottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? const Color(0xFF28A745) : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? const Color(0xFF28A745) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
