import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:muawin_app/chats_screen.dart';
import 'package:muawin_app/widgets/bottom_navigation_bar.dart';
import 'package:muawin_app/service_provider_feed_screen.dart';
import 'package:muawin_app/service_provider_profile_screen.dart';

/// Max content width adjusted to match navigation bar span (responsive)
double _getMaxContentWidth(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  return screenWidth - 32;
}

class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  int _tabIndex = 0;
  bool _isLoading = true;
  String _currentProviderId = '';
  Timer? _statusCheckTimer;

  // State management for jobs loaded from Supabase
  List<Map<String, dynamic>> activeJobs = [];
  List<Map<String, dynamic>> completedJobs = [];
  List<Map<String, dynamic>> scheduledJobs = [];
  List<Map<String, dynamic>> cancelledJobs = [];

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _checkAndPromoteJobs(),
    );
  }

  Future<void> _initializeAndLoad() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Get profile
      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final profileId = profile['id'].toString();

      // Get provider record
      final provider = await supabase
          .from('providers')
          .select('id')
          .eq('profile_id', profileId)
          .single();

      _currentProviderId = provider['id'].toString();

      // Load jobs from Supabase
      await _loadJobs();

      // Check for jobs that need promotion immediately on screen open
      await _checkAndPromoteJobs();
    } catch (e) {
      debugPrint('Error initializing provider: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadJobs() async {
    try {
      if (_currentProviderId.isEmpty) {
        return;
      }

      if (mounted) setState(() => _isLoading = true);

      final response = await Supabase.instance.client
          .from('jobs')
          .select('''
            id, title, service_category, status, scheduled_date,
            scheduled_time, location, city, area, description, created_at,
            customer_id, cancel_reason, cancel_description, cancel_date,
            completion_date,
            customers!inner(
              profile_id,
              profiles!inner(full_name, profile_image_url, phone_number)
            )
          ''')
          .eq('provider_id', _currentProviderId)
          .order('created_at', ascending: false);

      final allJobs = List<Map<String, dynamic>>.from(response);

      // Map to the format expected by UI cards
      final List<Map<String, dynamic>> mapped = allJobs.map((job) {
        final customerName =
            job['customers']?['profiles']?['full_name']?.toString() ??
                'Customer';
        final scheduledDate = job['scheduled_date']?.toString() ?? '';
        final scheduledTime = job['scheduled_time']?.toString() ?? '';
        final city = job['city']?.toString() ?? '';
        final area = job['area']?.toString() ?? '';
        final location = area.isNotEmpty
            ? '$area, $city'
            : (job['location']?.toString() ?? 'Location TBD');
        final jobId = job['id']?.toString() ?? '';

        // Format time display
        String timeDisplay = '';
        if (scheduledDate.isNotEmpty) timeDisplay = scheduledDate;
        if (scheduledTime.isNotEmpty) {
          timeDisplay = timeDisplay.isNotEmpty
              ? '$timeDisplay $scheduledTime'
              : scheduledTime;
        }
        if (timeDisplay.isEmpty) timeDisplay = 'Flexible';

        return {
          'id': jobId,
          'supabase_id': jobId,
          'title': job['title']?.toString() ?? 'Service Request',
          'category': job['service_category']?.toString() ?? '',
          'details': job['description']?.toString() ??
              job['title']?.toString() ??
              'Service request',
          'snippet': job['description']?.toString() ??
              job['title']?.toString() ??
              'Service request',
          'location': location,
          'city': city,
          'area': area,
          'time': timeDisplay,
          'date': scheduledDate,
          'scheduledDate': scheduledDate,
          'scheduledTime': scheduledTime,
          'status': job['status']?.toString() ?? 'scheduled',
          'price': 'Negotiable',
          'budget': '0',
          'customer': customerName,
          'name': customerName,
          'customer_id': job['customer_id']?.toString() ?? '',
          'created_at': job['created_at']?.toString() ?? '',
          'completionDate': job['completion_date']?.toString(),
          'cancelDate': job['cancel_date']?.toString(),
          'cancelReason': job['cancel_reason']?.toString() ?? '',
          'customerImage':
              job['customers']?['profiles']?['profile_image_url'] ?? '',
          'cancelDescription': job['cancel_description']?.toString() ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          activeJobs = List<Map<String, dynamic>>.from(mapped
              .where((j) =>
                  j['status']?.toString().trim().toLowerCase() == 'active')
              .map((j) => Map<String, dynamic>.from(j)));
          scheduledJobs = List<Map<String, dynamic>>.from(mapped
              .where((j) =>
                  j['status']?.toString().trim().toLowerCase() == 'scheduled')
              .map((j) => Map<String, dynamic>.from(j)));
          completedJobs = List<Map<String, dynamic>>.from(mapped
              .where((j) =>
                  j['status']?.toString().trim().toLowerCase() == 'completed')
              .map((j) => Map<String, dynamic>.from(j)));
          cancelledJobs = List<Map<String, dynamic>>.from(mapped
              .where((j) =>
                  j['status']?.toString().trim().toLowerCase() == 'cancelled')
              .map((j) => Map<String, dynamic>.from(j)));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading jobs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _triggerSOSAlert(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

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

    if (confirmed != true) return;

    final emergencyContacts = await _getEmergencyContacts();

    if (emergencyContacts.isEmpty) {
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

      final mapsUrl =
          'https://www.google.com/maps?q=${position.latitude},${position.longitude}';

      final emergencyMessage = '🚨 *EMERGENCY ALERT* 🚨\n\n'
          'I need immediate help!\n\n'
          '*My Current Location:*\n'
          '$mapsUrl\n\n'
          '*Coordinates:* ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}\n'
          '*Time:* ${DateTime.now().toString()}\n\n'
          'Sent from Muawin App Emergency SOS';

      await _sendEmergencyAlert(emergencyMessage, position);

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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sendEmergencyAlert(String message, Position position) async {
    final emergencyContacts = await _getEmergencyContacts();

    for (final contact in emergencyContacts) {
      await _sendWhatsAppToContact(contact['phone']!, message);
    }

    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> _sendWhatsAppToContact(String phone, String message) async {
    try {
      final formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      final encodedMessage = Uri.encodeComponent(message);
      final whatsappUrl = 'https://wa.me/$formattedPhone?text=$encodedMessage';

      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        debugPrint('Could not launch WhatsApp for phone: $formattedPhone');
      }

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

  Future<List<Map<String, dynamic>>> _getEmergencyContacts() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final profileResp = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final profileId = profileResp['id']?.toString() ?? '';

      if (profileId.isNotEmpty) {
        final providerResp = await supabase
            .from('providers')
            .select('id')
            .eq('profile_id', profileId)
            .maybeSingle();

        final providerId = providerResp?['id']?.toString() ?? '';

        if (providerId.isNotEmpty) {
          final contactsResp = await supabase
              .from('emergency_contacts')
              .select('name, phone_number')
              .eq('provider_id', providerId);

          return (contactsResp as List)
              .map((c) => {
                    'name': c['name']?.toString() ?? '',
                    'phone': c['phone_number']?.toString() ?? '',
                  })
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
    }

    return [];
  }

  void _launchMaps(BuildContext context, String url) async {
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
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(context).pop();
                // Supabase: update job status to completed
                try {
                  await Supabase.instance.client.from('jobs').update({
                    'status': 'completed',
                    'completion_date':
                        DateTime.now().toIso8601String().split('T')[0],
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', jobData['id']);
                } catch (e) {
                  debugPrint('Error completing job: $e');
                }
                setState(() {
                  activeJobs.removeWhere((job) => job['id'] == jobData['id']);
                  final completedJob = Map<String, dynamic>.from(jobData);
                  completedJob['status'] = 'completed';
                  completedJob['completionDate'] =
                      DateTime.now().toString().split(' ')[0];
                  completedJob['time'] =
                      'Completed on ${completedJob['completionDate']}';
                  completedJob['rating'] = null;
                  completedJob['review'] = null;
                  completedJobs.add(Map<String, dynamic>.from(completedJob));
                });
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Job completed and moved to Completed Jobs!'),
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
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.of(context).pop();
                          // Supabase: update job status to cancelled
                          try {
                            await Supabase.instance.client.from('jobs').update({
                              'status': 'cancelled',
                              'cancel_reason': _getReasonText(selectedReason!),
                              'cancel_description':
                                  descriptionController.text.isNotEmpty
                                      ? descriptionController.text
                                      : 'No additional details provided.',
                              'cancel_date': DateTime.now()
                                  .toIso8601String()
                                  .split('T')[0],
                              'updated_at': DateTime.now().toIso8601String(),
                            }).eq('id', jobData['id']);
                          } catch (e) {
                            debugPrint('Error cancelling job: $e');
                          }
                          setState(() {
                            scheduledJobs.removeWhere(
                                (job) => job['id'] == jobData['id']);
                            final cancelledJob =
                                Map<String, dynamic>.from(jobData);
                            cancelledJob['status'] = 'cancelled';
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
                            cancelledJobs
                                .add(Map<String, dynamic>.from(cancelledJob));
                          });
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Job Cancellation Successful'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDADC85),
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
  }

  final int _currentNavIndex = 1;

  Future<void> _checkAndPromoteJobs() async {
    final now = DateTime.now();

    // Find scheduled jobs whose time has passed
    final jobsToPromote = scheduledJobs.where((job) {
      try {
        final dateStr =
            (job['scheduled_date'] ?? job['scheduledDate'] ?? '').toString();
        final timeStr =
            (job['scheduled_time'] ?? job['scheduledTime'] ?? '00:00:00')
                .toString();
        if (dateStr.isEmpty) return false;

        // Parse date and time
        final dateParts = dateStr.split('-');
        final timeParts = timeStr.split(':');
        if (dateParts.length < 3) return false;

        final scheduledDateTime = DateTime(
          int.parse(dateParts[0]),
          int.parse(dateParts[1]),
          int.parse(dateParts[2]),
          timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0,
          timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0,
        );

        return now.isAfter(scheduledDateTime);
      } catch (e) {
        return false;
      }
    }).toList();

    // Update each job in Supabase and local state
    for (final job in jobsToPromote) {
      try {
        await Supabase.instance.client.from('jobs').update({
          'status': 'active',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', job['id']);
      } catch (e) {
        // Silently handle update errors
      }
    }

    // If any jobs were promoted, reload from Supabase
    if (jobsToPromote.isNotEmpty) {
      await _loadJobs();
    }
  }

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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                          top: 48,
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
                            const SizedBox(width: 54),
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
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                            child: IndexedStack(
                              index: _tabIndex,
                              children: [
                                _ActiveJobsView(
                                  primary: primary,
                                  jobs: activeJobs,
                                  onJobCompleted: _markJobAsCompleted,
                                  onSOSPressed: _triggerSOSAlert,
                                  onRefresh: _loadJobs,
                                ),
                                _ScheduledJobsView(
                                  primary: primary,
                                  jobs: scheduledJobs,
                                  onJobCancelled: _cancelScheduledJob,
                                  onRefresh: _loadJobs,
                                ),
                                _JobHistoryView(
                                  primary: primary,
                                  completedJobs: completedJobs,
                                  cancelledJobs: cancelledJobs,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
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
  });

  final Map<String, dynamic> jobData;
  final Color primary;
  final Function(BuildContext, Map<String, dynamic>)? onJobCompleted;
  final Function(BuildContext, Map<String, dynamic>)? onJobCancelled;
  final Function(BuildContext)? onSOSPressed;

  @override
  Widget build(BuildContext context) {
    final statusStr = jobData['status']?.toString() ?? '';
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
            ],
          ),
          const SizedBox(height: 12),
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
                        (statusStr == 'completed'
                            ? 'Completed on ${jobData['completionDate']}'
                            : statusStr == 'cancelled'
                                ? 'Cancelled on ${jobData['cancelDate']}'
                                : 'Scheduled'),
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black45),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          Row(
            children: [
              const Icon(Icons.work_outline, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text(
                jobData['category'] ?? 'Service',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (statusStr == 'scheduled') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 12, color: Colors.blue[700]),
                  const SizedBox(width: 3),
                  Text(
                    'Scheduled',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else if (statusStr == 'active' || statusStr == 'In Progress') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 12, color: Colors.green[700]),
                  const SizedBox(width: 3),
                  Text(
                    'Job in Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else if (statusStr == 'completed') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 12, color: Colors.green[700]),
                  const SizedBox(width: 3),
                  Text(
                    'Job Completed',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else if (statusStr == 'cancelled') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cancel, size: 12, color: Colors.red[700]),
                  const SizedBox(width: 3),
                  Text(
                    'Job Cancelled',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(children: [
            const Icon(Icons.access_time, size: 14, color: Colors.black45),
            const SizedBox(width: 4),
            Text(
                statusStr == 'completed'
                    ? 'Completed on ${jobData['completionDate']}'
                    : statusStr == 'cancelled'
                        ? 'Cancelled on ${jobData['cancelDate']}'
                        : statusStr == 'active' || statusStr == 'In Progress'
                            ? 'Job in Progress'
                            : 'Scheduled',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.black45)),
          ]),
          const SizedBox(height: 16),
          if (statusStr == 'scheduled') ...[
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () => onJobCancelled?.call(context, jobData),
                icon: const Icon(Icons.cancel, size: 20),
                label: const Text('Cancel Job'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDADC85),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
          ] else if (statusStr == 'completed') ...[
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: () => _showRegisterComplaintDialog(context, jobData),
                icon: const Icon(Icons.report_problem_outlined, size: 20),
                label: const Text('Register Complaint'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else if (statusStr == 'cancelled') ...[
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
          ] else if (statusStr == 'active' || statusStr == 'In Progress') ...[
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
                'Reason: ${jobData['cancel_reason'] ?? jobData['cancelReason'] ?? 'Not specified'}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Description: ${jobData['cancel_description'] ?? jobData['cancelDescription'] ?? 'No details'}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${jobData['cancel_date'] ?? jobData['cancelDate'] ?? 'Unknown date'}',
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

  Widget _buildProfileImage(Map<String, dynamic> jobData) {
    final customerImageUrl = jobData['customerImage']?.toString() ?? '';
    final avatarUrl = customerImageUrl.isNotEmpty
        ? customerImageUrl
        : (jobData['avatar'] ?? jobData['profilePicture'] ?? '');
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

  void _showRegisterComplaintDialog(
      BuildContext context, Map<String, dynamic> jobData) {
    String? selectedComplaintType;
    final TextEditingController complaintDescriptionController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.report_problem_outlined,
                      color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Register Complaint',
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
                      'Job: ${jobData['title'] ?? 'Service Request'}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Complaint Type',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedComplaintType,
                        decoration: const InputDecoration(
                          hintText: 'Select complaint type',
                          border: InputBorder.none,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'unprofessional_behavior',
                              child: Text('Unprofessional Behavior')),
                          DropdownMenuItem(
                              value: 'incomplete_work',
                              child: Text('Incomplete Work')),
                          DropdownMenuItem(
                              value: 'property_damage',
                              child: Text('Property Damage')),
                          DropdownMenuItem(
                              value: 'overcharging',
                              child: Text('Overcharging')),
                          DropdownMenuItem(
                              value: 'other', child: Text('Other')),
                        ],
                        onChanged: (String? value) {
                          setDialogState(() {
                            selectedComplaintType = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
                        controller: complaintDescriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Describe your complaint...',
                          border: InputBorder.none,
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
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: selectedComplaintType == null
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          try {
                            final supabase = Supabase.instance.client;
                            final user = supabase.auth.currentUser;

                            // Get provider_id from current auth user
                            String providerId = '';
                            if (user != null) {
                              final profile = await supabase
                                  .from('profiles')
                                  .select('id')
                                  .eq('user_id', user.id)
                                  .single();
                              final provider = await supabase
                                  .from('providers')
                                  .select('id')
                                  .eq('profile_id', profile['id'].toString())
                                  .single();
                              providerId = provider['id'].toString();
                            }

                            final complaintDescription =
                                complaintDescriptionController.text.isNotEmpty
                                    ? complaintDescriptionController.text
                                    : '';

                            await supabase.from('complaints').insert({
                              'provider_id': providerId,
                              'customer_id': jobData['customer_id'] ?? '',
                              'job_id': jobData['id'] ?? '',
                              'complaint_type': selectedComplaintType,
                              'description': complaintDescription,
                              'status': 'open',
                              'priority': 'medium',
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Complaint registered successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            debugPrint('Error registering complaint: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to register complaint'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Submit',
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
      },
    );
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
    this.onRefresh,
  });

  final Color primary;
  final List<Map<String, dynamic>> jobs;
  final Function(BuildContext, Map<String, dynamic>) onJobCompleted;
  final Function(BuildContext)? onSOSPressed;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) onRefresh!();
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
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
            if (jobs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.work, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No active jobs',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your active jobs will appear here',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...jobs.map((job) => _JobCard(
                    jobData: job,
                    primary: primary,
                    onJobCompleted: onJobCompleted,
                    onSOSPressed: onSOSPressed,
                  )),
          ],
        ),
      ),
    );
  }
}

class _ScheduledJobsView extends StatelessWidget {
  const _ScheduledJobsView({
    required this.primary,
    this.jobs,
    required this.onJobCancelled,
    this.onRefresh,
  });

  final Color primary;
  final List<Map<String, dynamic>>? jobs;
  final Function(BuildContext, Map<String, dynamic>) onJobCancelled;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final jobsList = jobs ?? [];
    return RefreshIndicator(
      onRefresh: () async {
        if (onRefresh != null) onRefresh!();
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
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
                      onRefresh?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Scheduled jobs refreshed'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Icon(Icons.refresh, color: primary, size: 20),
                  ),
                ],
              ),
            ),
            if (jobsList.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.schedule, size: 64, color: Colors.grey[400]),
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
              ...jobsList.map((job) => _JobCard(
                    jobData: job,
                    primary: primary,
                    onJobCancelled: onJobCancelled,
                  )),
          ],
        ),
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
          if (completedJobsList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No completed jobs yet',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            ...completedJobsList
                .map((job) => _JobCard(jobData: job, primary: primary)),
          const SizedBox(height: 24),
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
          if (cancelledJobsList.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.cancel, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No cancelled jobs',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            ...cancelledJobsList
                .map((job) => _JobCard(jobData: job, primary: primary)),
        ],
      ),
    );
  }
}
