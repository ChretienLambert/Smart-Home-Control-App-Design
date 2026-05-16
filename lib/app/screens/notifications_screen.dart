import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/bloc/alert_bloc.dart';
import '../../core/models/alert.dart';
import '../../core/services/logger_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/hardware_ui_utils.dart';
import '../widgets/adaptive_scaffold.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AlertBloc>().add(const LoadAlerts());
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Notifications',
      showBackButton: true,
      actions: [
        IconButton(
          onPressed: () => context.read<AlertBloc>().add(MarkAllAlertsAsRead()),
          icon: const Icon(Icons.done_all_rounded),
          tooltip: 'Mark all as read',
        ),
        IconButton(
          onPressed: () => context.read<AlertBloc>().add(const LoadAlerts()),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
        ),
      ],
      body: StreamBuilder<List<LogEntry>>(
        stream: LoggerService().logsStream,
        initialData: LoggerService().logs,
        builder: (context, logSnapshot) {
          final logs = _recentHardwareLogs(logSnapshot.data ?? LoggerService().logs);

          return BlocBuilder<AlertBloc, AlertState>(
            builder: (context, state) {
              if (state is AlertLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is AlertError) {
                return Center(child: Text(state.message));
              }

              final alerts = state is AlertLoaded ? state.alerts : const <Alert>[];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionHeader(
                    title: 'Alerts',
                    subtitle: 'What the system has already recorded as notifications.',
                  ),
                  const SizedBox(height: 12),
                  if (alerts.isEmpty)
                    _buildEmptyState()
                  else
                    ...alerts.map((alert) => _AlertListItem(alert: alert)),
                  const SizedBox(height: 24),
                  _sectionHeader(
                    title: 'Hardware Logs',
                    subtitle: 'Live board and serial logs mirrored onto the alerts page.',
                    action: TextButton(
                      onPressed: () => context.push('/hardware-logs'),
                      child: const Text('Open full logs'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (logs.isEmpty)
                    _buildLogsEmptyState()
                  else
                    ...logs.map((entry) => _HardwareLogCard(entry: entry)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cyanoBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: AppColors.cyanoBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All Clear!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No notifications at the moment.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: const Text(
        'No hardware logs yet. Once the Arduino starts sending status or errors, they will appear here.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }
}

class _AlertListItem extends StatelessWidget {
  final Alert alert;

  const _AlertListItem({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = hardwareAlertColor(alert.severity);
    final icon = hardwareAlertIcon(alert.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: alert.isRead ? Colors.white : color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.isRead ? Colors.grey.withValues(alpha: 0.2) : color.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        onTap: () {
          if (!alert.isRead) {
            context.read<AlertBloc>().add(MarkAlertAsRead(alert.id));
          }
        },
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          alert.title,
          style: TextStyle(
            fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.w800,
            color: alert.isRead ? AppColors.textPrimary : color,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(alert.message),
            const SizedBox(height: 6),
            Text(
              _formatTimestamp(alert.timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: alert.isRead
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

class _HardwareLogCard extends StatelessWidget {
  final LogEntry entry;

  const _HardwareLogCard({required this.entry});

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
      case LogLevel.critical:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getLevelColor(entry.level);
    final timeStr = entry.timestamp.toIso8601String().substring(11, 19);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              entry.level == LogLevel.error || entry.level == LogLevel.critical
                  ? Icons.error_outline_rounded
                  : Icons.subject_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        entry.level.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.message,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (entry.context != null && entry.context!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    entry.context.toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<LogEntry> _recentHardwareLogs(List<LogEntry> logs) {
  final filtered = logs.where((log) {
    final message = log.message.toLowerCase();
    return message.contains('hardware') ||
        message.contains('arduino') ||
        log.level == LogLevel.error ||
        log.level == LogLevel.critical ||
        log.level == LogLevel.warning;
  }).toList();
  return filtered.reversed.take(6).toList();
}
