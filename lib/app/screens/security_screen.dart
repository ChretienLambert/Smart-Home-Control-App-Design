import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _securityArmed = true;
  bool _camerasActive = true;
  bool _motionDetection = true;
  bool _doorSensors = true;
  bool _windowSensors = true;

  final List<Map<String, dynamic>> _securityEvents = [
    {
      'id': '1',
      'type': 'motion',
      'title': 'Motion Detected',
      'message': 'Backyard camera detected motion',
      'time': '2 min ago',
      'severity': 'low',
    },
    {
      'id': '2',
      'type': 'door',
      'title': 'Door Opened',
      'message': 'Front door opened',
      'time': '15 min ago',
      'severity': 'info',
    },
    {
      'id': '3',
      'type': 'alarm',
      'title': 'System Armed',
      'message': 'Security system armed in away mode',
      'time': '1 hour ago',
      'severity': 'success',
    },
  ];

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return const Color(0xFFFFC857);
      case 'info':
        return Colors.blue;
      case 'success':
        return const Color(0xFF1E7F5C);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E7F5C),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Security history
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: _securityArmed
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1E7F5C),
                          Color(0xFF4ECDC4),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[400]!,
                          Colors.grey[600]!,
                        ],
                      ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _securityArmed
                            ? Icons.security
                            : Icons.security_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Security System',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _securityArmed ? 'Armed' : 'Disarmed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _securityArmed
                        ? 'All sensors active'
                        : 'System is disabled',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _securityArmed = !_securityArmed;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _securityArmed
                            ? const Color(0xFF1E7F5C)
                            : Colors.grey[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _securityArmed ? 'Disarm System' : 'Arm System',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Security components
            const Text(
              'Security Components',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Cameras'),
                    subtitle: const Text('Monitor all security cameras'),
                    secondary: Icon(
                      Icons.videocam,
                      color: _camerasActive
                          ? const Color(0xFF1E7F5C)
                          : Colors.grey,
                    ),
                    value: _camerasActive,
                    onChanged: (value) {
                      setState(() {
                        _camerasActive = value;
                      });
                    },
                    activeColor: const Color(0xFF1E7F5C),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Motion Detection'),
                    subtitle: const Text('Detect motion in monitored areas'),
                    secondary: Icon(
                      Icons.motion_photos_on,
                      color: _motionDetection
                          ? const Color(0xFF1E7F5C)
                          : Colors.grey,
                    ),
                    value: _motionDetection,
                    onChanged: (value) {
                      setState(() {
                        _motionDetection = value;
                      });
                    },
                    activeColor: const Color(0xFF1E7F5C),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Door Sensors'),
                    subtitle: const Text('Monitor door openings'),
                    secondary: Icon(
                      Icons.door_front_door,
                      color:
                          _doorSensors ? const Color(0xFF1E7F5C) : Colors.grey,
                    ),
                    value: _doorSensors,
                    onChanged: (value) {
                      setState(() {
                        _doorSensors = value;
                      });
                    },
                    activeColor: const Color(0xFF1E7F5C),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Window Sensors'),
                    subtitle: const Text('Monitor window openings'),
                    secondary: Icon(
                      Icons.window,
                      color: _windowSensors
                          ? const Color(0xFF1E7F5C)
                          : Colors.grey,
                    ),
                    value: _windowSensors,
                    onChanged: (value) {
                      setState(() {
                        _windowSensors = value;
                      });
                    },
                    activeColor: const Color(0xFF1E7F5C),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent security events
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Events',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: View all events
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFF1E7F5C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ..._securityEvents.map((event) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getSeverityColor(event['severity'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getEventIcon(event['type']),
                          color: _getSeverityColor(event['severity']),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              event['message'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        event['time'],
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 4),
    );
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'motion':
        return Icons.motion_photos_on;
      case 'door':
        return Icons.door_front_door;
      case 'window':
        return Icons.window;
      case 'alarm':
        return Icons.alarm;
      default:
        return Icons.info;
    }
  }
}
