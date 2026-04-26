import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_manager.dart' as nm;

class NotificationBell extends StatelessWidget {
  const NotificationBell({
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF047A62), // Brand green
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
