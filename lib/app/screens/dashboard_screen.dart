import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/bloc/device_bloc.dart';
import '../../core/config/smart_home_hardware.dart';
import '../../core/services/app_service.dart';
import '../../core/services/mqtt_service.dart';
import '../../core/services/logger_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/hardware_ui_utils.dart';
import '../../core/models/device.dart';
import '../providers/auth_provider.dart';
import '../providers/hardware_controller_provider.dart';
import '../widgets/adaptive_scaffold.dart';

// ─── Room ordering helpers ────────────────────────────────────────────────────

const _kRoomOrder = ['Bedroom', 'Living Room', 'Entrance'];

int _roomSortIndex(String name) {
  final i = _kRoomOrder.indexOf(name);
  return i == -1 ? 999 : i;
}

Map<String, List<Device>> _groupByRoom(List<Device> devices) {
  final map = <String, List<Device>>{};
  for (final device in devices) {
    final room = SmartHomeHardware.roomLabel(device);
    map.putIfAbsent(room, () => []).add(device);
  }
  return map;
}

List<MapEntry<String, List<Device>>> _sortedRoomEntries(
    Map<String, List<Device>> map) {
  final entries = map.entries.toList();
  entries.sort((a, b) {
    final ai = _roomSortIndex(a.key);
    final bi = _roomSortIndex(b.key);
    if (ai != bi) return ai.compareTo(bi);
    return a.key.compareTo(b.key);
  });
  return entries;
}

