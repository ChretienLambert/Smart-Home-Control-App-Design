import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/bloc/room_bloc.dart';
import '../../core/models/room.dart';
import '../../core/services/app_service.dart';
import '../../core/services/home_service.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/adaptive_scaffold.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _newRoomController = TextEditingController();
  final _pinController = TextEditingController();
  final HomeService _homeService = HomeService();

  HomeDeviceProfile _selectedProfile = HomeDeviceProfiles.relayLight;
  bool _createNewRoom = false;
  bool _isLoading = false;
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _pinController.text = _selectedProfile.defaultPinLabel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newRoomController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AdaptiveScaffold(
      title: 'Add Device',
      currentIndex: 1,
      showBackButton: true,
      body: BlocBuilder<RoomBloc, RoomState>(
        builder: (context, state) {
          final roomIds = {...?auth.currentUser?.roomIds};
          final rooms = state is RoomLoaded
              ? (() {
                  final ownedRooms = state.rooms
                      .where((room) => roomIds.contains(room.id))
                      .toList();
                  ownedRooms.sort((a, b) => a.name.compareTo(b.name));
                  return ownedRooms;
                })()
              : <Room>[];

          _selectedRoomId ??= rooms.isNotEmpty ? rooms.first.id : null;

          return AdaptiveScaffold.isDesktop(context)
              ? _buildDesktop(auth, rooms)
              : _buildMobile(auth, rooms);
        },
      ),
    );
  }

  Widget _buildDesktop(AuthProvider auth, List<Room> rooms) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildHero(auth.homeName),
              const SizedBox(height: 16),
              Expanded(child: _buildProfilePicker()),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildDeviceForm()),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: _buildRoomSelector(rooms)),
                            const SizedBox(height: 16),
                            _buildConnectivityCard(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSubmitButton(auth, rooms),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(AuthProvider auth, List<Room> rooms) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHero(auth.homeName),
            const SizedBox(height: 20),
            _buildProfilePicker(),
            const SizedBox(height: 20),
            _buildDeviceForm(),
            const SizedBox(height: 20),
            _buildRoomSelector(rooms),
            const SizedBox(height: 20),
            _buildConnectivityCard(),
            const SizedBox(height: 20),
            _buildSubmitButton(auth, rooms),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(String homeName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
          Text(
            'Add Bluetooth Hardware To $homeName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New devices stay binary like the relay hardware: ON/OFF outputs or LOCK/UNLOCK for door locks.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicker() {
    return PaneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Compatible Device Type',
            subtitle:
                'Choose a hardware profile that matches the real output style you plan to wire through Bluetooth.',
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth > 860
                    ? 3
                    : constraints.maxWidth > 520
                        ? 2
                        : 1;
                return GridView.builder(
                  itemCount: HomeDeviceProfiles.values.length,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: count == 1 ? 3.2 : 1.55,
                  ),
                  itemBuilder: (context, index) {
                    final profile = HomeDeviceProfiles.values[index];
                    final selected = profile == _selectedProfile;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedProfile = profile;
                          _pinController.text = profile.defaultPinLabel;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Ink(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFE8F6F3)
                              : const Color(0xFFF6FAF9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF0E6B63)
                                : const Color(0xFFD7E3E1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              profile.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              profile.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceForm() {
    return PaneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Device Details',
            subtitle:
                'The hardware pin is used as the GPIO label in the app and hardware commands.',
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Device Name',
              hintText: 'e.g., Kitchen Light',
              prefixIcon: const Icon(Icons.label_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a device name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pinController,
            decoration: InputDecoration(
              labelText: 'Hardware Pin / GPIO',
              hintText: _selectedProfile.defaultPinLabel,
              prefixIcon: const Icon(Icons.memory_outlined),
              helperText:
                  'Used as the module pin label in the UI and hardware commands.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomSelector(List<Room> rooms) {
    return PaneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Room Assignment',
            subtitle:
                'Attach the device to an existing room or provision a new room inside this user home.',
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            value: _createNewRoom,
            onChanged: (value) {
              setState(() {
                _createNewRoom = value;
              });
            },
            title: const Text('Create a new room'),
            subtitle: const Text(
              'Turn this on if the device belongs to a brand-new room.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          if (_createNewRoom)
            TextFormField(
              controller: _newRoomController,
              decoration: InputDecoration(
                labelText: 'New Room Name',
                hintText: 'e.g., Kitchen',
                prefixIcon: const Icon(Icons.meeting_room_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (_createNewRoom && (value == null || value.trim().isEmpty)) {
                  return 'Please enter the new room name';
                }
                return null;
              },
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedRoomId,
              decoration: InputDecoration(
                labelText: 'Existing Room',
                prefixIcon: const Icon(Icons.room_preferences_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: [
                for (final room in rooms)
                  DropdownMenuItem(
                    value: room.id,
                    child: Text(room.name),
                  ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRoomId = value;
                });
              },
              validator: (value) {
                if (!_createNewRoom && (value == null || value.isEmpty)) {
                  return 'Please choose a room';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildConnectivityCard() {
    return const PaneCard(
      color: Color(0xFF102A2A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bluetooth Module Notes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Each added device uses direct hardware control on the Arduino side, with Bluetooth serial acting as the live transport.',
            style: TextStyle(
              color: Color(0xFFD1E5E3),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AuthProvider auth, List<Room> rooms) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isLoading ? null : () => _addDevice(auth, rooms),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0E6B63),
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded),
        label: Text(_isLoading ? 'Adding device...' : 'Add Device'),
      ),
    );
  }

  Future<void> _addDevice(AuthProvider auth, List<Room> rooms) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    if (!_createNewRoom && (_selectedRoomId == null || rooms.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose an existing room or create a new one first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final roomName = _createNewRoom
        ? _newRoomController.text.trim()
        : rooms.firstWhere((room) => room.id == _selectedRoomId).name;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _homeService.addDeviceToUserHome(
        user: user,
        deviceName: _nameController.text.trim(),
        roomName: roomName,
        profile: _selectedProfile,
        hardwarePin: _pinController.text.trim(),
      );

      auth.syncCurrentUser(result.user);
      await AppService().refreshHardwareData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('${result.device.name} added to ${result.room.name}.'),
            backgroundColor: const Color(0xFF0E6B63),
          ),
        );
        context.go('/devices/${result.device.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add device: $e'),
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
}
