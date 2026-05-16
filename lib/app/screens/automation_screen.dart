import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../widgets/adaptive_scaffold.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  final List<Map<String, dynamic>> _automations = [
    {
      'id': '1',
      'name': 'Good Morning',
      'description': 'Turn on lights and open blinds at 7:00 AM',
      'icon': Icons.wb_sunny,
      'isActive': true,
      'time': '7:00 AM',
      'days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      'trigger': 'Time',
      'actions': ['Turn on lights', 'Open blinds'],
    },
    {
      'id': '2',
      'name': 'Good Night',
      'description': 'Turn off all lights and lock doors at 11:00 PM',
      'icon': Icons.nightlight,
      'isActive': true,
      'time': '11:00 PM',
      'days': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      'trigger': 'Time',
      'actions': ['Turn off lights', 'Lock doors'],
    },
    {
      'id': '3',
      'name': 'Away Mode',
      'description': 'Turn off lights and enable security when leaving',
      'icon': Icons.directions_walk,
      'isActive': false,
      'trigger': 'Location',
      'actions': ['Turn off lights', 'Enable security'],
    },
    {
      'id': '4',
      'name': 'Movie Time',
      'description': 'Dim lights and close blinds when TV turns on',
      'icon': Icons.tv,
      'isActive': false,
      'trigger': 'Device State',
      'actions': ['Close blinds', 'Turn off lights'],
    },
  ];

  void _toggleAutomation(String id) {
    setState(() {
      final idx = _automations.indexWhere((a) => a['id'] == id);
      if (idx != -1) {
        _automations[idx]['isActive'] = !(_automations[idx]['isActive'] as bool);
      }
    });
  }

  Future<void> _openCreateAutomation() async {
    final created = await context.push<Map<String, dynamic>>('/automation/create');
    if (created == null || !mounted) return;
    setState(() {
      _automations.insert(0, created);
    });
  }

  Future<void> _editAutomation(Map<String, dynamic> automation) async {
    final nameController =
        TextEditingController(text: automation['name'] as String? ?? '');
    final descriptionController =
        TextEditingController(text: automation['description'] as String? ?? '');
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Automation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated != true || !mounted) return;

    setState(() {
      final idx = _automations.indexWhere((a) => a['id'] == automation['id']);
      if (idx == -1) return;
      _automations[idx] = {
        ..._automations[idx],
        'name': nameController.text.trim().isEmpty
            ? _automations[idx]['name']
            : nameController.text.trim(),
        'description': descriptionController.text.trim().isEmpty
            ? _automations[idx]['description']
            : descriptionController.text.trim(),
      };
    });
  }

  Future<void> _deleteAutomation(Map<String, dynamic> automation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Automation'),
        content: Text(
          'Delete "${automation['name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() {
      _automations.removeWhere((a) => a['id'] == automation['id']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _automations.where((a) => a['isActive'] as bool).length;

    return AdaptiveScaffold(
      title: 'Automations',
      currentIndex: 2,
      contentPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _openCreateAutomation,
        ),
      ],
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _automations.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildStatsCard(activeCount),
            );
          }
          return _buildAutomationCard(_automations[index - 1]);
        },
      ),
    );
  }

  Widget _buildStatsCard(int activeCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart Automations',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$activeCount active',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 30,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationCard(Map<String, dynamic> automation) {
    final isActive = automation['isActive'] as bool;
    final hasSchedule = automation.containsKey('time');
    final hasTrigger = automation.containsKey('trigger');
    final actionCount = (automation['actions'] as List<dynamic>? ?? const []).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.cyanoBlue.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    automation['icon'] as IconData,
                    size: 24,
                    color: isActive ? AppColors.cyanoBlue : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        automation['name'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        automation['description'] as String,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (_) => _toggleAutomation(automation['id'] as String),
                  activeTrackColor: AppColors.cyanoBlue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasSchedule) ...[
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    automation['time'] as String,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: (automation['days'] as List<dynamic>)
                          .map<Widget>(
                            (day) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cyanoBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                day as String,
                                style: const TextStyle(
                                  color: AppColors.cyanoBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ] else if (hasTrigger) ...[
              Row(
                children: [
                  Icon(Icons.sensors, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Trigger: ${automation['trigger'] as String}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '$actionCount action${actionCount == 1 ? '' : 's'} configured',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _editAutomation(automation),
                  child: const Text(
                    'Edit',
                    style: TextStyle(color: AppColors.cyanoBlue),
                  ),
                ),
                TextButton(
                  onPressed: () => _deleteAutomation(automation),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
