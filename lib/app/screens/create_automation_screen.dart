import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/mobile_app_bar.dart';

class CreateAutomationScreen extends StatefulWidget {
  const CreateAutomationScreen({super.key});

  @override
  State<CreateAutomationScreen> createState() => _CreateAutomationScreenState();
}

class _CreateAutomationScreenState extends State<CreateAutomationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedTrigger = 'Time';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  final List<String> _selectedDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final List<Map<String, dynamic>> _actions = [];
  bool _isLoading = false;

  final List<String> _triggers = ['Time', 'Device State', 'Location', 'Sensor'];
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _availableActions = [
    'Turn on lights',
    'Turn off lights',
    'Lock doors',
    'Unlock doors',
    'Set temperature',
    'Close blinds',
    'Open blinds',
    'Enable security',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createAutomation() async {
    if (!_formKey.currentState!.validate() || _actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one action'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate creating automation - in real app, this would call an API
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Automation created successfully'),
            backgroundColor: Color(0xFF1E7F5C),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create automation: ${e.toString()}'),
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

  void _addAction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Action'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableActions.length,
            itemBuilder: (context, index) {
              final action = _availableActions[index];
              return ListTile(
                title: Text(action),
                onTap: () {
                  setState(() {
                    _actions.add({
                      'id': DateTime.now().toString(),
                      'name': action,
                    });
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _removeAction(String id) {
    setState(() {
      _actions.removeWhere((action) => action['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MobileAppBar(
        title: 'Create Automation',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Automation name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Automation Name',
                  hintText: 'e.g., Good Morning Routine',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E7F5C)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an automation name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Trigger section
              const Text(
                'Trigger',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Trigger type
              DropdownButtonFormField<String>(
                initialValue: _selectedTrigger,
                decoration: InputDecoration(
                  labelText: 'When should this run?',
                  prefixIcon: const Icon(Icons.sensors),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E7F5C)),
                  ),
                ),
                items: _triggers.map((trigger) {
                  return DropdownMenuItem(
                    value: trigger,
                    child: Text(trigger),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTrigger = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Time picker (if time trigger)
              if (_selectedTrigger == 'Time') ...[
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Time'),
                  subtitle: Text(_selectedTime.format(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (time != null) {
                      setState(() {
                        _selectedTime = time;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Day selector
                const Text('Repeat on'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _days.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDays.add(day);
                          } else {
                            _selectedDays.remove(day);
                          }
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: const Color(0xFF1E7F5C).withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1E7F5C)
                            : Colors.grey[700],
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF1E7F5C)
                            : Colors.grey[300]!,
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              // Actions section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addAction,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Action'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1E7F5C),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Actions list
              if (_actions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No actions added',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "Add Action" to get started',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._actions.map((action) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.play_arrow),
                        title: Text(action['name']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeAction(action['id']),
                        ),
                      ),
                    )),

              const SizedBox(height: 32),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createAutomation,
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
                          'Create Automation',
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
