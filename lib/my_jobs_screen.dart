import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:muawin_app/chats_screen.dart';
import 'package:muawin_app/widgets/bottom_navigation_bar.dart';
import 'package:muawin_app/service_provider_feed_screen.dart';
import 'package:muawin_app/service_provider_profile_screen.dart';

/// Max content width adjusted to match navigation bar span (responsive)
double _getMaxContentWidth(BuildContext context) {
  // Get screen width and subtract appropriate padding
  final screenWidth = MediaQuery.of(context).size.width;
  // Use most of the screen width, leaving some margin for visual balance
  return screenWidth - 32; // 16px padding on each side
}

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  int _tabIndex = 0;
  Timer? _schedulerTimer;

  // Service provider's registered category (this would come from user profile/authentication data)
  final String _providerCategory =
      'Driver'; // Default to Driver, should come from user profile

  // State management for jobs
  List<Map<String, dynamic>> activeJobs = [
    {
      'id': 'job_001',
      'name': 'Saira Khan',
      'role': 'CUSTOMER',
      'snippet': 'Need help with home cleaning',
      'time': '2 hours ago',
      'unread': true,
      'profilePicture': 'https://i.pravatar.cc/150?img=5',
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'isOnline': true,
      'type': 'customer',
      'lastMessage': 'Need help with home cleaning',
      'timestamp': '2 hours ago',
      'category': 'Home Cleaning',
      'status': 'In Progress',
      'location': 'DHA Phase 5, Lahore',
      'budget': '2,500',
      'providerCategory': 'Maid',
    },
    {
      'id': 'job_002',
      'name': 'Ahmed Raza',
      'role': 'CUSTOMER',
      'snippet': 'Plumbing emergency repair',
      'time': '1 hour ago',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=3',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'isOnline': false,
      'type': 'customer',
      'lastMessage': 'Water pipe burst in kitchen',
      'timestamp': '1 hour ago',
      'category': 'Plumbing',
      'status': 'In Progress',
      'location': 'Gulberg III, Lahore',
      'budget': '3,200',
      'providerCategory': 'Plumber',
    },
    {
      'id': 'job_003',
      'name': 'Fatima Ali',
      'role': 'CUSTOMER',
      'snippet': 'Electrical wiring issues in living room',
      'time': '3 hours ago',
      'unread': true,
      'profilePicture': 'https://i.pravatar.cc/150?img=8',
      'avatar': 'https://i.pravatar.cc/150?img=8',
      'isOnline': true,
      'type': 'customer',
      'lastMessage': 'Lights flickering and some outlets not working',
      'timestamp': '3 hours ago',
      'category': 'Electrician',
      'status': 'In Progress',
      'location': 'Bahria Town, Lahore',
      'budget': '4,500',
      'providerCategory': 'Electrician',
    },
    {
      'id': 'job_004',
      'name': 'Omar Hassan',
      'role': 'CUSTOMER',
      'snippet': 'Garden maintenance and landscaping',
      'time': '5 hours ago',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=2',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'isOnline': false,
      'type': 'customer',
      'lastMessage': 'Need regular garden cleanup and tree trimming',
      'timestamp': '5 hours ago',
      'category': 'Gardening',
      'status': 'In Progress',
      'location': 'LDA Avenue, Lahore',
      'budget': '3,800',
      'providerCategory': 'Gardener',
    },
    {
      'id': 'job_005',
      'name': 'Ayesha Rahman',
      'role': 'CUSTOMER',
      'snippet': 'Cooking for family dinner party',
      'time': '6 hours ago',
      'unread': true,
      'profilePicture': 'https://i.pravatar.cc/150?img=10',
      'avatar': 'https://i.pravatar.cc/150?img=10',
      'isOnline': true,
      'type': 'customer',
      'lastMessage': 'Need chef for 20 people dinner party tomorrow',
      'timestamp': '6 hours ago',
      'category': 'Cooking',
      'status': 'In Progress',
      'location': 'Cantonment, Lahore',
      'budget': '8,000',
      'providerCategory': 'Cook',
    },
    {
      'id': 'job_006',
      'name': 'M. Khan',
      'role': 'CUSTOMER',
      'snippet': 'Transportation to airport',
      'time': '8 hours ago',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=6',
      'avatar': 'https://i.pravatar.cc/150?img=6',
      'isOnline': false,
      'type': 'customer',
      'lastMessage': 'Need ride to Allama Iqbal Airport at 6 AM',
      'timestamp': '8 hours ago',
      'category': 'Transportation',
      'status': 'In Progress',
      'location': 'Gulberg II, Lahore',
      'budget': '1,500',
      'providerCategory': 'Driver',
    },
  ];

  List<Map<String, dynamic>> completedJobs = [
    {
      'id': 'job_011',
      'name': 'Ayesha Malik',
      'role': 'CUSTOMER',
      'snippet': 'Monthly house cleaning completed',
      'time': 'Completed on Mar 10, 2024',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=9',
      'avatar': 'https://i.pravatar.cc/150?img=9',
      'isOnline': false,
      'type': 'customer',
      'lastMessage': 'Thank you for excellent service',
      'timestamp': 'Completed on Mar 10, 2024',
      'category': 'Home Cleaning',
      'status': 'Completed',
      'location': 'Model Town, Lahore',
      'budget': '2,200',
      'providerCategory': 'Maid',
      'completionDate': 'Mar 10, 2024',
      'rating': 5,
      'review': 'Excellent service, very professional and thorough',
    },
    {
      'id': 'job_012',
      'name': 'Imran Khan',
      'role': 'CUSTOMER',
      'snippet': 'Electrical repair completed',
      'time': 'Completed on Mar 8, 2024',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=4',
      'avatar': 'https://i.pravatar.cc/150?img=4',
      'isOnline': true,
      'type': 'customer',
      'lastMessage': 'All wiring issues fixed perfectly',
      'timestamp': 'Completed on Mar 8, 2024',
      'category': 'Electrician',
      'status': 'Completed',
      'location': 'Johar Town, Lahore',
      'budget': '4,000',
      'providerCategory': 'Electrician',
      'completionDate': 'Mar 8, 2024',
      'rating': 5,
      'review': 'Very skilled electrician, quick and efficient',
    },
    {
      'id': 'job_013',
      'name': 'Nadia Shah',
      'role': 'CUSTOMER',
      'snippet': 'Garden landscaping completed',
      'time': 'Completed on Mar 6, 2024',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=11',
      'avatar': 'https://i.pravatar.cc/150?img=11',
      'isOnline': false,
      'type': 'customer',
      'lastMessage': 'Garden looks amazing now!',
      'timestamp': 'Completed on Mar 6, 2024',
      'category': 'Gardening',
      'status': 'Completed',
      'location': 'Askari XI, Lahore',
      'budget': '5,500',
      'providerCategory': 'Gardener',
      'completionDate': 'Mar 6, 2024',
      'rating': 4,
      'review': 'Great work, garden transformed completely',
    },
    {
      'id': 'job_014',
      'name': 'Farooq Ahmed',
      'role': 'CUSTOMER',
      'snippet': 'Birthday party cooking service',
      'time': 'Completed on Mar 5, 2024',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=13',
      'avatar': 'https://i.pravatar.cc/150?img=13',
      'isOnline': true,
      'type': 'customer',
      'lastMessage': 'Food was delicious, guests loved it',
      'timestamp': 'Completed on Mar 5, 2024',
      'category': 'Cooking',
      'status': 'Completed',
      'location': 'Defense Housing Authority, Lahore',
      'budget': '12,000',
      'providerCategory': 'Cook',
      'completionDate': 'Mar 5, 2024',
      'rating': 5,
      'review': 'Exceptional cooking service, highly recommended',
    },
    {
      'id': 'job_015',
      'name': 'Saima Yousaf',
      'role': 'CUSTOMER',
      'snippet': 'Airport transfer completed',
      'time': 'Completed on Mar 4, 2024',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=15',
      'avatar': 'https://i.pravatar.cc/150?img=15',
      'isOnline': false,
      'type': 'customer',
      'lastMessage': 'Reached airport on time, safe driving',
      'timestamp': 'Completed on Mar 4, 2024',
      'category': 'Transportation',
      'status': 'Completed',
      'location': 'Gulberg I, Lahore',
      'budget': '1,800',
      'providerCategory': 'Driver',
      'completionDate': 'Mar 4, 2024',
      'rating': 4,
      'review': 'Punctual and professional driver',
    },
  ];

  List<Map<String, dynamic>> scheduledJobs = [
    {
      'id': 'job_007',
      'name': 'Tariq Mehmood',
      'role': 'CUSTOMER',
      'snippet': 'Airport transfer service',
      'time': 'Tomorrow at 5:30 AM',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=18',
      'avatar': 'https://i.pravatar.cc/150?img=18',
      'isOnline': false,
      'type': 'customer',
      'lastMessage': 'Need pickup for early morning flight',
      'timestamp': 'Tomorrow at 5:30 AM',
      'category': 'Transportation',
      'status': 'Scheduled',
      'location': 'Model Town, Lahore',
      'budget': '2,200',
      'providerCategory': 'Driver',
      'scheduledDate': '2024-03-29',
      'scheduledTime': '5:30 AM',
    },
    {
      'id': 'job_008',
      'name': 'Ali Hassan',
      'role': 'CUSTOMER',
      'snippet': 'City tour transportation',
      'time': 'Mar 30 at 10:00 AM',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=21',
      'avatar': 'https://i.pravatar.cc/150?img=21',
      'isOnline': true,
      'type': 'customer',
      'lastMessage': 'Need driver for city tour',
      'timestamp': 'Mar 30 at 10:00 AM',
      'category': 'Transportation',
      'status': 'Scheduled',
      'location': 'Lahore Fort, Lahore',
      'budget': '3,500',
      'providerCategory': 'Driver',
      'scheduledDate': '2024-03-30',
      'scheduledTime': '10:00 AM',
    },
    {
      'id': 'job_009',
      'name': 'Nadia Khan',
      'role': 'CUSTOMER',
      'snippet': 'Shopping trip driver needed',
      'time': 'Mar 31 at 2:00 PM',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=22',
      'avatar': 'https://i.pravatar.cc/150?img=22',
      'isOnline': false,
      'type': 'customer',
      'lastMessage': 'Need ride for shopping in Mall of Lahore',
      'timestamp': 'Mar 31 at 2:00 PM',
      'category': 'Transportation',
      'status': 'Scheduled',
      'location': 'Cavalry Ground, Lahore',
      'budget': '1,800',
      'providerCategory': 'Driver',
      'scheduledDate': '2024-03-31',
      'scheduledTime': '2:00 PM',
    },
    {
      'id': 'job_010',
      'name': 'Faisal Ahmed',
      'role': 'CUSTOMER',
      'snippet': 'Outstation trip to Islamabad',
      'time': 'Apr 1 at 8:00 AM',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=23',
      'avatar': 'https://i.pravatar.cc/150?img=23',
      'isOnline': true,
      'type': 'customer',
      'lastMessage': 'Need driver for Islamabad trip',
      'timestamp': 'Apr 1 at 8:00 AM',
      'category': 'Transportation',
      'status': 'Scheduled',
      'location': 'Gulberg II, Lahore',
      'budget': '8,000',
      'providerCategory': 'Driver',
      'scheduledDate': '2024-04-01',
      'scheduledTime': '8:00 AM',
    },
  ];

  List<Map<String, dynamic>> cancelledJobs = [
    {
      'id': 'job_016',
      'name': 'Sarah Johnson',
      'role': 'CUSTOMER',
      'snippet': 'Emergency plumbing cancelled',
      'time': 'Cancelled on Mar 5, 2024',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=7',
      'avatar': 'https://i.pravatar.cc/150?img=7',
      'isOnline': false,
      'type': 'customer',
      'lastMessage': 'Customer cancelled the appointment',
      'timestamp': 'Cancelled on Mar 5, 2024',
      'category': 'Plumbing',
      'status': 'Cancelled',
      'location': 'Model Town, Lahore',
      'budget': '2,800',
      'providerCategory': 'Plumber',
      'cancelDate': 'Mar 5, 2024',
      'cancelReason': 'Customer found another provider',
      'cancelDescription':
          'Customer mentioned they found a more affordable option and decided to cancel this job.',
    },
    {
      'id': 'job_017',
      'name': 'Rashid Mehmood',
      'role': 'CUSTOMER',
      'snippet': 'House cleaning service cancelled',
      'time': 'Cancelled on Mar 7, 2024',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=17',
      'avatar': 'https://i.pravatar.cc/150?img=17',
      'isOnline': true,
      'type': 'customer',
      'lastMessage': 'Customer had emergency and cancelled',
      'timestamp': 'Cancelled on Mar 7, 2024',
      'category': 'Home Cleaning',
      'status': 'Cancelled',
      'location': 'Township, Lahore',
      'budget': '2,000',
      'providerCategory': 'Maid',
      'cancelDate': 'Mar 7, 2024',
      'cancelReason': 'Family emergency',
      'cancelDescription':
          'Customer had a family emergency and had to cancel the scheduled cleaning service.',
    },
    {
      'id': 'job_018',
      'name': 'Mariam Sadiq',
      'role': 'CUSTOMER',
      'snippet': 'Cooking service cancelled',
      'time': 'Cancelled on Mar 9, 2024',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=19',
      'avatar': 'https://i.pravatar.cc/150?img=19',
      'isOnline': false,
      'type': 'customer',
      'lastMessage': 'Event was postponed',
      'timestamp': 'Cancelled on Mar 9, 2024',
      'category': 'Cooking',
      'status': 'Cancelled',
      'location': 'Cavalry Ground, Lahore',
      'budget': '6,000',
      'providerCategory': 'Cook',
      'cancelDate': 'Mar 9, 2024',
      'cancelReason': 'Event postponed',
      'cancelDescription':
          'Customer postponed the dinner party and cancelled the cooking service.',
    },
    {
      'id': 'job_019',
      'name': 'Zain Ali',
      'role': 'CUSTOMER',
      'snippet': 'Garden maintenance cancelled',
      'time': 'Cancelled on Mar 11, 2024',
      'unread': false,
      'profilePicture': 'https://i.pravatar.cc/150?img=20',
      'avatar': 'https://i.pravatar.cc/150?img=20',
      'isOnline': true,
      'type': 'customer',
      'lastMessage': 'Weather conditions not suitable',
      'timestamp': 'Cancelled on Mar 11, 2024',
      'category': 'Gardening',
      'status': 'Cancelled',
      'location': 'EME Society, Lahore',
      'budget': '1,500',
      'providerCategory': 'Gardener',
      'cancelDate': 'Mar 11, 2024',
      'cancelReason': 'Bad weather',
      'cancelDescription':
          'Customer cancelled due to heavy rain and unsuitable weather conditions for garden work.',
    },
  ];

  // Filter jobs based on provider's registered category
  List<Map<String, dynamic>> get _filteredActiveJobs {
    return activeJobs
        .where((job) => job['providerCategory'] == _providerCategory)
        .toList();
  }

  List<Map<String, dynamic>> get _filteredScheduledJobs {
    return scheduledJobs
        .where((job) => job['providerCategory'] == _providerCategory)
        .toList();
  }

  List<Map<String, dynamic>> get _filteredCompletedJobs {
    return completedJobs
        .where((job) => job['providerCategory'] == _providerCategory)
        .toList();
  }

  List<Map<String, dynamic>> get _filteredCancelledJobs {
    return cancelledJobs
        .where((job) => job['providerCategory'] == _providerCategory)
        .toList();
  }

  // Check if job matches provider's category
  bool _isJobMatchingProviderCategory(Map<String, dynamic> job) {
    return job['providerCategory'] == _providerCategory;
  }

  Future<void> _loadScheduledJobsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scheduledJobsJson = prefs.getString('scheduled_jobs') ?? '[]';
      final storedJobs = jsonDecode(scheduledJobsJson) as List<dynamic>;

      debugPrint('Found ${storedJobs.length} jobs in storage');
      debugPrint('Provider category: $_providerCategory');

      // Remove duplicates by keeping only the first occurrence of each job ID
      final uniqueJobs = <Map<String, dynamic>>[];
      final seenJobIds = <String>{};

      for (final job in storedJobs) {
        final jobId = job['id'] as String?;
        if (jobId != null && !seenJobIds.contains(jobId)) {
          uniqueJobs.add(Map<String, dynamic>.from(job));
          seenJobIds.add(jobId);
        }
      }

      debugPrint('Loaded ${uniqueJobs.length} unique jobs from storage');

      setState(() {
        // Merge hardcoded jobs with stored jobs (filter by provider category)
        final filteredStoredJobs = uniqueJobs.where((job) {
          final jobCategory = job['providerCategory'] as String? ?? 'General';
          final matches = jobCategory == _providerCategory;
          return matches;
        }).toList();

        // Get hardcoded jobs that match provider category
        final hardcodedJobs = <Map<String, dynamic>>[];
        for (final job in [
          {
            'id': 'job_007',
            'name': 'Tariq Mehmood',
            'role': 'CUSTOMER',
            'snippet': 'Airport transfer service',
            'time': 'Tomorrow at 5:30 AM',
            'unread': false,
            'profilePicture': 'https://i.pravatar.cc/150?img=18',
            'avatar': 'https://i.pravatar.cc/150?img=18',
            'isOnline': false,
            'type': 'customer',
            'lastMessage': 'Need pickup for early morning flight',
            'timestamp': 'Tomorrow at 5:30 AM',
            'category': 'Transportation',
            'status': 'Scheduled',
            'location': 'Model Town, Lahore',
            'budget': '2,200',
            'providerCategory': 'Driver',
            'scheduledDate': '2024-03-29',
            'scheduledTime': '5:30 AM',
          },
          {
            'id': 'job_008',
            'name': 'Ali Hassan',
            'role': 'CUSTOMER',
            'snippet': 'City tour transportation',
            'time': 'Mar 30 at 10:00 AM',
            'unread': false,
            'profilePicture': 'https://i.pravatar.cc/150?img=21',
            'avatar': 'https://i.pravatar.cc/150?img=21',
            'isOnline': true,
            'type': 'customer',
            'lastMessage': 'Need driver for city tour',
            'timestamp': 'Mar 30 at 10:00 AM',
            'category': 'Transportation',
            'status': 'Scheduled',
            'location': 'Lahore Fort, Lahore',
            'budget': '3,500',
            'providerCategory': 'Driver',
            'scheduledDate': '2024-03-30',
            'scheduledTime': '10:00 AM',
          },
          {
            'id': 'job_009',
            'name': 'Nadia Khan',
            'role': 'CUSTOMER',
            'snippet': 'Shopping trip driver needed',
            'time': 'Mar 31 at 2:00 PM',
            'unread': false,
            'profilePicture': 'https://i.pravatar.cc/150?img=22',
            'avatar': 'https://i.pravatar.cc/150?img=22',
            'isOnline': false,
            'type': 'customer',
            'lastMessage': 'Need ride for shopping in Mall of Lahore',
            'timestamp': 'Mar 31 at 2:00 PM',
            'category': 'Transportation',
            'status': 'Scheduled',
            'location': 'Cavalry Ground, Lahore',
            'budget': '1,800',
            'providerCategory': 'Driver',
            'scheduledDate': '2024-03-31',
            'scheduledTime': '2:00 PM',
          },
          {
            'id': 'job_010',
            'name': 'Faisal Ahmed',
            'role': 'CUSTOMER',
            'snippet': 'Outstation trip to Islamabad',
            'time': 'Apr 1 at 8:00 AM',
            'unread': false,
            'profilePicture': 'https://i.pravatar.cc/150?img=23',
            'avatar': 'https://i.pravatar.cc/150?img=23',
            'isOnline': true,
            'type': 'customer',
            'lastMessage': 'Need driver for Islamabad trip',
            'timestamp': 'Apr 1 at 8:00 AM',
            'category': 'Transportation',
            'status': 'Scheduled',
            'location': 'Gulberg II, Lahore',
            'budget': '8,000',
            'providerCategory': 'Driver',
            'scheduledDate': '2024-04-01',
            'scheduledTime': '8:00 AM',
          }
        ]) {
          if (job['providerCategory'] == _providerCategory) {
            hardcodedJobs.add(Map<String, dynamic>.from(job));
          }
        }

        // Combine hardcoded and stored jobs, avoiding duplicates
        final allJobs = <Map<String, dynamic>>[];
        final seenJobIds = <String>{};

        // Add hardcoded jobs first
        for (final job in hardcodedJobs) {
          final jobId = job['id'] as String?;
          if (jobId != null && !seenJobIds.contains(jobId)) {
            allJobs.add(job);
            seenJobIds.add(jobId);
          }
        }

        // Add stored jobs that aren't duplicates
        for (final job in filteredStoredJobs) {
          final jobId = job['id'] as String?;
          if (jobId != null && !seenJobIds.contains(jobId)) {
            allJobs.add(job);
            seenJobIds.add(jobId);
          }
        }

        scheduledJobs = allJobs;
        debugPrint(
            'Total scheduled jobs after merge: ${scheduledJobs.length} jobs');
      });
    } catch (e) {
      debugPrint('Error loading scheduled jobs: $e');
    }
  }

  Future<void> _clearAllStoredJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('scheduled_jobs');
      debugPrint('Cleared all stored jobs - starting fresh');

      // Also clear the local list
      if (mounted) {
        setState(() {
          scheduledJobs.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All stored jobs cleared - starting fresh'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error clearing stored jobs: $e');
    }
  }

  Future<void> _saveJobsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save scheduled jobs
      final scheduledJobsJson = jsonEncode(scheduledJobs);
      await prefs.setString('scheduled_jobs', scheduledJobsJson);

      // Save cancelled jobs
      final cancelledJobsJson = jsonEncode(cancelledJobs);
      await prefs.setString('cancelled_jobs', cancelledJobsJson);

      // Save active jobs
      final activeJobsJson = jsonEncode(activeJobs);
      await prefs.setString('active_jobs', activeJobsJson);

      debugPrint('Jobs saved to storage successfully');
    } catch (e) {
      debugPrint('Error saving jobs to storage: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadScheduledJobsFromStorage();
    _startSchedulerTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh scheduled jobs when screen becomes visible
    _loadScheduledJobsFromStorage();
  }

  @override
  void dispose() {
    _schedulerTimer?.cancel();
    super.dispose();
  }

  void _startSchedulerTimer() {
    // Check every 30 seconds for more precise job activation
    _schedulerTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAndMoveScheduledJobs();
    });

    // Also check immediately when the screen loads
    _checkAndMoveScheduledJobs();
  }

  void _checkAndMoveScheduledJobs() {
    final now = DateTime.now();
    final jobsToMove = <Map<String, dynamic>>[];

    for (final job in scheduledJobs) {
      // Only check jobs that match provider's category
      if (_isJobMatchingProviderCategory(job) && _isJobTimeReached(job, now)) {
        jobsToMove.add(job);
      }
    }

    if (jobsToMove.isNotEmpty) {
      setState(() {
        for (final job in jobsToMove) {
          // Check if service provider already has an active job
          if (_hasActiveJobForProvider(job['provider'] ?? job['name'])) {
            // Skip moving this job as provider is already busy
            continue;
          }

          // Remove from scheduled jobs
          scheduledJobs.removeWhere((j) => j['id'] == job['id']);

          // Add to active jobs with updated status
          final activeJob = Map<String, dynamic>.from(job);
          activeJob['status'] = 'In Progress';
          activeJob['time'] = 'Started just now';
          activeJob.remove('scheduledDate');
          activeJob.remove('scheduledTime');
          activeJobs.add(activeJob);
        }
      });

      // Show notification for moved jobs
      if (mounted) {
        _showScheduledJobsMovedNotification(jobsToMove);
      }
    }
  }

  bool _hasActiveJobForProvider(String providerName) {
    // Check if the provider already has an active job
    return activeJobs.any((job) =>
        (job['provider'] == providerName || job['name'] == providerName) &&
        job['status'] == 'In Progress');
  }

  bool _isJobTimeReached(Map<String, dynamic> job, DateTime now) {
    final scheduledDate = job['scheduledDate'] as String?;
    final scheduledTime = job['scheduledTime'] as String?;

    if (scheduledDate == null || scheduledTime == null) {
      return false;
    }

    // Parse scheduled date and time
    final scheduledDateTime = _parseDateTime(scheduledDate, scheduledTime);

    // Check if the scheduled time has been reached (more precise timing)
    final difference = now.difference(scheduledDateTime);

    // Job becomes active exactly at scheduled time or up to 2 minutes after
    return difference.inMinutes >= 0 && difference.inMinutes <= 2;
  }

  DateTime _parseDateTime(String date, String time) {
    try {
      // Parse date (assuming format like "Mar 15, 2024")
      final dateParts = date.split(' ');
      if (dateParts.length < 3) {
        // Fallback to today if date format is invalid
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, 12, 0); // Default to noon
      }

      final month = _getMonthNumber(dateParts[0]);
      final day = int.parse(dateParts[1].replaceAll(',', ''));
      final year = int.parse(dateParts[2]);

      // Parse time (assuming format like "10:00 PM" or "2:00 PM")
      final timeParts = time.split(' ');
      if (timeParts.isEmpty) {
        // Fallback to current time if time format is invalid
        final now = DateTime.now();
        return DateTime(year, month, day, now.hour, now.minute);
      }

      final hourMinute = timeParts[0].split(':');
      if (hourMinute.length < 2) {
        // Fallback to current time if hour format is invalid
        final now = DateTime.now();
        return DateTime(year, month, day, now.hour, now.minute);
      }

      var hour = int.parse(hourMinute[0]);
      var minute = int.parse(hourMinute[1]);

      // Handle AM/PM period
      String period = '';
      if (timeParts.length > 1) {
        period = timeParts[1];
      } else if (hourMinute.length > 2) {
        // Handle case like "10:00PM" without space
        final timeStr = hourMinute[1];
        if (timeStr.toLowerCase().contains('am') ||
            timeStr.toLowerCase().contains('pm')) {
          period = timeStr.substring(timeStr.length - 2).toUpperCase();
          // Remove AM/PM from minutes if it's attached
          minute = int.parse(timeStr.substring(0, timeStr.length - 2));
        }
      }

      // Convert to 24-hour format
      if (period.toUpperCase() == 'PM' && hour != 12) {
        hour += 12;
      } else if (period.toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      // Fallback to current time if parsing fails
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, now.hour, now.minute);
    }
  }

  int _getMonthNumber(String monthAbbreviation) {
    switch (monthAbbreviation.toLowerCase()) {
      case 'jan':
        return 1;
      case 'feb':
        return 2;
      case 'mar':
        return 3;
      case 'apr':
        return 4;
      case 'may':
        return 5;
      case 'jun':
        return 6;
      case 'jul':
        return 7;
      case 'aug':
        return 8;
      case 'sep':
        return 9;
      case 'oct':
        return 10;
      case 'nov':
        return 11;
      case 'dec':
        return 12;
      default:
        return 1;
    }
  }

  void _showScheduledJobsMovedNotification(
      List<Map<String, dynamic>> movedJobs) {
    final actuallyMoved = movedJobs
        .where(
            (job) => !_hasActiveJobForProvider(job['provider'] ?? job['name']))
        .toList();

    final skippedJobs = movedJobs
        .where(
            (job) => _hasActiveJobForProvider(job['provider'] ?? job['name']))
        .toList();

    String message;
    if (actuallyMoved.length == 1 && skippedJobs.isEmpty) {
      message =
          'Job for ${actuallyMoved.first['customer'] ?? 'Customer'} automatically started at scheduled time!';
    } else if (actuallyMoved.length > 1 && skippedJobs.isEmpty) {
      message =
          '${actuallyMoved.length} jobs automatically started at scheduled time!';
    } else if (actuallyMoved.length == 1 && skippedJobs.length == 1) {
      message =
          'Job for ${actuallyMoved.first['customer'] ?? 'Customer'} started. ${skippedJobs.first['customer'] ?? 'Customer'}\'s job skipped (provider already busy).';
    } else if (actuallyMoved.isEmpty && skippedJobs.length == 1) {
      message =
          'Job for ${skippedJobs.first['customer'] ?? 'Customer'} skipped (provider already has an active job).';
    } else if (actuallyMoved.isEmpty && skippedJobs.length > 1) {
      message =
          '${skippedJobs.length} jobs skipped (providers already have active jobs).';
    } else {
      message =
          '${actuallyMoved.length} jobs started, ${skippedJobs.length} skipped (providers busy).';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: actuallyMoved.isNotEmpty ? Colors.blue : Colors.orange,
        duration: const Duration(seconds: 5),
        action: actuallyMoved.isNotEmpty
            ? SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _tabIndex = 0; // Switch to Active Jobs tab
                  });
                },
              )
            : null,
      ),
    );
  }

  void _triggerSOSAlert(BuildContext context) async {
    // Store context-dependent values before any async operations
    final messenger = ScaffoldMessenger.of(context);

    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                'SOS Emergency Alert',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to send SOS Alert?\n\nThis will send your current location to all your emergency contacts.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red[600],
              ),
              child: Text(
                'Send SOS',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    // If user didn't confirm, return
    if (confirmed != true) return;

    // First check if there are any emergency contacts
    final emergencyContacts = await _getEmergencyContacts();

    if (emergencyContacts.isEmpty) {
      // Show error message for no contacts
      try {
        if (context.mounted) {
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
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'ADD CONTACTS',
                textColor: Colors.white,
                onPressed: () {
                  // Navigate to profile screen to add emergency contacts
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ServiceProviderProfileScreen(),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }
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

      // Create emergency message with location (WhatsApp friendly format)
      final emergencyMessage = '🚨 *EMERGENCY ALERT* 🚨\n\n'
          'I need immediate help!\n\n'
          '*My Current Location:*\n'
          '$mapsUrl\n\n'
          '*Coordinates:* ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}\n'
          '*Time:* ${DateTime.now().toString()}\n\n'
          'Sent from Muawin App Emergency SOS';

      // Send alert to emergency contacts
      await _sendEmergencyAlert(emergencyMessage, position);

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
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'VIEW LOCATION',
              textColor: Colors.white,
              onPressed: () => _launchMaps(context, mapsUrl),
            ),
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sendEmergencyAlert(String message, Position position) async {
    // Send to emergency contacts via WhatsApp
    // This will open WhatsApp with pre-filled emergency message for each contact

    // Get emergency contacts from profile (in real app, this would be from shared preferences)
    final emergencyContacts = await _getEmergencyContacts();

    for (final contact in emergencyContacts) {
      // Send WhatsApp message to each contact
      await _sendWhatsAppToContact(contact['phone']!, message);
    }

    await Future.delayed(
        const Duration(seconds: 2)); // Simulate delay between messages

    // Emergency alert sent successfully
    // In production, this would log to a proper logging service
  }

  Future<void> _sendWhatsAppToContact(String phone, String message) async {
    try {
      // Format phone number (remove any non-digit characters except +)
      final formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      // Encode message for URL
      final encodedMessage = Uri.encodeComponent(message);

      // Create WhatsApp URL
      final whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';

      // Launch WhatsApp
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback: Show message that WhatsApp couldn't be opened
        debugPrint('Could not launch WhatsApp for phone: $formattedPhone');
      }

      // Small delay between messages to avoid overwhelming
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error sending WhatsApp message: $e');
    }
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
            Text(
              'Getting location and sending alert...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
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

  void _markJobAsCompleted(BuildContext context, Map<String, dynamic> jobData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Mark Job as Completed',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to mark this job as completed?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.work, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Job ID: ${jobData['id'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Customer: ${jobData['customer'] ?? jobData['name'] ?? 'Customer'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.category,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Service: ${jobData['category'] ?? 'Service'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This job will instantly move from Active Jobs to Completed Jobs section.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.amber[700],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
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
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog

                // Move job from active to completed (only if matches provider category)
                if (_isJobMatchingProviderCategory(jobData)) {
                  setState(() {
                    // Remove job from active jobs
                    activeJobs.removeWhere((job) => job['id'] == jobData['id']);

                    // Add job to completed jobs with updated data
                    final completedJob = Map<String, dynamic>.from(jobData);
                    completedJob['status'] = 'Completed';
                    completedJob['completionDate'] =
                        DateTime.now().toString().split(' ')[0];
                    completedJob['time'] =
                        'Completed on ${completedJob['completionDate']}';
                    completedJob['rating'] =
                        null; // Will be added by customer later
                    completedJob['review'] =
                        null; // Will be added by customer later
                    completedJobs.add(completedJob);
                  });
                }

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Job completed and moved to Completed Jobs section!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(
                'Complete',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _cancelScheduledJob(BuildContext context, Map<String, dynamic> jobData) {
    final TextEditingController descriptionController = TextEditingController();
    String? selectedReason;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.cancel, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Cancel Scheduled Job',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to cancel this scheduled job?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.work,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Job ID: ${jobData['id'] ?? 'N/A'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Customer: ${jobData['customer'] ?? jobData['name'] ?? 'Customer'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.category,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Service: ${jobData['category'] ?? 'Service'}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Scheduled: ${jobData['scheduledDate']} at ${jobData['scheduledTime']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cancellation Reason',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedReason,
                        decoration: const InputDecoration(
                          hintText: 'Select cancellation reason',
                          border: InputBorder.none,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'schedule_conflict',
                              child: Text('Schedule Conflict')),
                          DropdownMenuItem(
                              value: 'emergency', child: Text('Emergency')),
                          DropdownMenuItem(
                              value: 'customer_request',
                              child: Text('Customer Request')),
                          DropdownMenuItem(
                              value: 'double_booking',
                              child: Text('Double Booking')),
                          DropdownMenuItem(
                              value: 'unavailability',
                              child: Text('Unavailable')),
                          DropdownMenuItem(
                              value: 'other', child: Text('Other')),
                        ],
                        onChanged: (String? value) {
                          setDialogState(() {
                            selectedReason = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Additional Details',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText:
                              'Please provide additional details about the cancellation...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning,
                              color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Job will be moved to Cancelled Jobs section.',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.amber[700],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Back',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: selectedReason == null
                      ? null
                      : () {
                          Navigator.of(context)
                              .pop(); // Close confirmation dialog

                          // Move job from scheduled to cancelled
                          setState(() {
                            // Remove job from scheduled jobs
                            scheduledJobs.removeWhere(
                                (job) => job['id'] == jobData['id']);

                            // Add job to cancelled jobs with updated data
                            final cancelledJob =
                                Map<String, dynamic>.from(jobData);
                            cancelledJob['status'] = 'Cancelled';
                            cancelledJob['cancelDate'] =
                                DateTime.now().toString().split(' ')[0];
                            cancelledJob['time'] =
                                'Cancelled on ${cancelledJob['cancelDate']}';
                            cancelledJob['cancelReason'] =
                                _getReasonText(selectedReason!);
                            cancelledJob['cancelDescription'] =
                                descriptionController.text.isNotEmpty
                                    ? descriptionController.text
                                    : 'No additional details provided.';
                            cancelledJobs.add(cancelledJob);
                          });

                          // Save updated state to SharedPreferences
                          _saveJobsToStorage();

                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Job Cancellation Successful'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFDADC85), // Light yellow-green color
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    'Cancel Job',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getReasonText(String reason) {
    switch (reason) {
      case 'schedule_conflict':
        return 'Schedule Conflict';
      case 'emergency':
        return 'Emergency';
      case 'customer_request':
        return 'Customer Request';
      case 'double_booking':
        return 'Double Booking';
      case 'unavailability':
        return 'Unavailable';
      case 'other':
        return 'Other';
      default:
        return 'Unknown';
    }
  } // 0: Ongoing, 1: Upcoming, 2: History

  final int _currentNavIndex = 1; // bottom nav starts on My Jobs

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
              constraints:
                  BoxConstraints(maxWidth: _getMaxContentWidth(context)),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                          top: 48, // pt-12
                          left: 24,
                          right: 24,
                          bottom: 40,
                        ) +
                        EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
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
                            const SizedBox(
                                width:
                                    54), // Compensate for removed back button
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

                  // Segmented control with proper spacing
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Container(
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
                                  'Future',
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _setTab(2),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _tabIndex == 2
                                      ? primary
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Job History',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: _tabIndex == 2
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
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                      child: IndexedStack(
                        index: _tabIndex,
                        children: [
                          _ActiveJobsView(
                            primary: primary,
                            jobs: _filteredActiveJobs,
                            onJobCompleted: _markJobAsCompleted,
                            onSOSPressed: _triggerSOSAlert,
                          ),
                          _ScheduledJobsView(
                            primary: primary,
                            jobs: _filteredScheduledJobs,
                            onJobCancelled: _cancelScheduledJob,
                            activeJobs: _filteredActiveJobs,
                            onRefresh: _loadScheduledJobsFromStorage,
                            onClear: _clearAllStoredJobs,
                          ),
                          _JobHistoryView(
                            primary: primary,
                            completedJobs: _filteredCompletedJobs,
                            cancelledJobs: _filteredCancelledJobs,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // sticky nav bar
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
                if (index == 2) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ChatsScreen(),
                  ));
                  return;
                }
                if (index == 3) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ServiceProviderProfileScreen(),
                  ));
                  return;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.jobData,
    required this.primary,
    this.onJobCompleted,
    this.onJobCancelled,
    this.onSOSPressed,
    this.isProviderBusy = false,
  });

  final Map<String, dynamic> jobData;
  final Color primary;
  final Function(BuildContext, Map<String, dynamic>)? onJobCompleted;
  final Function(BuildContext, Map<String, dynamic>)? onJobCancelled;
  final Function(BuildContext)? onSOSPressed;
  final bool isProviderBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with customer info and busy indicator
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey[300],
                child: ClipOval(
                  child: _buildProfileImage(jobData),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jobData['customer'] ?? jobData['name'] ?? 'Customer',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      jobData['details'] ??
                          jobData['snippet'] ??
                          'Service request',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Busy indicator
              if (isProviderBusy &&
                  (jobData['status']?.toString() == 'In Progress' ||
                      jobData['status']?.toString() == 'Active'))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        'Provider Busy',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Job details
          Row(
            children: [
              Flexible(
                child: Text(jobData['location'] ?? 'Location',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: primary),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                    jobData['time'] ??
                        (jobData['status']?.toString() == 'Completed'
                            ? 'Completed on ${jobData['completionDate']}'
                            : jobData['status']?.toString() == 'Cancelled'
                                ? 'Cancelled on ${jobData['cancelDate']}'
                                : 'Scheduled'),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black45),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Price information
          Row(
            children: [
              const Icon(Icons.attach_money, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text(
                jobData['price'] ?? 'Price not specified',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Service category
          Row(
            children: [
              const Icon(Icons.work_outline, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text(
                jobData['providerCategory'] ?? 'Driver',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status indicators for all job types
          if (jobData['status']?.toString() == 'Scheduled') ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 3), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6), // Reduced border radius
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule,
                      size: 12, color: Colors.blue[700]), // Reduced icon size
                  const SizedBox(width: 3), // Reduced spacing
                  Text(
                    'Auto-starts at ${jobData['scheduledTime'] ?? 'Scheduled Time'}',
                    style: GoogleFonts.poppins(
                      fontSize: 10, // Reduced font size
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8), // Reduced spacing
          ] else if (jobData['status']?.toString() == 'In Progress' ||
              jobData['status']?.toString() == 'Active') ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 3), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6), // Reduced border radius
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow,
                      size: 12, color: Colors.green[700]), // Reduced icon size
                  const SizedBox(width: 3), // Reduced spacing
                  Text(
                    'Job in Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 10, // Reduced font size
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8), // Reduced spacing
          ] else if (jobData['status']?.toString() == 'Completed') ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 3), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6), // Reduced border radius
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      size: 12, color: Colors.green[700]), // Reduced icon size
                  const SizedBox(width: 3), // Reduced spacing
                  Text(
                    'Job Completed',
                    style: GoogleFonts.poppins(
                      fontSize: 10, // Reduced font size
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8), // Reduced spacing
          ] else if (jobData['status']?.toString() == 'Cancelled') ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 3), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6), // Reduced border radius
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel,
                      size: 12, color: Colors.red[700]), // Reduced icon size
                  const SizedBox(width: 3), // Reduced spacing
                  Text(
                    'Job Cancelled',
                    style: GoogleFonts.poppins(
                      fontSize: 10, // Reduced font size
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8), // Reduced spacing
          ],
          Row(children: [
            const Icon(Icons.access_time, size: 14, color: Colors.black45),
            const SizedBox(width: 4),
            Text(
                jobData['status']?.toString() == 'Completed'
                    ? 'Completed on ${jobData['completionDate']}'
                    : jobData['status']?.toString() == 'Cancelled'
                        ? 'Cancelled on ${jobData['cancelDate']}'
                        : jobData['status']?.toString() == 'In Progress' ||
                                jobData['status']?.toString() == 'Active'
                            ? 'Job in Progress'
                            : 'Scheduled',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
          ]),
          const SizedBox(height: 16),
          // Conditional buttons based on job status
          if (jobData['status']?.toString() == 'Scheduled') ...[
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () => onJobCancelled?.call(context, jobData),
                icon: const Icon(Icons.cancel, size: 20),
                label: const Text('Cancel Job'),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFDADC85), // Light yellow-green color
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ] else if (jobData['status']?.toString() == 'Completed') ...[
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _showRatingDialog(context, jobData),
                icon: const Icon(Icons.star, size: 20),
                label: const Text('View Rating'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else if (jobData['status']?.toString() == 'Cancelled') ...[
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () =>
                    _showCancellationReasonDialog(context, jobData),
                icon: const Icon(Icons.info_outline, size: 20),
                label: Text('View Reason',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.grey.shade600),
              ),
            ),
          ] else if (jobData['status']?.toString() == 'In Progress' ||
              jobData['status']?.toString() == 'Active') ...[
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () => onJobCompleted?.call(context, jobData),
                icon: const Icon(Icons.check_circle),
                label: Text('Mark as Completed',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade600),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => onSOSPressed?.call(context),
                icon: const Icon(Icons.warning_rounded),
                label: Text('SOS EMERGENCY',
                    style: GoogleFonts.poppins(
                        letterSpacing: 0.2, fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getCustomerReview(String jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewsJson = prefs.getString('customer_reviews') ?? '[]';
      final reviews = jsonDecode(reviewsJson) as List<dynamic>;

      // Find review for this specific job
      final jobReview = reviews.firstWhere(
        (review) => review['jobId'] == jobId,
        orElse: () => null,
      );

      if (jobReview != null) {
        return {
          'rating': jobReview['rating'] as int? ?? 0,
          'review': jobReview['review'] as String? ?? '',
          'timestamp': jobReview['timestamp'] as String? ?? '',
          'customerName': jobReview['customerName'] as String? ?? 'Customer',
        };
      }
    } catch (e) {
      debugPrint('Error loading customer review: $e');
    }

    // Return empty data if no review found or error
    return {
      'rating': 0,
      'review': '',
      'timestamp': '',
      'customerName': '',
    };
  }

  String _formatReviewDate(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}-${dateTime.month}-${dateTime.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  void _showRatingDialog(
      BuildContext context, Map<String, dynamic> jobData) async {
    // Load actual customer review from SharedPreferences
    final customerReview =
        await _getCustomerReview(jobData['id'] as String? ?? '');

    // Use a fresh context after async operation
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.star_rate, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Customer Rating',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rating stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 1; i <= 5; i++)
                    Icon(
                      i <= (customerReview['rating'] ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Rating value
              Center(
                child: Text(
                  customerReview['rating'] > 0
                      ? '${customerReview['rating']}/5'
                      : 'Not Rated',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: customerReview['rating'] > 0
                        ? Colors.amber
                        : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Customer review
              Text(
                customerReview['review']?.isNotEmpty == true
                    ? customerReview['review']
                    : 'No customer review available yet.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.4,
                  color: customerReview['review']?.isNotEmpty == true
                      ? Colors.black87
                      : Colors.grey[600],
                  fontStyle: customerReview['review']?.isNotEmpty == true
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              // Job details
              Row(
                children: [
                  const Icon(Icons.work_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    jobData['providerCategory'] ?? 'Driver',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    jobData['price'] ?? 'Price not specified',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    jobData['location'] ?? 'Location not specified',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    jobData['time'] ?? 'Time not specified',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      jobData['details'] ?? 'No additional details',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              if (customerReview['timestamp']?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Reviewed on ${_formatReviewDate(customerReview['timestamp'])}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCancellationReasonDialog(
      BuildContext context, Map<String, dynamic> jobData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Cancellation Reason',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Job ID: ${jobData['id'] ?? 'N/A'}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reason: ${jobData['cancelReason'] ?? 'Not specified'}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Description: ${jobData['cancelDescription'] ?? 'No additional description provided.'}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper method to build profile image with cross-platform support
  Widget _buildProfileImage(Map<String, dynamic> jobData) {
    final avatarUrl = jobData['avatar'] ?? jobData['profilePicture'] ?? '';

    if (avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          );
        },
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(26),
      ),
      child: Icon(
        Icons.person,
        size: 26,
        color: Colors.grey[600],
      ),
    );
  }
}

class _ActiveJobsView extends StatelessWidget {
  const _ActiveJobsView({
    required this.primary,
    required this.jobs,
    required this.onJobCompleted,
    this.onSOSPressed,
  });

  final Color primary;
  final List<Map<String, dynamic>> jobs;
  final Function(BuildContext, Map<String, dynamic>) onJobCompleted;
  final Function(BuildContext)? onSOSPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.work, color: primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Active Jobs',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Active Jobs List
          ...jobs.map((job) => _JobCard(
                jobData: job,
                primary: primary,
                onJobCompleted: onJobCompleted,
                onSOSPressed: onSOSPressed,
              )),
        ],
      ),
    );
  }
}

class _ScheduledJobsView extends StatelessWidget {
  const _ScheduledJobsView({
    required this.primary,
    this.jobs,
    required this.onJobCancelled,
    this.activeJobs,
    this.onRefresh,
    this.onClear,
  });

  final Color primary;
  final List<Map<String, dynamic>>? jobs;
  final Function(BuildContext, Map<String, dynamic>) onJobCancelled;
  final List<Map<String, dynamic>>? activeJobs;
  final VoidCallback? onRefresh;
  final VoidCallback? onClear;

  bool _hasActiveJobForProvider(
      String providerName, List<Map<String, dynamic>>? activeJobs) {
    if (activeJobs == null) return false;
    return activeJobs.any((job) =>
        (job['provider'] == providerName || job['name'] == providerName) &&
        job['status'] == 'In Progress');
  }

  @override
  Widget build(BuildContext context) {
    final jobsList = jobs ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.schedule, color: primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Scheduled Jobs',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    // Show options dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Job Options'),
                        content: const Text('Choose an action:'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onRefresh?.call();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Scheduled jobs refreshed'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Text('Refresh'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onClear?.call();
                            },
                            child: const Text('Clear All Jobs'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    Icons.refresh,
                    color: primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Scheduled Jobs List
          if (jobsList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No scheduled jobs',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your upcoming jobs will appear here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            ...jobsList.map((job) {
              final providerName = job['provider'] ?? job['name'] ?? '';
              final isProviderBusy =
                  _hasActiveJobForProvider(providerName, activeJobs);

              return _JobCard(
                jobData: job,
                primary: primary,
                onJobCancelled: onJobCancelled,
                isProviderBusy: isProviderBusy,
              );
            }),
        ],
      ),
    );
  }
}

class _JobHistoryView extends StatelessWidget {
  const _JobHistoryView({
    required this.primary,
    this.completedJobs,
    this.cancelledJobs,
  });

  final Color primary;
  final List<Map<String, dynamic>>? completedJobs;
  final List<Map<String, dynamic>>? cancelledJobs;

  @override
  Widget build(BuildContext context) {
    final completedJobsList = completedJobs ?? [];
    final cancelledJobsList = cancelledJobs ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Completed Jobs Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Completed Jobs',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Completed Jobs List
          ...completedJobsList
              .map((job) => _JobCard(jobData: job, primary: primary)),

          const SizedBox(height: 24),

          // Cancelled Jobs Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.cancel, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Cancelled Jobs',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Cancelled Jobs List
          ...cancelledJobsList
              .map((job) => _JobCard(jobData: job, primary: primary)),
        ],
      ),
    );
  }
}
