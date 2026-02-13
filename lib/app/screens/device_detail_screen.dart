import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/mobile_app_bar.dart';
import '../../core/theme/app_colors.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  bool _isOn = true;
  double _brightness = 0.7;
  String _selectedSchedule = 'None';

  final Map<String, dynamic> _deviceData = {
    '1': {
      'name': 'Living Room Light',
      'icon': Icons.lightbulb,
      'status': 'active',
      'room': 'Living Room',
      'type': 'Smart Light',
      'brand': 'Philips Hue',
      'model': 'White and Color Ambiance',
      'powerConsumption': '9W',
    },
  };

  late Map<String, dynamic> _device;

  @override
  void initState() {
    super.initState();
    _device = _deviceData[widget.deviceId] ?? _deviceData['1'] ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MobileAppBar(
        title: _device['name'] ?? 'Unknown Device',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit device
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _device['icon'],
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _device['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _device['room'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _device['status'] == 'active'
                              ? const Color(0xFFFFC857)
                              : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _device['status'] == 'active' ? 'Active' : 'Online',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Power control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Power Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Device Power',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Switch(
                          value: _isOn,
                          onChanged: (value) {
                            setState(() {
                              _isOn = value;
                            });
                          },
                          activeThumbColor: const Color(0xFF1E7F5C),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Brightness control (for lights)
            if (_device['icon'] == Icons.lightbulb) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Brightness',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: _brightness,
                        onChanged: (value) {
                          setState(() {
                            _brightness = value;
                          });
                        },
                        activeColor: const Color(0xFF1E7F5C),
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(_brightness * 100).round()}%',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Device information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Device Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Type', _device['type']),
                    _buildInfoRow('Brand', _device['brand']),
                    _buildInfoRow('Model', _device['model']),
                    _buildInfoRow(
                        'Power Consumption', _device['powerConsumption']),
                    _buildInfoRow('Status', _device['status']),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Schedule
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Current Schedule',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedSchedule,
                          onChanged: (value) {
                            setState(() {
                              _selectedSchedule = value!;
                            });
                          },
                          items: ['None', 'Sunset On', 'Sunrise Off', 'Custom']
                              .map((schedule) => DropdownMenuItem(
                                    value: schedule,
                                    child: Text(schedule),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Save changes
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Device settings saved'),
              backgroundColor: Color(0xFF1E7F5C),
            ),
          );
        },
        backgroundColor: const Color(0xFF1E7F5C),
        icon: const Icon(Icons.save),
        label: const Text('Save Changes'),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete ${_device['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Device deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