// ─── Dashboard Screen ─────────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AdaptiveScaffold(
      title: auth.homeName,
      currentIndex: 0,
      actions: [
        IconButton(
          onPressed: () => MQTTService().requestStateSync(),
          icon: const Icon(Icons.sync_rounded),
          tooltip: 'Sync Hardware',
        ),
        IconButton(
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Alerts',
        ),
        IconButton(
          onPressed: () => showBluetoothDialog(context),
          icon: const Icon(Icons.usb_rounded),
          tooltip: 'Hardware Settings',
        ),
      ],
      body: _DashboardBody(auth: auth),
    );
  }

  Future<void> showBluetoothDialog(BuildContext context) async {
    final appService = AppService();
    final config = await appService.getBluetoothConfiguration();
    final mqttService = MQTTService();
    final availablePorts = mqttService.listAvailablePorts();
    if (!context.mounted) return;

    final portController = TextEditingController(
      text: config.portName.isNotEmpty
          ? config.portName
          : (mqttService.preferredPortName() ??
              SmartHomeHardware.defaultBluetoothPort),
    );
    final baudRateController =
        TextEditingController(text: '${config.baudRate}');
    final deviceHintController = TextEditingController(text: config.deviceHint);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Hardware Connection Settings'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Serial Communication',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: portController,
                        decoration: const InputDecoration(
                          labelText: 'Serial Port',
                          hintText: 'e.g. COM3 or /dev/ttyUSB0',
                          prefixIcon: Icon(Icons.usb_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: baudRateController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Baud Rate',
                          hintText: '9600',
                          prefixIcon: Icon(Icons.speed_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: deviceHintController,
                        decoration: const InputDecoration(
                          labelText: 'Device Name Hint',
                          hintText: 'Arduino Uno',
                          prefixIcon: Icon(Icons.label_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Available Ports',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      if (availablePorts.isEmpty)
                        const Text('No serial ports detected.',
                            style: TextStyle(color: AppColors.textSecondary))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availablePorts.map((port) {
                            final isSelected =
                                portController.text.trim() == port.name;
                            return ChoiceChip(
                              selected: isSelected,
                              label: Text(port.name),
                              onSelected: (_) {
                                setDialogState(() {
                                  portController.text = port.name;
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final baudRate =
                        int.tryParse(baudRateController.text.trim()) ?? 9600;
                    await appService.updateBluetoothConfiguration(
                      portName: portController.text.trim(),
                      baudRate: baudRate,
                      deviceHint: deviceHintController.text.trim(),
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Save & Connect'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final AuthProvider auth;
  const _DashboardBody({required this.auth});

  @override
  Widget build(BuildContext context) {
    final hardware = context.watch<HardwareControllerProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        if (!hardware.isHardwareVerified || !hardware.isTransportConnected)
          _LiveModeConnectionCard(auth: auth),
        if (!hardware.isHardwareVerified || !hardware.isTransportConnected)
          const SizedBox(height: 20),
        _DashboardHero(auth: auth),
        const SizedBox(height: 24),
        const SectionTitle(
          title: 'Live Hardware LCD',
          subtitle: 'Real-time status display from the Arduino controller.',
        ),
        const SizedBox(height: 14),
        const _LcdScreensGrid(),
        const SizedBox(height: 28),
        const SectionTitle(
          title: 'Environmental Overview',
          subtitle: 'Live readings from DHT11 and LDR sensors.',
        ),
        const SizedBox(height: 14),
        const _QuickStatsGrid(),
        const SizedBox(height: 28),
        const SectionTitle(
          title: 'Active Rooms',
          subtitle: 'Overview of devices wired to the Arduino sketch.',
        ),
        const SizedBox(height: 14),
        _RoomsOverview(auth: auth),
        const SizedBox(height: 28),
        const SectionTitle(
          title: 'System Activity',
          subtitle: 'Hardware traffic and automation status.',
        ),
        const SizedBox(height: 14),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _BluetoothTrafficCard()),
            SizedBox(width: 16),
            Expanded(flex: 2, child: _ActiveAutomationsCard()),
          ],
        ),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final AuthProvider auth;
  const _DashboardHero({required this.auth});

  @override
  Widget build(BuildContext context) {
    final isVerified = context
        .select<HardwareControllerProvider, bool>((h) => h.isHardwareVerified);
    final statusMsg = context
        .select<HardwareControllerProvider, String>((h) => h.statusMessage);
    final autoModeLabel = context
        .select<HardwareControllerProvider, String>((h) => h.autoModeLabel);
    final canControl =
        context.select<HardwareControllerProvider, bool>((h) => h.canControl);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              const Text(
                'Control Center',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'VERIFIED',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusMsg,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          BlocBuilder<DeviceBloc, DeviceState>(
            builder: (context, state) {
              if (state is! DeviceLoaded) return const SizedBox();

              final displayDevices = state.devices
                  .where(SmartHomeHardware.isArduinoWired)
                  .toList();
              final activeCount = displayDevices
                  .where((d) => SmartHomeHardware.isControllable(d) && d.isOn)
                  .length;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _statChip('Active Devices', '$activeCount'),
                  _statChip('Hardware Wired', '${displayDevices.length}'),
                  _hardwareActionBtn(
                    icon: Icons.sync_rounded,
                    label: 'SYNC STATE',
                    onTap: () => MQTTService().requestStateSync(),
                  ),
                  _hardwareActionBtn(
                    icon: autoModeLabel == 'AUTO'
                        ? Icons.toggle_on_rounded
                        : Icons.toggle_off_rounded,
                    label: autoModeLabel == 'AUTO'
                        ? 'AUTO MODE ON'
                        : (autoModeLabel == 'MANUAL'
                            ? 'AUTO MODE OFF'
                            : 'AUTO MODE'),
                    onTap: canControl
                        ? () => context
                            .read<HardwareControllerProvider>()
                            .toggleAutoMode(homeId: auth.homeId)
                        : () {},
                  ),
                ],
              );
            },
          ),
        ],
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

  Widget _hardwareActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
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
              const SizedBox(width: 8),
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
}

class _LcdScreensGrid extends StatelessWidget {
  const _LcdScreensGrid();
  @override
  Widget build(BuildContext context) {
    final screens =
        context.select<HardwareControllerProvider, List<HardwareLcdScreen>>(
            (h) => h.lcdScreens);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : (constraints.maxWidth > 800 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: screens.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) =>
              _LcdMiniScreen(screen: screens[index]),
        );
      },
    );
  }
}

class _LcdMiniScreen extends StatelessWidget {
  final HardwareLcdScreen screen;
  const _LcdMiniScreen({required this.screen});

  @override
  Widget build(BuildContext context) {
    final metrics = _screenMetrics(screen);
    final accent = _accentForScreen(screen.title);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF081B1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2C5C57), width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.display_settings_rounded,
                  color: Color(0xFF9DE2D7), size: 14),
              const SizedBox(width: 6),
              Text(
                screen.title,
                style: const TextStyle(
                  color: Color(0xFF9DE2D7),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metrics
                .map((metric) => _MetricChip(
                      label: metric.label,
                      value: metric.value,
                      color: accent,
                    ))
                .toList(),
          ),
          const Spacer(),
          _lcdRow(screen.line1),
          const SizedBox(height: 8),
          _lcdRow(screen.line2),
        ],
      ),
    );
  }

  Widget _lcdRow(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE9FFF9),
          fontFamily: 'monospace',
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  List<_ScreenMetric> _screenMetrics(HardwareLcdScreen screen) {
    switch (screen.title) {
      case 'Device Status':
        return [
          _ScreenMetric('Lamp', _valueAfter(screen.line1, 'Lamp')),
          _ScreenMetric('Fan', _valueAfter(screen.line1, 'Fan')),
          _ScreenMetric('Door', _valueAfter(screen.line2, 'Door')),
          _ScreenMetric('Auto', _valueAfter(screen.line2, 'Auto')),
        ];
      case 'Environment':
        return [
          _ScreenMetric('Temp', _valueAfter(screen.line1, 'Temp')),
          _ScreenMetric('Humidity', _valueAfter(screen.line1, 'Hum')),
          _ScreenMetric('Light', _valueAfter(screen.line2, 'Light')),
          _ScreenMetric('Label', screen.line2.split('|').last.trim()),
        ];
      case 'Security':
        return [
          _ScreenMetric('Motion', _valueAfter(screen.line1, 'Motion')),
          _ScreenMetric('Flame', _valueAfter(screen.line1, 'Flame')),
          _ScreenMetric('Door', _valueAfter(screen.line2, 'Door')),
          _ScreenMetric('Buzzer', _valueAfter(screen.line2, 'Bzr')),
        ];
      case 'System Info':
        return [
          _ScreenMetric('Mode', _valueAfter(screen.line1, 'Mode')),
          _ScreenMetric('Uptime', _valueAfter(screen.line2, 'Up')),
          _ScreenMetric('Auto key', 'A'),
          _ScreenMetric('Status', 'Live'),
        ];
      default:
        return const [];
    }
  }

  String _valueAfter(String text, String key) {
    final regex = RegExp('$key\\s+([^|]+)');
    final match = regex.firstMatch(text);
    if (match == null) return '--';
    return match.group(1)!.trim();
  }

  Color _accentForScreen(String title) {
    switch (title) {
      case 'Environment':
        return const Color(0xFF4EB3FF);
      case 'Security':
        return const Color(0xFFFF9A3D);
      case 'System Info':
        return const Color(0xFF9DE2D7);
      default:
        return const Color(0xFF7DE0C8);
    }
  }
}

class _ScreenMetric {
  final String label;
  final String value;

  const _ScreenMetric(this.label, this.value);
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.92),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE9FFF9),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspectRatio = constraints.maxWidth > 800 ? 1.6 : 1.2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          children: [
            _LcdValueTile(
              icon: Icons.thermostat_rounded,
              label: 'Temperature',
              screenIndex: 1,
              line: 1,
              color: Colors.orange,
              extractor: (text) =>
                  _matchNumber(text, r'Temp\s+([0-9]+)') ?? '--',
            ),
            _LcdValueTile(
              icon: Icons.water_drop_rounded,
              label: 'Humidity',
              screenIndex: 1,
              line: 1,
              color: Colors.blue,
              extractor: (text) {
                final value = _matchNumber(text, r'Hum\s+([0-9]+)');
                return value == null ? '--%' : '$value%';
              },
            ),
            _LcdValueTile(
              icon: Icons.light_mode_rounded,
              label: 'Light Level',
              screenIndex: 1,
              line: 2,
              color: Colors.amber,
              extractor: (text) =>
                  _matchNumber(text, r'Light\s+([0-9]+)') ?? '--',
            ),
          ],
        );
      },
    );
  }
}

