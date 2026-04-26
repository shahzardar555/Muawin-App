import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_manager.dart' as nm;
import '../widgets/vendor_notification_bell.dart';

/// Test screen to verify vendor notification badge functionality
class VendorNotificationBadgeTest extends StatefulWidget {
  const VendorNotificationBadgeTest({super.key});

  @override
  State<VendorNotificationBadgeTest> createState() =>
      _VendorNotificationBadgeTestState();
}

class _VendorNotificationBadgeTestState
    extends State<VendorNotificationBadgeTest> {
  final nm.NotificationManager _notificationManager = nm.NotificationManager();

  @override
  void initState() {
    super.initState();
    // Add some test notifications when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addTestNotifications();
    });
  }

  void _addTestNotifications() {
    final now = DateTime.now();

    // Add various types of test notifications for vendor
    final testNotifications = [
      nm.Notification(
        id: 'vendor_test_1',
        title: 'New Job Request',
        body: 'Customer requested plumbing services',
        timestamp: now.subtract(const Duration(minutes: 5)),
        type: nm.NotificationType.jobRequestReceived,
        priority: nm.NotificationPriority.high,
        isRead: false,
        senderId: 'customer_123',
        receiverId: 'vendor_456',
        receiverType: 'vendor',
        category: nm.NotificationCategory.jobs,
      ),
      nm.Notification(
        id: 'vendor_test_2',
        title: 'Payment Received',
        body: '\$250.00 payment received for completed job',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: nm.NotificationType.paymentReceived,
        priority: nm.NotificationPriority.medium,
        isRead: false,
        senderId: 'customer_789',
        receiverId: 'vendor_456',
        receiverType: 'vendor',
        category: nm.NotificationCategory.payments,
      ),
      nm.Notification(
        id: 'vendor_test_3',
        title: 'New Review Posted',
        body: 'Customer left a 5-star review',
        timestamp: now.subtract(const Duration(hours: 4)),
        type: nm.NotificationType.reviewReceived,
        priority: nm.NotificationPriority.medium,
        isRead: false,
        senderId: 'customer_101',
        receiverId: 'vendor_456',
        receiverType: 'vendor',
        category: nm.NotificationCategory.reviews,
      ),
      nm.Notification(
        id: 'vendor_test_4',
        title: 'Emergency Service Request',
        body: 'Urgent plumbing emergency - immediate response needed',
        timestamp: now.subtract(const Duration(minutes: 30)),
        type: nm.NotificationType.emergencySosAlert,
        priority: nm.NotificationPriority.emergency,
        isRead: false,
        senderId: 'customer_202',
        receiverId: 'vendor_456',
        receiverType: 'vendor',
        category: nm.NotificationCategory.alerts,
      ),
      nm.Notification(
        id: 'vendor_test_5',
        title: 'Profile Verification Approved',
        body: 'Your business profile has been verified',
        timestamp: now.subtract(const Duration(days: 1)),
        type: nm.NotificationType.profileVerificationApproved,
        priority: nm.NotificationPriority.medium,
        isRead: true, // This one is read
        senderId: 'system',
        receiverId: 'vendor_456',
        receiverType: 'vendor',
        category: nm.NotificationCategory.verification,
      ),
      nm.Notification(
        id: 'vendor_test_6',
        title: 'Featured Ad Activated',
        body: 'Your featured advertisement is now live',
        timestamp: now.subtract(const Duration(hours: 6)),
        type: nm.NotificationType.featuredAdActivated,
        priority: nm.NotificationPriority.medium,
        isRead: false,
        senderId: 'system',
        receiverId: 'vendor_456',
        receiverType: 'vendor',
        category: nm.NotificationCategory.ads,
      ),
      nm.Notification(
        id: 'vendor_test_7',
        title: 'Chat Message Received',
        body: 'Customer sent you a message about job details',
        timestamp: now.subtract(const Duration(minutes: 15)),
        type: nm.NotificationType.chatMessageReceived,
        priority: nm.NotificationPriority.medium,
        isRead: false,
        senderId: 'customer_303',
        receiverId: 'vendor_456',
        receiverType: 'vendor',
        category: nm.NotificationCategory.chat,
      ),
    ];

    // Add all test notifications
    for (final notification in testNotifications) {
      _notificationManager.sendNotification(
        receiverId: notification.receiverId,
        receiverType: notification.receiverType,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        priority: notification.priority,
      );
    }

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added 7 test notifications (6 unread)'),
          backgroundColor: Color(0xFF047A62),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _clearTestNotifications() {
    _notificationManager.clearAll('vendor');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All test notifications cleared'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _markAllAsRead() {
    _notificationManager.markAllAsRead('vendor');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  int _getUnreadCount() {
    return _notificationManager.getUnreadCount('vendor');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Notification Badge Test'),
        backgroundColor: const Color(0xFF047A62),
        actions: const [
          // Show the notification bell in the app bar for testing
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: VendorNotificationBell(
              receiverType: 'vendor',
              onPrimary: Colors.white,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Vendor Notification Badge Test',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),

          // Current status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF047A62).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF047A62), width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'Current Status',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF047A62),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Large notification bell for testing
                    const VendorNotificationBell(
                      receiverType: 'vendor',
                      onPrimary: Color(0xFF047A62),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unread Count',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${_getUnreadCount()}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF047A62),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Test notifications added
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Notifications Added:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                ...[
                  '✅ New Job Request (High Priority)',
                  '✅ Payment Received (\$250)',
                  '✅ 5-Star Review Posted',
                  '✅ Emergency Service Request',
                  '✅ Featured Ad Activated',
                  '✅ Chat Message Received',
                  '✅ Profile Verification (Already Read)',
                ].map((notification) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        notification,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _addTestNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047A62),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Add More Test Notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _markAllAsRead,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Mark All Read',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _clearTestNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Clear All Notifications',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  'Testing Instructions:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  '1. Look at the notification bell in the app bar (top right)',
                  '2. Badge should show "6" for unread notifications',
                  '3. Tap the bell to navigate to NotificationScreen',
                  '4. Use "Mark All Read" to clear the badge',
                  '5. Use "Add More" to test with larger numbers',
                  '6. Use "Clear All" to reset to zero',
                ].map((instruction) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        instruction,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
