import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'emergency_banner_service.dart';
import '../utils/haptic_feedback.dart';

enum NotificationType {
  // Job Related
  jobRequestSent,
  jobRequestReceived,
  jobRequestAccepted,
  jobRequestRejected,
  jobRequestNegotiation,

  // Payment Related
  paymentSent,
  paymentReceived,
  paymentFailed,
  paymentRefunded,

  // Review Related
  reviewReceived,
  ratingReceived,

  // Complaint Related
  complaintFiled,
  complaintResolved,

  // General Alerts
  generalAlert,

  // Pro Upgrade Related
  proUpgradeSuccess,

  // Profile Verification
  profileVerificationPending,
  profileVerificationApproved,
  profileVerificationRejected,

  // Ads Related
  featuredAdExpiring,
  featuredAdExpired,
  featuredAdActivated,

  // Chat Related
  chatMessageReceived,

  // Call Related
  callIncoming,
  callMissed,
  callEnded,

  // Emergency Related
  emergencySosAlert,
  emergencySosResolved,

  // Document Related
  documentSubmitted,
  documentVerified,
  documentRejected,

  // Job Management
  jobScheduled,
  jobReminder,
  jobStarted,
  jobCompleted,
  jobCancelled,
  jobRescheduled,

  // Booking Related
  bookingConfirmed,
  bookingReminder,

  // Offer Related
  newOfferReceived,

  // Subscription Related
  subscriptionExpiring,
  subscriptionExpired,

  // Account Related
  accountSuspended,
  accountReactivated,

  // System Related
  systemUpdate,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
  emergency,
}

enum NotificationCategory {
  jobs,
  payments,
  reviews,
  alerts,
  verification,
  ads,
  chat,
  calls,
  emergency,
  documents,
  system,
}

