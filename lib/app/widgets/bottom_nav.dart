import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;

  const BottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {
        'path': '/dashboard',
        'icon': Icons.home,
        'label': 'Home',
      },
      {
        'path': '/devices',
        'icon': Icons.devices,
        'label': 'Devices',
      },
      {
        'path': '/automation',
        'icon': Icons.bolt,
        'label': 'Automation',
      },
      {
        'path': '/notifications',
        'icon': Icons.notifications,
        'label': 'Alerts',
      },
      {
        'path': '/profile',
        'icon': Icons.person,
        'label': 'Profile',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => context.go(item['path'] as String),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      Icon(
                        item['icon'] as IconData,
                        size: 24,
                        color: isActive
                            ? const Color(0xFF1E7F5C)
                            : Colors.grey[600],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive
                              ? const Color(0xFF1E7F5C)
                              : Colors.grey[600],
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
