import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'service_provider_feed_screen.dart';
import 'my_jobs_screen.dart';
import 'chats_screen.dart';
import 'service_provider_profile_screen.dart';

class ServiceProviderNotificationsScreen extends StatefulWidget {
  const ServiceProviderNotificationsScreen({super.key});

  @override
  State<ServiceProviderNotificationsScreen> createState() =>
      _ServiceProviderNotificationsScreenState();
}

class _ServiceProviderNotificationsScreenState
    extends State<ServiceProviderNotificationsScreen> {
  int _currentNavIndex = 0;

  // Empty notifications list - all notification logic removed
  final List<Map<String, dynamic>> _notifications = [];

  // Mark all notifications as read (functional but works on empty list)
  void _markAllAsRead() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Color(0xFF047A62),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Clear all notifications (functional but works on empty list)
  void _clearAllNotifications() {
    HapticFeedback.lightImpact();
    setState(() {
      _notifications.clear();
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications cleared'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // Mint-tinted off-white
      body: Stack(
        children: [
          // Main Content
          Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 60,
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF047A62), // Primary Teal
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
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
                        const SizedBox(width: 16),
                        Text(
                          'Notifications',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stay updated with your job requests and activities',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      children: [
                        // Mark as Read Button
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _markAllAsRead,
                            icon: const Icon(Icons.done_all_rounded, size: 18),
                            label: Text(
                              'Mark as Read',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Clear All Button
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _clearAllNotifications,
                            icon: const Icon(Icons.clear_all_rounded, size: 18),
                            label: Text(
                              'Clear All',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Colors.red.withValues(alpha: 0.8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Notifications List
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildEmptyState(),
                ),
              ),
            ],
          ),
          // Sticky Bottom Navigation
          Align(
            alignment: Alignment.bottomCenter,
            child: MuawinBottomNavigationBar(
              currentIndex: _currentNavIndex,
              isProvider: true,
              onItemTapped: (index) {
                if (index == 0) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const ServiceProviderFeedScreen()),
                    (route) => false,
                  );
                  return;
                }
                if (index == 1) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MyJobsScreen()),
                    (route) => false,
                  );
                  return;
                }
                if (index == 2) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ChatsScreen(),
                  ));
                  return;
                }
                if (index == 3) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const ServiceProviderProfileScreen()),
                    (route) => false,
                  );
                  return;
                }
                setState(() {
                  _currentNavIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            child: const Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: Color(0xFF047A62),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF047A62),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! New notifications will appear here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
