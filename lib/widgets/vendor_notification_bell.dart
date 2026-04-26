import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_manager.dart' as nm;

/// Vendor-specific notification bell widget that matches vendor home screen theme
class VendorNotificationBell extends StatelessWidget {
  const VendorNotificationBell({
    super.key,
    required this.receiverType,
    required this.onPrimary,
  });

  final String receiverType;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Consumer<nm.NotificationManager>(
      builder: (context, notificationManager, child) {
        final unreadCount = notificationManager.getUnreadCount(receiverType);

        return GestureDetector(
          onTap: () {
            Navigator.of(context)
                .pushNamed('/notifications', arguments: receiverType);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: onPrimary.withValues(alpha: 0.15), // Semi-transparent background
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: onPrimary.withValues(alpha: 0.3), // Subtle border
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_rounded,
                  size: 20,
                  color: onPrimary, // Use onPrimary color for icon
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF047A62), // Brand green for badge
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: onPrimary.withValues(alpha: 0.9), // Border matches theme
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
