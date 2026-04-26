import 'package:flutter/material.dart';
import '../services/notification_manager.dart' as nm;

/// Test screen for notification settings and sound/haptic feedback
class NotificationSettingsTest extends StatelessWidget {
  const NotificationSettingsTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings Test'),
        backgroundColor: const Color(0xFF047A62),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                nm.NotificationManager().sendNotification(
                  receiverId: 'test_user',
                  receiverType: 'provider',
                  type: nm.NotificationType.emergencySosAlert,
                  title: 'Emergency Test',
                  body: 'This should trigger haptic feedback and sound',
                  priority: nm.NotificationPriority.emergency,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency notification sent!')),
                );
              },
              child: const Text('Send Emergency Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                nm.NotificationManager().sendNotification(
                  receiverId: 'test_user',
                  receiverType: 'provider',
                  type: nm.NotificationType.jobRequestReceived,
                  title: 'Urgent Test',
                  body: 'This should trigger medium haptic feedback',
                  priority: nm.NotificationPriority.urgent,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Urgent notification sent!')),
                );
              },
              child: const Text('Send Urgent Notification'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/notification_settings');
              },
              child: const Text('Open Settings Screen'),
            ),
          ],
        ),
      ),
    );
  }
}