String? _matchNumber(String text, String pattern) {
  final match = RegExp(pattern).firstMatch(text);
  return match?.group(1);
}

class _LcdValueTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int screenIndex;
  final int line;
  final Color color;
  final String Function(String) extractor;

  const _LcdValueTile({
    required this.icon,
    required this.label,
    required this.screenIndex,
    required this.line,
    required this.color,
    required this.extractor,
  });

  @override
  Widget build(BuildContext context) {
    final value = context.select<HardwareControllerProvider, String>((h) {
      if (h.lcdScreens.length <= screenIndex) return '--';
      final text = line == 1
          ? h.lcdScreens[screenIndex].line1
          : h.lcdScreens[screenIndex].line2;
      try {
        return extractor(text);
      } catch (_) {
        return '--';
      }
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RoomsOverview extends StatelessWidget {
  final AuthProvider auth;
  const _RoomsOverview({required this.auth});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceBloc, DeviceState>(
      builder: (context, state) {
        if (state is! DeviceLoaded) return const SizedBox();

        final displayDevices =
            state.devices.where(SmartHomeHardware.isArduinoWired).toList();
        final roomEntries = _sortedRoomEntries(_groupByRoom(displayDevices));

        return Column(
          children: roomEntries
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _RoomSummaryCard(
                      roomName: entry.key,
                      devices: entry.value,
                      homeId: auth.homeId,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _RoomSummaryCard extends StatelessWidget {
  final String roomName;
  final List<Device> devices;
  final String homeId;

  const _RoomSummaryCard({
    required this.roomName,
    required this.devices,
    required this.homeId,
  });

  @override
  Widget build(BuildContext context) {
    final canControl =
        context.select<HardwareControllerProvider, bool>((h) => h.canControl);
    final activeCount = devices
        .where((d) => SmartHomeHardware.isControllable(d) && d.isOn)
        .length;

    return PaneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                roomName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '$activeCount/${devices.where(SmartHomeHardware.isControllable).length} active',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...devices
              .where(SmartHomeHardware.isControllable)
              .map((d) => _CompactDeviceRow(
                    device: d,
                    homeId: homeId,
                    canControl: canControl,
                  )),
        ],
      ),
    );
  }
}

class _CompactDeviceRow extends StatelessWidget {
  final Device device;
  final String homeId;
  final bool canControl;

  const _CompactDeviceRow({
    required this.device,
    required this.homeId,
    required this.canControl,
  });

  @override
  Widget build(BuildContext context) {
    final color = hardwareColorForDevice(device);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(hardwareIconForDevice(device), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              device.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Switch.adaptive(
            value: device.isOn,
            activeThumbColor: AppColors.cyanoBlue,
            onChanged: canControl
                ? (v) {
                    context
                        .read<HardwareControllerProvider>()
                        .sendDeviceCommand(device, v, homeId: homeId);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _ActiveAutomationsCard extends StatelessWidget {
  const _ActiveAutomationsCard();
  @override
  Widget build(BuildContext context) {
    return PaneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Automations',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _RuleItem(
              title: 'Fire Safety',
              icon: Icons.local_fire_department_rounded,
              color: Colors.red),
          _RuleItem(
              title: 'Auto Lights',
              icon: Icons.lightbulb_outline_rounded,
              color: Colors.amber),
          _RuleItem(
              title: 'Auto Fan',
              icon: Icons.ac_unit_rounded,
              color: Colors.blue),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _RuleItem(
      {required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('LIVE',
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _BluetoothTrafficCard extends StatelessWidget {
  const _BluetoothTrafficCard();
  @override
  Widget build(BuildContext context) {
    return PaneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Serial Traffic',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _TrafficList(),
        ],
      ),
    );
  }
}

class _TrafficList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final logger = LoggerService();
    return StreamBuilder<List<LogEntry>>(
      stream: logger.logsStream,
      initialData: logger.logs,
      builder: (context, snapshot) {
        final entries = (snapshot.data ?? logger.logs)
            .where((entry) => entry.message.contains('Hardware'))
            .toList()
            .reversed
            .take(4)
            .toList();

        if (entries.isEmpty) {
          return const Text(
            'Waiting for data...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          );
        }

        return Column(
          children: entries.map((entry) {
            final isTx = entry.message.contains('TX');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    isTx ? Icons.upload_rounded : Icons.download_rounded,
                    size: 14,
                    color: isTx ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.message.replaceAll('Hardware ', ''),
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _LiveModeConnectionCard extends StatelessWidget {
  final AuthProvider auth;
  const _LiveModeConnectionCard({required this.auth});

  @override
  Widget build(BuildContext context) {
    final hardware = context.watch<HardwareControllerProvider>();
    final isConnected = hardware.isTransportConnected;
    final isVerified = hardware.isHardwareVerified;
    final stage = hardware.connectionStage;
    final isReconnecting = hardware.isReconnecting;
    final isConnecting = stage == HardwareLinkState.connecting ||
        stage == HardwareLinkState.awaitingPin;

    final icon = isReconnecting
        ? Icons.sync_rounded
        : isConnecting
            ? Icons.hourglass_top_rounded
            : (isVerified
                ? Icons.verified_rounded
                : (isConnected
                    ? Icons.lock_open_rounded
                    : Icons.usb_off_rounded));
    final title = isReconnecting
        ? 'Reconnecting to Hardware'
        : isConnecting
            ? 'Connecting to Hardware'
            : (isVerified
                ? 'Hardware Verified'
                : (isConnected
                    ? 'Verification Required'
                    : 'Hardware Disconnected'));
    final subtitle = isReconnecting
        ? hardware.statusMessage
        : isConnecting
            ? hardware.statusMessage
            : (isVerified
                ? 'The Arduino link is live. Control buttons are enabled and sensor cards will update from hardware.'
                : (isConnected
                    ? 'The serial port is open. Send the controller PIN to authorize hardware control.'
                    : 'No live hardware link is available right now. You can still browse cached data and configure the port.'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVerified
              ? AppColors.success.withValues(alpha: 0.24)
              : AppColors.cyanoBlue.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isVerified
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.cyanoBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.cyanoBlue, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.45),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _statusChip(
                      isConnected ? 'PORT OPEN' : 'PORT CLOSED',
                      isConnected ? AppColors.success : AppColors.warning,
                    ),
                    _statusChip(
                      isVerified ? 'PIN VERIFIED' : 'PIN NEEDED',
                      isVerified ? AppColors.success : AppColors.cyanoBlue,
                    ),
                    _statusChip(
                      hardware.isOfflineMode ? 'OFFLINE READY' : 'LIVE MODE',
                      hardware.isOfflineMode
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: isConnected
                    ? () => hardware.submitControllerPin(
                          SmartHomeHardware.pinCode,
                          homeId: auth.homeId,
                        )
                    : () =>
                        const DashboardScreen().showBluetoothDialog(context),
                icon: Icon(isConnected
                    ? Icons.pin_rounded
                    : Icons.settings_input_component_rounded),
                label: Text(isConnected ? 'Send PIN' : 'Configure Port'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () =>
                    const DashboardScreen().showBluetoothDialog(context),
                icon: const Icon(Icons.usb_rounded),
                label: const Text('Save & Connect'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
