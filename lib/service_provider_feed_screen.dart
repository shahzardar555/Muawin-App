import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'my_jobs_screen.dart';
import 'chats_screen.dart';

/// Max width 28rem (448px), centered (max-w-md mx-auto).
const double _kMaxContentWidth = 448;

/// Header bottom radius 2rem (32px).
const double _kHeaderRadius = 32;

/// Profile squircle 3rem (w-12 h-12).
const double _kProfileSize = 48;

/// Card radius 1.5rem.
const double _kCardRadius = 24;

/// Provider status options.
enum ProviderAvailability { available, busy, offline }

Color _availabilityColor(ProviderAvailability s) {
  switch (s) {
    case ProviderAvailability.available:
      return const Color(0xFF4ADE80);
    case ProviderAvailability.busy:
      return const Color(0xFFFBBF24);
    case ProviderAvailability.offline:
      return const Color(0xFF94A3B8);
  }
}

String _availabilityLabel(ProviderAvailability s) {
  switch (s) {
    case ProviderAvailability.available:
      return 'Available';
    case ProviderAvailability.busy:
      return 'Busy';
    case ProviderAvailability.offline:
      return 'Offline';
  }
}

/// Service Provider Feed — the professional's opportunity dashboard.
class ServiceProviderFeedScreen extends StatefulWidget {
  const ServiceProviderFeedScreen({super.key});

  @override
  State<ServiceProviderFeedScreen> createState() =>
      _ServiceProviderFeedScreenState();
}

class _ServiceProviderFeedScreenState extends State<ServiceProviderFeedScreen> {
  ProviderAvailability _status = ProviderAvailability.available;
  int _currentNavIndex = 0;

  final List<Map<String, dynamic>> _jobAlerts = [
    {
      'id': '#48291',
      'customer': 'Ahmed R.',
      'distance': '1.2 km',
      'details':
          'Need a driver for airport pickup. Must have own car. Round trip required, estimated 2 hours total.',
      'location': 'DHA Phase 6, Lahore',
      'time': 'Today, 3:00 PM',
      'price': 'Rs. 1,500',
      'highPriority': true,
    },
    {
      'id': '#48285',
      'customer': 'Fatima S.',
      'distance': '3.5 km',
      'details':
          'Looking for a driver for weekly grocery runs. Flexible timing, prefer mornings.',
      'location': 'Gulberg III, Lahore',
      'time': 'Tomorrow, 10:00 AM',
      'price': 'Rs. 800',
      'highPriority': false,
    },
    {
      'id': '#48270',
      'customer': 'Bilal K.',
      'distance': '5.0 km',
      'details':
          'Office commute driver needed for 1 month. Monday to Friday, 8 AM to 6 PM.',
      'location': 'Johar Town, Lahore',
      'time': 'Mon, 8:00 AM',
      'price': 'Rs. 25,000/mo',
      'highPriority': false,
    },
  ];

