import '../services/notification_manager.dart' as nm;

/// Utility to quickly add test notifications for vendor
class VendorNotificationTestHelper {
  static void addVendorTestNotifications() {
    final notificationManager = nm.NotificationManager();

    // Add different types of vendor notifications
    final testNotifications = [
      {
        'receiverId': 'vendor_456',
        'receiverType': 'vendor',
        'type': nm.NotificationType.jobRequestReceived,
        'title': 'New Job Request',
        'body': 'Customer requested emergency plumbing services',
        'priority': nm.NotificationPriority.high,
      },
      {
        'receiverId': 'vendor_456',
        'receiverType': 'vendor',
        'type': nm.NotificationType.paymentReceived,
        'title': 'Payment Received',
        'body': '\$350.00 payment for completed job',
        'priority': nm.NotificationPriority.medium,
      },
      {
        'receiverId': 'vendor_456',
        'receiverType': 'vendor',
        'type': nm.NotificationType.reviewReceived,
        'title': '5-Star Review',
        'body': 'Customer left excellent review',
        'priority': nm.NotificationPriority.medium,
      },
      {
        'receiverId': 'vendor_456',
        'receiverType': 'vendor',
        'type': nm.NotificationType.emergencySosAlert,
        'title': 'Emergency Alert',
        'body': 'Urgent service request - immediate attention needed',
        'priority': nm.NotificationPriority.emergency,
      },
      {
        'receiverId': 'vendor_456',
        'receiverType': 'vendor',
        'type': nm.NotificationType.chatMessageReceived,
        'title': 'New Message',
        'body': 'Customer sent inquiry about availability',
        'priority': nm.NotificationPriority.medium,
      },
    ];

    // Add notifications with staggered timestamps for realistic feel
    for (int i = 0; i < testNotifications.length; i++) {
      final notification = testNotifications[i];
      notificationManager.sendNotification(
        receiverId: notification['receiverId'] as String,
        receiverType: notification['receiverType'] as String,
        type: notification['type'] as nm.NotificationType,
        title: notification['title'] as String,
        body: notification['body'] as String,
        priority: notification['priority'] as nm.NotificationPriority,
      );
    }
  }

  static void clearVendorNotifications() {
    final notificationManager = nm.NotificationManager();
    notificationManager.clearAll('vendor');
  }

  static int getVendorUnreadCount() {
    final notificationManager = nm.NotificationManager();
    return notificationManager.getUnreadCount('vendor');
  }
}
