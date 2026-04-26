import 'package:flutter/material.dart';
import '../services/notification_manager.dart' as nm;
import '../services/emergency_banner_service.dart';

/// Example of how to integrate EmergencyBannerService in your main app
class EmergencyBannerIntegrationExample extends StatelessWidget {
  const EmergencyBannerIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Banner Demo',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Emergency Banner Integration'),
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Emergency Banner Service Integration Example',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '1. Initialize EmergencyBannerService in main app',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '2. EmergencyBannerService().initialize(navigatorKey)',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '3. Emergency notifications will auto-display as overlays',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      nm.NotificationManager().sendNotification(
                        receiverId: 'test_user',
                        receiverType: 'provider',
                        type: nm.NotificationType.emergencySosAlert,
                        title: 'Emergency Alert',
                        body: 'This is an emergency test notification',
                        priority: nm.NotificationPriority.emergency,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Send Emergency'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      nm.NotificationManager().sendNotification(
                        receiverId: 'test_user',
                        receiverType: 'provider',
                        type: nm.NotificationType.jobRequestReceived,
                        title: 'Urgent Alert',
                        body: 'This is an urgent test notification',
                        priority: nm.NotificationPriority.urgent,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Send Urgent'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      EmergencyBannerService().dismissAllBanners();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('All emergency banners dismissed')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Dismiss All'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Active: ${EmergencyBannerService().activeBannerCount}')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Show Active Count'),
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
