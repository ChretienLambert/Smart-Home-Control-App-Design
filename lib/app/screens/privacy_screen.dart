import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _dataCollection = true;
  bool _analytics = true;
  bool _crashReporting = true;
  bool _locationServices = false;
  bool _voiceCommands = true;
  bool _cameraAccess = true;
  bool _microphoneAccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E7F5C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Overview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E7F5C),
                    Color(0xFF4ECDC4),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.privacy_tip,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Privacy Protection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your data is encrypted and secure',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'End-to-end encryption active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data Collection
            const Text(
              'Data Collection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Control what data is collected to improve your experience',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Usage Data'),
                    subtitle: const Text('Help improve app performance'),
                    secondary: Icon(
                      Icons.analytics,
                      color: _dataCollection
                          ? const Color(0xFF1E7F5C)
                          : Colors.grey,
                    ),
                    value: _dataCollection,
                    onChanged: (value) {
                      setState(() {
                        _dataCollection = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF1E7F5C),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Analytics'),
                    subtitle: const Text('Anonymous usage statistics'),
                    secondary: Icon(
                      Icons.bar_chart,
                      color: _analytics ? const Color(0xFF1E7F5C) : Colors.grey,
                    ),
                    value: _analytics,
                    onChanged: (value) {
                      setState(() {
                        _analytics = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF1E7F5C),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Crash Reports'),
                    subtitle: const Text('Automatically report crashes'),
                    secondary: Icon(
                      Icons.bug_report,
                      color: _crashReporting
                          ? const Color(0xFF1E7F5C)
                          : Colors.grey,
                    ),
                    value: _crashReporting,
                    onChanged: (value) {
                      setState(() {
                        _crashReporting = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF1E7F5C),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Device Permissions
            const Text(
              'Device Permissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage app access to device features',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Location Services'),
                    subtitle: const Text('Access device location'),
                    secondary: Icon(
                      Icons.location_on,
                      color: _locationServices
                          ? const Color(0xFF1E7F5C)
                          : Colors.grey,
                    ),
                    value: _locationServices,
                    onChanged: (value) {
                      setState(() {
                        _locationServices = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF1E7F5C),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Voice Commands'),
                    subtitle: const Text('Process voice commands'),
                    secondary: Icon(
                      Icons.mic,
                      color: _voiceCommands
                          ? const Color(0xFF1E7F5C)
                          : Colors.grey,
                    ),
                    value: _voiceCommands,
                    onChanged: (value) {
                      setState(() {
                        _voiceCommands = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF1E7F5C),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Camera Access'),
                    subtitle: const Text('Access device camera'),
                    secondary: Icon(
                      Icons.camera_alt,
                      color:
                          _cameraAccess ? const Color(0xFF1E7F5C) : Colors.grey,
                    ),
                    value: _cameraAccess,
                    onChanged: (value) {
                      setState(() {
                        _cameraAccess = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF1E7F5C),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Microphone Access'),
                    subtitle: const Text('Access device microphone'),
                    secondary: Icon(
                      Icons.mic_none,
                      color: _microphoneAccess
                          ? const Color(0xFF1E7F5C)
                          : Colors.grey,
                    ),
                    value: _microphoneAccess,
                    onChanged: (value) {
                      setState(() {
                        _microphoneAccess = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF1E7F5C),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data Management
            const Text(
              'Data Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Download My Data'),
                    subtitle: const Text('Export all your personal data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showDataDownloadDialog();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Delete My Data'),
                    subtitle:
                        const Text('Permanently remove all personal data'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showDeleteDataDialog();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Privacy History'),
                    subtitle: const Text('View privacy settings changes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to privacy history
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Privacy Policy
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Read our full privacy policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to privacy policy
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.gavel),
                    title: const Text('Terms of Service'),
                    subtitle: const Text('Read our terms of service'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to terms of service
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 4),
    );
  }

  void _showDataDownloadDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Your Data'),
          content: const Text(
            'Your data will be compiled and sent to your registered email address. This may take a few minutes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data download request sent'),
                    backgroundColor: Color(0xFF1E7F5C),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E7F5C),
              ),
              child: const Text('Request Download'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Data'),
          content: const Text(
            'This action cannot be undone. All your personal data, settings, and preferences will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data deletion request sent'),
                    backgroundColor: Color(0xFF1E7F5C),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete Data'),
            ),
          ],
        );
      },
    );
  }
}
