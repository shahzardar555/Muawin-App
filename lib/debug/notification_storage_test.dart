import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_manager.dart' as nm;

class NotificationStorageTest extends StatelessWidget {
  const NotificationStorageTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<nm.NotificationManager>(
      builder: (context, notificationManager, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Storage Test'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Customer: ${notificationManager.customerNotifications.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Provider: ${notificationManager.providerNotifications.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vendor: ${notificationManager.vendorNotifications.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    notificationManager.sendNotification(
                      receiverId: 'test_user',
                      receiverType: 'customer',
                      type: nm.NotificationType.jobRequestReceived,
                      title: 'Test Notification',
                      body: 'This is a test notification for storage',
                      priority: nm.NotificationPriority.high,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Test notification sent')),
                    );
                  },
                  child: const Text('Send Test Notification'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    notificationManager.markAllAsRead('customer');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked all as read')),
                    );
                  },
                  child: const Text('Mark All Read'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    notificationManager.clearAll('customer');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cleared all notifications')),
                    );
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
