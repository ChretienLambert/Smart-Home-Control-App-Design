// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/mobile_app_bar.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roomController = TextEditingController();
  String _selectedType = 'Light';
  String _selectedBrand = 'Philips';
  String _connectionMethod = 'wifi';
  bool _isLoading = false;

  final List<String> _deviceTypes = [
    'Light',
    'Switch',
    'Thermostat',
    'Camera',
    'Lock',
    'Sensor',
    'Fan',
    'TV',
  ];

  final List<String> _brands = [
    'Philips',
    'TP-Link',
    'Nest',
    'Ring',
    'August',
    'Ecobee',
    'Arlo',
    'Samsung',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _addDevice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate adding device - in real app, this would call an API
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device added successfully'),
            backgroundColor: Color(0xFF1E7F5C),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add device: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case 'Light':
        return Icons.lightbulb;
      case 'Switch':
        return Icons.toggle_on;
      case 'Thermostat':
        return Icons.thermostat;
      case 'Camera':
        return Icons.videocam;
      case 'Lock':
        return Icons.lock;
      case 'Sensor':
        return Icons.sensors;
      case 'Fan':
        return Icons.air;
      case 'TV':
        return Icons.tv;
      default:
        return Icons.device_unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MobileAppBar(
        title: 'Add Device',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device type selection
              const Text(
                'Device Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _deviceTypes.length,
                  itemBuilder: (context, index) {
                    final type = _deviceTypes[index];
                    final isSelected = type == _selectedType;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                        });
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1E7F5C)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getDeviceIcon(type),
                              size: 32,
                              color: isSelected
                                  ? const Color(0xFF1E7F5C)
                                  : Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              type,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF1E7F5C)
                                    : Colors.grey[600],
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Device name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Device Name',
                  hintText: 'e.g., Living Room Light',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E7F5C)),
                  ),
                ),
                validator: (initialValue) {
                  if (initialValue == null || initialValue.isEmpty) {
                    return 'Please enter a device name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Room
              TextFormField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Room',
                  hintText: 'e.g., Living Room',
                  prefixIcon: const Icon(Icons.room),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E7F5C)),
                  ),
                ),
                validator: (initialValue) {
                  if (initialValue == null || initialValue.isEmpty) {
                    return 'Please enter a room';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Brand selection
              DropdownButtonFormField<String>(
                initialValue: _selectedBrand,
                decoration: InputDecoration(
                  labelText: 'Brand',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E7F5C)),
                  ),
                ),
                items: _brands.map((brand) {
                  return DropdownMenuItem(
                    value: brand,
                    child: Text(brand),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBrand = value!;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Connection method
              const Text(
                'Connection Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: RadioListTile<String>(
                  title: const Text('Wi-Fi'),
                  subtitle: const Text('Connect via your home network'),
                  value: 'wifi',
                  groupValue: _connectionMethod,
                  onChanged: (value) {
                    setState(() {
                      _connectionMethod = value!;
                    });
                  },
                  activeColor: const Color(0xFF1E7F5C),
                ),
              ),

              Card(
                child: RadioListTile<String>(
                  title: const Text('Bluetooth'),
                  subtitle: const Text('Connect via Bluetooth'),
                  value: 'bluetooth',
                  groupValue: _connectionMethod,
                  onChanged: (value) {
                    setState(() {
                      _connectionMethod = value!;
                    });
                  },
                  activeColor: const Color(0xFF1E7F5C),
                ),
              ),

              const SizedBox(height: 32),

              // Add device button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E7F5C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Add Device',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
