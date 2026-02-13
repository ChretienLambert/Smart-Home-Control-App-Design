import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/mobile_app_bar.dart';
import '../widgets/device_card.dart';
import '../widgets/bottom_nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/logger_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final bool _isOnline = true;

  final List<Map<String, dynamic>> _devices = [
    {
      'id': '1',
      'name': 'Living Room',
      'icon': Icons.lightbulb,
      'status': 'active',
      'isOn': true,
    },
    {
      'id': '2',
      'name': 'Bedroom Fan',
      'icon': Icons.air,
      'status': 'online',
      'isOn': false,
    },
    {
      'id': '3',
      'name': 'Front Door',
      'icon': Icons.lock,
      'status': 'online',
      'isOn': true,
    },
    {
      'id': '4',
      'name': 'Security Cam',
      'icon': Icons.videocam,
      'status': 'active',
      'isOn': true,
    },
    {
      'id': '5',
      'name': 'Kitchen Light',
      'icon': Icons.lightbulb,
      'status': 'online',
      'isOn': false,
    },
    {
      'id': '6',
      'name': 'Hallway',
      'icon': Icons.lightbulb,
      'status': 'offline',
      'isOn': false,
    },
  ];

  void _toggleDevice(String id) {
    setState(() {
      final deviceIndex = _devices.indexWhere((device) => device['id'] == id);
      if (deviceIndex != -1) {
        _devices[deviceIndex]['isOn'] = !_devices[deviceIndex]['isOn'];
      }
    });
  }

  void _handleDeviceClick(String id) {
    context.go('/devices/$id');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().userName;

    return Scaffold(
      appBar: MobileAppBar(
        title: 'Smart Home',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.meeting_room, color: Colors.red),
            onPressed: _triggerBadDoorEvent,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isOnline ? Icons.wifi : Icons.wifi_off,
                              size: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOnline ? 'Cloud Connected' : 'Local Mode',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => context.go('/notifications'),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Stack(
                            children: [
                              Icon(
                                Icons.security,
                                color: Colors.white,
                                size: 20,
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: CircleAvatar(
                                  radius: 3,
                                  backgroundColor: Color(0xFFFFC857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${_getGreeting()}, $userName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your home is secure and running smoothly',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Home Status Summary
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Home Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatusItem(
                                  Icons.thermostat,
                                  'Temperature',
                                  '24°C',
                                  const Color(0xFF1E7F5C),
                                ),
                              ),
                              Expanded(
                                child: _buildStatusItem(
                                  Icons.water_drop,
                                  'Humidity',
                                  '65%',
                                  const Color(0xFF1E7F5C),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatusItem(
                                  Icons.bolt,
                                  'Power',
                                  '2.4 kW',
                                  const Color(0xFFFFC857),
                                ),
                              ),
                              Expanded(
                                child: _buildStatusItem(
                                  Icons.security,
                                  'Security',
                                  'Active',
                                  const Color(0xFF1E7F5C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // My Devices Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Devices',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/devices'),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFF1E7F5C),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Device Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return DeviceCard(
                          id: device['id'],
                          name: device['name'],
                          icon: device['icon'],
                          status: device['status'],
                          isOn: device['isOn'],
                          onToggle: _toggleDevice,
                          onClick: _handleDeviceClick,
                        );
                      },
                    ),

                    const SizedBox(height: 100), // Space for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-device'),
        backgroundColor: const Color(0xFF1E7F5C),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }

  Widget _buildStatusItem(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _triggerBadDoorEvent() {
    logger.logSecurityEvent('BAD_DOOR_TRIGGERED', details: {
      'source': 'dashboard_test_button',
      'timestamp': DateTime.now().toIso8601String(),
      'severity': 'test',
      'description': 'Bad door event triggered for testing purposes',
    });

    // Show a snackbar to indicate the event was triggered
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Text('⚠️ Bad Door Event Triggered (Testing)'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View Logs',
          textColor: Colors.white,
          onPressed: () {
            _showLogsDialog();
          },
        ),
      ),
    );
  }

  void _showLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recent Security Events'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<LogEntry>>(
            stream: logger.logsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final logs = snapshot.data!
                  .where((log) =>
                      log.level == LogLevel.warning ||
                      log.level == LogLevel.error)
                  .take(10)
                  .toList();

              if (logs.isEmpty) {
                return const Center(child: Text('No security events found.'));
              }

              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      leading: Icon(
                        Icons.warning,
                        color: _getLogLevelColor(log.level),
                      ),
                      title: Text(log.message),
                      subtitle:
                          Text(log.timestamp.toString().substring(11, 19)),
                      dense: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              logger.clearLogs();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs cleared')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.critical:
        return Colors.purple;
    }
  }
}
