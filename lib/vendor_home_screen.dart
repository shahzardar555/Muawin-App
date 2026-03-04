import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screen.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'my_jobs_screen.dart';

/// Header bottom radius 2.5rem (40px).
const double _kHeaderBottomRadius = 40;

/// Header padding: pt-12 (3rem).
const double _kHeaderTopPadding = 48;

/// Profile squircle 3.5rem (w-14 h-14).
const double _kProfileSize = 56;

/// Card radius 1.5rem.
const double _kCardRadius = 24;

/// Premium banner radius 2rem (32px).
const double _kBannerRadius = 32;

/// Max width for centered content (max-w-md).
const double _kMaxContentWidth = 448;

/// Vendor status options.
enum VendorStatus { open, busy, break_, closed }

Color _statusColorFor(VendorStatus s) {
  switch (s) {
    case VendorStatus.open:
      return const Color(0xFF4ADE80); // green-400
    case VendorStatus.busy:
      return const Color(0xFFFBBF24); // amber-400
    case VendorStatus.break_:
      return const Color(0xFF60A5FA); // blue-400
    case VendorStatus.closed:
      return const Color(0xFF94A3B8); // slate-400
  }
}

/// Primary "command center" for shop owners.
class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  VendorStatus _status = VendorStatus.open;
  int _selectedNavIndex = 0;
  int? _replyingReviewIndex;
  final Map<int, String> _reviewReplies = {};

  static const String _vendorName = 'Super Grocery Store';
  static const String _vendorRating = '4.8';
  static const int _vendorReviewCount = 24;

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'title': 'New message',
      'body': 'Customer asked about delivery time',
      'type': 'message',
      'read': false
    },
    {
      'id': '2',
      'title': 'Missed call',
      'body': 'Unknown number tried to reach you',
      'type': 'call',
      'read': false
    },
    {
      'id': '3',
      'title': 'App update',
      'body': 'Muawin Vendor Hub v1.0.5 is available',
      'type': 'app_update',
      'read': true
    },
  ];

  int get _unreadNotificationCount =>
      _notifications.where((n) => n['read'] != true).length;

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationsSheet(
        notifications: _notifications,
        onMarkRead: (id) {
          setState(() {
            final i = _notifications.indexWhere((n) => n['id'] == id);
            if (i >= 0) _notifications[i]['read'] = true;
          });
        },
        onClear: (id) {
          setState(() => _notifications.removeWhere((n) => n['id'] == id));
        },
        onClearAll: () {
          setState(() => _notifications.clear());
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  String get _statusLabel {
    switch (_status) {
      case VendorStatus.open:
        return 'Open';
      case VendorStatus.busy:
        return 'Busy';
      case VendorStatus.break_:
        return 'Break';
      case VendorStatus.closed:
        return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: IndexedStack(
              index: _selectedNavIndex,
              sizing: StackFit.expand,
              children: [
                _DashboardTab(
                  vendorName: _vendorName,
                  vendorRating: _vendorRating,
                  vendorReviewCount: _vendorReviewCount,
                  status: _status,
                  statusLabel: _statusLabel,
                  onStatusChanged: (v) => setState(() => _status = v),
                  notificationCount: _unreadNotificationCount,
                  onNotificationTap: _showNotificationsSheet,
                  replyingReviewIndex: _replyingReviewIndex,
                  vendorReplies: _reviewReplies,
                  onReplyTap: (i) => setState(() => _replyingReviewIndex = i),
                  onReplyCancel: () =>
                      setState(() => _replyingReviewIndex = null),
                  onReplySubmit: (i, text) {
                    setState(() {
                      _reviewReplies[i] = text;
                      _replyingReviewIndex = null;
                    });
                  },
                ),
                _VendorChatsTab(
                  onBack: () => setState(() => _selectedNavIndex = 0),
                ),
                const _VendorProfileTab(),
              ],
            ),
          ),
          MuawinBottomNavigationBar(
            currentIndex: _selectedNavIndex,
            onItemTapped: (index) {
              if (index == 1) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const MyJobsScreen(),
                ));
                return;
              }
              if (index == 2) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _VendorChatsTab(
                    onBack: () => setState(() => _selectedNavIndex = 0),
                  ),
                ));
                return;
              }
              setState(() => _selectedNavIndex = index);
            },
          ),
        ],
      ),
    );
  }
}

