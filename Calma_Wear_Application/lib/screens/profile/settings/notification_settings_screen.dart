import 'package:flutter/material.dart';

class NotificationSettingScreen extends StatefulWidget {
  const NotificationSettingScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingScreen> createState() =>
      _NotificationSettingScreenState();
}

class _NotificationSettingScreenState extends State<NotificationSettingScreen> {
  // State variables for notification preferences
  bool _stressAlerts = true;
  bool _dailyReports = true;
  bool _communityUpdates = true;
  bool _chatResponses = false;
  bool _plannerReminders = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  String _stressAlertFrequency = 'Immediate';
  String _dailyReportTime = '8:00 PM';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.black,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Notification Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Settings Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: <Widget>[
                  // Alert Types Section
                  _buildSectionHeader('Alert Types'),
                  _buildSwitchTile(
                    icon: Icons.warning_amber_rounded,
                    title: 'Stress Alerts',
                    subtitle: 'Get notified when stress levels are high',
                    value: _stressAlerts,
                    onChanged: (value) => setState(() => _stressAlerts = value),
                  ),
                  if (_stressAlerts)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 72,
                        right: 16,
                        bottom: 8,
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _stressAlertFrequency,
                        decoration: InputDecoration(
                          labelText: 'Alert Frequency',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: ['Immediate', 'Every 15 min', 'Hourly']
                            .map(
                              (freq) => DropdownMenuItem(
                                value: freq,
                                child: Text(freq),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _stressAlertFrequency = value);
                          }
                        },
                      ),
                    ),

                  _buildSwitchTile(
                    icon: Icons.people,
                    title: 'Community Updates',
                    subtitle: 'New stories, events, and comments',
                    value: _communityUpdates,
                    onChanged: (value) =>
                        setState(() => _communityUpdates = value),
                  ),
                  _buildSwitchTile(
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat Responses',
                    subtitle: 'AI assistant conversation updates',
                    value: _chatResponses,
                    onChanged: (value) =>
                        setState(() => _chatResponses = value),
                  ),
                  _buildSwitchTile(
                    icon: Icons.task_alt,
                    title: 'Planner Reminders',
                    subtitle: 'Task and todo notifications',
                    value: _plannerReminders,
                    onChanged: (value) =>
                        setState(() => _plannerReminders = value),
                  ),

                  const Divider(height: 32, thickness: 1),

                  // Notification Channels Section
                  _buildSectionHeader('Notification Channels'),
                  _buildSwitchTile(
                    icon: Icons.notifications_active,
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications on this device',
                    value: _pushNotifications,
                    onChanged: (value) =>
                        setState(() => _pushNotifications = value),
                  ),
                  _buildSwitchTile(
                    icon: Icons.email_outlined,
                    title: 'Email Notifications',
                    subtitle: 'Receive notifications via email',
                    value: _emailNotifications,
                    onChanged: (value) =>
                        setState(() => _emailNotifications = value),
                  ),

                  const Divider(height: 32, thickness: 1),

                  // Sound & Vibration Section
                  _buildSectionHeader('Sound & Vibration'),
                  _buildSwitchTile(
                    icon: Icons.volume_up,
                    title: 'Sound',
                    subtitle: 'Play sound for notifications',
                    value: _soundEnabled,
                    onChanged: (value) => setState(() => _soundEnabled = value),
                  ),
                  _buildSwitchTile(
                    icon: Icons.vibration,
                    title: 'Vibration',
                    subtitle: 'Vibrate for notifications',
                    value: _vibrationEnabled,
                    onChanged: (value) =>
                        setState(() => _vibrationEnabled = value),
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notification settings saved'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Save Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0066FF),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.blue[700]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.blue,
    );
  }
}
