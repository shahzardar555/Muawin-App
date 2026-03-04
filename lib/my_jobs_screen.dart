import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'chats_screen.dart';

/// Max content width used across screens (28rem / 448px).
const double _kMaxContentWidth = 448;

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  int _tabIndex = 0; // 0: Ongoing, 1: History
  int _currentNavIndex = 1; // bottom nav starts on My Jobs

  void _setTab(int i) => setState(() => _tabIndex = i);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top + 48, // pt-12
                      left: 24,
                      right: 24,
                      bottom: 40, // pb-10
                    ),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Large decorative icon
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Transform.rotate(
                            angle: 12 * (math.pi / 180),
                            child: const Opacity(
                              opacity: 0.1,
                              child: Icon(
                                Icons.assignment_rounded,
                                size: 128,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // Back button (glass)
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_back_rounded,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Headline and subtext
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Jobs',
                                    style: GoogleFonts.poppins(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Manage your active assignments',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Colors.white.withValues(alpha: 0.95),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Glass squircle with clipboard icon
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.assignment_rounded,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Segmented control overlapping header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      transform: Matrix4.translationValues(0, -28, 0),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _setTab(0),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _tabIndex == 0
                                      ? primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Ongoing',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: _tabIndex == 0
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _setTab(1),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _tabIndex == 1
                                      ? primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'History',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: _tabIndex == 1
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                      // bottom padding increased for nav bar
                      child: _tabIndex == 0
                          ? _OngoingView(primary: primary)
                          : const _HistoryView(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // sticky nav bar
          MuawinBottomNavigationBar(
            currentIndex: _currentNavIndex,
            onItemTapped: (index) {
              if (index == 0) {
                Navigator.of(context).pop();
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

class _OngoingView extends StatelessWidget {
  const _OngoingView({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Active Job Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: primary, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    // Avatar squircle
                    Stack(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person,
                              size: 28, color: Colors.black54),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saira Khan',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('Active Now',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                            Text('ID: #55012',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Info grid
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(children: [
                        Icon(Icons.location_on_outlined, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Gulberg III, Lahore',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700)))
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.access_time_rounded, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Started: Today, 9:00 AM',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700)))
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.payments_outlined, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text('Rs. 1,800',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700)))
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.call),
                          label: const Text('Call'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Chat'))),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle),
                    label: Text('Mark as Completed',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade600),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.warning_rounded),
                    label: Text('SOS EMERGENCY',
                        style: GoogleFonts.poppins(
                            letterSpacing: 0.2, fontWeight: FontWeight.w800)),
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Empty state CTA if needed
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: Icon(Icons.assignment_rounded,
                        size: 48, color: primary.withValues(alpha: 0.3))),
                const SizedBox(height: 12),
                Text('No active jobs',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Check your feed for new job requests and start earning.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.black54)),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: () {},
                    child: Text('View Job Feed',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w700)))
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.history_rounded,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3))),
          const SizedBox(height: 12),
          Text('No jobs found.',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
