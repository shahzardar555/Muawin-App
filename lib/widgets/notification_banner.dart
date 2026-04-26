import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_manager.dart' as nm;

class NotificationBanner extends StatefulWidget {
  const NotificationBanner({
    super.key,
    required this.notification,
  });

  final nm.Notification notification;

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Show banner after a brief delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isVisible = true);
        _animationController.forward();
      }
    });

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismissBanner();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismissBanner() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Material(
              color: _getBannerColor(),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              elevation: 8,
              shadowColor: Colors.black26,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.notification.body,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _dismissBanner,
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
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