/// Dashboard tab content (Vendor Hub).
class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.vendorName,
    required this.vendorRating,
    required this.vendorReviewCount,
    required this.status,
    required this.statusLabel,
    required this.onStatusChanged,
    required this.notificationCount,
    required this.onNotificationTap,
    required this.replyingReviewIndex,
    required this.vendorReplies,
    required this.onReplyTap,
    required this.onReplyCancel,
    required this.onReplySubmit,
  });

  final String vendorName;
  final String vendorRating;
  final int vendorReviewCount;
  final VendorStatus status;
  final String statusLabel;
  final ValueChanged<VendorStatus> onStatusChanged;
  final int notificationCount;
  final void Function(BuildContext context) onNotificationTap;
  final int? replyingReviewIndex;
  final Map<int, String> vendorReplies;
  final ValueChanged<int> onReplyTap;
  final VoidCallback onReplyCancel;
  final void Function(int index, String text) onReplySubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onPrimary = theme.colorScheme.onPrimary;

    return Container(
      color: surface,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top,
          left: 24,
          right: 24,
          bottom: 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sleek header (scrolls with content)
            _DashboardHeader(
              vendorName: vendorName,
              vendorRating: vendorRating,
              vendorReviewCount: vendorReviewCount,
              status: status,
              onStatusChanged: onStatusChanged,
              notificationCount: notificationCount,
              onNotificationTap: () => onNotificationTap(context),
              primary: primary,
              onPrimary: onPrimary,
            ),
            const SizedBox(height: 20),
            _ManagementCard(status: statusLabel),
            const SizedBox(height: 20),
            _PremiumBanner(),
            const SizedBox(height: 24),
            _ReviewsSection(
              replyingIndex: replyingReviewIndex,
              vendorReplies: vendorReplies,
              onReplyTap: onReplyTap,
              onReplyCancel: onReplyCancel,
              onReplySubmit: onReplySubmit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sleek, non-sticky dashboard header.
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.vendorName,
    required this.vendorRating,
    required this.vendorReviewCount,
    required this.status,
    required this.onStatusChanged,
    required this.notificationCount,
    required this.onNotificationTap,
    required this.primary,
    required this.onPrimary,
  });

  final String vendorName;
  final String vendorRating;
  final int vendorReviewCount;
  final VendorStatus status;
  final ValueChanged<VendorStatus> onStatusChanged;
  final int notificationCount;
  final VoidCallback onNotificationTap;
  final Color primary;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            primary.withValues(alpha: 0.92),
          ],
        ),
        borderRadius: BorderRadius.circular(_kHeaderBottomRadius),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: _kProfileSize,
                    height: _kProfileSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.store_rounded, size: 26, color: primary),
                        Positioned(
                          right: 5,
                          bottom: 5,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _statusColorFor(status),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$vendorName ($vendorReviewCount reviews)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: onPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NotificationAnchor(
                    count: notificationCount,
                    primary: primary,
                    onTap: onNotificationTap,
                  ),
                  const SizedBox(width: 10),
                  _StatusDropdownButton(
                    value: status,
                    onChanged: onStatusChanged,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: 16, color: Color(0xFFEAB308)),
              const SizedBox(width: 4),
              Text(
                vendorRating,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.dashboard_rounded, color: onPrimary, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vendor Hub',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: onPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Store Management Dashboard',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: onPrimary.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chats tab (Messages) — Customer Chats screen.
class _VendorChatsTab extends StatefulWidget {
  const _VendorChatsTab({required this.onBack});

  final VoidCallback onBack;

  @override
  State<_VendorChatsTab> createState() => _VendorChatsTabState();
}

class _VendorChatsTabState extends State<_VendorChatsTab> {
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _selectedThread;

  final List<Map<String, dynamic>> _threads = [
    {
      'name': 'Ayesha Khan',
      'snippet': 'Hi, is same day delivery available?',
      'time': '2 min ago',
      'unread': true,
      'isNewCustomer': true,
    },
    {
      'name': 'Rahim Store',
      'snippet': 'Thanks for the quick response!',
      'time': '1 hr ago',
      'unread': false,
      'isNewCustomer': false,
    },
    {
      'name': 'Sara R.',
      'snippet': 'Can you confirm item availability?',
      'time': 'Yesterday',
      'unread': true,
      'isNewCustomer': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _unreadCount => _threads.where((t) => t['unread'] as bool).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onPrimary = theme.colorScheme.onPrimary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final query = _searchController.text.trim().toLowerCase();
    final filtered = _threads.where((t) {
      final name = (t['name'] as String).toLowerCase();
      final snippet = (t['snippet'] as String).toLowerCase();
      return name.contains(query) || snippet.contains(query) || query.isEmpty;
    }).toList();

    final bool isSearching = query.isNotEmpty;
    final bool hasResults = filtered.isNotEmpty;

    final bool showingConversation = _selectedThread != null;
    final selectedThread = _selectedThread;

    return Container(
      color: surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: _kHeaderTopPadding + MediaQuery.paddingOf(context).top,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(_kHeaderBottomRadius),
                    bottomRight: Radius.circular(_kHeaderBottomRadius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (showingConversation) {
                              setState(() => _selectedThread = null);
                            } else {
                              widget.onBack();
                            }
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                showingConversation
                                    ? (selectedThread!['name'] as String)
                                    : 'Customer Chats',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: onPrimary,
                                ),
                              ),
                              if (!showingConversation && _unreadCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '$_unreadCount NEW',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (showingConversation)
                          GestureDetector(
                            onTap: () {
                              // Call customer - could launch url_launcher
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.call_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.group_rounded,
                              color: onPrimary,
                              size: 24,
                            ),
                          ),
                      ],
                    ),
                    if (!showingConversation) ...[
                      const SizedBox(height: 20),
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(Icons.search_rounded,
                                size: 20, color: Colors.white70),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search customers or messages...',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: showingConversation && selectedThread != null
                    ? _ConversationView(
                        thread: selectedThread,
                        primary: primary,
                        muted: muted,
                      )
                    : hasResults
                        ? ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
                            itemBuilder: (context, index) {
                              final t = filtered[index];
                              final bool unread = t['unread'] as bool;
                              final bool isNew = t['isNewCustomer'] as bool;
                              final String name = t['name'] as String;
                              final String snippet = t['snippet'] as String;
                              final String time = t['time'] as String;

                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedThread = t),
                                child: _ChatThreadCard(
                                  name: name,
                                  snippet: snippet,
                                  time: time,
                                  unread: unread,
                                  isNewCustomer: isNew,
                                ),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemCount: filtered.length,
                          )
                        : _ChatsEmptyState(
                            isSearch: isSearching,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vendor Profile tab — primary configuration suite.
class _VendorProfileTab extends StatelessWidget {
  const _VendorProfileTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      color: surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: MediaQuery.paddingOf(context).top + 8,
              bottom: 96,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding & Hero Header: primary/20, rounded-b-40
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(_kHeaderBottomRadius),
                      bottomRight: Radius.circular(_kHeaderBottomRadius),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar 6rem, squircle, 4px white border, edit at bottom-right
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.store_rounded,
                              size: 44,
                              color: primary,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Super Grocery Store',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'SUPERMARKET',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.15 * 10,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 14, color: muted),
                          const SizedBox(width: 4),
                          Text(
                            'Lahore, Pakistan',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Stats Summary Card: -mt-10 overlap
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(_kCardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 22, color: Color(0xFFEAB308)),
                              const SizedBox(height: 4),
                              Text(
                                'Rating',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '24',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Reviews',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '156',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Orders',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Store Management section
                Text(
                  'Store Management',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.12 * 14,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileMenuItem(
                  icon: Icons.store_rounded,
                  label: 'Store Information',
                  onTap: () => _showStoreInformationSheet(context),
                ),
                const SizedBox(height: 8),
                _ProfileMenuItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notification Settings',
                  onTap: () => _showNotificationSettingsSheet(context),
                ),
                const SizedBox(height: 8),
                _ProfileMenuItem(
                  icon: Icons.security_rounded,
                  label: 'Account Security',
                  onTap: () => _showAccountSecuritySheet(context),
                ),
                const SizedBox(height: 8),
                _ProfileMenuItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () => _showHelpSupportSheet(context),
                ),
                const SizedBox(height: 8),
                _ProfileMenuItem(
                  icon: Icons.settings_rounded,
                  label: 'General Settings',
                  onTap: () => _showGeneralSettingsSheet(context),
                ),
                const SizedBox(height: 32),
                // Logout button
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const AuthScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFDC2626)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Muawin Vendor Hub v1.0.4',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1 * 10,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      shadowColor: Colors.black,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 22, color: primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 24, color: primary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

void _showStoreInformationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Store Information',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              const _SheetField(hint: 'Business Name'),
              const SizedBox(height: 12),
              const _SheetField(hint: 'Category'),
              const SizedBox(height: 12),
              const _SheetField(hint: 'Contact Phone'),
              const SizedBox(height: 12),
              const _SheetField(hint: 'Location Address'),
              const SizedBox(height: 12),
              const _SheetField(hint: 'About the Store', maxLines: 3),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Save',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showNotificationSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Notification Settings',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          const _ToggleRow(label: 'Customer Messages', value: true),
          const SizedBox(height: 12),
          const _ToggleRow(label: 'Email Updates', value: false),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

void _showAccountSecuritySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Account Security',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              const _SheetField(hint: 'Current Password', obscure: true),
              const SizedBox(height: 12),
              const _SheetField(hint: 'New Password', obscure: true),
              const SizedBox(height: 12),
              const _SheetField(hint: 'Confirm New Password', obscure: true),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Update',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void _showHelpSupportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Help & Support',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SupportIcon(icon: Icons.chat_rounded, label: 'WhatsApp Support'),
              _SupportIcon(icon: Icons.email_rounded, label: 'Email Support'),
            ],
          ),
          const SizedBox(height: 20),
          ExpansionTile(
            title: Text(
              'Common Questions',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'FAQ content goes here.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

void _showGeneralSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'General Settings',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          const _ToggleRow(label: 'Dark Mode', value: false),
          const SizedBox(height: 16),
          Text(
            'App Language',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: 'English',
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'Urdu', child: Text('Urdu')),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.hint,
    this.obscure = false,
    this.maxLines = 1,
  });

  final String hint;
  final bool obscure;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: obscure,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.black45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: GoogleFonts.poppins(fontSize: 15),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Switch(value: value, onChanged: (_) {}),
      ],
    );
  }
}

