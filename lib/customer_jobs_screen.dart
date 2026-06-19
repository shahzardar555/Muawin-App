import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:muawin_app/services/location_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'customer_home_screen.dart';
import 'post_job_screen.dart';
import 'customer_profile_screen.dart';
import 'customer_messages_screen.dart';
import 'chat_screen.dart';

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
  List<Map<String, dynamic>> _futureJobs = [];
  List<Map<String, dynamic>> _historyJobs = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _customerId;
  Timer? _jobStatusTimer;
  RealtimeChannel? _jobsChannel;

  @override
  void initState() {
    super.initState();
    onShowDetails = null;
    _tabController = TabController(length: 3, vsync: this);
    _loadJobs();

    _jobStatusTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkAndActivateJobs(),
    );
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

  void _subscribeToJobUpdates() {
    if (_customerId == null) return;
    _jobsChannel = Supabase.instance.client
        .channel('customer_jobs:$_customerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'jobs',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: _customerId!,
          ),
          callback: (payload) {
            debugPrint('Job updated — refreshing customer jobs');
            _loadJobs();
          },
        )
        .subscribe();
  }

  Future<void> _checkAndActivateJobs() async {
    if (_customerId == null) return;
    try {
      final now = DateTime.now();
      final supabase = Supabase.instance.client;

      final scheduledJobs = await supabase
          .from('jobs')
          .select('id, scheduled_date, scheduled_time')
          .eq('customer_id', _customerId!)
          .eq('status', 'scheduled')
          .not('provider_id', 'is', null);

      for (final job in scheduledJobs) {
        final dateStr = job['scheduled_date']?.toString() ?? '';
        final timeStr = job['scheduled_time']?.toString() ?? '';

        if (dateStr.isEmpty) continue;

        DateTime? scheduledDateTime;
        try {
          if (timeStr.isNotEmpty) {
            final timeParts = timeStr.split(':');
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final minute =
                timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
            final dateParts = dateStr.split('-');
            scheduledDateTime = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
              hour,
              minute,
            );
          } else {
            final dateParts = dateStr.split('-');
            scheduledDateTime = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );
          }
        } catch (e) {
          continue;
        }

        if (now.isAfter(scheduledDateTime)) {
          await supabase.from('jobs').update({
            'status': 'active',
            'updated_at': now.toIso8601String(),
          }).eq('id', job['id']);
        }
      }

      await _loadJobs();
    } catch (e) {
      debugPrint('Error checking job activation: $e');
    }
  }

  Future<List<Map<String, String>>> _getEmergencyContacts() async {
    try {
      if (_customerId == null) return [];

      final response = await Supabase.instance.client
          .from('emergency_contacts')
          .select('name, phone_number')
          .eq('customer_id', _customerId!);

      if ((response as List).isNotEmpty) {
        return response
            .map((c) => {
                  'name': c['name'] as String? ?? '',
                  'phone': c['phone_number'] as String? ?? '',
                })
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
    }

    return [];
  }

  Future<void> _saveReviewData(String jobId, int rating, String review) async {
    try {
      final supabase = Supabase.instance.client;

      final job = _ongoingJobs.firstWhere(
        (j) => j['id'] == jobId,
        orElse: () => _historyJobs.firstWhere(
          (j) => j['id'] == jobId,
          orElse: () => {},
        ),
      );

      final providerId =
          job['provider_id']?.toString() ?? job['providers']?['id']?.toString();

      if (providerId == null) {
        debugPrint('No provider ID found for job $jobId');
        return;
      }

      await supabase.from('reviews').insert({
        'job_id': jobId,
        'customer_id': _customerId,
        'provider_id': providerId,
        'rating': rating,
        'review': review,
        'is_verified': true,
      });

      debugPrint('Review saved to Supabase for job $jobId: $rating stars');
    } catch (e) {
      debugPrint('Error saving review to Supabase: $e');
    }
  }

  Future<void> _loadJobs() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      _customerId = await _getCustomerId();

      if (_customerId == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      _subscribeToJobUpdates();

      final allJobs = await Supabase.instance.client
          .from('jobs')
          .select("""
          id, title, status, scheduled_date, scheduled_time, 
          created_at, updated_at, service_category, location, 
          description, total_amount, cancel_reason, 
          cancel_description, cancel_date, completion_date,
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

      final negotiatingRequests = await Supabase.instance.client
          .from('direct_job_requests')
          .select('''
            id, title, service_category, status, proposed_price,
            negotiation_notes, scheduled_date, scheduled_time,
            location, city, area, created_at, provider_id,
            providers!inner(
              id, service_category, rating, city,
              profiles!inner(
                full_name, profile_image_url, phone_number
              )
            )
          ''')
          .eq('customer_id', _customerId!)
          .eq('status', 'negotiating')
          .order('created_at', ascending: false);

      final negotiatingJobs = (negotiatingRequests as List).map((req) {
        return {
          'id': req['id'],
          'is_direct_request': true,
          'status': 'negotiating',
          'title': req['title'] ?? 'Direct Request',
          'service_category': req['service_category'] ?? '',
          'scheduled_date': req['scheduled_date'] ?? '',
          'scheduled_time': req['scheduled_time'] ?? '',
          'location': req['location'] ?? '',
          'created_at': req['created_at'] ?? '',
          'proposed_price': req['proposed_price'] ?? 0,
          'negotiation_notes': req['negotiation_notes'] ?? '',
          'providers': req['providers'],
        };
      }).toList();

      final ongoing = <Map<String, dynamic>>[];
      final future = <Map<String, dynamic>>[];
      final history = <Map<String, dynamic>>[];

      for (final job in allJobs) {
        final status = job['status'] as String? ?? '';

        (job)['providerCategory'] = job['service_category']?.toString() ??
            job['providers']?['service_category']?.toString() ??
            '';

        if (status == 'active') {
          ongoing.add(job);
        } else if (status == 'scheduled' ||
            status == 'pending' ||
            status == 'negotiating') {
          future.add(job);
        } else {
          history.add(job);
        }
      }

      future.addAll(
          negotiatingJobs.map((j) => Map<String, dynamic>.from(j)).toList());

      if (mounted) {
        setState(() {
          _ongoingJobs = ongoing;
          _futureJobs = future;
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
    _jobsChannel?.unsubscribe();
    _jobStatusTimer?.cancel();
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
              Color(0xFF088771),
              Color(0xFF064e3b),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(primary),
            const SizedBox(height: 16),
            _buildTabBar(),
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
      bottomNavigationBar: MuawinBottomNavigationBar(
        currentIndex: 1,
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
              (route) => false,
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PostJobScreen()),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerMessagesScreen()),
            );
          } else if (index == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 32,
        left: 24,
        right: 24,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF088771),
            Color(0xFF064e3b),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -15,
            right: -15,
            child: Transform.rotate(
              angle: -0.21,
              child: Icon(
                Icons.work_outline,
                size: 80,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Jobs',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.025,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your ongoing and completed service requests',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromRGBO(248, 255, 248, 0.8),
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
              Color(0xFF088771),
              Color(0xFF064e3b),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorWeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: primary,
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
          Tab(text: 'Future'),
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
          onCancelJob: _cancelJob,
          onGetEmergencyContacts: _getEmergencyContacts,
          onSaveReviewData: _saveReviewData,
          customerId: _customerId,
          onRefresh: _loadJobs,
        ),
        _FutureJobsView(
          jobs: _futureJobs,
          primary: Theme.of(context).colorScheme.primary,
          onShowDetails: _showJobDetailsDialog,
          onGetEmergencyContacts: _getEmergencyContacts,
          onSaveReviewData: _saveReviewData,
          customerId: _customerId,
          onRefresh: _loadJobs,
        ),
        _HistoryJobsView(
          jobs: _historyJobs,
          primary: Theme.of(context).colorScheme.primary,
          onShowDetails: _showJobDetailsDialog,
          onGetEmergencyContacts: _getEmergencyContacts,
          onSaveReviewData: _saveReviewData,
          customerId: _customerId,
          onRefresh: _loadJobs,
        ),
      ],
    );
  }

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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJobDetailRow('Job ID', job['id']?.toString() ?? ''),
                    _buildJobDetailRow('Category', _getValidCategory(job)),
                    _buildJobDetailRow(
                        'Status', job['status']?.toString() ?? ''),
                    _buildJobDetailRow(
                        'Posted', job['postedDate']?.toString() ?? ''),
                    _buildJobDetailRow(
                        'Budget', 'PKR ${job['total_amount'] ?? 'N/A'}'),
                  ],
                ),
              ),
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

    String categoryToCheck = job['providerCategory']?.toString() ?? '';

    if (validCategories.contains(categoryToCheck)) {
      return categoryToCheck;
    }

    String lowerCategory = categoryToCheck.toLowerCase();
    for (String validCategory in validCategories) {
      if (validCategory.toLowerCase().contains(lowerCategory) ||
          lowerCategory.contains(validCategory.toLowerCase())) {
        return validCategory;
      }
    }

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
    this.onGetEmergencyContacts,
    this.onSaveReviewData,
    this.customerId,
    this.onRefresh,
  });

  final List<Map<String, dynamic>> jobs;
  final Color primary;
  final Function(BuildContext, Map<String, dynamic>, Color)? onShowDetails;
  final Function(String) onCancelJob;
  final Future<List<Map<String, String>>> Function()? onGetEmergencyContacts;
  final Future<void> Function(String jobId, int rating, String review)?
      onSaveReviewData;
  final String? customerId;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final activeJobs = jobs.where((job) => job['status'] == 'active').toList();
    final scheduledJobs = jobs
        .where(
            (job) => job['status'] == 'scheduled' || job['status'] == 'pending')
        .toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          if (activeJobs.isNotEmpty) ...[
            _buildSectionHeader('Active Jobs', Icons.circle, Colors.green),
            ...activeJobs.map((job) => _JobCard(
                  job: job,
                  primary: primary,
                  onShowDetails: onShowDetails,
                  onCancelJob: onCancelJob,
                  onGetEmergencyContacts: onGetEmergencyContacts,
                  onSaveReviewData: onSaveReviewData,
                  customerId: customerId,
                  onRefresh: onRefresh,
                )),
          ],
          if (scheduledJobs.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Scheduled Jobs', Icons.schedule, Colors.blue),
            ...scheduledJobs.map((job) => _JobCard(
                  job: job,
                  primary: primary,
                  onShowDetails: onShowDetails,
                  onCancelJob: onCancelJob,
                  onGetEmergencyContacts: onGetEmergencyContacts,
                  onSaveReviewData: onSaveReviewData,
                  customerId: customerId,
                  onRefresh: onRefresh,
                )),
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

class _FutureJobsView extends StatelessWidget {
  const _FutureJobsView({
    required this.jobs,
    required this.primary,
    required this.onShowDetails,
    this.onGetEmergencyContacts,
    this.onSaveReviewData,
    this.customerId,
    this.onRefresh,
  });

  final List<Map<String, dynamic>> jobs;
  final Color primary;
  final Function(BuildContext, Map<String, dynamic>, Color)? onShowDetails;
  final Future<List<Map<String, String>>> Function()? onGetEmergencyContacts;
  final Future<void> Function(String jobId, int rating, String review)?
      onSaveReviewData;
  final String? customerId;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...jobs.map((job) => _JobCard(
                job: job,
                primary: primary,
                onShowDetails: onShowDetails,
                onGetEmergencyContacts: onGetEmergencyContacts,
                onSaveReviewData: onSaveReviewData,
                customerId: customerId,
                onRefresh: onRefresh,
              )),
        ],
      ),
    );
  }
}

class _HistoryJobsView extends StatelessWidget {
  const _HistoryJobsView({
    required this.jobs,
    required this.primary,
    required this.onShowDetails,
    this.onGetEmergencyContacts,
    this.onSaveReviewData,
    this.customerId,
    this.onRefresh,
  });

  final List<Map<String, dynamic>> jobs;
  final Color primary;
  final Function(BuildContext, Map<String, dynamic>, Color)? onShowDetails;
  final Future<List<Map<String, String>>> Function()? onGetEmergencyContacts;
  final Future<void> Function(String jobId, int rating, String review)?
      onSaveReviewData;
  final String? customerId;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...jobs.map((job) => _JobCard(
                job: job,
                primary: primary,
                onShowDetails: onShowDetails,
                onGetEmergencyContacts: onGetEmergencyContacts,
                onSaveReviewData: onSaveReviewData,
                customerId: customerId,
                onRefresh: onRefresh,
              )),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.primary,
    this.onShowDetails,
    this.onCancelJob,
    this.onGetEmergencyContacts,
    this.onSaveReviewData,
    this.customerId,
    this.onRefresh,
  });

  final Map<String, dynamic> job;
  final Color primary;
  final Function(BuildContext, Map<String, dynamic>, Color)? onShowDetails;
  final Function(String)? onCancelJob;
  final Future<List<Map<String, String>>> Function()? onGetEmergencyContacts;
  final Future<void> Function(String jobId, int rating, String review)?
      onSaveReviewData;
  final String? customerId;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final status = job['status']?.toString() ?? '';

    if (status == 'active') {
      return _buildInProgressCard(context);
    } else if (status == 'scheduled') {
      return _buildScheduledCard(context);
    } else if (status == 'pending') {
      return _buildPendingCard(context);
    } else if (status == 'completed') {
      return _buildCompletedCard(context);
    } else if (status == 'cancelled') {
      return _buildCancelledCard(context);
    } else if (status == 'negotiating') {
      return _buildNegotiatingCard(context);
    }

    return _buildStandardCard(context);
  }

  Widget _buildInProgressCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onShowDetails != null) {
          onShowDetails!(context, job, primary);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            Icons.cleaning_services,
                            size: 28,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['service_category'] ?? 'Service',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                job['id']?.toString() ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[600],
                                  letterSpacing: 2.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 24,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'In Progress',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.9,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assigned Helper',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey[600],
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job['providers']?['profiles']?['full_name'] ??
                              'Provider',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _makePhoneCall(context),
                        child: Container(
                          width: 40,
                          height: 40,
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
                      GestureDetector(
                        onTap: () async {
                          try {
                            final supabase = Supabase.instance.client;
                            final currentUser = supabase.auth.currentUser;
                            if (currentUser == null) return;

                            final myProfile = await supabase
                                .from('profiles')
                                .select('id')
                                .eq('user_id', currentUser.id)
                                .single();
                            final myProfileId = myProfile['id'].toString();

                            final providerProfileId = await supabase
                                .from('providers')
                                .select('profile_id')
                                .eq('id',
                                    job['providers']?['id']?.toString() ?? '')
                                .single();
                            final otherProfileId =
                                providerProfileId['profile_id'].toString();

                            String? threadId;
                            final existing1 = await supabase
                                .from('message_threads')
                                .select('id')
                                .eq('participant_1_id', myProfileId)
                                .eq('participant_2_id', otherProfileId)
                                .maybeSingle();

                            if (existing1 != null) {
                              threadId = existing1['id'].toString();
                            } else {
                              final existing2 = await supabase
                                  .from('message_threads')
                                  .select('id')
                                  .eq('participant_1_id', otherProfileId)
                                  .eq('participant_2_id', myProfileId)
                                  .maybeSingle();

                              if (existing2 != null) {
                                threadId = existing2['id'].toString();
                              } else {
                                final newThread = await supabase
                                    .from('message_threads')
                                    .insert({
                                      'participant_1_id': myProfileId,
                                      'participant_2_id': otherProfileId,
                                      'is_active': true,
                                    })
                                    .select('id')
                                    .single();
                                threadId = newThread['id'].toString();
                              }
                            }

                            if (!context.mounted) return;

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  chatData: {
                                    'id': threadId,
                                    'name': job['providers']?['profiles']
                                                ?['full_name']
                                            ?.toString() ??
                                        'Service Provider',
                                    'avatar': job['providers']?['profiles']
                                                ?['profile_image_url']
                                            ?.toString() ??
                                        '',
                                    'isOnline': false,
                                    'type': 'provider',
                                  },
                                ),
                              ),
                            );
                          } catch (e) {
                            debugPrint('Chat error: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Could not open chat. Please try again.'),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 40,
                          height: 40,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['postedDate']?.toString() ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
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
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              job['location']?.toString() ?? 'Location',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        'PKR ${job['total_amount'] ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  _showCancelJobDialog(context);
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDADC85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFC8C875),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Cancel Job',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () => _triggerSOSAlert(context),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(28),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 2.4,
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
        if (onShowDetails != null) {
          onShowDetails!(context, job, primary);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            size: 28,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['service_category'] ?? 'Service',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                job['id']?.toString() ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[600],
                                  letterSpacing: 2.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'SCHEDULED',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildProviderProfileImage(job),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomerMessagesScreen(
                                  providerName: job['provider']?.toString() ??
                                      'Service Provider',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
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
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['postedDate']?.toString() ?? '',
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
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              job['location']?.toString() ?? 'Location',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        'PKR ${job['total_amount'] ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.translate(
                offset: const Offset(0, -8),
                child: GestureDetector(
                  onTap: () {
                    _showCancelJobDialog(context);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDADC85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFC8C875),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel Job',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
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
        if (onShowDetails != null) {
          onShowDetails!(context, job, primary);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            Icons.directions_car,
                            size: 28,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['service_category'] ?? 'Service',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                job['id']?.toString() ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[600],
                                  letterSpacing: 2.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'SCHEDULED',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildProviderProfileImage(job),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CustomerMessagesScreen(
                                  providerName: job['provider']?.toString() ??
                                      'Service Provider',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
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
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['postedDate']?.toString() ?? '',
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
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              job['location']?.toString() ?? 'Location',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        'PKR ${job['total_amount'] ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Transform.translate(
                offset: const Offset(0, -8),
                child: GestureDetector(
                  onTap: () {
                    _showCancelJobDialog(context);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFDADC85),
                          Color(0xFFC8C875),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFC8C875),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel Job',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
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
        if (onShowDetails != null) {
          onShowDetails!(context, job, primary);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            job['service_category'] == 'Baby Sitter'
                                ? Icons.child_care
                                : job['service_category'] == 'Domestic Helper'
                                    ? Icons.cleaning_services
                                    : Icons.build,
                            size: 28,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['service_category'] ?? 'Service',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                job['id']?.toString() ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[600],
                                  letterSpacing: 2.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'COMPLETED',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildProviderProfileImage(job),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        Row(
                          children: [
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['postedDate']?.toString() ?? '',
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
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              job['location']?.toString() ?? 'Location',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        'PKR ${job['total_amount'] ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTap: () {
                  _showComplaintDialog(context);
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(28),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
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
        if (onShowDetails != null) {
          onShowDetails!(context, job, primary);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Icon(
                            job['service_category'] == 'Baby Sitter'
                                ? Icons.child_care
                                : job['service_category'] == 'Domestic Helper'
                                    ? Icons.cleaning_services
                                    : job['service_category'] == 'Driver'
                                        ? Icons.drive_eta
                                        : Icons.cancel,
                            size: 28,
                            color: Colors.red[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job['service_category'] ?? 'Service',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                job['id']?.toString() ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[600],
                                  letterSpacing: 2.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'CANCELLED',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _buildProviderProfileImage(job),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            job['postedDate']?.toString() ?? '',
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
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              job['location']?.toString() ?? 'Location',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        'PKR ${job['total_amount'] ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildNegotiatingCard(BuildContext context) {
    final provider = job['providers'];
    final providerProfile = provider?['profiles'];
    final providerName = providerProfile?['full_name'] ?? 'Provider';
    final providerImage = providerProfile?['profile_image_url'] ?? '';
    final providerRating = (provider?['rating'] ?? 0.0).toDouble();
    final negotiationNotes = job['negotiation_notes']?.toString() ?? '';
    final proposedPrice = job['proposed_price']?.toString() ?? '0';
    final category = job['service_category']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NEGOTIATING',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: providerImage.isNotEmpty
                      ? NetworkImage(providerImage)
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: providerImage.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(children: [
                        Icon(Icons.star, size: 14, color: Colors.amber[600]),
                        const SizedBox(width: 4),
                        Text(
                          providerRating.toStringAsFixed(1),
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Counter Offer from Provider:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    negotiationNotes.isNotEmpty
                        ? negotiationNotes
                        : 'Provider sent a counter offer',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Original Budget: Rs. $proposedPrice',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptCounterOffer(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Accept Offer',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineCounterOffer(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.inter(
                        color: Colors.red[400],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptCounterOffer(BuildContext context) async {
    try {
      await Supabase.instance.client.from('direct_job_requests').update({
        'status': 'accepted',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', job['id']);

      await Supabase.instance.client.from('jobs').insert({
        'direct_request_id': job['id'],
        'customer_id': customerId,
        'provider_id': job['providers']?['id'],
        'service_category': job['service_category'] ?? '',
        'title': job['title'] ?? 'Direct Request',
        'description': job['negotiation_notes'] ?? '',
        'location': job['location'] ?? '',
        'scheduled_date': job['scheduled_date'],
        'scheduled_time': job['scheduled_time'],
        'status': 'scheduled',
        'total_amount': (job['proposed_price'] as num?)?.toDouble() ?? 0.0,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer accepted! Job has been scheduled.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        onRefresh?.call();
      }
    } catch (e) {
      debugPrint('Error accepting offer: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept offer. Try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _declineCounterOffer(BuildContext context) async {
    try {
      await Supabase.instance.client.from('direct_job_requests').update({
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', job['id']);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Counter offer declined.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        onRefresh?.call();
      }
    } catch (e) {
      debugPrint('Error declining offer: $e');
    }
  }

  Widget _buildStandardCard(BuildContext context) {
    final status = job['status']?.toString() ?? '';
    final statusColor = status == 'completed'
        ? Colors.green
        : status == 'cancelled'
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                job['id']?.toString() ?? '',
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
          Text(
            job['category']?.toString() ?? '',
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
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                job['postedDate']?.toString() ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.attach_money, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                'PKR ${job['total_amount'] ?? 'N/A'}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                  onPressed: () {},
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
              if (onCancelJob != null) {
                onCancelJob!(job['id']?.toString() ?? '');
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
    final messenger = ScaffoldMessenger.of(context);

    final emergencyContacts = onGetEmergencyContacts != null
        ? await onGetEmergencyContacts!()
        : <Map<String, String>>[];

    if (emergencyContacts.isEmpty) {
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
        debugPrint('Error showing no contacts snackbar: $e');
      }
      return;
    }

    try {
      if (context.mounted) {
        _showLocationLoadingDialog(context);
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      String addressName = await LocationService.getAddressFromLatLng(
          position.latitude, position.longitude);

      final mapsUrl =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      final emergencyMessage = '🚨 EMERGENCY ALERT 🚨\n\n'
          'I need immediate help!\n\n'
          'My current location:\n'
          '$addressName\n'
          '$mapsUrl\n\n'
          'Time: ${DateTime.now().toString()}\n\n'
          'Sent from Muawin App Emergency SOS';

      await _sendEmergencyAlert(emergencyMessage, position);

      final locationUrl =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';

      if (context.mounted) {
        _launchMaps(context, locationUrl);
      }

      if (context.mounted) {
        Navigator.of(context).pop();
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
      if (context.mounted) {
        Navigator.of(context).pop();
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
    final emergencyContacts = onGetEmergencyContacts != null
        ? await onGetEmergencyContacts!()
        : <Map<String, String>>[];

    for (final contact in emergencyContacts) {
      await _sendWhatsAppToContact(contact['phone']!, message);
    }
  }

  void _showLocationLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: double.maxFinite,
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  job['location']?.toString() ?? 'Location',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendWhatsAppToContact(String phone, String message) async {
    try {
      String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

      if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
        cleanPhone = '92${cleanPhone.substring(1)}';
      }

      final encodedMessage = Uri.encodeComponent(message);

      final whatsappUri = Uri.parse(
        'whatsapp://send?phone=$cleanPhone&text=$encodedMessage',
      );

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        final fallbackUri = Uri.parse(
          'https://wa.me/$cleanPhone?text=$encodedMessage',
        );
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(
            fallbackUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          debugPrint('Could not launch WhatsApp for: $cleanPhone');
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error sending WhatsApp message: $e');
    }
  }

  Future<void> _launchMaps(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching maps: $e');
    }
  }

  void _showComplaintDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ComplaintDialog(job: job),
    );
  }

  void _makePhoneCall(BuildContext context) {
    final providerPhone = _getProviderPhone();

    if (providerPhone.isEmpty) {
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
    return job['providers']?['profiles']?['phone_number']?.toString() ?? '';
  }

  void _initiatePhoneCall(String phoneNumber, BuildContext context) async {
    try {
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
        cleanPhone = '+92${cleanPhone.substring(1)}';
      }

      final uri = Uri.parse('tel:$cleanPhone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch phone dialer'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Phone call error: $e');
    }
  }

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ReviewDialog(
        providerName: job['provider']?.toString() ?? 'Service Provider',
        jobId: job['id']?.toString() ?? 'Unknown',
        onSubmit: (rating, review) => _submitReview(
            context, job['id']?.toString() ?? 'Unknown', rating, review),
      ),
    );
  }

  void _submitReview(
      BuildContext context, String jobId, int rating, String review) {
    onSaveReviewData?.call(jobId, rating, review);

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

  Widget _buildProviderProfileImage(Map<String, dynamic> job) {
    final imageUrl =
        job['providers']?['profiles']?['profile_image_url']?.toString();

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(
          imageUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
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
              ? () async {
                  Navigator.of(context).pop();
                  try {
                    final supabase = Supabase.instance.client;
                    final user = supabase.auth.currentUser;
                    if (user == null) return;

                    final profile = await supabase
                        .from('profiles')
                        .select('id')
                        .eq('user_id', user.id)
                        .single();

                    final customer = await supabase
                        .from('customers')
                        .select('id')
                        .eq('profile_id', profile['id'])
                        .single();

                    final providerId = widget.job['provider_id']?.toString() ??
                        widget.job['providers']?['id']?.toString();

                    await supabase.from('complaints').insert({
                      'customer_id': customer['id'],
                      'provider_id': providerId,
                      'job_id': widget.job['id']?.toString(),
                      'complaint_type': 'service_quality',
                      'description': _complaintController.text.trim(),
                      'priority': 'medium',
                      'status': 'open',
                    });

                    if (context.mounted) {
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
                  } catch (e) {
                    debugPrint('Error saving complaint: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to submit complaint'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
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
