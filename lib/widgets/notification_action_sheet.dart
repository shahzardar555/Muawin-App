import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_manager.dart' as nm;
import '../utils/haptic_feedback.dart';
import 'notification_action_button.dart';

/// Modal bottom sheet for notification actions
class NotificationActionSheet extends StatelessWidget {
  const NotificationActionSheet({
    super.key,
    required this.notification,
    required this.onAction,
  });

  final nm.Notification notification;
  final Function(String action) onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Notification Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Action buttons based on notification type
            _buildActionButtons(context),

            // Close button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: NotificationActionButton(
                label: 'Close',
                color: Colors.grey[600]!,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (notification.type) {
      case nm.NotificationType.jobRequestReceived:
        return _buildJobActions(context);
      case nm.NotificationType.paymentReceived:
        return _buildPaymentActions(context);
      case nm.NotificationType.reviewReceived:
        return _buildReviewActions(context);
      case nm.NotificationType.emergencySosAlert:
        return _buildEmergencyActions(context);
      case nm.NotificationType.chatMessageReceived:
        return _buildChatActions(context);
      case nm.NotificationType.callIncoming:
        return _buildCallActions(context);
      default:
        return _buildDefaultActions(context);
    }
  }

  Widget _buildJobActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          NotificationActionButton(
            label: 'Accept Job',
            color: Colors.green,
            icon: Icons.check_circle_rounded,
            onPressed: () => onAction('accept_job'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'Decline Job',
            color: Colors.red,
            icon: Icons.cancel_rounded,
            onPressed: () => onAction('decline_job'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'Negotiate',
            color: Colors.blue,
            icon: Icons.handshake_rounded,
            onPressed: () => onAction('negotiate_job'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'View Job Details',
            color: const Color(0xFF047A62),
            icon: Icons.visibility_rounded,
            onPressed: () => onAction('view_job_details'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          NotificationActionButton(
            label: 'View Details',
            color: const Color(0xFF047A62),
            icon: Icons.visibility_rounded,
            onPressed: () => onAction('view_payment_details'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'Download Receipt',
            color: Colors.green,
            icon: Icons.download_rounded,
            onPressed: () => onAction('download_receipt'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'Report Issue',
            color: Colors.orange,
            icon: Icons.report_rounded,
            onPressed: () => onAction('report_payment_issue'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          NotificationActionButton(
            label: 'View Review',
            color: const Color(0xFF047A62),
            icon: Icons.star_rounded,
            onPressed: () => onAction('view_review'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'Reply to Review',
            color: Colors.blue,
            icon: Icons.reply_rounded,
            onPressed: () => onAction('reply_review'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'Report Review',
            color: Colors.red,
            icon: Icons.flag_rounded,
            onPressed: () => onAction('report_review'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          NotificationActionButton(
            label: 'Call Emergency Services',
            color: Colors.red,
            icon: Icons.emergency_rounded,
            onPressed: () => onAction('call_emergency'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'View Location',
            color: Colors.orange,
            icon: Icons.location_on_rounded,
            onPressed: () => onAction('view_location'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'Contact Help',
            color: const Color(0xFF047A62),
            icon: Icons.help_rounded,
            onPressed: () => onAction('contact_help'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          NotificationActionButton(
            label: 'Reply to Message',
            color: const Color(0xFF047A62),
            icon: Icons.reply_rounded,
            onPressed: () => onAction('reply_chat'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'View Profile',
            color: Colors.blue,
            icon: Icons.person_rounded,
            onPressed: () => onAction('view_profile'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'Block User',
            color: Colors.red,
            icon: Icons.block_rounded,
            onPressed: () => onAction('block_user'),
          ),
        ],
      ),
    );
  }

  Widget _buildCallActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          NotificationActionButton(
            label: 'Call Back',
            color: Colors.green,
            icon: Icons.call_rounded,
            onPressed: () => onAction('call_back'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'View Profile',
            color: const Color(0xFF047A62),
            icon: Icons.person_rounded,
            onPressed: () => onAction('view_caller_profile'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'Block Number',
            color: Colors.red,
            icon: Icons.block_rounded,
            onPressed: () => onAction('block_caller'),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          NotificationActionButton(
            label: 'View Details',
            color: const Color(0xFF047A62),
            icon: Icons.visibility_rounded,
            onPressed: () => onAction('view_details'),
          ),
          const SizedBox(height: 8),
          NotificationActionButton(
            label: 'Mark as Read',
            color: Colors.grey[600]!,
            icon: Icons.check_rounded,
            onPressed: () => onAction('mark_read'),
          ),
        ],
      ),
    );
  }
}
