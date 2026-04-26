import '../services/notification_manager.dart' as nm;

/// Utility to quickly add test notifications for customer
class CustomerNotificationTestHelper {
  static void addCustomerTestNotifications() {
    final notificationManager = nm.NotificationManager();

    // Add different types of customer notifications
    final testNotifications = [
      {
        'receiverId': 'customer_789',
        'receiverType': 'customer',
        'type': nm.NotificationType.jobRequestAccepted,
        'title': 'Job Request Accepted',
        'body': 'Provider accepted your plumbing repair request',
        'priority': nm.NotificationPriority.high,
      },
      {
        'receiverId': 'customer_789',
        'receiverType': 'customer',
        'type': nm.NotificationType.jobScheduled,
        'title': 'Job Scheduled',
        'body': 'Your service has been scheduled for tomorrow at 2 PM',
        'priority': nm.NotificationPriority.medium,
      },
      {
        'receiverId': 'customer_789',
        'receiverType': 'customer',
        'type': nm.NotificationType.jobCompleted,
        'title': 'Job Completed',
        'body': 'Provider has completed the plumbing service',
        'priority': nm.NotificationPriority.medium,
      },
      {
        'receiverId': 'customer_789',
        'receiverType': 'customer',
        'type': nm.NotificationType.paymentReceived,
        'title': 'Payment Request',
        'body': 'Please confirm payment for completed service',
        'priority': nm.NotificationPriority.urgent,
      },
      {
        'receiverId': 'customer_789',
        'receiverType': 'customer',
        'type': nm.NotificationType.chatMessageReceived,
        'title': 'New Message',
        'body': 'Provider sent you a message about job details',
        'priority': nm.NotificationPriority.medium,
      },
      {
        'receiverId': 'customer_789',
        'receiverType': 'customer',
        'type': nm.NotificationType.ratingReceived,
        'title': 'Review Request',
        'body': 'Please rate your service experience',
        'priority': nm.NotificationPriority.medium,
      },
      {
        'receiverId': 'customer_789',
        'receiverType': 'customer',
        'type': nm.NotificationType.emergencySosResolved,
        'title': 'Emergency Resolved',
        'body': 'Your emergency service request has been resolved',
        'priority': nm.NotificationPriority.urgent,
      },
    ];

    // Add notifications
    for (final notification in testNotifications) {
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

  static void clearCustomerNotifications() {
    final notificationManager = nm.NotificationManager();
    notificationManager.clearAll('customer');
  }

  static int getCustomerUnreadCount() {
    final notificationManager = nm.NotificationManager();
    return notificationManager.getUnreadCount('customer');
  }
}