class _SupportIcon extends StatelessWidget {
  const _SupportIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 28, color: primary),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

/// Expanded conversation view with message bubbles.
class _ConversationView extends StatelessWidget {
  const _ConversationView({
    required this.thread,
    required this.primary,
    required this.muted,
  });

  final Map<String, dynamic> thread;
  final Color primary;
  final Color muted;

  static final List<Map<String, dynamic>> _sampleMessages = [
    {
      'text': 'Hi, is same day delivery available?',
      'isCustomer': true,
      'time': '2:15 PM'
    },
    {
      'text': 'Yes! We offer same-day delivery for orders placed before 2 PM.',
      'isCustomer': false,
      'time': '2:18 PM'
    },
    {
      'text': 'Great, thanks! I\'ll place my order now.',
      'isCustomer': true,
      'time': '2:20 PM'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            reverse: true,
            itemCount: _sampleMessages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final i = _sampleMessages.length - 1 - index;
              final m = _sampleMessages[i];
              final isCustomer = m['isCustomer'] as bool;
              return Align(
                alignment:
                    isCustomer ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCustomer
                        ? Colors.grey.shade100
                        : primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isCustomer ? 4 : 16),
                      bottomRight: Radius.circular(isCustomer ? 16 : 4),
                    ),
                    border: isCustomer
                        ? null
                        : Border.all(color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        m['text'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m['time'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Type a message...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Single chat thread card.
class _ChatThreadCard extends StatelessWidget {
  const _ChatThreadCard({
    required this.name,
    required this.snippet,
    required this.time,
    required this.unread,
    required this.isNewCustomer,
  });

  final String name;
  final String snippet;
  final String time;
  final bool unread;
  final bool isNewCustomer;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    final Color bgColor =
        unread ? Colors.white : Colors.white.withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: unread ? 0.12 : 0.04),
            blurRadius: unread ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: unread
            ? Border.all(color: primary.withValues(alpha: 0.1), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // Avatar squircle
          Container(
            width: _kProfileSize,
            height: _kProfileSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  _initialsFromName(name),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
                if (unread)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.access_time_rounded,
                        size: 11, color: muted.withValues(alpha: 0.9)),
                    const SizedBox(width: 2),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: muted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (isNewCustomer)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'NEW',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                if (isNewCustomer) const SizedBox(height: 4),
                Text(
                  snippet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initialsFromName(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

/// Empty state widget for chats.
class _ChatsEmptyState extends StatelessWidget {
  const _ChatsEmptyState({required this.isSearch});

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    final icon =
        isSearch ? Icons.search_off_rounded : Icons.chat_bubble_outline_rounded;
    final title = isSearch ? 'No results found' : 'No customer inquiries yet';
    final body = isSearch
        ? 'Try changing your search or filters.'
        : 'When customers message your shop about services or products, they will appear here.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 72,
              color: muted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Notifications bottom sheet: messages, calls, app updates — Mark read / Clear.
class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet({
    required this.notifications,
    required this.onMarkRead,
    required this.onClear,
    required this.onClearAll,
  });

  final List<Map<String, dynamic>> notifications;
  final void Function(String id) onMarkRead;
  final void Function(String id) onClear;
  final VoidCallback onClearAll;

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  late List<Map<String, dynamic>> _list;

  @override
  void initState() {
    super.initState();
    _list = List.from(
        widget.notifications.map((e) => Map<String, dynamic>.from(e)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (_list.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      widget.onClearAll();
                    },
                    child: Text(
                      'Clear all',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Flexible(
            child: _list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: muted,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: _list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = _list[index];
                      final id = n['id'] as String;
                      final read = n['read'] == true;
                      final type = n['type'] as String;
                      IconData icon = Icons.message_rounded;
                      if (type == 'call') icon = Icons.call_rounded;
                      if (type == 'app_update') {
                        icon = Icons.system_update_rounded;
                      }
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: read
                              ? Colors.grey.shade50
                              : primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(icon, size: 22, color: primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n['title'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: read
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    n['body'] as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (!read)
                                        TextButton(
                                          onPressed: () {
                                            widget.onMarkRead(id);
                                            setState(() => n['read'] = true);
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            'Mark read',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: primary,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          widget.onClear(id);
                                          setState(() => _list.removeWhere(
                                              (e) => e['id'] == id));
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Clear',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFDC2626),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Glass-morphism notification anchor: squircle, bell, alert badge.
class _NotificationAnchor extends StatelessWidget {
  const _NotificationAnchor({
    required this.count,
    required this.primary,
    required this.onTap,
  });

  final int count;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  size: 24,
                  color: Colors.white,
                ),
                if (count > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFACC15), // yellow-400
                        shape: BoxShape.circle,
                        border: Border.all(color: primary, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass-morphism status dropdown button (shown in header): compact vertical layout.
class _StatusDropdownButton extends StatelessWidget {
  const _StatusDropdownButton({
    required this.value,
    required this.onChanged,
  });

  final VendorStatus value;
  final ValueChanged<VendorStatus> onChanged;

  String get _label {
    switch (value) {
      case VendorStatus.open:
        return 'Open';
      case VendorStatus.busy:
        return 'Busy';
      case VendorStatus.break_:
        return 'Break';
      case VendorStatus.closed:
        return 'Closed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: PopupMenuButton<VendorStatus>(
            offset: const Offset(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.98),
            onSelected: onChanged,
            itemBuilder: (context) => [
              _buildMenuItem(VendorStatus.open),
              _buildMenuItem(VendorStatus.busy),
              _buildMenuItem(VendorStatus.break_),
              _buildMenuItem(VendorStatus.closed),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS',
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1 * 8,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _statusColorFor(value),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _label,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<VendorStatus> _buildMenuItem(VendorStatus s) {
    String label;
    switch (s) {
      case VendorStatus.open:
        label = 'Open';
        break;
      case VendorStatus.busy:
        label = 'Busy';
        break;
      case VendorStatus.break_:
        label = 'Break';
        break;
      case VendorStatus.closed:
        label = 'Closed';
        break;
    }
    return PopupMenuItem<VendorStatus>(
      value: s,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _statusColorFor(s),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 14)),
        ],
      ),
    );
  }
}

/// Core Management Card: status icon, "Store is [Status]", copy.
class _ManagementCard extends StatelessWidget {
  const _ManagementCard({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    IconData icon = Icons.check_circle_rounded;
    Color iconBg = const Color(0xFF22C55E).withValues(alpha: 0.15);
    if (status == 'Busy') {
      icon = Icons.schedule_rounded;
      iconBg = const Color(0xFFEAB308).withValues(alpha: 0.15);
    } else if (status == 'Break') {
      icon = Icons.free_breakfast_rounded;
      iconBg = const Color(0xFFF97316).withValues(alpha: 0.15);
    } else if (status == 'Closed') {
      icon = Icons.cancel_rounded;
      iconBg = const Color(0xFFEF4444).withValues(alpha: 0.15);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status == 'Break'
                          ? 'Store is currently on a Break'
                          : 'Store is $status',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Update your status to manage visibility',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your store availability and profile from this central hub. Use the navigation bar below to access chats and settings.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: muted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium Promotion Banner: gradient, "Boost Your Sales", Rs. 99 / per day.
class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D9488), // teal-600
            Color(0xFF047857), // emerald-700
            Color(0xFF134E4A), // teal-900
          ],
        ),
        borderRadius: BorderRadius.circular(_kBannerRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VENDOR PROMOTION',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15 * 10,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Boost Your Sales',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rs. 99 / per day',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 18, color: Colors.white.withValues(alpha: 0.95)),
              const SizedBox(width: 8),
              Text(
                '#1 Spot in Vendor listings',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  size: 18, color: Colors.white.withValues(alpha: 0.95)),
              const SizedBox(width: 8),
              Text(
                'Unlimited customer chat access',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            elevation: 2,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                child: Text(
                  'Promote My Store',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D9488),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recent Customer Reviews + Reply
class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({
    required this.replyingIndex,
    required this.vendorReplies,
    required this.onReplyTap,
    required this.onReplyCancel,
    required this.onReplySubmit,
  });

  final int? replyingIndex;
  final Map<int, String> vendorReplies;
  final ValueChanged<int> onReplyTap;
  final VoidCallback onReplyCancel;
  final void Function(int index, String text) onReplySubmit;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  final TextEditingController _replyController = TextEditingController();

  static final List<Map<String, dynamic>> _reviews = [
    {
      'initials': 'AK',
      'rating': 5,
      'text': 'Great service and quick delivery. Will order again!'
    },
    {
      'initials': 'SR',
      'rating': 4,
      'text': 'Good quality products. Store was a bit busy.'
    },
  ];

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review_rounded, size: 22, color: primary),
                const SizedBox(width: 8),
                Text(
                  'Recent Customer Reviews',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_reviews.length, (i) {
          final r = _reviews[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primary,
                        child: Text(
                          r['initials'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ...List.generate(
                          5,
                          (s) => Icon(
                                s < (r['rating'] as int)
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 18,
                                color: const Color(0xFFEAB308),
                              )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    r['text'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: muted,
                      height: 1.4,
                    ),
                  ),
                  if (widget.vendorReplies[i] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.store_rounded, size: 16, color: primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.vendorReplies[i]!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (widget.replyingIndex == i) ...[
                    TextField(
                      controller: _replyController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Write your reply...',
                        hintStyle:
                            GoogleFonts.poppins(color: muted, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: widget.onReplyCancel,
                          child: Text('Cancel',
                              style: GoogleFonts.poppins(color: muted)),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            final text = _replyController.text.trim();
                            if (text.isNotEmpty) {
                              widget.onReplySubmit(i, text);
                              _replyController.clear();
                            }
                          },
                          child: Text('Send',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ] else if (widget.vendorReplies[i] == null)
                    OutlinedButton.icon(
                      onPressed: () => widget.onReplyTap(i),
                      icon: const Icon(Icons.reply_rounded, size: 18),
                      label: Text(
                        'Reply to review',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
