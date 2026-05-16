import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../widgets/adaptive_scaffold.dart';
import '../../core/bloc/device_bloc.dart';
import '../../core/bloc/alert_bloc.dart';
import '../../core/models/device.dart';
import '../../core/models/alert.dart';
import '../../core/config/smart_home_hardware.dart';
import '../providers/auth_provider.dart';
import '../providers/hardware_controller_provider.dart';
import '../../core/theme/app_colors.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  // Local-state toggles for peripheral security features.
  bool _camerasActive = true;
  bool _motionDetection = true;
  bool _doorSensors = true;
  bool _windowSensors = true;

  // New states for real functionalities
  bool _isSystemArmed = true;
  bool _isAutoLockEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityPreferences();
    // Defer reads until the first frame so context is fully mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final alertState = context.read<AlertBloc>().state;
      if (alertState is! AlertLoaded) {
        context.read<AlertBloc>().add(const LoadAlerts());
      }
      final deviceState = context.read<DeviceBloc>().state;
      if (deviceState is! DeviceLoaded) {
        context.read<DeviceBloc>().add(LoadDevices());
      }
    });
  }

  Future<void> _loadSecurityPreferences() async {
    final auth = context.read<AuthProvider>();
    final prefs = auth.currentUser?.preferences;
    if (prefs != null) {
      setState(() {
        _isSystemArmed = prefs['security_armed'] as bool? ?? true;
        _isAutoLockEnabled = prefs['security_auto_lock'] as bool? ?? true;
      });
    }
  }

  Future<void> _toggleSystemArm() async {
    final newState = !_isSystemArmed;
    setState(() => _isSystemArmed = newState);

    final auth = context.read<AuthProvider>();
    final prefs = Map<String, dynamic>.from(auth.currentUser?.preferences ?? {});
    prefs['security_armed'] = newState;
    await auth.updateProfile(preferences: prefs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState ? 'System Armed' : 'System Disarmed'),
          backgroundColor: newState ? AppColors.success : AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleAutoLock(bool value) async {
    setState(() => _isAutoLockEnabled = value);

    final auth = context.read<AuthProvider>();
    final prefs = Map<String, dynamic>.from(auth.currentUser?.preferences ?? {});
    prefs['security_auto_lock'] = value;
    await auth.updateProfile(preferences: prefs);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Color _severityColor(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.info:
        return AppColors.alertInfo;
      case AlertSeverity.warning:
        return AppColors.alertWarning;
      case AlertSeverity.error:
        return AppColors.alertError;
      case AlertSeverity.critical:
        return AppColors.alertCritical;
    }
  }

  IconData _alertTypeIcon(AlertType t) {
    switch (t) {
      case AlertType.securityAlert:
        return Icons.security;
      case AlertType.deviceOffline:
        return Icons.device_unknown;
      case AlertType.sensorThreshold:
        return Icons.sensors;
      case AlertType.automationTriggered:
        return Icons.auto_awesome;
      case AlertType.systemError:
        return Icons.error_outline;
      case AlertType.maintenance:
        return Icons.build;
      case AlertType.lowBattery:
        return Icons.battery_alert;
      case AlertType.connectivity:
        return Icons.bluetooth_disabled;
    }
  }

  String _relativeTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AdaptiveScaffold(
      title: 'Security',
      showBackButton: true,
      contentPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {
            context.push('/notifications');
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityStatusHero(),
            const SizedBox(height: 24),

            const Text(
              'Access Control',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDoorLockSection(context, auth),
            const SizedBox(height: 24),

            const Text(
              'Panic Alarm',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBuzzerSection(context, auth),
            const SizedBox(height: 24),

            _buildSecurityComponents(),
            const SizedBox(height: 24),

            _buildRecentAlerts(context),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStatusHero() {
    final statusColor = _isSystemArmed ? AppColors.success : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _isSystemArmed ? Icons.shield_rounded : Icons.shield_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSystemArmed ? 'System Armed' : 'System Disarmed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
                Text(
                  _isSystemArmed
                      ? 'All sensors are active and monitoring.'
                      : 'Security monitoring is partially active.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isSystemArmed,
            onChanged: (_) => _toggleSystemArm(),
            activeTrackColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildDoorLockSection(BuildContext context, AuthProvider auth) {
    return BlocBuilder<DeviceBloc, DeviceState>(
      builder: (context, state) {
        if (state is DeviceLoading) {
          return _shimmerCard(height: 196);
        }

        if (state is DeviceLoaded) {
          final userDeviceIds = auth.currentUser?.deviceIds;
          final locks = state.devices.where((d) {
            if (d.type != DeviceType.doorLock) return false;
            if (userDeviceIds == null || userDeviceIds.isEmpty) return true;
            return userDeviceIds.contains(d.id);
          }).toList();

          if (locks.isEmpty) return _buildNoLockCard();

          return Column(
            children: locks
                .map((device) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildLockCard(context, auth, device),
                    ))
                .toList(),
          );
        }

        return _buildNoLockCard();
      },
    );
  }

  Widget _buildLockCard(
      BuildContext context, AuthProvider auth, Device device) {
    final isLocked = SmartHomeHardware.isLocked(device);
    final isOnline = device.status == DeviceStatus.online;

    final gradient = isLocked
        ? AppColors.primaryGradient
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[400]!, Colors.grey[600]!],
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLocked ? Icons.lock : Icons.lock_open,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isOnline)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Offline',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            isLocked ? 'Locked' : 'Unlocked',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            SmartHomeHardware.roomLabel(device),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  isOnline && context.read<HardwareControllerProvider>().canControl
                      ? () => context
                          .read<HardwareControllerProvider>()
                          .sendDeviceCommand(
                            device,
                            !device.isOn,
                            homeId: auth.homeId,
                          )
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                    isLocked ? AppColors.cyanoBlue : Colors.grey[700],
                disabledBackgroundColor: Colors.white54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isLocked ? 'Unlock Door' : 'Lock Door',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLockCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.lock_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No Door Lock Device',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No door lock is assigned to your account.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBuzzerSection(BuildContext context, AuthProvider auth) {
    return BlocBuilder<DeviceBloc, DeviceState>(
      builder: (context, state) {
        if (state is DeviceLoading) return _shimmerCard(height: 100);

        if (state is DeviceLoaded) {
          final userDeviceIds = auth.currentUser?.deviceIds;
          final buzzers = state.devices.where((d) {
            if (d.type != DeviceType.speaker) return false;
            if (userDeviceIds == null || userDeviceIds.isEmpty) return true;
            return userDeviceIds.contains(d.id);
          }).toList();

          if (buzzers.isEmpty) return _buildNoBuzzerCard();

          return Column(
            children: buzzers
                .map((device) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildBuzzerCard(context, auth, device),
                    ))
                .toList(),
          );
        }
        return _buildNoBuzzerCard();
      },
    );
  }

  Widget _buildBuzzerCard(
      BuildContext context, AuthProvider auth, Device device) {
    final isOn = device.isOn;
    final isOnline = device.status == DeviceStatus.online;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOn ? AppColors.error.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOn ? AppColors.error : Colors.grey[300]!,
          width: isOn ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isOn ? AppColors.error : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: isOn ? Colors.white : Colors.grey[400],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  isOn ? 'ALARM ACTIVE' : 'System Silent',
                  style: TextStyle(
                    color: isOn ? AppColors.error : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isOn ? FontWeight.w800 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: isOnline &&
                    context.read<HardwareControllerProvider>().canControl
                ? () => context
                    .read<HardwareControllerProvider>()
                    .sendDeviceCommand(device, !isOn, homeId: auth.homeId)
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: isOn ? AppColors.error : AppColors.cyanoBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isOn ? 'STOP' : 'ACTIVATE'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBuzzerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (Colors.grey[50] ?? Colors.grey).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200] ?? Colors.grey),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_off_rounded, color: Colors.grey),
          SizedBox(width: 12),
          Text(
            'No siren/buzzer connected to system.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityComponents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Components',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Auto-Lock Door'),
                subtitle: const Text('Automatically lock door after 5 minutes'),
                secondary: Icon(
                  Icons.timer_outlined,
                  color: _isAutoLockEnabled ? AppColors.cyanoBlue : Colors.grey,
                ),
                value: _isAutoLockEnabled,
                onChanged: _toggleAutoLock,
                activeTrackColor: AppColors.cyanoBlue,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Cameras'),
                subtitle: const Text('Monitor all security cameras'),
                secondary: Icon(
                  Icons.videocam,
                  color: _camerasActive ? AppColors.cyanoBlue : Colors.grey,
                ),
                value: _camerasActive,
                onChanged: (v) => setState(() => _camerasActive = v),
                activeTrackColor: AppColors.cyanoBlue,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Motion Detection'),
                subtitle: const Text('Detect motion in monitored areas'),
                secondary: Icon(
                  Icons.motion_photos_on,
                  color: _motionDetection ? AppColors.cyanoBlue : Colors.grey,
                ),
                value: _motionDetection,
                onChanged: (v) => setState(() => _motionDetection = v),
                activeTrackColor: AppColors.cyanoBlue,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Door Sensors'),
                subtitle: const Text('Monitor door openings'),
                secondary: Icon(
                  Icons.door_front_door,
                  color: _doorSensors ? AppColors.cyanoBlue : Colors.grey,
                ),
                value: _doorSensors,
                onChanged: (v) => setState(() => _doorSensors = v),
                activeTrackColor: AppColors.cyanoBlue,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Window Sensors'),
                subtitle: const Text('Monitor window openings'),
                secondary: Icon(
                  Icons.window,
                  color: _windowSensors ? AppColors.cyanoBlue : Colors.grey,
                ),
                value: _windowSensors,
                onChanged: (v) => setState(() => _windowSensors = v),
                activeTrackColor: AppColors.cyanoBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAlerts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            BlocBuilder<AlertBloc, AlertState>(
              builder: (context, state) {
                if (state is AlertLoaded && state.unreadCount > 0) {
                  return TextButton(
                    onPressed: () =>
                        context.read<AlertBloc>().add(MarkAllAlertsAsRead()),
                    child: const Text(
                      'Mark All Read',
                      style: TextStyle(color: AppColors.cyanoBlue),
                    ),
                  );
                }
                return TextButton(
                  onPressed: () {
                    context.push('/notifications');
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: AppColors.cyanoBlue),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        BlocBuilder<AlertBloc, AlertState>(
          builder: (context, state) {
            if (state is AlertLoading) {
              return Column(
                children: List.generate(3, (_) => _shimmerCard(height: 72)),
              );
            }

            if (state is AlertLoaded) {
              final alerts = state.alerts.take(10).toList();
              if (alerts.isEmpty) return _buildNoAlertsCard();
              return Column(
                children:
                    alerts.map((a) => _buildAlertItem(context, a)).toList(),
              );
            }

            if (state is AlertError) {
              return _buildNoAlertsCard(message: state.message);
            }

            return _buildNoAlertsCard();
          },
        ),
      ],
    );
  }

  Widget _buildAlertItem(BuildContext context, Alert alert) {
    final color = _severityColor(alert.severity);
    final icon = _alertTypeIcon(alert.type);

    return GestureDetector(
      onTap: () {
        if (!alert.isRead) {
          context.read<AlertBloc>().add(MarkAlertAsRead(alert.id));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alert.isRead ? Colors.white : color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.isRead
                ? Colors.transparent
                : color.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            fontWeight: alert.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!alert.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 4),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    alert.message,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            Text(
              _relativeTime(alert.timestamp),
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAlertsCard({String? message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message ?? 'No recent events',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _shimmerCard({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
