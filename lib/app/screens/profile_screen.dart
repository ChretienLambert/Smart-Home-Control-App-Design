import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/password_utils.dart';
import '../../core/models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/adaptive_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.currentUser;
    final prefs = Map<String, dynamic>.from(user?.preferences ?? {});

    final notificationsEnabled =
        (prefs['notifications'] as bool?) ?? theme.notificationsEnabled;
    final autoBackup = (prefs['autoBackup'] as bool?) ?? theme.autoBackup;
    final locationSharing = (prefs['locationSharing'] as bool?) ?? false;
    final homeName = auth.homeName;
    final homeId = auth.homeId;

    return AdaptiveScaffold(
      title: 'Profile',
      currentIndex: 4,
      body: AdaptiveScaffold.isDesktop(context)
          ? _buildDesktop(
              context,
              auth,
              theme,
              user,
              homeName,
              homeId,
              notificationsEnabled,
              autoBackup,
              locationSharing,
            )
          : _buildMobile(
              context,
              auth,
              theme,
              user,
              homeName,
              homeId,
              notificationsEnabled,
              autoBackup,
              locationSharing,
            ),
    );
  }

  Widget _buildDesktop(
    BuildContext context,
    AuthProvider auth,
    ThemeProvider theme,
    User? user,
    String homeName,
    String homeId,
    bool notificationsEnabled,
    bool autoBackup,
    bool locationSharing,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: _profileOverview(auth, theme, user, homeName, homeId),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(
                child: _preferencesPanel(
                    auth,
                    theme,
                    notificationsEnabled,
                    autoBackup,
                    locationSharing,
                  ),
              ),
              const SizedBox(height: 16),
              _actionsPanel(auth),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(
    BuildContext context,
    AuthProvider auth,
    ThemeProvider theme,
    User? user,
    String homeName,
    String homeId,
    bool notificationsEnabled,
    bool autoBackup,
    bool locationSharing,
  ) {
    return ListView(
      children: [
        _profileOverview(auth, theme, user, homeName, homeId),
        const SizedBox(height: 16),
        _preferencesPanel(
          auth,
          theme,
          notificationsEnabled,
          autoBackup,
          locationSharing,
        ),
        const SizedBox(height: 16),
        _actionsPanel(auth),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _profileOverview(
    AuthProvider auth,
    ThemeProvider theme,
    User? user,
    String homeName,
    String homeId,
  ) {
    final isAdmin = auth.isAdmin;

    return PaneCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(44),
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? auth.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email available',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? Colors.red.withValues(alpha: 0.18)
                          : Colors.green.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      isAdmin ? 'ADMIN ACCESS' : 'STANDARD ACCESS',
                      style: TextStyle(
                        color:
                            isAdmin ? Colors.red.shade100 : Colors.green.shade100,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle(
              title: 'Home Identity',
              subtitle:
                  'Each user owns a separate home. This is the home currently linked to your account.',
            ),
            const SizedBox(height: 14),
            _infoRow('Home name', homeName),
            _infoRow('Home ID', homeId),
            _infoRow('Role', user?.role.displayName ?? 'Unknown'),
            _infoRow('Phone', user?.phoneNumber ?? 'Not set'),
            _infoRow('Theme', theme.isDarkMode ? 'Dark' : 'Light'),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _statTile('Devices', '${user?.deviceIds?.length ?? 0}',
                      Icons.devices_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statTile('Rooms', '${user?.roomIds?.length ?? 0}',
                      Icons.meeting_room_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showEditProfileDialog(context, auth),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preferencesPanel(
    AuthProvider auth,
    ThemeProvider theme,
    bool notificationsEnabled,
    bool autoBackup,
    bool locationSharing,
  ) {
    return PaneCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionTitle(
              title: 'Preferences',
              subtitle:
                  'These settings are now connected to stored profile state instead of only local placeholders.',
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: notificationsEnabled,
              onChanged: (value) => _updatePreference(
                auth,
                theme,
                'notifications',
                value,
                sideEffect: () async {
                  if (theme.notificationsEnabled != value) {
                    await theme.toggleNotifications();
                  }
                },
              ),
              title: const Text('Notifications'),
              subtitle: const Text('Alert notifications for device events'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: theme.isDarkMode,
              onChanged: (value) async {
                await theme
                    .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                await _updatePreference(
                  auth,
                  theme,
                  'theme',
                  value ? 'dark' : 'light',
                );
              },
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch the whole app theme'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: autoBackup,
              onChanged: (value) => _updatePreference(
                auth,
                theme,
                'autoBackup',
                value,
                sideEffect: () async {
                  if (theme.autoBackup != value) {
                    await theme.toggleAutoBackup();
                  }
                },
              ),
              title: const Text('Auto Backup'),
              subtitle: const Text('Keep data export automation enabled'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: locationSharing,
              onChanged: (value) =>
                  _updatePreference(auth, theme, 'locationSharing', value),
              title: const Text('Location Sharing'),
              subtitle: const Text('Allow trusted-home location workflows'),
              contentPadding: EdgeInsets.zero,
            ),
            if (_saving) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionsPanel(AuthProvider auth) {
    return PaneCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Actions',
            subtitle: 'Manage your ${auth.homeName} home, devices, and scenes.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showChangePasswordDialog(context, auth),
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('Change Password'),
              ),
              FilledButton.icon(
                onPressed: () => context.go('/devices'),
                icon: const Icon(Icons.devices_rounded),
                label: const Text('Manage Devices'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/automation'),
                icon: const Icon(Icons.smart_toy_rounded),
                label: const Text('Automations'),
              ),
              if (auth.isAdmin)
                OutlinedButton.icon(
                  onPressed: () => context.go('/admin'),
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: const Text('Admin Panel'),
                ),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await auth.logout();
                  if (mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.cyanoBlue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
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

  void _showEditProfileDialog(BuildContext context, AuthProvider auth) {
    final user = auth.currentUser;
    final firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    final lastNameCtrl  = TextEditingController(text: user?.lastName  ?? '');
    final phoneCtrl     = TextEditingController(text: user?.phoneNumber ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameCtrl,
                decoration: const InputDecoration(labelText: 'First Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Last Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _saving = true);
              try {
                await auth.updateProfile(
                  firstName: firstNameCtrl.text.trim().isEmpty
                      ? null
                      : firstNameCtrl.text.trim(),
                  lastName: lastNameCtrl.text.trim().isEmpty
                      ? null
                      : lastNameCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim().isEmpty
                      ? null
                      : phoneCtrl.text.trim(),
                );
              } finally {
                if (mounted) setState(() => _saving = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider auth) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentCtrl,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setDlgState(
                          () => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    helperText: 'Min 8 chars, upper, lower, number',
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setDlgState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Confirm New Password'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (newCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Passwords do not match')),
                  );
                  return;
                }
                if (newCtrl.text.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Password must be at least 8 characters')),
                  );
                  return;
                }
                // Capture messenger before async gap
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                setState(() => _saving = true);
                try {
                  await _changePassword(
                      auth,
                      currentCtrl.text.trim(),
                      newCtrl.text.trim());
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                          content: Text('Password changed successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _saving = false);
                }
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(
    AuthProvider auth,
    String currentPassword,
    String newPassword,
  ) async {
    final user = auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final db = DatabaseService();
    final storedHash = await db.getUserPasswordHash(user.id);
    if (storedHash == null ||
        !PasswordUtils.verifyPassword(currentPassword, storedHash)) {
      throw Exception('Current password is incorrect');
    }

    if (!PasswordUtils.isStrongPassword(newPassword)) {
      throw Exception(
          'Password must be at least 8 characters with uppercase, lowercase, and number');
    }

    final newHash = PasswordUtils.hashPassword(newPassword);
    await db.setUserPassword(user.id, newHash);
  }

  Future<void> _updatePreference(
    AuthProvider auth,
    ThemeProvider theme,
    String key,
    dynamic value, {
    Future<void> Function()? sideEffect,
  }) async {
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (sideEffect != null) {
        await sideEffect();
      }
      final prefs = Map<String, dynamic>.from(user.preferences ?? {});
      prefs[key] = value;
      await auth.updateProfile(preferences: prefs);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}
