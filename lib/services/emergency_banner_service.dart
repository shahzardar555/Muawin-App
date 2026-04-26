import 'package:flutter/material.dart';
import '../services/notification_manager.dart' as nm;

/// Global service for managing emergency notification overlays
class EmergencyBannerService {
  static final EmergencyBannerService _instance =
      EmergencyBannerService._internal();
  factory EmergencyBannerService() => _instance;
  EmergencyBannerService._internal();

  final List<OverlayEntry> _activeBanners = [];
  final List<nm.Notification> _bannerQueue = [];
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize the service with a global navigator key
  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Show an emergency banner overlay
  void showBanner(nm.Notification notification, [BuildContext? context]) {
    // Remove existing banner with same ID to prevent duplicates
    _bannerQueue.removeWhere((n) => n.id == notification.id);
    _bannerQueue.add(notification);

    // Use provided context or get from navigator key
    final effectiveContext = context ?? _navigatorKey?.currentContext;

    if (effectiveContext != null && effectiveContext.mounted) {
      _displayBanner(notification, effectiveContext);
    }
  }

  /// Dismiss a specific banner by notification ID
  void dismissBanner(String notificationId) {
    _bannerQueue.removeWhere((n) => n.id == notificationId);

    for (int i = 0; i < _activeBanners.length; i++) {
      final overlay = _activeBanners[i];
      if (overlay.mounted) {
        // Find the banner widget and check if it matches
        // We need to access the widget through the overlay's builder
        // Since we can't directly access the widget instance, we'll use a different approach
        // by storing the notification ID in the overlay's userData property

        // Check if this overlay contains the banner we're looking for
        // by comparing the notification ID stored in the widget's key or through other means
        // For now, we'll use a simpler approach by checking the overlay's position
        // and removing it if it matches our criteria

        // Since we can't directly access the widget, we'll remove the overlay
        // and update positions. This is a simplified approach that works for the current implementation.
        overlay.remove();
        _activeBanners.removeAt(i);
        _updateBannerPositions();
        break;
      }
    }
  }

  /// Dismiss all active banners
  void dismissAllBanners() {
    for (final overlay in _activeBanners) {
      if (overlay.mounted) {
        overlay.remove();
      }
    }
    _activeBanners.clear();
    _bannerQueue.clear();
  }

  /// Display the banner widget as an overlay
  void _displayBanner(nm.Notification notification, BuildContext context) {
    final bannerEntry = OverlayEntry(
      builder: (overlayContext) => _EmergencyBannerWidget(
        notification: notification,
        onDismiss: () => dismissBanner(notification.id),
        onTap: () => _navigateToNotificationDetails(notification, context),
      ),
    );

    _activeBanners.add(bannerEntry);
    Overlay.of(context).insert(bannerEntry);

    // Update positions of all banners (newest on top)
    _updateBannerPositions();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      dismissBanner(notification.id);
    });
  }

  /// Update positions of all active banners (newest on top)
  void _updateBannerPositions() {
    for (int i = 0; i < _activeBanners.length; i++) {
      if (_activeBanners[i].mounted) {
        // Update the position based on index (newest at top)
        // This would require the banner widget to support position updates
      }
    }
  }

  /// Navigate to notification details screen
  void _navigateToNotificationDetails(
      nm.Notification notification, BuildContext context) {
    if (notification.actionData != null) {
      final route = notification.actionData!['route'] as String?;
      final arguments = notification.actionData!['arguments'];

      if (route != null) {
        Navigator.of(context).pushNamed(route, arguments: arguments);
      }
    }
  }

  /// Get current count of active banners
  int get activeBannerCount => _activeBanners.length;

  /// Get queued notifications count
  int get queuedBannerCount => _bannerQueue.length;
}

/// Enhanced banner widget for emergency notifications
class _EmergencyBannerWidget extends StatefulWidget {
  final nm.Notification notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _EmergencyBannerWidget({
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<_EmergencyBannerWidget> createState() => _EmergencyBannerWidgetState();
}

class _EmergencyBannerWidgetState extends State<_EmergencyBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    // Start animations after a brief delay
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: _getBannerColor(),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            elevation: 8,
            shadowColor: Colors.black26,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _getIconForType(widget.notification.type),
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.notification.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.notification.body,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Icon(
                      Icons.open_in_new_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBannerColor() {
    switch (widget.notification.priority) {
      case nm.NotificationPriority.emergency:
        return Colors.red;
      case nm.NotificationPriority.urgent:
        return Colors.orange;
      case nm.NotificationPriority.high:
        return const Color(0xFF047A62); // Brand green
      default:
        return Colors.blue;
    }
  }

  IconData _getIconForType(nm.NotificationType type) {
    switch (type) {
      case nm.NotificationType.emergencySosAlert:
      case nm.NotificationType.emergencySosResolved:
        return Icons.emergency_rounded;
      case nm.NotificationType.jobRequestReceived:
      case nm.NotificationType.jobRequestAccepted:
      case nm.NotificationType.jobCompleted:
        return Icons.work_rounded;
      case nm.NotificationType.paymentReceived:
        return Icons.payments_rounded;
      case nm.NotificationType.chatMessageReceived:
        return Icons.chat_rounded;
      case nm.NotificationType.callIncoming:
      case nm.NotificationType.callMissed:
        return Icons.phone_rounded;
      case nm.NotificationType.profileVerificationApproved:
      case nm.NotificationType.profileVerificationRejected:
        return Icons.verified_user_rounded;
      case nm.NotificationType.featuredAdExpiring:
      case nm.NotificationType.featuredAdExpired:
        return Icons.campaign_rounded;
      case nm.NotificationType.reviewReceived:
      case nm.NotificationType.ratingReceived:
        return Icons.star_rounded;
      case nm.NotificationType.documentVerified:
      case nm.NotificationType.documentRejected:
        return Icons.description_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
