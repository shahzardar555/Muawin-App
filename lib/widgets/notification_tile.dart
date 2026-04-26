import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_manager.dart' as nm;
import '../utils/time_ago.dart';
import 'notification_action_button.dart';
import 'notification_action_sheet.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final nm.Notification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final iconData = _getIconForType(notification.type);
    final iconColor = _getColorForType(notification.type);
    final cardColor = isUnread
        ? iconColor.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.05);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: isUnread
                ? Border.all(color: iconColor.withValues(alpha: 0.3), width: 1)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  iconData,
                  size: 24,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _buildActionButtons(context),
                    Row(
                      children: [
                        Text(
                          getTimeAgo(notification.timestamp),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (isUnread) {
                              onTap();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isUnread ? 'Mark as read' : 'Read',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isUnread ? iconColor : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    switch (notification.type) {
      case nm.NotificationType.jobRequestReceived:
        return _buildJobRequestActions(context);
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
        return const SizedBox.shrink();
    }
  }

  Widget _buildJobRequestActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        NotificationActionButton(
          label: 'Accept',
          color: Colors.green,
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'Decline',
          color: Colors.red,
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'Negotiate',
          color: Colors.blue,
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'Details',
          color: Colors.grey[600]!,
          onPressed: () => _showActionSheet(context),
        ),
      ],
    );
  }

  Widget _buildPaymentActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        NotificationActionButton(
          label: 'View Details',
          color: const Color(0xFF047A62),
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'Receipt',
          color: Colors.green,
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'Report Issue',
          color: Colors.orange,
          onPressed: () => _showActionSheet(context),
        ),
      ],
    );
  }

  Widget _buildReviewActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        NotificationActionButton(
          label: 'View Review',
          color: const Color(0xFF047A62),
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'Reply',
          color: Colors.blue,
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'Report',
          color: Colors.red,
          onPressed: () => _showActionSheet(context),
        ),
      ],
    );
  }

  Widget _buildEmergencyActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        NotificationActionButton(
          label: 'Call Emergency',
          color: Colors.red,
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'View Location',
          color: Colors.orange,
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'Contact Help',
          color: const Color(0xFF047A62),
          onPressed: () => _showActionSheet(context),
        ),
      ],
    );
  }

  Widget _buildChatActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        NotificationActionButton(
          label: 'Reply',
          color: const Color(0xFF047A62),
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'View Profile',
          color: Colors.blue,
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'Block User',
          color: Colors.red,
          onPressed: () => _showActionSheet(context),
        ),
      ],
    );
  }

  Widget _buildCallActions(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        NotificationActionButton(
          label: 'Call Back',
          color: Colors.green,
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'View Profile',
          color: const Color(0xFF047A62),
          onPressed: () => _showActionSheet(context),
        ),
        NotificationActionButton(
          label: 'Block Number',
          color: Colors.red,
          onPressed: () => _showActionSheet(context),
        ),
      ],
    );
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NotificationActionSheet(
        notification: notification,
        onAction: (action) {
          Navigator.of(context).pop();
          _handleAction(action);
        },
      ),
    );
  }

  void _handleAction(String action) {
    // Handle different actions based on notification type and action
    switch (action) {
      case 'accept_job':
        // Navigate to job details with accepted status
        break;
      case 'decline_job':
        // Update job status, show confirmation
        break;
      case 'negotiate_job':
        // Open negotiation screen/dialog
        break;
      case 'view_job_details':
        // Navigate to job details screen
        break;
      case 'view_payment_details':
        // Navigate to payment details screen
        break;
      case 'download_receipt':
        // Generate and download PDF receipt
        break;
      case 'report_payment_issue':
        // Open dispute resolution screen
        break;
      case 'view_review':
        // Navigate to review details
        break;
      case 'reply_review':
        // Open reply dialog/screen
        break;
      case 'report_review':
        // Open report violation screen
        break;
      case 'call_emergency':
        // Initiate emergency call
        break;
      case 'view_location':
        // Show map with emergency location
        break;
      case 'contact_help':
        // Open emergency contact screen
        break;
      case 'reply_chat':
        // Open messaging screen with user
        break;
      case 'view_profile':
        // Navigate to user profile
        break;
      case 'block_user':
        // Show block confirmation dialog
        break;
      case 'call_back':
        // Initiate return call
        break;
      case 'view_caller_profile':
        // Navigate to caller profile
        break;
      case 'block_caller':
        // Show block confirmation dialog
        break;
    }
  }

  IconData _getIconForType(nm.NotificationType type) {
    switch (type) {
      // Jobs → briefcase icon → blue
      case nm.NotificationType.jobRequestSent:
      case nm.NotificationType.jobRequestReceived:
      case nm.NotificationType.jobRequestAccepted:
      case nm.NotificationType.jobCompleted:
      case nm.NotificationType.jobScheduled:
      case nm.NotificationType.jobReminder:
      case nm.NotificationType.jobStarted:
      case nm.NotificationType.jobCancelled:
      case nm.NotificationType.jobRescheduled:
      case nm.NotificationType.bookingConfirmed:
      case nm.NotificationType.bookingReminder:
      case nm.NotificationType.newOfferReceived:
        return Icons.work_rounded;

      // Payments → money icon → green
      case nm.NotificationType.paymentSent:
      case nm.NotificationType.paymentReceived:
        return Icons.payments_rounded;
      case nm.NotificationType.paymentFailed:
      case nm.NotificationType.paymentRefunded:
        return Icons.error_rounded;

      // Reviews → star icon → amber
      case nm.NotificationType.reviewReceived:
      case nm.NotificationType.ratingReceived:
        return Icons.star_rounded;

      // Chat → message icon → purple
      case nm.NotificationType.chatMessageReceived:
        return Icons.chat_rounded;

      // Emergency → warning icon → red
      case nm.NotificationType.emergencySosAlert:
      case nm.NotificationType.emergencySosResolved:
        return Icons.emergency_rounded;

      // Verification → shield icon → orange
      case nm.NotificationType.profileVerificationPending:
      case nm.NotificationType.profileVerificationApproved:
      case nm.NotificationType.profileVerificationRejected:
        return Icons.verified_user_rounded;

      // Ads → megaphone icon → pink
      case nm.NotificationType.featuredAdExpiring:
      case nm.NotificationType.featuredAdExpired:
      case nm.NotificationType.featuredAdActivated:
        return Icons.campaign_rounded;

      // Calls → phone icon → teal
      case nm.NotificationType.callIncoming:
      case nm.NotificationType.callEnded:
        return Icons.phone_rounded;
      case nm.NotificationType.callMissed:
        return Icons.phone_missed_rounded;

      // Documents → file icon → indigo
      case nm.NotificationType.documentSubmitted:
      case nm.NotificationType.documentVerified:
      case nm.NotificationType.documentRejected:
        return Icons.description_rounded;

      // System → settings icon → grey
      case nm.NotificationType.generalAlert:
      case nm.NotificationType.complaintFiled:
      case nm.NotificationType.complaintResolved:
      case nm.NotificationType.subscriptionExpiring:
      case nm.NotificationType.subscriptionExpired:
      case nm.NotificationType.accountSuspended:
      case nm.NotificationType.accountReactivated:
        return Icons.notifications_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(nm.NotificationType type) {
    switch (type) {
      // Jobs → blue
      case nm.NotificationType.jobRequestSent:
      case nm.NotificationType.jobRequestReceived:
      case nm.NotificationType.jobRequestAccepted:
      case nm.NotificationType.jobCompleted:
      case nm.NotificationType.jobScheduled:
      case nm.NotificationType.jobReminder:
      case nm.NotificationType.jobStarted:
        return Colors.blue;
      case nm.NotificationType.jobCancelled:
      case nm.NotificationType.jobRescheduled:
        return Colors.red;

      // Payments → green
      case nm.NotificationType.paymentSent:
      case nm.NotificationType.paymentReceived:
        return Colors.green;
      case nm.NotificationType.paymentFailed:
      case nm.NotificationType.paymentRefunded:
        return Colors.red;

      // Reviews → amber
      case nm.NotificationType.reviewReceived:
      case nm.NotificationType.ratingReceived:
        return Colors.amber;

      // Chat → purple
      case nm.NotificationType.chatMessageReceived:
        return Colors.purple;

      // Emergency → red
      case nm.NotificationType.emergencySosAlert:
      case nm.NotificationType.emergencySosResolved:
        return Colors.red;

      // Verification → orange
      case nm.NotificationType.profileVerificationPending:
      case nm.NotificationType.profileVerificationApproved:
      case nm.NotificationType.profileVerificationRejected:
        return Colors.orange;

      // Ads → pink
      case nm.NotificationType.featuredAdExpiring:
      case nm.NotificationType.featuredAdExpired:
      case nm.NotificationType.featuredAdActivated:
        return Colors.pink;

      // Calls → teal
      case nm.NotificationType.callIncoming:
      case nm.NotificationType.callEnded:
        return Colors.teal;
      case nm.NotificationType.callMissed:
        return Colors.red;

      // Documents → indigo
      case nm.NotificationType.documentSubmitted:
      case nm.NotificationType.documentVerified:
      case nm.NotificationType.documentRejected:
        return Colors.indigo;

      // System → grey
      case nm.NotificationType.generalAlert:
      case nm.NotificationType.complaintFiled:
      case nm.NotificationType.complaintResolved:
      case nm.NotificationType.subscriptionExpiring:
      case nm.NotificationType.subscriptionExpired:
      case nm.NotificationType.accountSuspended:
      case nm.NotificationType.accountReactivated:
        return Colors.grey;

      default:
        return Colors.blue;
    }
  }
}
