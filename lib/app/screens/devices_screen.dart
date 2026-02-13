import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/device_card.dart';
import '../widgets/bottom_nav.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Lights', 'Security', 'Climate', 'Entertainment'];
  
  final List<Map<String, dynamic>> _allDevices = [
    {
      'id': '1',
      'name': 'Living Room Light',
      'icon': Icons.lightbulb,
      'status': 'active',
      'isOn': true,
      'category': 'Lights',
      'room': 'Living Room',
    },
    {
      'id': '2',
      'name': 'Bedroom Fan',
      'icon': Icons.air,
      'status': 'online',
      'isOn': false,
      'category': 'Climate',
      'room': 'Bedroom',
    },
    {
      'id': '3',
      'name': 'Front Door Lock',
      'icon': Icons.lock,
      'status': 'online',
      'isOn': true,
      'category': 'Security',
      'room': 'Entrance',
    },
    {
      'id': '4',
      'name': 'Security Camera',
      'icon': Icons.videocam,
      'status': 'active',
      'isOn': true,
      'category': 'Security',
      'room': 'Front Yard',
    },
    {
      'id': '5',
      'name': 'Kitchen Light',
      'icon': Icons.lightbulb,
      'status': 'online',
      'isOn': false,
      'category': 'Lights',
      'room': 'Kitchen',
    },
    {
      'id': '6',
      'name': 'Hallway Light',
      'icon': Icons.lightbulb,
      'status': 'offline',
      'isOn': false,
      'category': 'Lights',
      'room': 'Hallway',
    },
    {
      'id': '7',
      'name': 'Smart TV',
      'icon': Icons.tv,
      'status': 'online',
      'isOn': false,
      'category': 'Entertainment',
      'room': 'Living Room',
    },
    {
      'id': '8',
      'name': 'Thermostat',
      'icon': Icons.thermostat,
      'status': 'active',
      'isOn': true,
      'category': 'Climate',
      'room': 'Living Room',
    },
  ];

  List<Map<String, dynamic>> get _filteredDevices {
    if (_selectedCategory == 'All') {
      return _allDevices;
    }
    return _allDevices.where((device) => device['category'] == _selectedCategory).toList();
  }

  void _toggleDevice(String id) {
    setState(() {
      final deviceIndex = _allDevices.indexWhere((device) => device['id'] == id);
      if (deviceIndex != -1) {
        _allDevices[deviceIndex]['isOn'] = !_allDevices[deviceIndex]['isOn'];
      }
    });
  }

  void _handleDeviceClick(String id) {
    context.go('/devices/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E7F5C),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: const Color(0xFF1E7F5C).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? const Color(0xFF1E7F5C) : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF1E7F5C) : Colors.grey[300]!,
                    ),
                  ),
                );
              },
            ),
          ),

          // Device count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  '${_filteredDevices.length} devices',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement filter/sort
                  },
                  icon: const Icon(Icons.filter_list, size: 16),
                  label: const Text('Filter'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E7F5C),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Device grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _filteredDevices.length,
                itemBuilder: (context, index) {
                  final device = _filteredDevices[index];
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
            ),
          ),

          const SizedBox(height: 80), // Space for bottom nav
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-device'),
        backgroundColor: const Color(0xFF1E7F5C),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}
