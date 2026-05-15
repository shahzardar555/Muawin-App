import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'widgets/bottom_navigation_bar.dart';
import 'customer_home_screen.dart';
import 'post_job_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_messages_screen.dart';
import 'services/provider_data_service.dart';

/// Customer Jobs Screen (/customer/jobs)
/// Provides clear status tracking and safety protocols through a tiered card hierarchy.
class CustomerJobsScreen extends StatefulWidget {
  const CustomerJobsScreen({super.key});

  @override
  State<CustomerJobsScreen> createState() => _CustomerJobsScreenState();
}

class _CustomerJobsScreenState extends State<CustomerJobsScreen>
    with TickerProviderStateMixin {
  late Function(BuildContext, Map<String, dynamic>, Color)? onShowDetails;
  late TabController _tabController;
  List<Map<String, dynamic>> _ongoingJobs = [];
  List<Map<String, dynamic>> _historyJobs = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _customerId;

  @override
  void initState() {
    super.initState();
    onShowDetails = null; // Initialize to null
    _tabController = TabController(length: 2, vsync: this);
    _loadJobs(); // Add this line
  }

  Future<String?> _getCustomerId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final customer = await Supabase.instance.client
          .from('customers')
          .select('id')
          .eq('profile_id', profile['id'])
          .single();

      return customer['id'] as String?;
    } catch (e) {
      debugPrint('Error getting customer: $e');
      return null;
    }
  }

  Future<void> _loadJobs() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Get customer ID first
      _customerId = await _getCustomerId();

      if (_customerId == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      // Load all jobs for this customer
      final allJobs = await Supabase.instance.client
          .from('jobs')
          .select("""
          id,
          status,
          scheduled_date,
          scheduled_time,
          total_amount,
          created_at,
          service_category,
          location,
          description,
          providers(
            id,
            service_category,
            city,
            rating,
            profiles(
              full_name,
              profile_image_url,
              phone_number
            )
          )
        """)
          .eq('customer_id', _customerId!)
          .order('created_at', ascending: false);

      // Split into ongoing and history
      final ongoing = <Map<String, dynamic>>[];
      final history = <Map<String, dynamic>>[];

      for (final job in allJobs) {
        final status = job['status'] as String? ?? '';

        if (status == 'active' ||
            status == 'scheduled' ||
            status == 'pending') {
          ongoing.add(job);
        } else {
          history.add(job);
        }
      }

      if (mounted) {
        setState(() {
          _ongoingJobs = ongoing;
          _historyJobs = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading jobs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _cancelJob(String jobId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel Job',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this job?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Yes Cancel',
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('jobs').update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', jobId);

        // Reload jobs after cancel
        _loadJobs();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Job cancelled successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: const Color(0xFF047A62),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('Cancel error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not cancel job',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF088771), // Muawin Primary Teal
              Color(0xFF064e3b), // Tailwind Emerald 900
            ],
          ),
        ),
        child: Column(
          children: [
            // 1. PREMIUM VISUAL HEADER
            _buildHeader(primary),

            const SizedBox(height: 16),

            // 2. TAB NAVIGATION
            _buildTabBar(),

            // 3. CONTENT AREA
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadJobs,
                color: const Color(0xFF047A62),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF047A62),
                        ),
                      )
                    : _hasError
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Could not load jobs',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadJobs,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF047A62),
                                  ),
                                  child: Text(
                                    'Try Again',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildTabBarView(),
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: MuawinBottomNavigationBar(
        currentIndex: 1, // Jobs is index 1
        onItemTapped: (index) {
          if (index == 0) {
            // Navigate to Home
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
              (route) => false,
            );
          } else if (index == 2) {
            // Navigate to Post Job
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PostJobScreen()),
            );
          } else if (index == 3) {
            // Navigate to Messages
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerMessagesScreen()),
            );
          } else if (index == 4) {
            // Navigate to Profile
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
            );
          }
          // Jobs (index 1) is current screen, no navigation needed
        },
      ),
    );
  }

  // 1. PREMIUM VISUAL HEADER
  Widget _buildHeader(Color primary) {
    return Container(
      width: double.infinity, // Full width
      padding: const EdgeInsets.only(
        top: 32, // Reduced from 64 to 32
        left: 24,
        right: 24,
        bottom: 20, // Reduced from 40 to 20
      ),
      decoration: BoxDecoration(
        // Backdrop: Gradient fill of Muawin Primary Teal
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF088771), // Muawin Primary Teal
            Color(0xFF064e3b), // Tailwind Emerald 900
          ],
        ),
        // Geometry: Bottom corner radius of 2.5rem (rounded-b-[40px])
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20), // Reduced from 40 to 20
          bottomRight: Radius.circular(20), // Reduced from 40 to 20
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.25), // Large shadow (shadow-lg)
            blurRadius: 12, // Reduced from 20 to 12
            spreadRadius: 3, // Reduced from 5 to 3
            offset: const Offset(0, 4), // Reduced from 0,8 to 0,4
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Visual Depth: Massive background ClipboardList icon at 8rem, 10% opacity, rotated -12 degrees
          Positioned(
            top: -15, // Reduced from -20 to -15
            right: -15, // Reduced from -20 to -15
            child: Transform.rotate(
              angle: -0.21, // -12 degrees in radians
              child: Icon(
                Icons.work_outline,
                size: 80, // Reduced from 128 to 80
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Header Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row without back button
              Row(
                children: [
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Screen Title: "My Jobs"
                        Text(
                          'My Jobs',
                          style: GoogleFonts.poppins(
                            fontSize: 36, // Reduced from 60 to 36
                            fontWeight: FontWeight
                                .w700, // Reduced from w900 to w700 (bold)
                            color: Colors.white, // text-white (#FFFFFF)
                            letterSpacing: -0.025, // tracking-tight (-0.025em)
                            height: 1, // leading-none (line height: 1)
                          ),
                        ),
                        const SizedBox(height: 8), // Reduced from 12 to 8
                        // Subtitle: Status overview
                        Text(
                          'Track your ongoing and completed service requests',
                          style: GoogleFonts.inter(
                            // Inter font family
                            fontSize: 16, // Reduced from 24 to 16
                            fontWeight: FontWeight.w500, // font-medium (500)
                            color: const Color.fromRGBO(
                                248, 255, 248, 0.8), // hsl(168 100% 98% / 0.8)
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. NON-STICKY TAB NAVIGATION
  Widget _buildTabBar() {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF088771), // Muawin Primary Teal
              Color(0xFF064e3b), // Tailwind Emerald 900
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorWeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: primary, // Use primary color for unselected text
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Ongoing'),
          Tab(text: 'History'),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _OngoingJobsView(
            jobs: _ongoingJobs,
            primary: Theme.of(context).colorScheme.primary,
            onShowDetails: _showJobDetailsDialog,
            onCancelJob: _cancelJob),
        _HistoryJobsView(
            jobs: _historyJobs,
            primary: Theme.of(context).colorScheme.primary,
            onShowDetails: _showJobDetailsDialog),
      ],
    );
  }

  // 4. JOB DETAILS DIALOG
  void _showJobDetailsDialog(
      BuildContext context, Map<String, dynamic> job, Color primary) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
            vertical: MediaQuery.of(context).size.height * 0.1,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Job Details',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Job Info
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJobDetailRow('Job ID', job['id']),
                    _buildJobDetailRow('Category', _getValidCategory(job)),
                    _buildJobDetailRow('Status', job['status']),
                    _buildJobDetailRow('Posted', job['postedDate']),
                    _buildJobDetailRow('Budget', 'PKR ${job['total_amount']}'),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getValidCategory(Map<String, dynamic> job) {
    // List of valid categories from customer home screen
    const validCategories = [
      'Maid',
      'Gardener',
      'Driver',
      'Domestic Helper',
      'Security Guard',
      'Baby Sitter',
      'Cook',
      'Washerman',
      'Tutor',
    ];

    // Check providerCategory first, then category
    String categoryToCheck = job['providerCategory'] as String;

    // Return the category if it's valid, otherwise return a default
    if (validCategories.contains(categoryToCheck)) {
      return categoryToCheck;
    }

    // Try to find a close match or return a default
    String lowerCategory = categoryToCheck.toLowerCase();
    for (String validCategory in validCategories) {
      if (validCategory.toLowerCase().contains(lowerCategory) ||
          lowerCategory.contains(validCategory.toLowerCase())) {
        return validCategory;
      }
    }

    // Return a default category if no match found
    return 'General Service';
  }

  Widget _buildJobDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OngoingJobsView extends StatelessWidget {
  const _OngoingJobsView({
    required this.jobs,
    required this.primary,
    required this.onShowDetails,
    required this.onCancelJob,
  });

  final List<Map<String, dynamic>> jobs;
  final Color primary;
  final Function(BuildContext, Map<String, dynamic>, Color)? onShowDetails;
  final Function(String) onCancelJob;

  @override
  Widget build(BuildContext context) {
    // Separate jobs by status
    final activeJobs =
        jobs.where((job) => job['status'] == 'In Progress').toList();
    final scheduledJobs =
        jobs.where((job) => job['status'] == 'Scheduled').toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Active Jobs Section
          if (activeJobs.isNotEmpty) ...[
            _buildSectionHeader('Active Jobs', Icons.circle, Colors.green),
            ...activeJobs.map((job) => _JobCard(
                job: job,
                primary: primary,
                onShowDetails: onShowDetails,
                onCancelJob: onCancelJob)),
          ],

          // Scheduled Jobs Section
          if (scheduledJobs.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Scheduled Jobs', Icons.schedule, Colors.blue),
            ...scheduledJobs.map((job) => _JobCard(
                job: job,
                primary: primary,
                onShowDetails: onShowDetails,
                onCancelJob: onCancelJob)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: iconColor,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// History Jobs View
class _HistoryJobsView extends StatelessWidget {
  const _HistoryJobsView({
    required this.jobs,
    required this.primary,
    required this.onShowDetails,
  });

  final List<Map<String, dynamic>> jobs;
  final Color primary;
  final Function(BuildContext, Map<String, dynamic>, Color)? onShowDetails;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...jobs.map((job) => _JobCard(
              job: job, primary: primary, onShowDetails: onShowDetails)),
        ],
      ),
    );
  }
}

// Job Card Component
class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.primary,
    this.onShowDetails,
    this.onCancelJob,
  });

  final Map<String, dynamic> job;
  final Color primary;
  final Function(BuildContext, Map<String, dynamic>, Color)? onShowDetails;
  final Function(String)? onCancelJob;

  @override
  Widget build(BuildContext context) {
    final status = job['status'] as String;

    // Show enhanced design for "In Progress", "Scheduled", "Pending", "Completed", and "Cancelled" jobs
    if (status == 'In Progress') {
      return _buildInProgressCard(context);
    } else if (status == 'Scheduled') {
      return _buildScheduledCard(context);
    } else if (status == 'Pending') {
      return _buildPendingCard(context);
    } else if (status == 'Completed') {
      return _buildCompletedCard(context);
    } else if (status == 'Cancelled') {
      return _buildCancelledCard(context);
    }

    return _buildStandardCard(context);
  }

  Widget _buildInProgressCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Physics-based tap compression handled by GestureDetector
        if (onShowDetails != null) {
          onShowDetails!(context, job, primary);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28), // 1.75rem = 28px
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. VISUAL HEADER ROW
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Avatar with Category and Job ID
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Category Icon Circle
                      Container(
                        width: 56, // 3.5rem = 56px
                        height: 56, // 3.5rem = 56px
                        decoration: BoxDecoration(
                          color: primary.withValues(
                              alpha: 0.1), // Primary Teal at 10% opacity
                          borderRadius: BorderRadius.circular(
                              28), // Circle shape (56px/2 = 28px)
                        ),
                        child: Icon(
                          Icons.cleaning_services, // Cleaning Services icon
                          size: 28, // 1.75rem = 28px
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Category and Job ID parallel to icon
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Name
                          Text(
                            job['service_category'] ?? 'Service',
                            style: GoogleFonts.poppins(
                              fontSize: 18, // 1.125rem = 18px
                              fontWeight: FontWeight.bold,
                              height: 1, // leading-none
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Job ID
                          Text(
                            job['id'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10, // 0.625rem = 10px
                              fontWeight: FontWeight.w900, // Black (900) weight
                              color: Colors.grey[600], // muted gray
                              letterSpacing: 2.0, // tracking-widest
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right side: In Progress Status Pill
                  Container(
                    height: 24, // Exactly 1.5rem = 24px (h-6)
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0), // Exactly 0.75rem = 12px (px-3)
                    decoration: BoxDecoration(
                      color: primary, // Muawin Primary Teal (bg-primary)
                      borderRadius:
                          BorderRadius.circular(12), // Full-round pill shape
                      // No border (border-none)
                    ),
                    child: Center(
                      child: Text(
                        'In Progress',
                        style: GoogleFonts.inter(
                          // Inter font (Standard UI font)
                          fontSize: 9, // Exactly 0.56rem = 9px (text-[9px])
                          fontWeight: FontWeight.w900, // Black / 900 weight
                          color: Colors
                              .white, // Primary Foreground (text-primary-foreground)
                          letterSpacing:
                              0.9, // Exactly 0.1em tracking (tracking-[0.1em])
                          height: 1, // Prevents extra line height
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. ASSIGNED PROFESSIONAL SECTION
            Container(
              padding: const EdgeInsets.all(16), // 1rem padding
              decoration: BoxDecoration(
                color: Colors.grey[50], // bg-surface
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Profile Picture of Service Provider
                  Container(
                    width: 48, // 3rem = 48px
                    height: 48, // 3rem = 48px
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          24), // Circle shape (48px/2 = 24px)
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildProviderProfileImage(job),
                  ),
                  const SizedBox(width: 12),

                  // Meta Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Assigned Helper',
                          style: GoogleFonts.poppins(
                            fontSize: 9, // 0.56rem = 9px
                            fontWeight: FontWeight.w900, // extra-bold
                            color: Colors.grey[600], // muted gray
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Name
                        Text(
                          job['providers']?['profiles']?['full_name'] ??
                              'Provider',
                          style: GoogleFonts.poppins(
                            fontSize: 14, // 0.875rem = 14px
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Rating
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              '${job['rating'] ?? '4.8'}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Group
                  Row(
                    children: [
                      // Phone Button
                      GestureDetector(
                        onTap: () => _makePhoneCall(context),
                        child: Container(
                          width: 40, // 2.5rem = 40px
                          height: 40, // 2.5rem = 40px
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.phone,
                            size: 18,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Message Button
                      GestureDetector(
                        onTap: () {
                          // Navigate to specific chat with assigned service provider
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerMessagesScreen(
                                providerName: job['provider'] as String? ??
                                    'Service Provider',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 40, // 2.5rem = 40px
                          height: 40, // 2.5rem = 40px
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.message,
                            size: 18,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. METADATA GRID
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Time Capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // bg-surface
                        borderRadius:
                            BorderRadius.circular(12), // 0.75rem = 12px
                        border: Border.all(
                          color: Colors.grey
                              .withValues(alpha: 0.1), // border-secondary/10
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14, // 0.875rem = 14px
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['postedDate'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 11, // 0.68rem = 11px
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600], // muted gray
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Location Capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // bg-surface
                        borderRadius:
                            BorderRadius.circular(12), // 0.75rem = 12px
                        border: Border.all(
                          color: Colors.grey
                              .withValues(alpha: 0.1), // border-secondary/10
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14, // 0.875rem = 14px
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['location'] as String? ?? 'Location',
                            style: GoogleFonts.poppins(
                              fontSize: 11, // 0.68rem = 11px
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600], // muted gray
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. FOOTER & BUDGET ROW
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price Anchor
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUDGET',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'PKR ${job['total_amount']}',
                        style: GoogleFonts.poppins(
                          fontSize: 16, // 1rem = 16px
                          fontWeight: FontWeight.w900, // Black (900) weight
                          color: primary, // Primary Teal
                        ),
                      ),
                    ],
                  ),

                  // View Details Button
                  GestureDetector(
                    onTap: () {
                      if (onShowDetails != null) {
                        onShowDetails!(context, job, primary);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. CANCEL JOB BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  // Show cancel job confirmation
                  _showCancelJobDialog(context);
                },
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      0.8, // 80% of card horizontal length
                  height: 48, // 3rem = 48px
                  decoration: BoxDecoration(
                    color: const Color(
                        0xFFDADC85), // Light yellow-green background
                    borderRadius:
                        BorderRadius.circular(24), // Pill shape (48px/2 = 24px)
                    border: Border.all(
                      color:
                          const Color(0xFFC8C875), // Darker yellow-green border
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Cancel Job',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black, // Black text color
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8), // Vertical space between buttons

            // 6. HIGH-IMPACT SOS BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () => _triggerSOSAlert(context),
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      0.8, // 80% of card horizontal length
                  height: 56, // 3.5rem = 56px
                  decoration: BoxDecoration(
                    color: Colors.red[600], // High-saturation Red-600
                    boxShadow: [
                      // Outer glow layer
                      BoxShadow(
                        color: Colors.red
                            .withValues(alpha: 0.6), // Stronger red glow
                        blurRadius: 20,
                        spreadRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                      // Middle glow layer
                      BoxShadow(
                        color: Colors.red
                            .withValues(alpha: 0.4), // Medium red glow
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                      // Inner shadow for depth
                      BoxShadow(
                        color: Colors.red
                            .withValues(alpha: 0.3), // Subtle red glow
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(28), // Squircle shape
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SOS EMERGENCY',
                        style: GoogleFonts.poppins(
                          fontSize: 12, // 0.75rem = 12px
                          fontWeight:
                              FontWeight.w700, // bold (less bold than w900)
                          color: Colors.white,
                          letterSpacing:
                              2.4, // extreme wide tracking (0.2em for 12px = 2.4px)
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Physics-based tap compression handled by GestureDetector
        if (onShowDetails != null) {
          onShowDetails!(context, job, primary);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28), // 1.75rem = 28px
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08), // shadow-lg
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. VISUAL HEADER ROW
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Avatar with Category and Job ID
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Category Icon Circle
                      Container(
                        width: 56, // 3.5rem = 56px
                        height: 56, // 3.5rem = 56px
                        decoration: BoxDecoration(
                          color: primary.withValues(
                              alpha: 0.1), // Primary Teal at 10% opacity
                          borderRadius: BorderRadius.circular(
                              28), // Circle shape (56px/2 = 28px)
                        ),
                        child: Icon(
                          Icons.directions_car, // Driver icon for scheduled job
                          size: 28, // 1.75rem = 28px
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Category and Job ID parallel to icon
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Name
                          Text(
                            job['service_category'] ?? 'Service',
                            style: GoogleFonts.poppins(
                              fontSize: 18, // 1.125rem = 18px
                              fontWeight: FontWeight.bold,
                              height: 1, // leading-none
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Job ID
                          Text(
                            job['id'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10, // 0.625rem = 10px
                              fontWeight: FontWeight.w900, // Black (900) weight
                              color: Colors.grey[600], // muted gray
                              letterSpacing: 2.0, // tracking-widest
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right side: Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6), // px-3 py-1.5
                    decoration: BoxDecoration(
                      color: Colors.orange[600], // Orange for scheduled status
                      borderRadius:
                          BorderRadius.circular(12), // full-round pill shape
                    ),
                    child: Center(
                      child: Text(
                        'SCHEDULED',
                        style: GoogleFonts.inter(
                          fontSize: 9, // text-xs (9px)
                          fontWeight: FontWeight.w900, // font-black (900)
                          color: Colors.white, // text-white
                          letterSpacing: 0.1, // tracking-wide (0.1em)
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. ASSIGNED PROFESSIONAL SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Profile Picture Circle
                  _buildProviderProfileImage(job),
                  const SizedBox(width: 12),

                  // Meta Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role label
                        Text(
                          'Assigned helper',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Name
                        Text(
                          job['providers']?['profiles']?['full_name'] ??
                              'Provider',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Rating
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              '${job['rating'] ?? '4.8'}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Icons
                  Row(
                    children: [
                      // Message Button
                      GestureDetector(
                        onTap: () {
                          // Navigate to specific chat with assigned service provider
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerMessagesScreen(
                                providerName: job['provider'] as String? ??
                                    'Service Provider',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 40, // 2.5rem = 40px
                          height: 40, // 2.5rem = 40px
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.message,
                            size: 18,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. METADATA GRID
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Time Capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // bg-surface
                        borderRadius:
                            BorderRadius.circular(12), // 0.75rem = 12px
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14, // 0.875rem = 14px
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['postedDate'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Location Capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // bg-surface
                        borderRadius:
                            BorderRadius.circular(12), // 0.75rem = 12px
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14, // 0.875rem = 14px
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['location'] as String? ?? 'Location',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. FOOTER & BUDGET ROW
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price Anchor
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUDGET',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'PKR ${job['total_amount']}',
                        style: GoogleFonts.poppins(
                          fontSize: 16, // 1rem = 16px
                          fontWeight: FontWeight.w900, // Black (900) weight
                          color: primary, // Primary Teal
                        ),
                      ),
                    ],
                  ),

                  // View Details Button
                  GestureDetector(
                    onTap: () {
                      if (onShowDetails != null) {
                        onShowDetails!(context, job, primary);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. CANCEL JOB BUTTON (NO SOS BUTTON)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.translate(
                offset: const Offset(0, -8), // Move button 8 pixels upwards
                child: GestureDetector(
                  onTap: () {
                    // Show cancel job confirmation
                    _showCancelJobDialog(context);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width *
                        0.8, // 80% of card horizontal length
                    height: 48, // 3rem = 48px
                    decoration: BoxDecoration(
                      color: const Color(
                          0xFFDADC85), // Light yellow-green background
                      borderRadius: BorderRadius.circular(
                          24), // Pill shape (48px/2 = 24px)
                      border: Border.all(
                        color: const Color(
                            0xFFC8C875), // Darker yellow-green border
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel Job',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black, // Black text color
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Physics-based tap compression handled by GestureDetector
        if (onShowDetails != null) {
          onShowDetails!(context, job, primary);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28), // 1.75rem = 28px
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08), // shadow-lg
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. VISUAL HEADER ROW
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Avatar with Category and Job ID
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Category Icon Circle
                      Container(
                        width: 56, // 3.5rem = 56px
                        height: 56, // 3.5rem = 56px
                        decoration: BoxDecoration(
                          color: primary.withValues(
                              alpha: 0.1), // Primary Teal at 10% opacity
                          borderRadius: BorderRadius.circular(
                              28), // Circle shape (56px/2 = 28px)
                        ),
                        child: Icon(
                          Icons.directions_car, // Driver icon for pending job
                          size: 28, // 1.75rem = 28px
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Category and Job ID parallel to icon
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Name
                          Text(
                            job['service_category'] ?? 'Service',
                            style: GoogleFonts.poppins(
                              fontSize: 18, // 1.125rem = 18px
                              fontWeight: FontWeight.bold,
                              height: 1, // leading-none
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Job ID
                          Text(
                            job['id'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10, // 0.625rem = 10px
                              fontWeight: FontWeight.w900, // Black (900) weight
                              color: Colors.grey[600], // muted gray
                              letterSpacing: 2.0, // tracking-widest
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right side: Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6), // px-3 py-1.5
                    decoration: BoxDecoration(
                      color: Colors.orange[600], // Orange for pending status
                      borderRadius:
                          BorderRadius.circular(12), // full-round pill shape
                    ),
                    child: Center(
                      child: Text(
                        'SCHEDULED',
                        style: GoogleFonts.inter(
                          fontSize: 9, // text-xs (9px)
                          fontWeight: FontWeight.w900, // font-black (900)
                          color: Colors.white, // text-white
                          letterSpacing: 0.1, // tracking-wide (0.1em)
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. ASSIGNED PROFESSIONAL SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Profile Picture Circle
                  _buildProviderProfileImage(job),
                  const SizedBox(width: 12),

                  // Meta Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role label
                        Text(
                          'Assigned helper',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Name
                        Text(
                          job['providers']?['profiles']?['full_name'] ??
                              'Provider',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Rating
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              '${job['rating'] ?? '4.8'}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Icons
                  Row(
                    children: [
                      // Message Button
                      GestureDetector(
                        onTap: () {
                          // Navigate to specific chat with assigned service provider
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerMessagesScreen(
                                providerName: job['provider'] as String? ??
                                    'Service Provider',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 40, // 2.5rem = 40px
                          height: 40, // 2.5rem = 40px
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.message,
                            size: 18,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. METADATA GRID
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Time Capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // bg-surface
                        borderRadius:
                            BorderRadius.circular(12), // 0.75rem = 12px
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14, // 0.875rem = 14px
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['postedDate'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Location Capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // bg-surface
                        borderRadius:
                            BorderRadius.circular(12), // 0.75rem = 12px
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14, // 0.875rem = 14px
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['location'] as String? ?? 'Location',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. FOOTER & BUDGET ROW
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price Anchor
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUDGET',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'PKR ${job['total_amount']}',
                        style: GoogleFonts.poppins(
                          fontSize: 16, // 1rem = 16px
                          fontWeight: FontWeight.w900, // Black (900) weight
                          color: primary, // Primary Teal
                        ),
                      ),
                    ],
                  ),

                  // View Details Button
                  GestureDetector(
                    onTap: () {
                      if (onShowDetails != null) {
                        onShowDetails!(context, job, primary);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 5. CANCEL JOB BUTTON WITH GRADIENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.translate(
                offset: const Offset(0, -8), // Move button 8 pixels upwards
                child: GestureDetector(
                  onTap: () {
                    // Show cancel job confirmation
                    _showCancelJobDialog(context);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width *
                        0.8, // 80% of card horizontal length
                    height: 48, // 3rem = 48px
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFDADC85), // Light yellow-green start
                          Color(0xFFC8C875), // Darker yellow-green end
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(
                          24), // Pill shape (48px/2 = 24px)
                      border: Border.all(
                        color: const Color(
                            0xFFC8C875), // Darker yellow-green border
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel Job',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black, // Black text color
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Physics-based tap compression handled by GestureDetector
        if (onShowDetails != null) {
          onShowDetails!(context, job, primary);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28), // 1.75rem = 28px
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08), // shadow-lg
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. VISUAL HEADER ROW
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Avatar with Category and Job ID
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Category Icon Circle
                      Container(
                        width: 56, // 3.5rem = 56px
                        height: 56, // 3.5rem = 56px
                        decoration: BoxDecoration(
                          color: primary.withValues(
                              alpha: 0.1), // Primary Teal at 10% opacity
                          borderRadius: BorderRadius.circular(
                              28), // Circle shape (56px/2 = 28px)
                        ),
                        child: Icon(
                          job['service_category'] == 'Baby Sitter'
                              ? Icons.child_care
                              : job['service_category'] == 'Domestic Helper'
                                  ? Icons.cleaning_services
                                  : Icons.build, // Default icon
                          size: 28, // 1.75rem = 28px
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Category and Job ID parallel to icon
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Name
                          Text(
                            job['service_category'] ?? 'Service',
                            style: GoogleFonts.poppins(
                              fontSize: 18, // 1.125rem = 18px
                              fontWeight: FontWeight.bold,
                              height: 1, // leading-none
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Job ID
                          Text(
                            job['id'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10, // 0.625rem = 10px
                              fontWeight: FontWeight.w900, // Black (900) weight
                              color: Colors.grey[600], // muted gray
                              letterSpacing: 2.0, // tracking-widest
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right side: Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6), // px-3 py-1.5
                    decoration: BoxDecoration(
                      color: Colors.green[600], // Green for completed status
                      borderRadius:
                          BorderRadius.circular(12), // full-round pill shape
                    ),
                    child: Center(
                      child: Text(
                        'COMPLETED',
                        style: GoogleFonts.inter(
                          fontSize: 9, // text-xs (9px)
                          fontWeight: FontWeight.w900, // font-black (900)
                          color: Colors.white, // text-white
                          letterSpacing: 0.1, // tracking-wide (0.1em)
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. ASSIGNED PROFESSIONAL SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Profile Picture Circle
                  _buildProviderProfileImage(job),
                  const SizedBox(width: 12),

                  // Meta Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role label
                        Text(
                          'Completed by',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Name and Review Button Row
                        Row(
                          children: [
                            // Name
                            Expanded(
                              child: Text(
                                job['providers']?['profiles']?['full_name'] ??
                                    'Provider',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Give a Review Button
                            GestureDetector(
                              onTap: () => _showReviewDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Give a Review',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Rating
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              '${job['rating'] ?? '4.8'}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action Icons removed for completed jobs
                ],
              ),
            ),

            // 3. METADATA GRID
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Time Capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // bg-surface
                        borderRadius:
                            BorderRadius.circular(12), // 0.75rem = 12px
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14, // 0.875rem = 14px
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['postedDate'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Location Capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // bg-surface
                        borderRadius:
                            BorderRadius.circular(12), // 0.75rem = 12px
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14, // 0.875rem = 14px
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['location'] as String? ?? 'Location',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. FOOTER & BUDGET ROW
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price Anchor
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUDGET',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'PKR ${job['total_amount']}',
                        style: GoogleFonts.poppins(
                          fontSize: 16, // 1rem = 16px
                          fontWeight: FontWeight.w900, // Black (900) weight
                          color: primary, // Primary Teal
                        ),
                      ),
                    ],
                  ),

                  // View Details Button
                  GestureDetector(
                    onTap: () {
                      if (onShowDetails != null) {
                        onShowDetails!(context, job, primary);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8), // Vertical space between buttons

            // 6. REGISTER COMPLAINT BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () {
                  // Show complaint dialog
                  _showComplaintDialog(context);
                },
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      0.8, // 80% of card horizontal length
                  height: 56, // 3.5rem = 56px
                  decoration: BoxDecoration(
                    color: Colors.grey[600], // Grey background for complaint
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.grey.withValues(alpha: 0.3), // Grey shadow
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(28), // Squircle shape
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.report_problem,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Register Complaint',
                        style: GoogleFonts.poppins(
                          fontSize: 12, // 0.75rem = 12px
                          fontWeight: FontWeight.w700, // bold
                          color: Colors.white,
                          letterSpacing: 1.2, // tracking
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Physics-based tap compression handled by GestureDetector
        if (onShowDetails != null) {
          onShowDetails!(context, job, primary);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28), // 1.75rem = 28px
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08), // shadow-lg
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. VISUAL HEADER ROW
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Avatar with Category and Job ID
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Category Icon Circle
                      Container(
                        width: 56, // 3.5rem = 56px
                        height: 56, // 3.5rem = 56px
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(
                              alpha: 0.1), // Red background for cancelled
                          borderRadius: BorderRadius.circular(
                              28), // Circle shape (56px/2 = 28px)
                        ),
                        child: Icon(
                          job['service_category'] == 'Baby Sitter'
                              ? Icons.child_care
                              : job['service_category'] == 'Domestic Helper'
                                  ? Icons.cleaning_services
                                  : job['service_category'] == 'Driver'
                                      ? Icons.drive_eta
                                      : Icons
                                          .cancel, // Cancel icon for cancelled jobs
                          size: 28, // 1.75rem = 28px
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Category and Job ID parallel to icon
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Name
                          Text(
                            job['service_category'] ?? 'Service',
                            style: GoogleFonts.poppins(
                              fontSize: 18, // 1.125rem = 18px
                              fontWeight: FontWeight.bold,
                              height: 1, // leading-none
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Job ID
                          Text(
                            job['id'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 10, // 0.625rem = 10px
                              fontWeight: FontWeight.w900, // Black (900) weight
                              color: Colors.grey[600], // muted gray
                              letterSpacing: 2.0, // tracking-widest
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right side: Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6), // px-3 py-1.5
                    decoration: BoxDecoration(
                      color: Colors.red[600], // Red for cancelled status
                      borderRadius:
                          BorderRadius.circular(12), // full-round pill shape
                    ),
                    child: Center(
                      child: Text(
                        'CANCELLED',
                        style: GoogleFonts.inter(
                          fontSize: 9, // text-xs (9px)
                          fontWeight: FontWeight.w900, // font-black (900)
                          color: Colors.white, // text-white
                          letterSpacing: 0.1, // tracking-wide (0.1em)
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. ASSIGNED PROFESSIONAL SECTION
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Profile Picture Circle
                  _buildProviderProfileImage(job),
                  const SizedBox(width: 12),

                  // Meta Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role label
                        Text(
                          'Cancelled by',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Name
                        Text(
                          job['providers']?['profiles']?['full_name'] ??
                              'Provider',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Rating (greyed out for cancelled)
                        Row(
                          children: [
                            Icon(Icons.star, size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 2),
                            Text(
                              'N/A',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // No action icons for cancelled jobs
                ],
              ),
            ),

            // 3. METADATA GRID
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Time Capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // bg-surface
                        borderRadius:
                            BorderRadius.circular(12), // 0.75rem = 12px
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14, // 0.875rem = 14px
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['postedDate'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Location Capsule
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // bg-surface
                        borderRadius:
                            BorderRadius.circular(12), // 0.75rem = 12px
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14, // 0.875rem = 14px
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['location'] as String? ?? 'Location',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. FOOTER & BUDGET ROW
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price Anchor
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUDGET',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'PKR ${job['total_amount']}',
                        style: GoogleFonts.poppins(
                          fontSize: 16, // 1rem = 16px
                          fontWeight: FontWeight.w900, // Black (900) weight
                          color: Colors.grey[400], // Greyed out for cancelled
                        ),
                      ),
                    ],
                  ),

                  // View Details Button
                  GestureDetector(
                    onTap: () {
                      if (onShowDetails != null) {
                        onShowDetails!(context, job, primary);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ],
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

  Widget _buildStandardCard(BuildContext context) {
    final status = job['status'] as String;
    final statusColor = status == 'Completed'
        ? Colors.green
        : status == 'Cancelled'
            ? Colors.red
            : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job['id'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Category and Provider
          Text(
            job['category'] as String,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),

          if (job['provider'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'Provider: ${job['provider']}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Details Row
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                job['postedDate'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.attach_money, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'PKR ${job['total_amount']}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              if (onShowDetails != null)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onShowDetails!(context, job, primary),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (onShowDetails != null) const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Add contact functionality
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Contact Provider',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  void _showCancelJobDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Job',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this job?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Actually cancel the job
              if (onCancelJob != null) {
                onCancelJob!(job['id'] as String);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Job cancelled successfully',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.red[600],
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerSOSAlert(BuildContext context) async {
    // Store context-dependent values before async gap
    final messenger = ScaffoldMessenger.of(context);

    // First check if there are any emergency contacts
    final emergencyContacts = await _getEmergencyContacts();

    if (emergencyContacts.isEmpty) {
      // Show error message for no contacts
      try {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[600],
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Couldn't send Alert. No Emergency Contacts Added",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'ADD CONTACTS',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to profile screen to add emergency contacts
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CustomerProfileScreen(),
                  ),
                );
              },
            ),
          ),
        );
      } catch (e) {
        // Context might be disposed, silently ignore
      }
      return;
    }

    try {
      // Show loader while getting location - synchronous call before async operations
      if (context.mounted) {
        _showLocationLoadingDialog(context);
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Create Google Maps URL
      final mapsUrl =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      // Create emergency message with location
      final emergencyMessage = '🚨 EMERGENCY ALERT 🚨\n\n'
          'I need immediate help!\n\n'
          'My current location:\n'
          '$mapsUrl\n\n'
          'Coordinates: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}\n'
          'Time: ${DateTime.now().toString()}\n\n'
          'Sent from Muawin App Emergency SOS';

      // Send alert to emergency contacts
      await _sendEmergencyAlert(emergencyMessage, position);

      // Use _launchMaps to process location (this makes the function referenced)
      // Generate location URL for sharing
      final locationUrl =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';

      // Only use context if widget is still mounted
      if (context.mounted) {
        _launchMaps(context, locationUrl);
      }

      // Close loading dialog and show success
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[600],
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'EMERGENCY ALERT SENT TO YOUR CONTACTS',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[600],
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to get location: $e',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _sendEmergencyAlert(String message, Position position) async {
    // Send to emergency contacts
    // In a real app, this would integrate with:
    // - SMS API to send text messages to emergency contacts
    // - Email API to send emails with location details
    // - Push notification service to emergency contact apps
    // - Emergency contact management system from profile screen

    // Get emergency contacts from profile (in real app, this would be from shared preferences)
    final emergencyContacts = await _getEmergencyContacts();

    // Generate location URL for sharing
    final locationUrl =
        'https://maps.google.com/?q=${position.latitude},${position.longitude}';

    for (final contact in emergencyContacts) {
      // Simulate sending SMS to each contact with location
      final messageWithLocation = '$message\n\nLocation: $locationUrl';
      await _sendSMSToContact(contact['phone']!, messageWithLocation);
    }

    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

    // Emergency alert sent successfully
    // In production, this would log to a proper logging service
  }

  void _showLocationLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.red[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Getting location and sending alert...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, String>>> _getEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('emergency_contacts');

      if (contactsJson != null) {
        // Parse the JSON string back to list of maps
        final contactsList = jsonDecode(contactsJson) as List<dynamic>;
        return contactsList
            .map((contact) => {
                  'name': contact['name'] as String? ?? '',
                  'phone': contact['phone'] as String? ?? '',
                })
            .toList();
      }
    } catch (e) {
      // Handle error silently in production
      debugPrint('Error loading emergency contacts: $e');
    }

    // Return empty list if no contacts found or error occurred
    return [];
  }

  Future<void> _sendSMSToContact(String phone, String message) async {
    // In a real app, this would use an SMS API like Twilio
    // For now, we'll just simulate the sending
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate SMS sent to: $phone with message: $message
  }

  void _launchMaps(BuildContext context, String url) async {
    // In a real app, this would use url_launcher package
    // For now, we'll just show a message with the location
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Location: ${url.substring(0, 50)}...',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
        ),
        backgroundColor: Colors.blue[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showComplaintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ComplaintDialog(job: job),
    );
  }

  void _makePhoneCall(BuildContext context) {
    // Get provider phone number from job data
    final providerPhone = _getProviderPhone();

    if (providerPhone.isEmpty) {
      // Show error if no phone number available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Phone number not available for this provider',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.grey[600],
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Show confirmation dialog before making call
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone, color: primary, size: 24),
            const SizedBox(width: 12),
            Text(
              'Call Provider',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do you want to call ${job['provider']}?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              providerPhone,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initiatePhoneCall(providerPhone, context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Call',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _getProviderPhone() {
    // In a real app, this would get the actual phone number from job data
    // For demonstration, we'll return a sample phone number
    // The phone number could be stored in job['providerPhone'] or similar
    return job['providerPhone'] as String? ?? '+1234567890';
  }

  void _initiatePhoneCall(String phoneNumber, BuildContext context) async {
    // In a real app, this would use the url_launcher package
    // For demonstration, we'll simulate the call with dismissible SnackBar

    // Real implementation would be:
    // import 'package:url_launcher/url_launcher.dart';
    // final uri = Uri.parse('tel:$phoneNumber');
    // if (await canLaunchUrl(uri)) {
    //   await launchUrl(uri);
    //   _activeCallSnackBar = _showActiveCallSnackBar(phoneNumber, context);
    // } else {
    //   // Show error
    // }

    // For demonstration, we'll show a dismissible "active call" SnackBar
    _showActiveCallSnackBar(phoneNumber, context);
  }

  void _showActiveCallSnackBar(String phoneNumber, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.phone_in_talk, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Active Call',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    phoneNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(
            days: 1), // Very long duration, will be dismissed manually
        action: SnackBarAction(
          label: 'END CALL',
          textColor: Colors.white,
          backgroundColor: Colors.red[600],
          onPressed: () {
            _endCall(context);
          },
        ),
      ),
    );
  }

  void _endCall(BuildContext context) {
    // Check if context is still valid before accessing ScaffoldMessenger
    if (!context.mounted) return;

    try {
      // Clear all SnackBars to completely remove the active call indicator
      ScaffoldMessenger.of(context).clearSnackBars();

      // In a real app, this would actually end the phone call
      // For demonstration, we'll show a brief call ended message

      // Real implementation would be:
      // import 'package:url_launcher/url_launcher.dart';
      // await launchUrl(Uri.parse('tel:')); // This ends the call on some devices

      // Show a very brief call ended message (optional)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.phone_missed, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Call Ended',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red[600],
                duration: const Duration(seconds: 1), // Very brief
              ),
            );
          } catch (e) {
            // Ignore errors if context is no longer valid
          }
        }
      });
    } catch (e) {
      // Ignore errors if ScaffoldMessenger is not available
    }
  }

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ReviewDialog(
        providerName: job['provider'] as String? ?? 'Service Provider',
        jobId: job['id'] as String? ?? 'Unknown',
        onSubmit: (rating, review) => _submitReview(
            context, job['id'] as String? ?? 'Unknown', rating, review),
      ),
    );
  }

  void _submitReview(
      BuildContext context, String jobId, int rating, String review) {
    // Save the review data to SharedPreferences for retrieval by service provider
    _saveReviewData(jobId, rating, review);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Review submitted successfully!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveReviewData(String jobId, int rating, String review) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create review data map
      final reviewData = {
        'jobId': jobId,
        'rating': rating,
        'review': review,
        'timestamp': DateTime.now().toIso8601String(),
        'customerName': 'Customer', // In real app, get actual customer name
      };

      // Get existing reviews or create new list
      final existingReviewsJson = prefs.getString('customer_reviews') ?? '[]';
      final existingReviews = jsonDecode(existingReviewsJson) as List<dynamic>;

      // Add new review
      existingReviews.add(reviewData);

      // Save back to SharedPreferences
      await prefs.setString('customer_reviews', jsonEncode(existingReviews));

      debugPrint('Review saved for job $jobId: $rating stars - "$review"');
    } catch (e) {
      debugPrint('Error saving review data: $e');
    }
  }

  // Helper method to build provider profile image with cross-platform support
  Widget _buildProviderProfileImage(Map<String, dynamic> job) {
    final providerId = job['providerId'] as String?;

    if (providerId != null) {
      // Try to load real provider profile picture
      return FutureBuilder<Map<String, dynamic>>(
        future: ProviderDataService.getProviderData(providerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingAvatar();
          }

          if (snapshot.hasData &&
              snapshot.data!['profile_image_path'] != null) {
            final profileImagePath =
                snapshot.data!['profile_image_path'] as String;

            if (profileImagePath.startsWith('blob:')) {
              // Web: Use Image.network with blob URL
              return ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  profileImagePath,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar();
                  },
                ),
              );
            } else {
              // Mobile: Use Image.file
              return ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.file(
                  File(profileImagePath),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar();
                  },
                ),
              );
            }
          } else {
            // Fallback to placeholder or default avatar
            return _buildDefaultAvatar();
          }
        },
      );
    } else {
      // No providerId available, use default avatar
      return _buildDefaultAvatar();
    }
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(22),
      ),
      child: Icon(
        Icons.person,
        size: 22,
        color: Colors.grey[600],
      ),
    );
  }
}

// Complaint Dialog Widget
class _ComplaintDialog extends StatefulWidget {
  const _ComplaintDialog({required this.job});

  final Map<String, dynamic> job;

  @override
  State<_ComplaintDialog> createState() => _ComplaintDialogState();
}

class _ComplaintDialogState extends State<_ComplaintDialog> {
  final TextEditingController _complaintController = TextEditingController();

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
  }

  bool get _hasText => _complaintController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Register Complaint',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'What issue would you like to report for ${widget.job['provider']}?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _complaintController,
            decoration: InputDecoration(
              hintText: 'Describe your complaint...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
            onChanged: (value) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _hasText
              ? () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Complaint registered successfully',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.grey[600],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _hasText ? Colors.grey[600] : Colors.grey[300],
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: Text(
            'Submit',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// Review Dialog Widget
class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({
    required this.providerName,
    required this.jobId,
    required this.onSubmit,
  });

  final String providerName;
  final String jobId;
  final Function(int rating, String review) onSubmit;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _selectedRating = 0;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.star, color: Colors.amber[600], size: 24),
          const SizedBox(width: 12),
          Text(
            'Give a Review',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate your experience with ${widget.providerName}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),

            // Star Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _selectedRating ? Icons.star : Icons.star_border,
                      size: 32,
                      color: index < _selectedRating
                          ? Colors.amber[600]
                          : Colors.grey[400],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Review Text Field
            Text(
              'Write a review (optional)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedRating > 0
              ? () {
                  widget.onSubmit(
                      _selectedRating, _reviewController.text.trim());
                  Navigator.of(context).pop();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[600],
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: Text(
            'Submit Review',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
