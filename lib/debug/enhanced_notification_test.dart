import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_manager.dart' as nm;
import '../widgets/notification_tile.dart';

/// Test screen for enhanced notification UI actions
class EnhancedNotificationTest extends StatelessWidget {
  const EnhancedNotificationTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Notification Actions Test'),
        backgroundColor: const Color(0xFF047A62),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Enhanced UI Actions Test',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),

          // Job Request Notification with Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF047A62), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Job Request Notification',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                NotificationTile(
                  notification: nm.Notification(
                    id: 'job_req_1',
                    title: 'New Job Request: Plumbing Repair',
                    body:
                        'Customer needs urgent plumbing repair for kitchen sink',
                    timestamp:
                        DateTime.now().subtract(const Duration(minutes: 5)),
                    type: nm.NotificationType.jobRequestReceived,
                    priority: nm.NotificationPriority.urgent,
                    isRead: false,
                    senderId: 'customer_123',
                    receiverId: 'provider_456',
                    receiverType: 'provider',
                    category: nm.NotificationCategory.jobs,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Tapped job request notification')),
                    );
                  },
                  onDelete: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Deleted job request notification')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Notification with Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Notification',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                NotificationTile(
                  notification: nm.Notification(
                    id: 'payment_1',
                    title: 'Payment Received: \$150.00',
                    body:
                        'Payment for completed plumbing job has been received',
                    timestamp:
                        DateTime.now().subtract(const Duration(hours: 1)),
                    type: nm.NotificationType.paymentReceived,
                    priority: nm.NotificationPriority.medium,
                    isRead: false,
                    senderId: 'customer_123',
                    receiverId: 'provider_456',
                    receiverType: 'provider',
                    category: nm.NotificationCategory.payments,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Tapped payment notification')),
                    );
                  },
                  onDelete: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Deleted payment notification')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Emergency Notification with Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Notification',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                NotificationTile(
                  notification: nm.Notification(
                    id: 'emergency_1',
                    title: 'Emergency SOS Alert',
                    body: 'Emergency assistance requested at customer location',
                    timestamp:
                        DateTime.now().subtract(const Duration(minutes: 2)),
                    type: nm.NotificationType.emergencySosAlert,
                    priority: nm.NotificationPriority.emergency,
                    isRead: false,
                    senderId: 'customer_123',
                    receiverId: 'provider_456',
                    receiverType: 'provider',
                    category: nm.NotificationCategory.alerts,
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Tapped emergency notification')),
                    );
                  },
                  onDelete: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Deleted emergency notification')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Instructions:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Tap on any notification to see action buttons',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '2. Action buttons appear below notification content',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '3. Tap action buttons to trigger modal bottom sheet',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '4. Different notification types show different actions',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