class Notification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final NotificationPriority priority;
  final String senderId;
  final String receiverId;
  final String receiverType;
  final Map<String, dynamic>? actionData;
  final NotificationCategory category;

  Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.priority = NotificationPriority.medium,
    required this.senderId,
    required this.receiverId,
    required this.receiverType,
    this.actionData,
    required this.category,
  });

  Notification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    NotificationPriority? priority,
    String? senderId,
    String? receiverId,
    String? receiverType,
    Map<String, dynamic>? actionData,
    NotificationCategory? category,
  }) {
    return Notification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      receiverType: receiverType ?? this.receiverType,
      actionData: actionData ?? this.actionData,
      category: category ?? this.category,
    );
  }

  // JSON serialization for persistent storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'priority': priority.toString(),
      'senderId': senderId,
      'receiverId': receiverId,
      'receiverType': receiverType,
      'actionData': actionData,
      'category': category.toString(),
    };
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    try {
      return Notification(
        id: json['id'] as String,
        type: _parseNotificationType(json['type'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isRead: json['isRead'] as bool? ?? false,
        priority:
            _parseNotificationPriority(json['priority'] as String? ?? 'medium'),
        senderId: json['senderId'] as String,
        receiverId: json['receiverId'] as String,
        receiverType: json['receiverType'] as String,
        actionData: json['actionData'] as Map<String, dynamic>?,
        category:
            _parseNotificationCategory(json['category'] as String? ?? 'jobs'),
      );
    } catch (e) {
      debugPrint('Error parsing notification from JSON: $e');
      rethrow;
    }
  }

  static NotificationType _parseNotificationType(String typeString) {
    switch (typeString) {
      case 'jobRequestSent':
        return NotificationType.jobRequestSent;
      case 'jobRequestReceived':
        return NotificationType.jobRequestReceived;
      case 'jobRequestAccepted':
        return NotificationType.jobRequestAccepted;
      case 'jobRequestRejected':
        return NotificationType.jobRequestRejected;
      case 'jobRequestNegotiation':
        return NotificationType.jobRequestNegotiation;
      case 'paymentSent':
        return NotificationType.paymentSent;
      case 'paymentReceived':
        return NotificationType.paymentReceived;
      case 'paymentFailed':
        return NotificationType.paymentFailed;
      case 'paymentRefunded':
        return NotificationType.paymentRefunded;
      case 'reviewReceived':
        return NotificationType.reviewReceived;
      case 'ratingReceived':
        return NotificationType.ratingReceived;
      case 'complaintFiled':
        return NotificationType.complaintFiled;
      case 'complaintResolved':
        return NotificationType.complaintResolved;
      case 'generalAlert':
        return NotificationType.generalAlert;
      case 'proUpgradeSuccess':
        return NotificationType.proUpgradeSuccess;
      case 'profileVerificationPending':
        return NotificationType.profileVerificationPending;
      case 'profileVerificationApproved':
        return NotificationType.profileVerificationApproved;
      case 'profileVerificationRejected':
        return NotificationType.profileVerificationRejected;
      case 'featuredAdExpiring':
        return NotificationType.featuredAdExpiring;
      case 'featuredAdExpired':
        return NotificationType.featuredAdExpired;
      case 'featuredAdActivated':
        return NotificationType.featuredAdActivated;
      case 'chatMessageReceived':
        return NotificationType.chatMessageReceived;
      case 'callIncoming':
        return NotificationType.callIncoming;
      case 'callMissed':
        return NotificationType.callMissed;
      case 'callEnded':
        return NotificationType.callEnded;
      case 'emergencySosAlert':
        return NotificationType.emergencySosAlert;
      case 'emergencySosResolved':
        return NotificationType.emergencySosResolved;
      case 'documentSubmitted':
        return NotificationType.documentSubmitted;
      case 'documentVerified':
        return NotificationType.documentVerified;
      case 'documentRejected':
        return NotificationType.documentRejected;
      case 'jobScheduled':
        return NotificationType.jobScheduled;
      case 'jobReminder':
        return NotificationType.jobReminder;
      case 'jobStarted':
        return NotificationType.jobStarted;
      case 'jobCompleted':
        return NotificationType.jobCompleted;
      case 'jobCancelled':
        return NotificationType.jobCancelled;
      case 'jobRescheduled':
        return NotificationType.jobRescheduled;
      case 'bookingConfirmed':
        return NotificationType.bookingConfirmed;
      case 'bookingReminder':
        return NotificationType.bookingReminder;
      case 'newOfferReceived':
        return NotificationType.newOfferReceived;
      case 'subscriptionExpiring':
        return NotificationType.subscriptionExpiring;
      case 'subscriptionExpired':
        return NotificationType.subscriptionExpired;
      case 'accountSuspended':
        return NotificationType.accountSuspended;
      case 'accountReactivated':
        return NotificationType.accountReactivated;
      case 'systemUpdate':
        return NotificationType.systemUpdate;
      default:
        return NotificationType.generalAlert;
    }
  }

  static NotificationPriority _parseNotificationPriority(
      String priorityString) {
    switch (priorityString) {
      case 'low':
        return NotificationPriority.low;
      case 'medium':
        return NotificationPriority.medium;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      case 'emergency':
        return NotificationPriority.emergency;
      default:
        return NotificationPriority.medium;
    }
  }

  static NotificationCategory _parseNotificationCategory(
      String categoryString) {
    switch (categoryString) {
      case 'jobs':
        return NotificationCategory.jobs;
      case 'payments':
        return NotificationCategory.payments;
      case 'reviews':
        return NotificationCategory.reviews;
      case 'alerts':
        return NotificationCategory.alerts;
      case 'verification':
        return NotificationCategory.verification;
      case 'ads':
        return NotificationCategory.ads;
      case 'chat':
        return NotificationCategory.chat;
      case 'calls':
        return NotificationCategory.calls;
      case 'emergency':
        return NotificationCategory.emergency;
      case 'documents':
        return NotificationCategory.documents;
      case 'system':
        return NotificationCategory.system;
      default:
        return NotificationCategory.jobs;
    }
  }
}

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();

  factory NotificationManager() {
    return _instance;
  }

  NotificationManager._internal();

  // Storage constants
  static const String _storageVersionKey = 'notifications_storage_version';
  static const String _customerNotificationsKey = 'customer_notifications_v1';
  static const String _providerNotificationsKey = 'provider_notifications_v1';
  static const String _vendorNotificationsKey = 'vendor_notifications_v1';
  static const int _currentStorageVersion = 1;
  static const int _maxNotificationsPerType = 100;

  final List<Notification> _customerNotifications = [];
  final List<Notification> _providerNotifications = [];
  final List<Notification> _vendorNotifications = [];

  bool _isInitialized = false;

  List<Notification> get customerNotifications =>
      List.unmodifiable(_customerNotifications);
  List<Notification> get providerNotifications =>
      List.unmodifiable(_providerNotifications);
  List<Notification> get vendorNotifications =>
      List.unmodifiable(_vendorNotifications);

  void sendNotification({
    required String receiverId,
    required String receiverType,
    required NotificationType type,
    required String title,
    required String body,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? actionData,
  }) {
    // Initialize storage if not already done
    if (!_isInitialized) {
      _initializeStorage();
    }

    final notification = Notification(
      id: _generateId(),
      type: type,
      title: title,
      body: body,
      timestamp: DateTime.now(),
      priority: priority,
      senderId: 'system', // System generated for now
      receiverId: receiverId,
      receiverType: receiverType,
      actionData: actionData,
      category: _getCategoryFromType(type),
    );

    _addNotificationToCorrectList(notification, receiverType);

    // Trigger in-app banner for urgent/emergency notifications
    if (priority == NotificationPriority.urgent ||
        priority == NotificationPriority.emergency) {
      _showUrgentBanner(notification);

      // Add sound and haptic feedback
      _triggerNotificationFeedback(priority);
    }

    // Auto-save to persistent storage
    _saveToStorage();

    notifyListeners();
  }

  void markAsRead(String notificationId, String receiverType) {
    // Initialize storage if not already done
    if (!_isInitialized) {
      _initializeStorage();
    }

    _getNotificationList(receiverType).forEach((notification) {
      if (notification.id == notificationId) {
        final index = _getNotificationList(receiverType).indexOf(notification);
        if (index != -1) {
          _getNotificationList(receiverType)[index] =
              notification.copyWith(isRead: true);
        }
      }
    });

    // Save to persistent storage
    _saveToStorage();
    notifyListeners();
  }

  void markAllAsRead(String receiverType) {
    // Initialize storage if not already done
    if (!_isInitialized) {
      _initializeStorage();
    }

    for (int i = 0; i < _getNotificationList(receiverType).length; i++) {
      _getNotificationList(receiverType)[i] =
          _getNotificationList(receiverType)[i].copyWith(isRead: true);
    }

    // Save to persistent storage
    _saveToStorage();
    notifyListeners();
  }

  void deleteNotification(String id, String receiverType) {
    // Initialize storage if not already done
    if (!_isInitialized) {
      _initializeStorage();
    }

    _getNotificationList(receiverType)
        .removeWhere((notification) => notification.id == id);

    // Save to persistent storage
    _saveToStorage();
    notifyListeners();
  }

  void clearAll(String receiverType) {
    // Initialize storage if not already done
    if (!_isInitialized) {
      _initializeStorage();
    }

    _getNotificationList(receiverType).clear();

    // Save to persistent storage
    _saveToStorage();
    notifyListeners();
  }

  int getUnreadCount(String receiverType) {
    return _getNotificationList(receiverType)
        .where((notification) => !notification.isRead)
        .length;
  }

  List<Notification> getNotificationsByCategory(
      String receiverType, NotificationCategory category) {
    return _getNotificationList(receiverType)
        .where((notification) => notification.category == category)
        .toList();
  }

  List<Notification> getNotificationsByPriority(
      String receiverType, NotificationPriority priority) {
    return _getNotificationList(receiverType)
        .where((notification) => notification.priority == priority)
        .toList();
  }

  void simulateNotification(NotificationType type) {
    String title;
    String body;
    String receiverType = 'customer'; // Default to customer for testing

    switch (type) {
      case NotificationType.jobRequestReceived:
        title = 'New Job Request';
        body = 'Ahmed R. requested your services for tomorrow at 3:00 PM';
        break;
      case NotificationType.paymentReceived:
        title = 'Payment Received';
        body = 'You received Rs. 1,500 for completed job #48291';
        break;
      case NotificationType.chatMessageReceived:
        title = 'New Message';
        body = 'Sarah sent you a message about your services';
        break;
      case NotificationType.emergencySosAlert:
        title = 'Emergency Alert';
        body =
            'Customer reported emergency situation - immediate attention required';
        receiverType = 'provider'; // Emergency goes to provider
        break;
      case NotificationType.profileVerificationApproved:
        title = 'Profile Verified';
        body = 'Your profile has been successfully verified';
        break;
      case NotificationType.featuredAdExpiring:
        title = 'Featured Ad Expiring';
        body = 'Your featured advertisement will expire in 3 days';
        break;
      default:
        title = 'New Notification';
        body = 'You have a new notification';
        break;
    }

    sendNotification(
      receiverId: 'test_user',
      receiverType: receiverType,
      type: type,
      title: title,
      body: body,
      priority: type == NotificationType.emergencySosAlert
          ? NotificationPriority.emergency
          : NotificationPriority.medium,
    );
  }

  void _addNotificationToCorrectList(
      Notification notification, String receiverType) {
    switch (receiverType) {
      case 'customer':
        _customerNotifications.insert(0, notification);
        break;
      case 'provider':
        _providerNotifications.insert(0, notification);
        break;
      case 'vendor':
        _vendorNotifications.insert(0, notification);
        break;
    }
  }

  List<Notification> _getNotificationList(String receiverType) {
    switch (receiverType) {
      case 'customer':
        return _customerNotifications;
      case 'provider':
        return _providerNotifications;
      case 'vendor':
        return _vendorNotifications;
      default:
        return [];
    }
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_customerNotifications.length}';
  }

  NotificationCategory _getCategoryFromType(NotificationType type) {
    switch (type) {
      case NotificationType.jobRequestSent:
      case NotificationType.jobRequestReceived:
      case NotificationType.jobRequestAccepted:
      case NotificationType.jobRequestRejected:
      case NotificationType.jobRequestNegotiation:
      case NotificationType.jobScheduled:
      case NotificationType.jobReminder:
      case NotificationType.jobStarted:
      case NotificationType.jobCompleted:
      case NotificationType.jobCancelled:
      case NotificationType.jobRescheduled:
      case NotificationType.bookingConfirmed:
      case NotificationType.bookingReminder:
      case NotificationType.newOfferReceived:
        return NotificationCategory.jobs;

      case NotificationType.paymentSent:
      case NotificationType.paymentReceived:
      case NotificationType.paymentFailed:
      case NotificationType.paymentRefunded:
        return NotificationCategory.payments;

      case NotificationType.reviewReceived:
      case NotificationType.ratingReceived:
        return NotificationCategory.reviews;

      case NotificationType.chatMessageReceived:
        return NotificationCategory.chat;

      case NotificationType.callIncoming:
      case NotificationType.callMissed:
      case NotificationType.callEnded:
        return NotificationCategory.calls;

      case NotificationType.emergencySosAlert:
      case NotificationType.emergencySosResolved:
        return NotificationCategory.alerts;

      case NotificationType.documentSubmitted:
      case NotificationType.documentVerified:
      case NotificationType.documentRejected:
        return NotificationCategory.verification;

      case NotificationType.featuredAdExpiring:
      case NotificationType.featuredAdExpired:
      case NotificationType.featuredAdActivated:
        return NotificationCategory.ads;

      case NotificationType.generalAlert:
      case NotificationType.complaintFiled:
      case NotificationType.complaintResolved:
      case NotificationType.subscriptionExpiring:
      case NotificationType.subscriptionExpired:
      case NotificationType.accountSuspended:
      case NotificationType.accountReactivated:
      case NotificationType.profileVerificationPending:
      case NotificationType.profileVerificationApproved:
      case NotificationType.profileVerificationRejected:
      case NotificationType.proUpgradeSuccess:
        return NotificationCategory.alerts;

      case NotificationType.systemUpdate:
        return NotificationCategory.system;
    }
  }

  void _triggerNotificationFeedback(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.emergency:
        HapticFeedback.heavyImpact();
        debugPrint('🔔 Playing emergency notification sound');
        break;
      case NotificationPriority.urgent:
        HapticFeedback.mediumImpact();
        debugPrint('🔔 Playing urgent notification sound');
        break;
      case NotificationPriority.high:
        HapticFeedback.lightImpact();
        break;
      default:
        // No haptic for lower priorities
        break;
    }
  }

  void _showUrgentBanner(Notification notification) {
    // Import and use EmergencyBannerService
    final emergencyService = EmergencyBannerService();
    emergencyService.showBanner(notification);
  }

  // Persistent Storage Methods
  Future<void> _initializeStorage() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check storage version and migrate if needed
      await _migrateStorageIfNeeded(prefs);

      // Load notifications from storage
      await _loadFromStorage(prefs);

      _isInitialized = true;
      debugPrint('✅ Notification storage initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notification storage: $e');
      _isInitialized = true; // Prevent infinite retry loops
    }
  }

  Future<void> _loadFromStorage(SharedPreferences prefs) async {
    try {
      // Load customer notifications
      final customerData = prefs.getString(_customerNotificationsKey);
      if (customerData != null) {
        final customerJson = jsonDecode(customerData) as Map<String, dynamic>;
        final customerNotificationsJson =
            customerJson['notifications'] as List<dynamic>? ?? [];
        _customerNotifications.clear();
        _customerNotifications.addAll(
          customerNotificationsJson
              .map((n) => Notification.fromJson(n as Map<String, dynamic>))
              .take(_maxNotificationsPerType)
              .toList(),
        );
      }

      // Load provider notifications
      final providerData = prefs.getString(_providerNotificationsKey);
      if (providerData != null) {
        final providerJson = jsonDecode(providerData) as Map<String, dynamic>;
        final providerNotificationsJson =
            providerJson['notifications'] as List<dynamic>? ?? [];
        _providerNotifications.clear();
        _providerNotifications.addAll(
          providerNotificationsJson
              .map((n) => Notification.fromJson(n as Map<String, dynamic>))
              .take(_maxNotificationsPerType)
              .toList(),
        );
      }

      // Load vendor notifications
      final vendorData = prefs.getString(_vendorNotificationsKey);
      if (vendorData != null) {
        final vendorJson = jsonDecode(vendorData) as Map<String, dynamic>;
        final vendorNotificationsJson =
            vendorJson['notifications'] as List<dynamic>? ?? [];
        _vendorNotifications.clear();
        _vendorNotifications.addAll(
          vendorNotificationsJson
              .map((n) => Notification.fromJson(n as Map<String, dynamic>))
              .take(_maxNotificationsPerType)
              .toList(),
        );
      }

      debugPrint(
          '✅ Loaded ${_customerNotifications.length} customer, ${_providerNotifications.length} provider, ${_vendorNotifications.length} vendor notifications');
    } catch (e) {
      debugPrint('❌ Error loading notifications from storage: $e');
      // Fallback to empty lists
      _customerNotifications.clear();
      _providerNotifications.clear();
      _vendorNotifications.clear();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Prepare customer notifications data
      final customerData = {
        'version': _currentStorageVersion,
        'notifications': _customerNotifications
            .take(_maxNotificationsPerType)
            .map((n) => n.toJson())
            .toList(),
      };

      // Prepare provider notifications data
      final providerData = {
        'version': _currentStorageVersion,
        'notifications': _providerNotifications
            .take(_maxNotificationsPerType)
            .map((n) => n.toJson())
            .toList(),
      };

      // Prepare vendor notifications data
      final vendorData = {
        'version': _currentStorageVersion,
        'notifications': _vendorNotifications
            .take(_maxNotificationsPerType)
            .map((n) => n.toJson())
            .toList(),
      };

      // Save all to storage
      await Future.wait([
        prefs.setString(_customerNotificationsKey, jsonEncode(customerData)),
        prefs.setString(_providerNotificationsKey, jsonEncode(providerData)),
        prefs.setString(_vendorNotificationsKey, jsonEncode(vendorData)),
      ]);

      debugPrint('✅ Saved notifications to storage');
    } catch (e) {
      debugPrint('❌ Error saving notifications to storage: $e');
    }
  }

  Future<void> _migrateStorageIfNeeded(SharedPreferences prefs) async {
    try {
      final currentVersion = prefs.getInt(_storageVersionKey) ?? 0;

      if (currentVersion < _currentStorageVersion) {
        debugPrint(
            '🔄 Migrating notification storage from version $currentVersion to $_currentStorageVersion');

        // Migration logic for future versions
        // For now, just clear old data and set new version
        await Future.wait([
          prefs.remove('customer_notifications'),
          prefs.remove('provider_notifications'),
          prefs.remove('vendor_notifications'),
        ]);

        await prefs.setInt(_storageVersionKey, _currentStorageVersion);
        debugPrint('✅ Storage migration completed');
      }
    } catch (e) {
      debugPrint('❌ Error during storage migration: $e');
    }
  }

  // Public method for manual storage refresh
  Future<void> refreshFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadFromStorage(prefs);
    notifyListeners();
  }
}