  void _showStatusSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Update Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ...ProviderAvailability.values.map((s) => ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _availabilityColor(s),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    _availabilityLabel(s),
                    style: GoogleFonts.poppins(
                      fontWeight:
                          _status == s ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  trailing: _status == s
                      ? const Icon(Icons.check_rounded,
                          color: Color(0xFF047A62))
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    setState(() => _status = s);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showNegotiationModal(Map<String, dynamic> job) {
    final priceController = TextEditingController();
    final timeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Negotiate Terms',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Send a counter-offer to ${job['customer']}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              // Proposed Price
              Text(
                'PROPOSED PRICE (RS.)',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 1200',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Customer's budget: ${job['price']}",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 20),
              // Proposed Time
              Text(
                'PROPOSED TIME',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: timeController,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 4:00 PM',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Customer's preference: ${job['time']}",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF047A62),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Send Offer'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;

    final int availableCount =
        _jobAlerts.where((j) => true).length; // all shown

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Column(
                children: [
                  // ─── Premium Glass-Morphism Header ───
                  _FeedHeader(
                    status: _status,
                    primary: primary,
                    availableCount: availableCount,
                    onStatusTap: _showStatusSheet,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  // ─── Scrollable Feed Content ───
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section Header
                          _SectionHeader(availableCount: availableCount),
                          const SizedBox(height: 16),
                          // Job Alert Cards
                          ..._jobAlerts.map((job) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _JobLeadCard(
                                  job: job,
                                  primary: primary,
                                  onDecline: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _jobAlerts.remove(job));
                                  },
                                  onNegotiate: () => _showNegotiationModal(job),
                                  onAccept: () {
                                    HapticFeedback.mediumImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Job ${job['id']} accepted!',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: primary,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )),
                          const SizedBox(height: 8),
                          // ─── Promotion Hero Section ───
                          const _PromotionHero(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ─── Sticky Bottom Navigation Bar ───
          MuawinBottomNavigationBar(
            currentIndex: _currentNavIndex,
            onItemTapped: (index) {
              if (index == 1) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const MyJobsScreen(),
                ));
                return;
              }
              if (index == 2) {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const ChatsScreen(),
                ));
                return;
              }
              setState(() {
                _currentNavIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
}

/// ─── Premium Glass-Morphism Header ───
class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.status,
    required this.primary,
    required this.availableCount,
    required this.onStatusTap,
    required this.onBack,
  });

  final ProviderAvailability status;
  final Color primary;
  final int availableCount;
  final VoidCallback onStatusTap;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPad + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(_kHeaderRadius),
          bottomRight: Radius.circular(_kHeaderRadius),
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
          // Navigation & Profile Block
          Row(
            children: [
              // Back button — glass circle
              GestureDetector(
                onTap: onBack,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Profile squircle with status dot
              Stack(
                children: [
                  Container(
                    width: _kProfileSize,
                    height: _kProfileSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          Icon(Icons.person_rounded, size: 28, color: primary),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _availabilityColor(status),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Provider name + rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ahmad M.',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(
                            4,
                            (_) => const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Color(0xFFFBBF24),
                                )),
                        const Icon(
                          Icons.star_half_rounded,
                          size: 14,
                          color: Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '124 reviews',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status Management Button
              GestureDetector(
                onTap: onStatusTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'STATUS',
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _availabilityLabel(status),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ─── Section Header: "New Requests" with pulse indicator ───
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.availableCount});

  final int availableCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Pulse indicator
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF4ADE80),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'New Requests',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF047A62).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$availableCount Available',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF047A62),
            ),
          ),
        ),
      ],
    );
  }
}

/// ─── Job Lead Card ─── (Standard & High Priority variants)
class _JobLeadCard extends StatelessWidget {
  const _JobLeadCard({
    required this.job,
    required this.primary,
    required this.onDecline,
    required this.onNegotiate,
    required this.onAccept,
  });

  final Map<String, dynamic> job;
  final Color primary;
  final VoidCallback onDecline;
  final VoidCallback onNegotiate;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final bool isHighPriority = job['highPriority'] as bool;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isHighPriority
            ? const Color(0xFFFFFBEB).withValues(alpha: 0.4)
            : Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: isHighPriority
            ? Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.6))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // High Priority Badge
          if (isHighPriority) ...[
            Text(
              'HIGH PRIORITY',
              style: GoogleFonts.poppins(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Identity Row
          Row(
            children: [
              Expanded(
                child: Text(
                  job['customer'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                job['distance'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                job['id'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Lead Details
          Text(
            job['details'] as String,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          // Data Grid
          Row(
            children: [
              _DataChip(
                icon: Icons.location_on_outlined,
                text: job['location'] as String,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _DataChip(
                icon: Icons.access_time_rounded,
                text: job['time'] as String,
              ),
              const SizedBox(width: 8),
              _DataChip(
                icon: Icons.payments_outlined,
                text: job['price'] as String,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Segmented Actions
          Row(
            children: [
              // Decline
              Expanded(
                child: GestureDetector(
                  onTap: onDecline,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Decline',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Negotiate
              Expanded(
                child: GestureDetector(
                  onTap: onNegotiate,
                  child: Container(
                    height: 44,
                    color: Colors.grey.shade100,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          'Negotiate',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Accept Job
              Expanded(
                child: GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(12),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Accept Job',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Standard Job Card (ID: #48295) — exact design implementation for standard priority
class _StandardJobCard extends StatefulWidget {
  const _StandardJobCard({
    required this.primary,
    required this.onDecline,
    required this.onNegotiate,
    required this.onAccept,
  });

  final Color primary;
  final VoidCallback onDecline;
  final VoidCallback onNegotiate;
  final VoidCallback onAccept;

  @override
  State<_StandardJobCard> createState() => _StandardJobCardState();
}

class _StandardJobCardState extends State<_StandardJobCard> {
  bool _hover = false;

  void _setHover(bool v) => setState(() => _hover = v);

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.primary.withValues(alpha: _hover ? 0.4 : 0.1);

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Squircle icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.public, color: widget.primary, size: 20),
                ),
                const SizedBox(width: 12),
                // Identity block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Omar Ali',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: #48295'.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Distance
                Text(
                  '3.5 km',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Lead info
            Text(
              'Pickup and drop service for children to school. Daily morning shift required.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // Data info grid
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: widget.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Model Town, Lahore',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 14, color: Colors.black54),
                            const SizedBox(width: 8),
                            Text(
                              'Tomorrow, 10:00 AM',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: widget.primary.withValues(alpha: 0.12),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Rs. 1,200',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: widget.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Segmented Interaction Row
            Container(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1)),
              ),
              child: Row(
                children: [
                  // Decline
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onDecline,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          'Decline',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Separator
                  Container(width: 1, height: 48, color: Colors.grey.shade100),
                  // Negotiate
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onNegotiate,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.message_outlined,
                                size: 16, color: widget.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Negotiate',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: widget.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Separator
                  Container(width: 1, height: 48, color: Colors.grey.shade100),
                  // Accept Job
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onAccept,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.primary,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Accept Job',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
}

/// Small data chip used in the card data grid.
class _DataChip extends StatelessWidget {
  const _DataChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.black45),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Premium Promotion Hero Section ───
class _PromotionHero extends StatefulWidget {
  const _PromotionHero();

  @override
  State<_PromotionHero> createState() => _PromotionHeroState();
}

class _PromotionHeroState extends State<_PromotionHero>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _scale;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _rotation = Tween<double>(begin: -0.21, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _kIndigo600 = Color(0xFF4F46E5);
  static const _kBlue700 = Color(0xFF1D4ED8);
  static const _kIndigo900 = Color(0xFF3730A3);
  static const _kYellow400 = Color(0xFFFBBF24);
  static const _kBlue100 = Color(0xFFDBEAFE);
  static const _kBlue200 = Color(0xFFBFDBFE);

  static const List<String> _benefits = [
    'Top position in search results',
    '"Featured" badge on your profile',
    'Priority alerts for new jobs',
    'Professional profile review',
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _controller.reverse();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(32), // p-8 = 2rem
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kIndigo600, _kBlue700, _kIndigo900],
            ),
            borderRadius: BorderRadius.circular(32), // rounded-[32px]
            boxShadow: [
              BoxShadow(
                color: _kIndigo600.withValues(alpha: 0.35),
                blurRadius: 32,
                offset: const Offset(0, 12),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: _kIndigo900.withValues(alpha: 0.2),
                blurRadius: 48,
                offset: const Offset(0, 20),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ─ Decorative Background Trophy ─
              Positioned(
                right: -20,
                top: -10,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotation.value,
                      child: Transform.scale(
                        scale: _scale.value,
                        child: child,
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 160, // w-40
                    height: 192, // h-48
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: 160,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
              // ─ Content Column ─
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) Top-Left Badge (Category)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              size: 16,
                              color: _kYellow400,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PRO PROMOTION',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0, // 0.2em
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 2) Hero Typography — "Get Featured"
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 30, // text-3xl
                        fontWeight: FontWeight.w900, // font-black
                        color: Colors.white,
                        height: 1.15,
                      ),
                      children: const [
                        TextSpan(text: 'Get '),
                        TextSpan(
                          text: 'Featured',
                          style: TextStyle(color: _kYellow400),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Marketing Body
                  SizedBox(
                    width: 220, // max-w-[220px]
                    child: Text(
                      'Stand out from the crowd and get up to 5x more job requests.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _kBlue100,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 3) Pricing Display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rs. 99',
                        style: GoogleFonts.poppins(
                          fontSize: 36, // text-4xl
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '/ per day',
                        style: GoogleFonts.poppins(
                          fontSize: 14, // text-sm
                          fontWeight: FontWeight.w700,
                          color: _kBlue200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 4) Benefit Checklist
                  ...List.generate(
                      _benefits.length,
                      (i) => Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  i < _benefits.length - 1 ? 8 : 0, // space-y-2
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 16, // w-4
                                  height: 16, // h-4
                                  decoration: const BoxDecoration(
                                    color: _kYellow400,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 10,
                                    color: _kIndigo600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _benefits[i],
                                    style: GoogleFonts.poppins(
                                      fontSize: 11, // text-[11px]
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                  const SizedBox(height: 24),
                  // 5) Primary CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 56, // h-14 = 3.5rem
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _kIndigo600,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16), // rounded-2xl
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Promote My Profile',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kIndigo600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: _kIndigo600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
