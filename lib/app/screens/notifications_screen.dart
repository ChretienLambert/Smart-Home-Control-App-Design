import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'Front Door Unlocked',
      'message': 'The front door was unlocked at 3:45 PM',
      'time': '5 min ago',
      'type': 'security',
      'isRead': false,
      'icon': Icons.lock_open,
    },
    {
      'id': '2',
      'title': 'Motion Detected',
      'message': 'Motion detected in the backyard',
      'time': '15 min ago',
      'type': 'security',
      'isRead': false,
      'icon': Icons.motion_photos_on,
    },
    {
      'id': '3',
      'title': 'Device Offline',
      'message': 'Hallway light is offline',
      'time': '1 hour ago',
      'type': 'device',
      'isRead': true,
      'icon': Icons.device_unknown,
    },
    {
      'id': '4',
      'title': 'Automation Completed',
      'message': 'Good Night routine completed successfully',
      'time': '2 hours ago',
      'type': 'automation',
      'isRead': true,
      'icon': Icons.auto_awesome,
    },
    {
      'id': '5',
      'title': 'High Energy Usage',
      'message': 'Energy usage is 20% higher than usual',
      'time': '3 hours ago',
      'type': 'energy',
      'isRead': true,
      'icon': Icons.bolt,
    },
    {
      'id': '6',
      'title': 'Low Battery',
      'message': 'Security camera battery is at 15%',
      'time': '5 hours ago',
      'type': 'device',
      'isRead': true,
      'icon': Icons.battery_alert,
    },
  ];

  void _markAsRead(String id) {
    setState(() {
      final notificationIndex = _notifications.indexWhere((n) => n['id'] == id);
      if (notificationIndex != -1) {
        _notifications[notificationIndex]['isRead'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
  }

  void _clearNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == id);
    });
  }

  void _clearAll() {
    setState(() {
      _notifications.clear();
    });
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'security':
        return Colors.red;
      case 'device':
        return Colors.orange;
      case 'automation':
        return const Color(0xFF1E7F5C);
      case 'energy':
        return const Color(0xFFFFC857);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E7F5C),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Color(0xFF1E7F5C),
                  fontSize: 14,
                ),
              ),
            ),
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text(
                'Clear all',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Notification stats
          if (_notifications.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E7F5C),
                    Color(0xFF4ECDC4),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$unreadCount unread',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Notifications list
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      final isRead = notification['isRead'] as bool;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isRead
                            ? null
                            : const Color(0xFF1E7F5C).withOpacity(0.05),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getTypeColor(notification['type'])
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              notification['icon'],
                              color: _getTypeColor(notification['type']),
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title'],
                                  style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E7F5C),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                notification['message'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification['time'],
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _markAsRead(notification['id']),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete') {
                                _clearNotification(notification['id']);
                              } else if (value == 'mark_read') {
                                _markAsRead(notification['id']);
                              }
                            },
                            itemBuilder: (context) => [
                              if (!isRead)
                                const PopupMenuItem(
                                  value: 'mark_read',
                                  child: Text('Mark as read'),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 80), // Space for bottom nav
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}
