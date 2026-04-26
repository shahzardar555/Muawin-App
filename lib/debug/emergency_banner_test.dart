import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_manager.dart' as nm;
import '../services/emergency_banner_service.dart';

class EmergencyBannerTest extends StatelessWidget {
  const EmergencyBannerTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<nm.NotificationManager>(
      builder: (context, notificationManager, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Emergency Banner Test'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Active Banners: ${EmergencyBannerService().activeBannerCount}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Queued Banners: ${EmergencyBannerService().queuedBannerCount}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Send emergency notification
                    notificationManager.sendNotification(
                      receiverId: 'test_user',
                      receiverType: 'provider',
                      type: nm.NotificationType.emergencySosAlert,
                      title: 'Emergency Test',
                      body: 'This is a test emergency notification',
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
                    // Send urgent notification
                    notificationManager.sendNotification(
                      receiverId: 'test_user',
                      receiverType: 'provider',
                      type: nm.NotificationType.jobRequestReceived,
                      title: 'Urgent Test',
                      body: 'This is a test urgent notification',
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
                    // Initialize emergency banner service
                    EmergencyBannerService().initialize(GlobalKey<NavigatorState>());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Emergency banner service initialized')),
                    );
                  },
                  child: const Text('Initialize Emergency Service'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Dismiss all banners
                    EmergencyBannerService().dismissAllBanners();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All banners dismissed')),
                    );
                  },
                  child: const Text('Dismiss All Banners'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
