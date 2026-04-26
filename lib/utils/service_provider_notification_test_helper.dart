import '../services/notification_manager.dart' as nm;

/// Utility to quickly add test notifications for service provider
class ServiceProviderNotificationTestHelper {
  static void addServiceProviderTestNotifications() {
    final notificationManager = nm.NotificationManager();
    
    // Add different types of service provider notifications
    final testNotifications = [
      {
        'receiverId': 'provider_123',
        'receiverType': 'provider',
        'type': nm.NotificationType.jobRequestReceived,
        'title': 'New Job Request',
        'body': 'Customer requested home repair services',
        'priority': nm.NotificationPriority.high,
      },
      {
        'receiverId': 'provider_123',
        'receiverType': 'provider',
        'type': nm.NotificationType.paymentReceived,
        'title': 'Payment Received',
        'body': '\$450.00 payment for completed plumbing job',
        'priority': nm.NotificationPriority.medium,
      },
      {
        'receiverId': 'provider_123',
        'receiverType': 'provider',
        'type': nm.NotificationType.reviewReceived,
        'title': 'New Review Posted',
        'body': 'Customer left 4-star review for your service',
        'priority': nm.NotificationPriority.medium,
      },
      {
        'receiverId': 'provider_123',
        'receiverType': 'provider',
        'type': nm.NotificationType.jobScheduled,
        'title': 'Job Scheduled',
        'body': 'Electrical repair job scheduled for tomorrow',
        'priority': nm.NotificationPriority.medium,
      },
      {
        'receiverId': 'provider_123',
        'receiverType': 'provider',
        'type': nm.NotificationType.chatMessageReceived,
        'title': 'New Message',
        'body': 'Customer asking about service availability',
        'priority': nm.NotificationPriority.medium,
      },
      {
        'receiverId': 'provider_123',
        'receiverType': 'provider',
        'type': nm.NotificationType.emergencySosAlert,
        'title': 'Emergency Service Request',
        'body': 'Urgent plumbing emergency - immediate response needed',
        'priority': nm.NotificationPriority.emergency,
      },
      {
        'receiverId': 'provider_123',
        'receiverType': 'provider',
        'type': nm.NotificationType.profileVerificationApproved,
        'title': 'Profile Verified',
        'body': 'Your service provider profile has been verified',
        'priority': nm.NotificationPriority.medium,
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

  static void clearServiceProviderNotifications() {
    final notificationManager = nm.NotificationManager();
    notificationManager.clearAll('provider');
  }

  static int getServiceProviderUnreadCount() {
    final notificationManager = nm.NotificationManager();
    return notificationManager.getUnreadCount('provider');
  }
}
