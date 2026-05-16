import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/bloc/device_bloc.dart';
import '../../core/config/smart_home_hardware.dart';
import '../../core/models/device.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/hardware_ui_utils.dart';
import '../providers/auth_provider.dart';
import '../providers/hardware_controller_provider.dart';
import '../widgets/controller_access_dialog.dart';
import '../widgets/adaptive_scaffold.dart';

class DeviceDetailScreen extends StatelessWidget {
  final String deviceId;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AdaptiveScaffold(
      title: 'Device Details',
      currentIndex: 1,
      showBackButton: true,
      body: BlocBuilder<DeviceBloc, DeviceState>(
        builder: (context, state) {
          if (state is DeviceLoading || state is DeviceInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DeviceError) {
            return Center(child: Text(state.message));
          }

          if (state is! DeviceLoaded) {
            return const SizedBox.shrink();
          }

          final ownedDeviceIds = {...?auth.currentUser?.deviceIds};
          final device = state.devices.cast<Device?>().firstWhere(
                (item) =>
                    item?.id == deviceId &&
                    (ownedDeviceIds.isEmpty || ownedDeviceIds.contains(item?.id)),
                orElse: () => null,
              );

          if (device == null) {
            return const Center(child: Text('Device not found in this home.'));
          }

          // Show sensor detail view for read-only sensor devices
          if (SmartHomeHardware.isSensor(device)) {
            return _SensorDetailBody(device: device);
          }

          final hardware = context.watch<HardwareControllerProvider>();
          final desktop = AdaptiveScaffold.isDesktop(context);
          return desktop
              ? _DesktopDeviceDetail(
                  device: device,
                  auth: auth,
                  hardware: hardware,
                )
              : _MobileDeviceDetail(
                  device: device,
                  auth: auth,
                  hardware: hardware,
                );
        },
      ),
    );
  }
}

class _DesktopDeviceDetail extends StatelessWidget {
  final Device device;
  final AuthProvider auth;
  final HardwareControllerProvider hardware;

  const _DesktopDeviceDetail({
    required this.device,
    required this.auth,
    required this.hardware,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _DeviceHero(
                device: device,
                hardware: hardware,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _DeviceSection(
                  title: 'Hardware Mapping',
                  child: _HardwareMapping(device: device),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _DirectControlSection(
                device: device,
                auth: auth,
                hardware: hardware,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _DeviceSection(
                  title: 'Control Logic',
                  child: _ControlLogic(
                    device: device,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileDeviceDetail extends StatelessWidget {
  final Device device;
  final AuthProvider auth;
  final HardwareControllerProvider hardware;

  const _MobileDeviceDetail({
    required this.device,
    required this.auth,
    required this.hardware,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DeviceHero(
            device: device,
            hardware: hardware,
          ),
          const SizedBox(height: 20),
          _DirectControlSection(
            device: device,
            auth: auth,
            hardware: hardware,
          ),
          const SizedBox(height: 16),
          _DeviceSection(
            title: 'Hardware Mapping',
            child: _HardwareMapping(device: device),
          ),
          const SizedBox(height: 16),
          _DeviceSection(
            title: 'Control Logic',
            child: _ControlLogic(
              device: device,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.go('/devices'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back To Device List'),
          ),
        ],
      ),
    );
  }
}

class _DeviceHero extends StatelessWidget {
  final Device device;
  final HardwareControllerProvider hardware;

  const _DeviceHero({
    required this.device,
    required this.hardware,
  });

  @override
  Widget build(BuildContext context) {
    final color = hardwareColorForDevice(device);
    final onCommand = device.properties?['onCommand'] as String?;
    final offCommand = device.properties?['offCommand'] as String?;
    final isKeypadMapped = onCommand != null && offCommand != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.92), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              hardwareIconForDevice(device),
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            device.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${device.properties?['channel']} / ${device.properties?['pin']}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _heroTag(hardwareStatusText(device)),
              _heroTag(hardwareCategoryForDevice(device)),
              _heroTag(isKeypadMapped
                  ? 'Key $onCommand/$offCommand'
                  : 'Bluetooth direct'),
              _heroTag(
                hardware.isHardwareConnected
                    ? 'Hardware reachable'
                    : 'Awaiting heartbeat',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DirectControlSection extends StatelessWidget {
  final Device device;
  final AuthProvider auth;
  final HardwareControllerProvider hardware;

  const _DirectControlSection({
    required this.device,
    required this.auth,
    required this.hardware,
  });

  @override
  Widget build(BuildContext context) {
    final isLock = device.type == DeviceType.doorLock;
    final color = hardwareColorForDevice(device);
    final canWireControl = SmartHomeHardware.isArduinoWired(device);

    return _DeviceSection(
      title: 'Direct Control',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tap the switch to toggle this device.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.35),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isLock
                          ? 'Keypad 9 / 0'
                          : 'Keypad ${device.properties?['onCommand']} / ${device.properties?['offCommand']}',
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
                          homeId: auth.homeId,
                        );
                      },
              ),
            ],
          ),
          if (!canWireControl) ...[
            const SizedBox(height: 10),
            const Text(
              'App only: this device is not wired to the Arduino sketch in live mode.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HardwareMapping extends StatelessWidget {
  final Device device;

  const _HardwareMapping({required this.device});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _infoRow('Type', device.type.displayName),
        _infoRow('Room', SmartHomeHardware.roomLabel(device)),
        _infoRow('GPIO / Analog Pin', '${device.properties?['pin']}'),
        _infoRow('Relay / Output', '${device.properties?['channel']}'),
        _infoRow('State', hardwareStatusText(device)),
        _infoRow('Hardware route', '${device.mqttTopic}/status'),
      ],
    );
  }
}

class _ControlLogic extends StatelessWidget {
  final Device device;

  const _ControlLogic({
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    final onCommand = device.properties?['onCommand'] as String?;
    final offCommand = device.properties?['offCommand'] as String?;
    final isKeypadMapped = onCommand != null && offCommand != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(
          'Routing',
          isKeypadMapped ? 'Arduino keypad + Bluetooth' : 'Direct Bluetooth',
        ),
        _infoRow('ON / Unlock key', onCommand ?? 'Not assigned'),
        _infoRow('OFF / Lock key', offCommand ?? 'Not assigned'),
      ],
    );
  }
}

class _DeviceSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DeviceSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PaneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SensorDetailBody extends StatelessWidget {
  final Device device;

  const _SensorDetailBody({required this.device});

  @override
  Widget build(BuildContext context) {
    final color = hardwareColorForDevice(device);
    final reading = hardwareSensorReading(device);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.92), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    hardwareIconForDevice(device),
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reading,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DeviceSection(
            title: 'Sensor Info',
            child: Column(
              children: [
                _infoRow('Type', device.type.displayName),
                _infoRow('Room', SmartHomeHardware.roomLabel(device)),
                _infoRow('GPIO / Analog Pin', '${device.properties?['pin']}'),
                _infoRow('Hardware route', '${device.mqttTopic}/status'),
                _infoRow('Current Reading', reading),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.go('/devices'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back To Device List'),
          ),
        ],
      ),
    );
  }
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
