import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/device.dart';
import '../../core/theme/app_colors.dart';

class DeviceCard extends StatefulWidget {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String status;
  final bool isOn;
  final Function(String) onToggle;
  final Function(String)? onClick;
  final Function(String)? onEdit;
  final Function(String)? onDelete;
  final DeviceStatus? deviceStatus;
  final DateTime? lastUpdated;

  const DeviceCard({
    super.key,
    required this.id,
    required this.name,
    this.description = '',
    required this.icon,
    required this.status,
    required this.isOn,
    required this.onToggle,
    this.onClick,
    this.onEdit,
    this.onDelete,
    this.deviceStatus,
    this.lastUpdated,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _statusColor() {
    switch (widget.deviceStatus) {
      case DeviceStatus.online:
        return AppColors.cyanoBlue;
      case DeviceStatus.offline:
        return AppColors.textSecondary;
      case DeviceStatus.error:
        return AppColors.error;
      case DeviceStatus.maintenance:
        return AppColors.warning;
      case null:
        switch (widget.status) {
          case 'online':
            return AppColors.cyanoBlue;
          case 'offline':
            return AppColors.textSecondary;
          case 'active':
            return AppColors.cyanoBlueLight;
          default:
            return AppColors.textSecondary;
        }
    }
  }

  String _formatLastUpdated(DateTime? lastUpdated) {
    if (lastUpdated == null) return 'No activity';
    final diff = DateTime.now().difference(lastUpdated);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(lastUpdated);
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
    widget.onClick?.call(widget.id);
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and actions
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: widget.isOn
                                    ? AppColors.cyanoBlue
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.isOn
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: 18,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.onEdit != null)
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16),
                                    onPressed: () => widget.onEdit!(widget.id),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                    color: Colors.blue,
                                  ),
                                if (widget.onDelete != null)
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 16),
                                    onPressed: () =>
                                        widget.onDelete!(widget.id),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                    color: Colors.red,
                                  ),
                                Switch(
                                  value: widget.isOn,
                                  onChanged: (value) {
                                    widget.onToggle(widget.id);
                                  },
                                  activeThumbColor: AppColors.cyanoBlue,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Device name
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 2),

                        // Device description
                        if (widget.description.isNotEmpty)
                          Text(
                            widget.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                        SizedBox(height: widget.description.isNotEmpty ? 6 : 4),

                        // Status indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _statusColor(),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.deviceStatus?.displayName ??
                                      widget.status,
                                  style: TextStyle(
                                    color: _statusColor(),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            // Last activity log
                            Text(
                              _formatLastUpdated(widget.lastUpdated),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 8,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
