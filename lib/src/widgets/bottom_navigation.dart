import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavigation extends StatelessWidget {
  final String currentRoute;

  const AppBottomNavigation({
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
            _BottomNavItem(
              icon: Icons.explore,
              label: 'Discover',
              isActive: currentRoute == '/matchmaking',
              onTap: () => context.go('/matchmaking'),
            ),
            _BottomNavItem(
              icon: Icons.favorite,
              label: 'Matches',
              isActive: currentRoute == '/matches',
              onTap: () => context.go('/matches'),
            ),
            _BottomNavItem(
              icon: Icons.chat_bubble_outline,
              label: 'Messages',
              isActive: currentRoute == '/chats',
              onTap: () => context.go('/chats'),
            ),
            _BottomNavItem(
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

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
                fontSize: 12,
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
