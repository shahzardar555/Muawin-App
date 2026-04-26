import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_manager.dart' as nm;

/// Service Provider-specific notification bell widget that matches existing design
class ServiceProviderNotificationBell extends StatelessWidget {
  const ServiceProviderNotificationBell({
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
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_rounded,
                  size: 32,
                  color: Color(0xFFFFD977), // Yellow bell icon (matches existing)
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
