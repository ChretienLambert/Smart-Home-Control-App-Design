import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/bloc/device_bloc.dart';
import '../../core/config/smart_home_hardware.dart';
import '../../core/models/device.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/hardware_ui_utils.dart';
import '../../core/services/mqtt_service.dart';
import '../providers/auth_provider.dart';
import '../providers/hardware_controller_provider.dart';
import '../widgets/adaptive_scaffold.dart';
import '../widgets/controller_access_dialog.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AdaptiveScaffold(
      title: '${auth.homeName} Devices',
      currentIndex: 1,
      actions: [
        IconButton(
          onPressed: () => context.go('/add-device'),
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Add Device',
        ),
      ],
      body: BlocBuilder<DeviceBloc, DeviceState>(
        builder: (context, state) {
          if (state is DeviceLoading || state is DeviceInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DeviceError) {
            return Center(child: Text(state.message));
          }

          final ownedDeviceIds = {...?auth.currentUser?.deviceIds};
          final allDevices = state is DeviceLoaded
              ? _sortDevices(
                  ownedDeviceIds.isEmpty
                      ? state.devices
                      : state.devices
                          .where((device) => ownedDeviceIds.contains(device.id))
                          .toList(),
                )
              : <Device>[];
          final displayDevices =
              allDevices.where(SmartHomeHardware.isArduinoWired).toList();
          final devices = _applyFilter(displayDevices);
          final controlDevices =
              devices.where(SmartHomeHardware.isControllable).toList();
          final sensorDevices =
              devices.where(SmartHomeHardware.isSensor).toList();
          final activeDevices =
              controlDevices.where((device) => device.isOn).length;
          final sensorCount = sensorDevices.length;
          final categories = <String>{
            'All',
            ...displayDevices.map(hardwareCategoryForDevice),
          }.toList();

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E6B63), Color(0xFF18A08F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hardware Components',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Live mode shows only devices wired in the Arduino sketch.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _statChip('Total', '${displayDevices.length}'),
                        _statChip('Controls', '${controlDevices.length}'),
                        _statChip('Sensors', '$sensorCount'),
                        _statChip('Active', '$activeDevices'),
                        _hardwareActionBtn(
                          icon: Icons.sync_rounded,
                          label: 'SYNC',
                          onTap: () => MQTTService().submitPin(SmartHomeHardware.pinCode),
                        ),
                        _hardwareActionBtn(
                          icon: Icons.power_settings_new_rounded,
                          label: 'RELEASE PORT',
                          color: Colors.red.shade300,
                          onTap: () {
                             MQTTService().disconnect(autoReconnect: false);
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(content: Text('Serial port released. You can now upload code in Arduino IDE.')),
                             );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final selected = category == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: AppColors.cyanoBlue,
                        labelStyle: TextStyle(
                          color:
                              selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: BlocBuilder<DeviceBloc, DeviceState>(
                  buildWhen: (previous, current) {
                    return current is DeviceLoaded;
                  },
                  builder: (context, state) {
                    if (state is DeviceLoading || state is DeviceInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is DeviceError) {
                      return Center(child: Text(state.message));
                    }

                    final ownedDeviceIds = {...?auth.currentUser?.deviceIds};
                    final allDevices = state is DeviceLoaded
                        ? _sortDevices(
                            ownedDeviceIds.isEmpty
                                ? state.devices
                                : state.devices
                                    .where((device) =>
                                        ownedDeviceIds.contains(device.id))
                                    .toList(),
                          )
                        : <Device>[];
                    final displayDevices = allDevices
                        .where(SmartHomeHardware.isArduinoWired)
                        .toList();
                    final devices = _applyFilter(displayDevices);

                    if (devices.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.devices_other_outlined, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'No Arduino-wired devices match your filter.',
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: () => context.go('/add-device'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Device'),
                            ),
                          ],
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            context,
                            title: 'Controllable outputs',
                            subtitle:
                                'Lamp, switch, fan, and door lock use keypad commands and toggle controls.',
                          ),
                          const SizedBox(height: 14),
                          _deviceWrap(
                            context,
                            devices
                                .where(SmartHomeHardware.isControllable)
                                .toList(),
                            homeId: auth.homeId,
                            isSensor: false,
                          ),
                          const SizedBox(height: 28),
                          _sectionHeader(
                            context,
                            title: 'Live sensors',
                            subtitle:
                                'Temperature, humidity, light, motion, and flame cards update from the hardware stream.',
                          ),
                          const SizedBox(height: 14),
                          _deviceWrap(
                            context,
                            devices.where(SmartHomeHardware.isSensor).toList(),
                            homeId: auth.homeId,
                            isSensor: true,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Device> _applyFilter(List<Device> devices) {
    if (_selectedCategory == 'All') {
      return devices;
    }

    return devices
        .where(
          (device) => hardwareCategoryForDevice(device) == _selectedCategory,
        )
        .toList();
  }

  List<Device> _sortDevices(List<Device> devices) {
    final sorted = [...devices];
    sorted.sort((a, b) {
      final aOrder = (a.properties?['sortOrder'] as num?)?.toInt() ?? 999;
      final bOrder = (b.properties?['sortOrder'] as num?)?.toInt() ?? 999;
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  Widget _hardwareActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: (color ?? Colors.white).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _deviceWrap(
    BuildContext context,
    List<Device> devices, {
    required String homeId,
    required bool isSensor,
  }) {
    if (devices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          isSensor
              ? 'No sensor cards match the current filter.'
              : 'No controllable devices match the current filter.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width - 40;
    final cardWidth = screenWidth > 1200
        ? (screenWidth - 32) / 3
        : screenWidth > 800
            ? (screenWidth - 16) / 2
            : screenWidth;

    final constrainedWidth = cardWidth < 280
        ? 280.0
        : cardWidth > 420
            ? 420.0
            : cardWidth;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        for (final device in devices)
          SizedBox(
            width: constrainedWidth,
            child: isSensor
                ? _SensorHardwareCard(device: device)
                : _ControlHardwareCard(device: device, homeId: homeId),
          ),
      ],
    );
  }
}

class _ControlHardwareCard extends StatelessWidget {
  final Device device;
  final String homeId;

  const _ControlHardwareCard({
    required this.device,
    required this.homeId,
  });

  @override
  Widget build(BuildContext context) {
    final hardware = context.watch<HardwareControllerProvider>();
    final color = hardwareColorForDevice(device);
    final isLock = device.type == DeviceType.doorLock;
    final onCommand = device.properties?['onCommand'] as String?;
    final offCommand = device.properties?['offCommand'] as String?;
    final routingLabel = (onCommand != null && offCommand != null)
        ? '$onCommand/$offCommand'
        : 'Bluetooth direct';
    final canWireControl = SmartHomeHardware.isArduinoWired(device);

    final hardwareId = device.id.contains('_') ? device.id.split('_').last : device.id;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => context.go('/devices/${device.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 280),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      hardwareIconForDevice(device),
                      color: color,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      hardwareStatusText(device),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                device.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                SmartHomeHardware.roomLabel(device).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: 0.8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                device.properties?['description'] as String? ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _smallTag('ID: $hardwareId'),
                  _smallTag('Pin: ${device.properties?['pin'] ?? 'N/A'}'),
                  _smallTag('Ch: ${device.properties?['channel'] ?? 'N/A'}'),
                  _smallTag('Cmd: $routingLabel'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLock
                              ? (device.isOn ? 'Unlocked' : 'Locked')
                              : (device.isOn ? 'On' : 'Off'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          isLock
                              ? 'Keypad 9 / 0'
                              : 'Keypad $onCommand / $offCommand',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: device.isOn,
                    activeThumbColor: color,
                    onChanged: !canWireControl
                        ? null
                        : (value) {
                            if (!hardware.canControl) {
                              showControllerAccessDialog(context);
                              return;
                            }
                            hardware.sendDeviceCommand(
                              device,
                              value,
                              homeId: homeId,
                            );
                          },
                  ),
                ],
              ),
              if (!canWireControl) ...[
                const SizedBox(height: 10),
                const Text(
                  'App only: not wired to the Arduino sketch.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SensorHardwareCard extends StatelessWidget {
  final Device device;

  const _SensorHardwareCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final color = hardwareSensorColor(device);
    final reading = hardwareSensorReading(device);
    final isMotion = device.type == DeviceType.motionSensor;
    final liveLabel = isMotion
        ? (device.isOn ? 'ACTIVE' : 'CLEAR')
        : (device.type == DeviceType.smokeDetector
            ? ((device.properties?['detected'] as bool? ?? false)
                ? 'ALERT'
                : 'CLEAR')
            : 'LIVE');

    final hardwareId = device.id.contains('_') ? device.id.split('_').last : device.id;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => context.go('/devices/${device.id}'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 280),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      hardwareIconForDevice(device),
                      color: color,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      liveLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                device.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                SmartHomeHardware.roomLabel(device).toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: 0.8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                device.properties?['description'] as String? ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                reading,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _smallTag('ID: $hardwareId'),
                  _smallTag('Pin: ${device.properties?['pin'] ?? 'N/A'}'),
                  _smallTag('Ch: ${device.properties?['channel'] ?? 'N/A'}'),
                  _smallTag(SmartHomeHardware.roomLabel(device)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _relativeTime(device.lastUpdated),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _smallTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Updated ${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }
}
