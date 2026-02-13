import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/mobile_app_bar.dart';
import '../../core/theme/app_colors.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  final List<Map<String, dynamic>> _automations = [
    {
      'id': '1',
      'name': 'Good Morning',
      'description': 'Turn on lights and open blinds at 7:00 AM',
      'icon': Icons.wb_sunny,
      'isActive': true,
      'time': '7:00 AM',
      'days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    },
    {
      'id': '2',
      'name': 'Good Night',
      'description': 'Turn off all lights and lock doors at 11:00 PM',
      'icon': Icons.nightlight,
      'isActive': true,
      'time': '11:00 PM',
      'days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    },
    {
      'id': '3',
      'name': 'Away Mode',
      'description': 'Turn off lights and enable security when leaving',
      'icon': Icons.directions_walk,
      'isActive': false,
      'trigger': 'Location',
    },
    {
      'id': '4',
      'name': 'Movie Time',
      'description': 'Dim lights and close blinds when TV turns on',
      'icon': Icons.tv,
      'isActive': false,
      'trigger': 'Device',
    },
  ];

  void _toggleAutomation(String id) {
    setState(() {
      final automationIndex =
          _automations.indexWhere((auto) => auto['id'] == id);
      if (automationIndex != -1) {
        _automations[automationIndex]['isActive'] =
            !_automations[automationIndex]['isActive'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MobileAppBar(
        title: 'Automation',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/automation/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick stats
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Smart Automations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_automations.where((a) => a['isActive']).length} active',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.54),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Automation list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _automations.length,
              itemBuilder: (context, index) {
                final automation = _automations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: automation['isActive']
                                    ? const Color(0xFF1E7F5C).withOpacity(0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                automation['icon'],
                                size: 24,
                                color: automation['isActive']
                                    ? const Color(0xFF1E7F5C)
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    automation['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    automation['description'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: automation['isActive'],
                              onChanged: (value) =>
                                  _toggleAutomation(automation['id']),
                              activeTrackColor: const Color(0xFF1E7F5C),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Schedule info
                        if (automation['time'] != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                automation['time'],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 16),
                              ...automation['days']
                                  .map<Widget>((day) => Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E7F5C)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            day,
                                            style: const TextStyle(
                                              color: Color(0xFF1E7F5C),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ],
                          ),
                        ] else if (automation['trigger'] != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.sensors,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Trigger: ${automation['trigger']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                // TODO: Edit automation
                              },
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: Color(0xFF1E7F5C),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Delete automation
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/automation/create'),
        backgroundColor: const Color(0xFF1E7F5C),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}
