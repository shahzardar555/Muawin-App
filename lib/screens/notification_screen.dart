import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/notification_manager.dart' as nm;
import '../utils/time_ago.dart';
import '../utils/filter_preferences.dart';
import '../widgets/custom_filter_chip.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _receiverType = 'customer'; // Default
  final nm.NotificationCategory _selectedCategory =
      nm.NotificationCategory.jobs;

  // Filter state variables
  int _currentTabIndex = 0;
  List<String> _selectedFilters = [];
  List<String> _availableFilters = [];
  bool _filtersEnabled = false;
  bool _showFilterBar = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);

    // Add tab listener to update filters when tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
        _loadFiltersForTab();
      }
    });

    // Get receiver type from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() {
          _receiverType = args;
        });
      }
      _loadFiltersForTab();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<nm.NotificationManager>(
      builder: (context, notificationManager, child) {
        final notifications = _getFilteredNotifications(notificationManager);

        return Scaffold(
          backgroundColor: const Color(0xFFF0FDF4),
          body: Column(
            children: [
              // Custom header with buttons
              Container(
                color: const Color(0xFF047A62),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Top row with buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Close',
                        ),
                        // Title
                        Text(
                          'Notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        // Action buttons
                        Row(
                          children: [
                            // Filter toggle button
                            IconButton(
                              icon: Icon(
                                _showFilterBar
                                    ? Icons.filter_list_off
                                    : Icons.filter_list,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showFilterBar = !_showFilterBar;
                                });
                              },
                            ),
                            // Menu button
                            if (notifications.isNotEmpty)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded,
                                    color: Colors.white),
                                onSelected: (value) {
                                  switch (value) {
                                    case 'mark_all_read':
                                      notificationManager
                                          .markAllAsRead(_receiverType);
                                      break;
                                    case 'clear_all':
                                      notificationManager
                                          .clearAll(_receiverType);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'mark_all_read',
                                    child: Row(
                                      children: [
                                        Icon(Icons.mark_email_read_rounded,
                                            size: 18),
                                        SizedBox(width: 8),
                                        Text('Mark All Read'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'clear_all',
                                    child: Row(
                                      children: [
                                        Icon(Icons.clear_all_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('Clear All'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                    // Filter bar (if enabled)
                    if (_showFilterBar) _buildFilterBar(),
                  ],
                ),
              ),
              // Tab bar section
              Container(
                color: const Color(0xFF047A62),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white.withValues(alpha: 0.7),
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                  labelStyle: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Jobs'),
                    Tab(text: 'Payments'),
                    Tab(text: 'Reviews'),
                    Tab(text: 'Alerts'),
                    Tab(text: 'Verify'),
                    Tab(text: 'Ads'),
                    Tab(text: 'Chat'),
                    Tab(text: 'Calls'),
                  ],
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationList(
                        notifications, null), // All notifications
                    _buildNotificationList(
                        notifications, nm.NotificationCategory.jobs),
                    _buildNotificationList(
                        notifications, nm.NotificationCategory.payments),
                    _buildNotificationList(
                        notifications, nm.NotificationCategory.reviews),
                    _buildNotificationList(
                        notifications, nm.NotificationCategory.alerts),
                    _buildNotificationList(
                        notifications, nm.NotificationCategory.verification),
                    _buildNotificationList(
                        notifications, nm.NotificationCategory.ads),
                    _buildNotificationList(
                        notifications, nm.NotificationCategory.chat),
                    _buildNotificationList(
                        notifications, nm.NotificationCategory.calls),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Filter management methods
  Future<void> _loadFiltersForTab() async {
    final tabName = _getTabName(_currentTabIndex);
    final filters = await FilterPreferences.getFilters(tabName);
    final enabled = await FilterPreferences.areFiltersEnabled(tabName);
    final available = FilterPreferences.getFilterOptionsForTab(tabName);

    setState(() {
      _selectedFilters = filters;
      _filtersEnabled = enabled;
      _availableFilters = available;
    });
  }

  String _getTabName(int index) {
    switch (index) {
      case 0:
        return 'all';
      case 1:
        return 'jobs';
      case 2:
        return 'payments';
      case 3:
        return 'reviews';
      case 4:
        return 'alerts';
      case 5:
        return 'verify';
      case 6:
        return 'ads';
      case 7:
        return 'chat';
      case 8:
        return 'calls';
      default:
        return 'all';
    }
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Notifications',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableFilters.map((filter) {
              return CustomFilterChip(
                label: FilterPreferences.getFilterLabel(filter),
                selected: _selectedFilters.contains(filter),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedFilters.add(filter);
                    } else {
                      _selectedFilters.remove(filter);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _selectedFilters.isNotEmpty ? _applyFilters : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047A62),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Apply Filters (${_selectedFilters.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _resetFilters,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Text(
                  'Reset All',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _applyFilters() async {
    final tabName = _getTabName(_currentTabIndex);
    await FilterPreferences.saveFilters(tabName, _selectedFilters);
    setState(() {
      _filtersEnabled = _selectedFilters.isNotEmpty;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied ${_selectedFilters.length} filter(s)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetFilters() async {
    final tabName = _getTabName(_currentTabIndex);
    await FilterPreferences.clearFilters(tabName);
    setState(() {
      _selectedFilters.clear();
      _filtersEnabled = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All filters cleared'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<nm.Notification> _getFilteredNotifications(
      nm.NotificationManager notificationManager) {
    List<nm.Notification> baseNotifications;

    // Get base notifications for the current category
    switch (_selectedCategory) {
      case nm.NotificationCategory.jobs:
        baseNotifications = notificationManager.getNotificationsByCategory(
            _receiverType, nm.NotificationCategory.jobs);
        break;
      case nm.NotificationCategory.payments:
        baseNotifications = notificationManager.getNotificationsByCategory(
            _receiverType, nm.NotificationCategory.payments);
        break;
      case nm.NotificationCategory.reviews:
        baseNotifications = notificationManager.getNotificationsByCategory(
            _receiverType, nm.NotificationCategory.reviews);
        break;
      case nm.NotificationCategory.alerts:
        baseNotifications = notificationManager.getNotificationsByCategory(
            _receiverType, nm.NotificationCategory.alerts);
        break;
      case nm.NotificationCategory.verification:
        baseNotifications = notificationManager.getNotificationsByCategory(
            _receiverType, nm.NotificationCategory.verification);
        break;
      case nm.NotificationCategory.ads:
        baseNotifications = notificationManager.getNotificationsByCategory(
            _receiverType, nm.NotificationCategory.ads);
        break;
      case nm.NotificationCategory.chat:
        baseNotifications = notificationManager.getNotificationsByCategory(
            _receiverType, nm.NotificationCategory.chat);
        break;
      case nm.NotificationCategory.calls:
        baseNotifications = notificationManager.getNotificationsByCategory(
            _receiverType, nm.NotificationCategory.calls);
        break;
      default:
        baseNotifications = _receiverType == 'customer'
            ? notificationManager.customerNotifications
            : _receiverType == 'provider'
                ? notificationManager.providerNotifications
                : notificationManager.vendorNotifications;
    }

    // Apply filters if they are enabled
    if (!_filtersEnabled || _selectedFilters.isEmpty) {
      return baseNotifications;
    }

    return baseNotifications.where((notification) {
      return _matchesFilters(notification);
    }).toList();
  }

  bool _matchesFilters(nm.Notification notification) {
    for (final filter in _selectedFilters) {
      if (!_matchesSingleFilter(notification, filter)) {
        return false;
      }
    }
    return true;
  }

  bool _matchesSingleFilter(nm.Notification notification, String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate = DateTime(
      notification.timestamp.year,
      notification.timestamp.month,
      notification.timestamp.day,
    );

    switch (filter) {
      // Read status filters
      case 'unread':
        return !notification.isRead;
      case 'read':
        return notification.isRead;

      // Time filters
      case 'today':
        return notificationDate.isAtSameMomentAs(today);
      case 'this_week':
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return notificationDate
            .isAfter(weekStart.subtract(const Duration(days: 1)));
      case 'this_month':
        return notificationDate.year == now.year &&
            notificationDate.month == now.month;

      // Priority filters
      case 'low_priority':
        return notification.priority == nm.NotificationPriority.low;
      case 'medium_priority':
        return notification.priority == nm.NotificationPriority.medium;
      case 'high_priority':
        return notification.priority == nm.NotificationPriority.high;
      case 'urgent':
        return notification.priority == nm.NotificationPriority.urgent;
      case 'emergency':
        return notification.priority == nm.NotificationPriority.emergency;

      // Job-specific filters
      case 'active':
        return _isActiveJobNotification(notification);
      case 'completed':
        return _isCompletedJobNotification(notification);
      case 'cancelled':
        return _isCancelledJobNotification(notification);
      case 'pending':
        return _isPendingJobNotification(notification);

      // Payment-specific filters
      case 'paid':
        return _isPaidPaymentNotification(notification);
      case 'failed':
        return _isFailedPaymentNotification(notification);
      case 'refunded':
        return _isRefundedPaymentNotification(notification);

      // Amount filters (simplified - would need actual amount data)
      case 'under_50':
        return true; // Placeholder - would check actual amount
      case '50_to_200':
        return true; // Placeholder
      case '200_to_500':
        return true; // Placeholder
      case 'over_500':
        return true; // Placeholder

      // Review filters
      case '5_star':
      case '4_star':
      case '3_star':
      case '2_star':
      case '1_star':
        return _matchesRatingFilter(notification, filter);
      case 'positive':
        return _isPositiveReview(notification);
      case 'negative':
        return _isNegativeReview(notification);
      case 'neutral':
        return _isNeutralReview(notification);

      // Alert filters
      case 'system':
        return _isSystemAlert(notification);
      case 'account':
        return _isAccountAlert(notification);
      case 'security':
        return _isSecurityAlert(notification);
      case 'marketing':
        return _isMarketingAlert(notification);

      // Verification filters
      case 'approved':
        return _isApprovedVerification(notification);
      case 'rejected':
        return _isRejectedVerification(notification);
      case 'document':
        return _isDocumentVerification(notification);
      case 'profile':
        return _isProfileVerification(notification);
      case 'business':
        return _isBusinessVerification(notification);

      // Ad filters
      case 'expired':
        return _isExpiredAd(notification);
      case 'expiring_soon':
        return _isExpiringSoonAd(notification);
      case 'featured':
        return _isFeaturedAd(notification);
      case 'standard':
        return _isStandardAd(notification);

      // Chat filters
      case 'customer':
        return _isCustomerChat(notification);
      case 'provider':
        return _isProviderChat(notification);
      case 'group':
        return _isGroupChat(notification);
      case 'direct':
        return _isDirectChat(notification);

      // Call filters
      case 'missed':
        return _isMissedCall(notification);
      case 'received':
        return _isReceivedCall(notification);
      case 'ended':
        return _isEndedCall(notification);
      case 'voice':
        return _isVoiceCall(notification);
      case 'video':
        return _isVideoCall(notification);

      default:
        return true;
    }
  }

  // Helper methods for specific filter types (simplified implementations)
  bool _isActiveJobNotification(nm.Notification notification) =>
      notification.type == nm.NotificationType.jobRequestReceived ||
      notification.type == nm.NotificationType.jobScheduled ||
      notification.type == nm.NotificationType.jobStarted;

  bool _isCompletedJobNotification(nm.Notification notification) =>
      notification.type == nm.NotificationType.jobCompleted;

  bool _isCancelledJobNotification(nm.Notification notification) =>
      notification.type == nm.NotificationType.jobRequestRejected ||
      notification.type == nm.NotificationType.jobCancelled;

  bool _isPendingJobNotification(nm.Notification notification) =>
      notification.type == nm.NotificationType.jobRequestSent ||
      notification.type == nm.NotificationType.jobRequestReceived;

  bool _isPaidPaymentNotification(nm.Notification notification) =>
      notification.type == nm.NotificationType.paymentReceived;

  bool _isFailedPaymentNotification(nm.Notification notification) =>
      notification.type == nm.NotificationType.paymentFailed;

  bool _isRefundedPaymentNotification(nm.Notification notification) =>
      notification.type == nm.NotificationType.paymentRefunded;

  bool _matchesRatingFilter(nm.Notification notification, String filter) {
    // Simplified - would need actual rating data
    return notification.type == nm.NotificationType.reviewReceived ||
        notification.type == nm.NotificationType.ratingReceived;
  }

  bool _isPositiveReview(nm.Notification notification) =>
      notification.type == nm.NotificationType.reviewReceived ||
      notification.type == nm.NotificationType.ratingReceived;

  bool _isNegativeReview(nm.Notification notification) =>
      false; // Would need rating data

  bool _isNeutralReview(nm.Notification notification) =>
      false; // Would need rating data

  bool _isSystemAlert(nm.Notification notification) =>
      notification.type == nm.NotificationType.systemUpdate ||
      notification.type == nm.NotificationType.generalAlert;

  bool _isAccountAlert(nm.Notification notification) =>
      notification.type == nm.NotificationType.accountSuspended ||
      notification.type == nm.NotificationType.accountReactivated ||
      notification.type == nm.NotificationType.subscriptionExpiring ||
      notification.type == nm.NotificationType.subscriptionExpired;

  bool _isSecurityAlert(nm.Notification notification) =>
      notification.type == nm.NotificationType.emergencySosAlert ||
      notification.type == nm.NotificationType.emergencySosResolved;

  bool _isMarketingAlert(nm.Notification notification) =>
      notification.type == nm.NotificationType.featuredAdExpiring ||
      notification.type == nm.NotificationType.featuredAdExpired ||
      notification.type == nm.NotificationType.featuredAdActivated;

  bool _isApprovedVerification(nm.Notification notification) =>
      notification.type == nm.NotificationType.profileVerificationApproved ||
      notification.type == nm.NotificationType.documentVerified;

  bool _isRejectedVerification(nm.Notification notification) =>
      notification.type == nm.NotificationType.profileVerificationRejected ||
      notification.type == nm.NotificationType.documentRejected;

  bool _isDocumentVerification(nm.Notification notification) =>
      notification.type == nm.NotificationType.documentSubmitted ||
      notification.type == nm.NotificationType.documentVerified ||
      notification.type == nm.NotificationType.documentRejected;

  bool _isProfileVerification(nm.Notification notification) =>
      notification.type == nm.NotificationType.profileVerificationPending ||
      notification.type == nm.NotificationType.profileVerificationApproved ||
      notification.type == nm.NotificationType.profileVerificationRejected;

  bool _isBusinessVerification(nm.Notification notification) =>
      false; // Would need data

  bool _isExpiredAd(nm.Notification notification) =>
      notification.type == nm.NotificationType.featuredAdExpired;

  bool _isExpiringSoonAd(nm.Notification notification) =>
      notification.type == nm.NotificationType.featuredAdExpiring;

  bool _isFeaturedAd(nm.Notification notification) =>
      notification.type == nm.NotificationType.featuredAdActivated;

  bool _isStandardAd(nm.Notification notification) => false; // Would need data

  bool _isCustomerChat(nm.Notification notification) =>
      notification.type ==
      nm.NotificationType.chatMessageReceived; // Would need sender data

  bool _isProviderChat(nm.Notification notification) =>
      false; // Would need sender data

  bool _isGroupChat(nm.Notification notification) =>
      false; // Would need chat type data

  bool _isDirectChat(nm.Notification notification) =>
      notification.type == nm.NotificationType.chatMessageReceived;

  bool _isMissedCall(nm.Notification notification) =>
      notification.type == nm.NotificationType.callMissed;

  bool _isReceivedCall(nm.Notification notification) =>
      notification.type == nm.NotificationType.callIncoming;

  bool _isEndedCall(nm.Notification notification) =>
      notification.type == nm.NotificationType.callEnded;

  bool _isVoiceCall(nm.Notification notification) =>
      false; // Would need call type data

  bool _isVideoCall(nm.Notification notification) =>
      false; // Would need call type data

  Widget _buildNotificationList(
      List<nm.Notification> notifications, nm.NotificationCategory? category) {
    if (notifications.isEmpty) {
      return _buildEmptyState(category ?? nm.NotificationCategory.jobs);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Pull to refresh would trigger a sync with backend
        // For now, just complete the future
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildEmptyState(nm.NotificationCategory category) {
    String title;
    String subtitle;
    IconData icon;

    switch (category) {
      case nm.NotificationCategory.jobs:
        title = 'No Job Notifications';
        subtitle = 'Job requests and updates will appear here';
        icon = Icons.work_rounded;
        break;
      case nm.NotificationCategory.payments:
        title = 'No Payment Notifications';
        subtitle = 'Payment confirmations and receipts will appear here';
        icon = Icons.payments_rounded;
        break;
      case nm.NotificationCategory.reviews:
        title = 'No Review Notifications';
        subtitle = 'Customer reviews and ratings will appear here';
        icon = Icons.star_rounded;
        break;
      case nm.NotificationCategory.alerts:
        title = 'No Alert Notifications';
        subtitle = 'Important alerts and announcements will appear here';
        icon = Icons.notifications_active_rounded;
        break;
      case nm.NotificationCategory.verification:
        title = 'No Verification Notifications';
        subtitle = 'Profile verification updates will appear here';
        icon = Icons.verified_user_rounded;
        break;
      case nm.NotificationCategory.ads:
        title = 'No Ad Notifications';
        subtitle = 'Featured ad updates will appear here';
        icon = Icons.campaign_rounded;
        break;
      case nm.NotificationCategory.chat:
        title = 'No Chat Notifications';
        subtitle = 'New chat messages will appear here';
        icon = Icons.chat_rounded;
        break;
      case nm.NotificationCategory.calls:
        title = 'No Call Notifications';
        subtitle = 'Incoming and missed call alerts will appear here';
        icon = Icons.phone_rounded;
        break;
      default:
        title = 'No Notifications';
        subtitle = 'Your notifications will appear here';
        icon = Icons.notifications_rounded;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF047A62).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: const Color(0xFF047A62).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 48,
              color: const Color(0xFF047A62),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF047A62),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(nm.Notification notification) {
    final isUnread = !notification.isRead;
    final iconData = _getIconForType(notification.type);
    final iconColor = _getColorForType(notification.type);
    final cardColor = isUnread
        ? iconColor.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.05);

    return GestureDetector(
      onTap: () {
        // Mark as read
        if (isUnread) {
          final notificationManager =
              Provider.of<nm.NotificationManager>(context, listen: false);
          notificationManager.markAsRead(notification.id, _receiverType);
        }

        // Navigate based on action data
        if (notification.actionData != null) {
          _handleNotificationAction(notification.actionData!);
        }
      },
      onLongPress: () {
        _showDeleteDialog(notification);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(color: iconColor.withValues(alpha: 0.3), width: 2)
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
            const SizedBox(width: 16),
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
                  Text(
                    getTimeAgo(notification.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(nm.NotificationType type) {
    switch (type) {
      // Job Related
      case nm.NotificationType.jobRequestSent:
      case nm.NotificationType.jobRequestReceived:
      case nm.NotificationType.jobRequestAccepted:
      case nm.NotificationType.jobCompleted:
        return Icons.work_rounded;
      case nm.NotificationType.jobRequestRejected:
        return Icons.close_rounded;
      case nm.NotificationType.jobRequestNegotiation:
        return Icons.handshake_rounded;
      case nm.NotificationType.jobScheduled:
      case nm.NotificationType.jobReminder:
        return Icons.schedule_rounded;

      // Payment Related
      case nm.NotificationType.paymentSent:
      case nm.NotificationType.paymentReceived:
      case nm.NotificationType.paymentFailed:
      case nm.NotificationType.paymentRefunded:
        return Icons.payment_rounded;

      // Review Related
      case nm.NotificationType.reviewReceived:
      case nm.NotificationType.ratingReceived:
        return Icons.star_rounded;

      // Chat Related
      case nm.NotificationType.chatMessageReceived:
        return Icons.chat_rounded;

      // Call Related
      case nm.NotificationType.callIncoming:
      case nm.NotificationType.callEnded:
        return Icons.phone_rounded;
      case nm.NotificationType.callMissed:
        return Icons.phone_missed_rounded;

      // Emergency Related
      case nm.NotificationType.emergencySosAlert:
      case nm.NotificationType.emergencySosResolved:
        return Icons.emergency_rounded;

      // Document Related
      case nm.NotificationType.documentSubmitted:
      case nm.NotificationType.documentVerified:
      case nm.NotificationType.documentRejected:
        return Icons.description_rounded;

      // Profile Verification
      case nm.NotificationType.profileVerificationPending:
      case nm.NotificationType.profileVerificationApproved:
      case nm.NotificationType.profileVerificationRejected:
        return Icons.verified_user_rounded;

      // Ads Related
      case nm.NotificationType.featuredAdExpiring:
      case nm.NotificationType.featuredAdExpired:
      case nm.NotificationType.featuredAdActivated:
        return Icons.campaign_rounded;

      // System Related
      case nm.NotificationType.systemUpdate:
      case nm.NotificationType.generalAlert:
      case nm.NotificationType.complaintFiled:
      case nm.NotificationType.complaintResolved:
      case nm.NotificationType.subscriptionExpiring:
      case nm.NotificationType.subscriptionExpired:
      case nm.NotificationType.accountSuspended:
      case nm.NotificationType.accountReactivated:
      case nm.NotificationType.bookingConfirmed:
      case nm.NotificationType.bookingReminder:
      case nm.NotificationType.newOfferReceived:
      case nm.NotificationType.proUpgradeSuccess:
        return Icons.notifications_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(nm.NotificationType type) {
    switch (type) {
      // Job Related - Blue
      case nm.NotificationType.jobRequestSent:
      case nm.NotificationType.jobRequestReceived:
      case nm.NotificationType.jobRequestAccepted:
      case nm.NotificationType.jobCompleted:
        return Colors.blue;
      case nm.NotificationType.jobRequestRejected:
      case nm.NotificationType.jobRequestNegotiation:
      case nm.NotificationType.jobCancelled:
      case nm.NotificationType.jobRescheduled:
        return Colors.red;
      case nm.NotificationType.jobScheduled:
      case nm.NotificationType.jobReminder:
      case nm.NotificationType.jobStarted:
        return Colors.orange;

      // Payment Related - Green
      case nm.NotificationType.paymentSent:
      case nm.NotificationType.paymentReceived:
      case nm.NotificationType.paymentFailed:
      case nm.NotificationType.paymentRefunded:
        return Colors.green;

      // Review Related - Amber
      case nm.NotificationType.reviewReceived:
      case nm.NotificationType.ratingReceived:
        return Colors.amber;

      // Chat Related - Purple
      case nm.NotificationType.chatMessageReceived:
        return Colors.purple;

      // Call Related - Teal
      case nm.NotificationType.callIncoming:
      case nm.NotificationType.callEnded:
        return Colors.teal;
      case nm.NotificationType.callMissed:
        return Colors.red;

      // Emergency Related - Red
      case nm.NotificationType.emergencySosAlert:
      case nm.NotificationType.emergencySosResolved:
        return Colors.red;

      // Document Related - Indigo
      case nm.NotificationType.documentSubmitted:
      case nm.NotificationType.documentVerified:
      case nm.NotificationType.documentRejected:
        return Colors.indigo;

      // Profile Verification - Orange
      case nm.NotificationType.profileVerificationPending:
      case nm.NotificationType.profileVerificationApproved:
      case nm.NotificationType.profileVerificationRejected:
        return Colors.orange;

      // Ads Related - Pink
      case nm.NotificationType.featuredAdExpiring:
      case nm.NotificationType.featuredAdExpired:
      case nm.NotificationType.featuredAdActivated:
        return Colors.pink;

      // System Related - Grey
      case nm.NotificationType.systemUpdate:
      case nm.NotificationType.generalAlert:
      case nm.NotificationType.complaintFiled:
      case nm.NotificationType.complaintResolved:
      case nm.NotificationType.subscriptionExpiring:
      case nm.NotificationType.subscriptionExpired:
      case nm.NotificationType.accountSuspended:
      case nm.NotificationType.accountReactivated:
      case nm.NotificationType.bookingConfirmed:
      case nm.NotificationType.bookingReminder:
      case nm.NotificationType.newOfferReceived:
      case nm.NotificationType.proUpgradeSuccess:
        return Colors.grey;
    }
  }

  void _handleNotificationAction(Map<String, dynamic> actionData) {
    final route = actionData['route'] as String?;
    if (route != null) {
      Navigator.of(context)
          .pushNamed(route, arguments: actionData['arguments']);
    }
  }

  void _showDeleteDialog(nm.Notification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content:
            const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final notificationManager =
                  Provider.of<nm.NotificationManager>(context, listen: false);
              notificationManager.deleteNotification(
                  notification.id, _receiverType);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
