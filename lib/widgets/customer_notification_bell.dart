import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_manager.dart' as nm;

/// Customer-specific notification bell widget that matches customer home screen theme
class CustomerNotificationBell extends StatelessWidget {
  const CustomerNotificationBell({
    super.key,
    required this.receiverType,
  });

  final String receiverType;

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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF088771).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF088771).withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  size: 32, // Increased from 24 to 32
                  color: Color(0xFF088771), // Customer teal color
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 18, // Moved from 8 to 18 to move downwards
                    right: 8,
                    child: Container(
                      width: 16, // Reduced from 20 to 16
                      height: 16, // Reduced from 20 to 16
                      decoration: BoxDecoration(
                        color: const Color(0xFF047A62), // Brand green for badge
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
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
