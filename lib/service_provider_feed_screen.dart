import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert'; // Add this import for jsonDecode
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'widgets/get_featured_overlay.dart';
import 'services/provider_data_service.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/chat_voice_input.dart';
import 'widgets/service_provider_notification_bell.dart';
import 'my_jobs_screen.dart';
import 'chats_screen.dart';
import 'service_provider_profile_screen.dart';

/// Max width adjusted to match navigation bar span (responsive)
double _getMaxContentWidth(BuildContext context) {
  // Get screen width and subtract appropriate padding
  final screenWidth = MediaQuery.of(context).size.width;
  // Use most of the screen width, leaving some margin for visual balance
  return screenWidth - 32; // 16px padding on each side
}

/// Header bottom radius 2rem (32px).
const double _kHeaderRadius = 32;

/// Card radius 1.5rem.
const double _kCardRadius = 24;

/// Provider status options.
enum ProviderAvailability { available, busy, offline }

Color _getGlowingStatusColor(ProviderAvailability status) {
  switch (status) {
    case ProviderAvailability.available:
      return Colors.green; // Glowing green for available
    case ProviderAvailability.busy:
      return Colors.amber; // Glowing yellow for busy
    case ProviderAvailability.offline:
      return Colors.red; // Glowing red for offline
  }
}

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

  // Current provider ID (this would come from authentication/user profile)
  // TODO: Load from Supabase
  final String _currentProviderId = '';

  // Real provider data from ProviderDataService
  Map<String, dynamic>? _providerData;

  // Service provider profile data
  // TODO: Load from Supabase
  Map<String, dynamic> get _providerProfile {
    // Use real provider data if available, otherwise fallback to mock data
    if (_providerData != null) {
      return {
        'name': _providerData!['provider_name'] ?? '',
        'category': _providerData!['service_type'] ?? '',
        'rating': '0.0',
        'profilePicture': '',
      };
    }

    // Fallback empty data
    return {
      'name': '',
      'category': '',
      'rating': '0.0',
      'profilePicture': '',
    };
  }

  // TODO: Load from Supabase
  final List<Map<String, dynamic>> _jobAlerts = [];

  void _showStatusSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                color: Theme.of(context).textTheme.titleLarge?.color,
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
                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Send a counter-offer to ${job['customer']}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.6),
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
                  color: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.color
                      ?.withValues(alpha: 0.6),
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
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.5),
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
                  color: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.color
                      ?.withValues(alpha: 0.6),
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
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: () {
                    // Safe haptic feedback alternative
                    try {
                      // Haptic feedback removed for compatibility
                    } catch (e) {
                      // Ignore haptic feedback errors
                    }
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

  // Method to load direct requests for this provider
  Future<void> _loadDirectRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final directRequestsKey = 'direct_requests_$_currentProviderId';
      final directRequestsJson = prefs.getString(directRequestsKey) ?? '[]';
      final directRequests = jsonDecode(directRequestsJson) as List<dynamic>;

      // Add direct requests to the job alerts
      setState(() {
        _jobAlerts.addAll(directRequests.cast<Map<String, dynamic>>());
      });
    } catch (e) {
      debugPrint('Error loading direct requests: $e');
    }
  }

  void _moveJobToMyJobs(Map<String, dynamic> job) async {
    try {
      // Debug: Print job data structure
      debugPrint('Job data keys: ${job.keys.toList()}');
      debugPrint('Job category field: ${job['category']}');
      debugPrint('Job service field: ${job['service']}');

      // Save to SharedPreferences to sync with My Jobs screen
      final prefs = await SharedPreferences.getInstance();
      final existingJobsJson = prefs.getString('scheduled_jobs') ?? '[]';
      final existingJobs = jsonDecode(existingJobsJson) as List<dynamic>;

      // Check if job already exists to prevent duplicates
      final jobExists =
          existingJobs.any((storedJob) => storedJob['id'] == job['id']);
      if (jobExists) {
        debugPrint(
            'Job ${job['id']} already exists in storage, skipping duplicate');
        return;
      }

      // Create a scheduled job entry with proper status and timestamps
      final scheduledJob = {
        ...job,
        'status': 'Scheduled',
        'scheduledDate': DateTime.now().toString().split(' ')[0],
        'scheduledTime':
            '${DateTime.now().hour + 1}:00 PM', // Schedule for 1 hour from now
        'acceptedAt': DateTime.now().toIso8601String(),
        'providerCategory': job['category'] ?? job['service'] ?? 'Driver',
      };

      // Add the new job
      existingJobs.add(scheduledJob);
      await prefs.setString('scheduled_jobs', jsonEncode(existingJobs));

      debugPrint('Job ${job['id']} moved to My Jobs as scheduled job');
    } catch (e) {
      debugPrint('Error moving job to My Jobs: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDirectRequests(); // Load direct requests when screen initializes
    _loadProviderData(); // Load real provider data
  }

  // Load real provider data from ProviderDataService
  Future<void> _loadProviderData() async {
    try {
      final data =
          await ProviderDataService.getProviderData(_currentProviderId);
      setState(() {
        _providerData = data;
      });

      // Listen for real-time service details changes
      ProviderDataService.addProviderDataChangeListener((updatedData) {
        if (mounted) {
          setState(() {
            _providerData = updatedData;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading provider data: $e');
    }
  }

  // Build provider profile image with real data support
  Widget _buildProviderProfileImage() {
    if (_providerData != null && _providerData!['profile_image_path'] != null) {
      final profileImagePath = _providerData!['profile_image_path'] as String;

      // Check if it's a local file or web URL
      if (profileImagePath.startsWith('blob:')) {
        // Web: Use Image.memory with bytes (would need to convert from blob URL)
        return Image.network(
          profileImagePath,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.person_rounded,
                size: 32, color: Colors.blue);
          },
        );
      } else {
        // Mobile: Use Image.file, Web: Use fallback
        if (kIsWeb) {
          // Web: Use placeholder or network image
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28),
            ),
            child:
                const Icon(Icons.person_rounded, size: 32, color: Colors.blue),
          );
        } else {
          // Mobile: Use Image.file
          return Image.file(
            File(profileImagePath),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.person_rounded,
                  size: 32, color: Colors.blue);
            },
          );
        }
      }
    } else {
      // Fallback to hardcoded profile picture
      return Image.network(
        _providerProfile['profilePicture'] ?? '',
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person_rounded, size: 32, color: Colors.blue);
        },
      );
    }
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
              constraints:
                  BoxConstraints(maxWidth: _getMaxContentWidth(context)),
              child: Column(
                children: [
                  // ─── Premium Glass-Morphism Header ───
                  _FeedHeader(
                    status: _status,
                    primary: primary,
                    availableCount: availableCount,
                    onStatusTap: _showStatusSheet,
                    onBack: () => Navigator.of(context).pop(),
                    providerProfile: _providerProfile,
                    providerData: _providerData,
                    buildProviderProfileImage: _buildProviderProfileImage,
                  ),
                  // ─── Scrollable Feed Content ───
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Status and Notification buttons row
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Status button on the left
                                GestureDetector(
                                  onTap: _showStatusSheet,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0a4e4c)
                                              .withValues(alpha: 0.35),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color(0xFF0a4e4c)
                                                .withValues(alpha: 0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // Glowing Status Dot
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _getGlowingStatusColor(
                                                                _status),
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color:
                                                                _getGlowingStatusColor(
                                                                        _status)
                                                                    .withValues(
                                                                        alpha:
                                                                            0.6),
                                                            blurRadius: 6,
                                                            spreadRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'STATUS',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 1.5,
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.7),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 1),
                                                Text(
                                                  _availabilityLabel(_status),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Notification bell on the right
                                const ServiceProviderNotificationBell(
                                  receiverType: 'provider',
                                ),
                              ],
                            ),
                          ),
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
                                    // Safe haptic feedback alternative
                                    try {
                                      // Haptic feedback removed for compatibility
                                    } catch (e) {
                                      // Ignore haptic feedback errors
                                    }
                                    setState(() => _jobAlerts.remove(job));
                                  },
                                  onNegotiate: () => _showNegotiationModal(job),
                                  onAccept: () {
                                    // Safe haptic feedback alternative
                                    try {
                                      // Haptic feedback removed for compatibility
                                    } catch (e) {
                                      // Ignore haptic feedback errors
                                    }

                                    // Move job to My Jobs screen
                                    _moveJobToMyJobs(job);

                                    // Remove from feed
                                    setState(() => _jobAlerts.remove(job));

                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Job ${job['id']} accepted and moved to My Jobs!',
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
          Align(
            alignment: Alignment.bottomCenter,
            child: MuawinBottomNavigationBar(
              currentIndex: _currentNavIndex,
              isProvider: true,
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
                if (index == 3) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ServiceProviderProfileScreen(),
                  ));
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
            bottom: 80), // Add bottom padding to avoid navigation bar
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Muawin Rehnuma',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF088771),
                ),
              ),
            ),
            SizedBox(
              width: 80,
              height: 80,
              child: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const _AIChatBottomSheet(),
                  );
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Image.asset(
                  'imagess/bot.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
    required this.providerProfile,
    required this.providerData,
    required this.buildProviderProfileImage,
  });

  final ProviderAvailability status;
  final Color primary;
  final int availableCount;
  final VoidCallback onStatusTap;
  final VoidCallback onBack;
  final Map<String, dynamic> providerProfile;
  final Map<String, dynamic>? providerData;
  final Widget Function() buildProviderProfileImage;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPad + 20, // Increased from 12 for more prominence
        left: 20, // Increased from 16 for better spacing
        right: 20, // Increased from 16 for better spacing
        bottom: 24, // Increased from 16 for taller header
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
              // Profile squircle with status dot - positioned on the left
              GestureDetector(
                onTap: () {
                  // Safe haptic feedback alternative
                  try {
                    // Haptic feedback removed for compatibility
                  } catch (e) {
                    // Ignore haptic feedback errors
                  }
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ServiceProviderProfileScreen(),
                  ));
                },
                child: Stack(
                  children: [
                    Container(
                      width: 56, // Increased from 48 for larger profile
                      height: 56, // Increased from 48 for larger profile
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16), // Increased from 14
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(14), // Increased from 12
                        child: buildProviderProfileImage(),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16, // Increased from 14
                        height: 16, // Increased from 14
                        decoration: BoxDecoration(
                          color: _availabilityColor(status),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6), // Reduced from 10
              // Provider name + rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      providerProfile['name'] ?? 'Ahmad M.',
                      style: GoogleFonts.poppins(
                        fontSize: 17, // Increased from 15 for larger header
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(
                        height: 4), // Increased from 2 for better spacing
                    Row(
                      children: [
                        ...List.generate(
                            4,
                            (_) => const Icon(
                                  Icons.star_rounded,
                                  size: 16, // Increased from 14
                                  color: Color(0xFFFBBF24),
                                )),
                        const Icon(
                          Icons.star_half_rounded,
                          size: 16, // Increased from 14 to match full stars
                          color: Color(0xFFFBBF24),
                        ),
                        const SizedBox(width: 8), // Increased from 6
                        Text(
                          '124 reviews',
                          style: GoogleFonts.poppins(
                            fontSize: 12, // Increased from 11
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4), // Reduced from 6
              const SizedBox(width: 6), // Reduced from 8
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
          // Direct Request Badge
          if (isHighPriority) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.priority_high,
                  size: 12,
                  color: Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  'DIRECT REQUEST',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
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
              Flexible(
                flex: 1,
                child: GestureDetector(
                  onTap: onDecline,
                  child: Container(
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFb63333),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isHighPriority ? 'Decline' : 'Not Interested',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Negotiate
              Flexible(
                flex: 1,
                child: GestureDetector(
                  onTap: onNegotiate,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Negotiate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // Accept Job
              Flexible(
                flex: 1,
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
                      isHighPriority ? 'Accept' : 'Apply',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                        fontFamily: 'Inter',
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
                        decoration: const BoxDecoration(
                          color: Color(0xFFb63333),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Not Interested',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                            fontFamily: 'Inter',
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
                        decoration: const BoxDecoration(
                          color: Color(0xFFffc55f),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Negotiate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.black87,
                            fontFamily: 'Inter',
                          ),
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
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: Colors.white,
                            fontFamily: 'Inter',
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

  // Get current user profile data
  Future<Map<String, dynamic>> _getCurrentUserProfile() async {
    try {
      // First try to get provider data from ProviderDataService
      final providerData =
          await ProviderDataService.getProviderData('provider_001');

      return {
        'userType': 'provider',
        'userId': 'provider_001',
        'userName': providerData['provider_name'] ?? 'Provider Name Here',
        'userCategory':
            providerData['service_type'] ?? 'Provider Category Here',
        'userRating': 4.8, // Could be added to ProviderDataService later
      };
    } catch (e) {
      debugPrint('Error loading provider data: $e');
      // Fallback to mock data if service fails
      return {
        'userType': 'provider',
        'userId': 'provider_001',
        'userName': 'Ahmed Hassan',
        'userCategory': 'Driver Service',
        'userRating': 4.8,
      };
    }
  }

  // Show GetFeaturedOverlay with real user data
  void _showGetFeaturedOverlay() async {
    if (!mounted) return;

    final userProfile = await _getCurrentUserProfile();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GetFeaturedOverlay(
        userType: userProfile['userType'] ?? 'provider',
        userName: userProfile['userName'] ?? 'Provider Name Here',
        userCategory: userProfile['userCategory'] ?? 'Provider Category Here',
        userRating: (userProfile['userRating'] as num?)?.toDouble() ?? 4.8,
        userId: userProfile['userId'] ?? 'provider_id_here',
      ),
    );
  }

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
                      onPressed: _showGetFeaturedOverlay,
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

class _AIChatBottomSheet extends StatefulWidget {
  const _AIChatBottomSheet();

  @override
  State<_AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends State<_AIChatBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  // Chat voice state variables
  bool _isChatListening = false;
  String _chatLocale = 'en_US';
  double _chatSoundLevel = 0.0;

  // Phase 2: Smart language detection
  String _detectedLanguage = 'unknown';
  double _languageConfidence = 0.0;

  // Phase 2: Error handling
  int _voiceRetryCount = 0;

  // Speech recognition instance
  final SpeechToText _speechToText = SpeechToText();

  void _sendMessage({bool isVoiceMessage = false}) {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _controller.text.trim(),
        'isUser': true,
        'isVoiceMessage': isVoiceMessage,
      });
      _controller.clear();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.add({'text': 'I am here to help!', 'isUser': false});
        });
      }
    });
  }

  // Chat Voice Handler
  Future<void> _handleChatVoice() async {
    // Check permission
    final micPermission = await Permission.microphone.status;

    if (micPermission.isDenied) {
      if (!mounted) return;

      // Show dialog instead of SnackBar for better visibility
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.mic_off, color: Color(0xFF047A62)),
                const SizedBox(width: 12),
                Text(
                  'Microphone Access Needed',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Please enable microphone access to use voice commands in the AI chatbot.',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(context).pop(); // Close dialog first

                  // Request permission
                  final result = await Permission.microphone.request();

                  // Check if permission was granted and retry voice command
                  if (result.isGranted && mounted) {
                    _handleChatVoice(); // Retry after permission granted
                  } else if (result.isPermanentlyDenied && mounted) {
                    // Open app settings if permission is permanently denied
                    await Permission.microphone
                        .request(); // This will open settings for permanently denied
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF047A62),
                ),
                child: Text(
                  'Enable',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    // Initialize speech to text if not already initialized
    bool available = await _speechToText.initialize(
      onError: (error) {
        if (mounted) {
          setState(() => _isChatListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Speech recognition error: ${error.errorMsg}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      onStatus: (status) {
        if (mounted) {
          if (status == 'notListening' || status == 'done') {
            setState(() => _isChatListening = false);
          }
        }
      },
    );

    if (!available) {
      if (mounted) {
        setState(() => _isChatListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Speech recognition not available on this device',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // If already listening stop
    if (_isChatListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isChatListening = false);
      }
      return;
    }

    // Start listening
    if (mounted) {
      setState(() => _isChatListening = true);
    }

    await _speechToText
        .listen(
      onResult: (result) {
        if (!mounted) return;

        // Update chat text field
        String recognizedText = result.recognizedWords;

        // Urdu to English mapping for service provider chatbot
        final urduChatPhrases = {
          'نئی بکنگ': 'New booking',
          'کتنی بکنگ ہیں': 'How many bookings',
          'آج کا شیڈول': 'Today schedule',
          'پیسے کب ملیں گے': 'When will I get paid',
          'پروفائل اپڈیٹ': 'Update profile',
          'ریٹنگ دیکھو': 'Show my rating',
          'کام مکمل': 'Job completed',
          'کام منسوخ': 'Job cancelled',
          'مدد چاہیے': 'I need help',
          'شکایت کرنی ہے': 'I want to complain',
          'فیچرڈ اشتہار': 'Featured ad',
          'نئے گاہک': 'New customers',
        };

        // Check if recognized words contain any Urdu phrase
        urduChatPhrases.forEach((urdu, english) {
          if (recognizedText.contains(urdu)) {
            recognizedText = english;
            _detectedLanguage = 'urdu';
            _languageConfidence = 0.8;
          }
        });

        // Phase 2: Smart language detection based on text patterns
        if (_detectedLanguage == 'unknown') {
          final urduChars =
              recognizedText.replaceAll(RegExp(r'[^\u0600-\u06FF]'), '');
          final englishChars =
              recognizedText.replaceAll(RegExp(r'[^a-zA-Z]'), '');

          if (urduChars.isNotEmpty &&
              (englishChars.isEmpty ||
                  urduChars.length > englishChars.length)) {
            _detectedLanguage = 'urdu';
            _languageConfidence = urduChars.length / recognizedText.length;
          } else if (englishChars.isNotEmpty) {
            _detectedLanguage = 'english';
            _languageConfidence = englishChars.length / recognizedText.length;
          }
        }

        _controller.text = recognizedText;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );

        if (result.finalResult) {
          if (mounted) {
            setState(() {
              _isChatListening = false;
              _voiceRetryCount = 0; // Reset retry count on success
            });
          }

          // Phase 2: Check if voice input is empty and handle error
          if (recognizedText.trim().isEmpty) {
            _showVoiceError('I didn\'t hear anything. Please try again.');
            return;
          }

          // Show manual send options instead of auto-sending
          _showVoiceSendOptions();
        }
      },
      localeId: _chatLocale,
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        onDevice: false,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        autoPunctuation: true,
      ),
      onSoundLevelChange: (level) {
        if (mounted) {
          setState(() => _chatSoundLevel = level);
        }
      },
    )
        .catchError((error) {
      // Phase 2: Enhanced error handling
      if (!mounted) return;

      setState(() {
        _isChatListening = false;
      });

      String errorMessage = 'Voice recognition failed';
      if (error.toString().contains('network')) {
        errorMessage = 'Network error. Check your connection.';
      } else if (error.toString().contains('timeout')) {
        errorMessage = 'Timeout. Please try again.';
      } else if (error.toString().contains('no speech')) {
        errorMessage = 'No speech detected. Please speak clearly.';
      }

      _showVoiceError(errorMessage);
    });
  }

  // Show voice send options after speech recognition
  void _showVoiceSendOptions() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          top: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom +
              20, // Add safe area padding for navigation bar
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.mic_rounded,
                    color: Color(0xFF047A62), size: 24),
                const SizedBox(width: 12),
                Text(
                  'Voice Message Ready',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF047A62),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Message preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF047A62).withValues(alpha: 0.3)),
              ),
              child: Text(
                _controller.text,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                // Retry button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _controller.clear();
                      _handleChatVoice(); // Retry voice input
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh, size: 18),
                        const SizedBox(width: 8),
                        Text('Retry',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Edit button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Focus on text field for editing
                      FocusScope.of(context).requestFocus(FocusNode());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[50],
                      foregroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit, size: 18),
                        const SizedBox(width: 8),
                        Text('Edit',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Send button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendMessage(isVoiceMessage: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047A62),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send, size: 18),
                        const SizedBox(width: 8),
                        Text('Send',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Cancel option
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _controller.clear();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Phase 2: Enhanced voice error handling
  void _showVoiceError(String errorMessage) {
    if (!mounted) return;

    _voiceRetryCount++;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: GoogleFonts.poppins(),
              ),
            ),
            if (_voiceRetryCount < 3)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _handleChatVoice(); // Retry voice input
                },
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: _voiceRetryCount >= 3 ? 'Type Instead' : 'Cancel',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            if (_voiceRetryCount >= 3) {
              // Focus on text field for manual typing
              FocusScope.of(context).requestFocus(FocusNode());
            }
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _speechToText.initialize().then((_) {
      setState(() {});
    });
  }

  // Show full-screen voice overlay
  void _showFullScreenVoiceOverlay() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF047A62).withValues(alpha: 0.9),
                  const Color(0xFF047A62).withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Column(
              children: [
                // Header with close button
                Padding(
                  padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Voice Input Mode',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Voice visualization
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Large mic icon with animation
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.mic_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Sound waves visualization
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(7, (index) {
                            return AnimatedContainer(
                              duration:
                                  Duration(milliseconds: 300 + (index * 50)),
                              width: 4,
                              height: 20 + (_chatSoundLevel * 40),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 30),

                        // Status text
                        Text(
                          'Listening...',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Language indicator
                        Text(
                          _chatLocale == 'en_US' ? 'English' : 'اردو',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Language toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _chatLocale =
                                _chatLocale == 'en_US' ? 'ur_PK' : 'en_US';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            _chatLocale == 'en_US' ? '🇺🇸 EN' : '🇵🇰 اردو',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // Stop button
                      GestureDetector(
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _speechToText.stop();
                          if (mounted) {
                            setState(() => _isChatListening = false);
                          }
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.stop,
                            color: Colors.white,
                            size: 30,
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
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Ensure bottom sheet shifts up when keyboard appears
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF047A62), // Splash screen color at top
              Color(0xFF047A62), // Splash screen color
              Colors.white, // White below header
              Colors.white,
            ],
            stops: [0.0, 0.15, 0.15, 1.0],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20.0,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              color: const Color(0xFF047A62), // Splash screen background color
              child: Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white, // White handle
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF047A62), // Same as splash screen
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.computer_outlined, // More IT-related icon
                        color: Colors.white,
                        size: 24, // Match text size
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Muawin Rehnuma',
                        style: GoogleFonts.poppins(
                          fontSize: 24, // Increased from 20 to 24
                          fontWeight: FontWeight.bold,
                          color: Colors.white, // White text
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['isUser'] as bool;
                  final isVoiceMessage =
                      msg['isVoiceMessage'] as bool? ?? false;
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xFF088771)
                            : Colors.grey[200]!,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isUser
                              ? const Color(0xFF088771)
                              : Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Text(
                            msg['text'] as String,
                            style: GoogleFonts.poppins(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          if (isUser && isVoiceMessage)
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Icon(
                                Icons.mic,
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Voice indicator (shows when listening)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isChatListening ? 120 : 0,
              child: _isChatListening
                  ? ChatVoiceIndicator(
                      soundLevel: _chatSoundLevel,
                      locale: _chatLocale,
                      onLanguageChange: (locale) {
                        setState(() => _chatLocale = locale);
                      },
                      onStop: () async {
                        await _speechToText.stop();
                        setState(() => _isChatListening = false);
                      },
                      onFullScreen: () {
                        // Show full-screen voice overlay
                        _showFullScreenVoiceOverlay();
                      },
                      detectedLanguage: _detectedLanguage,
                      languageConfidence: _languageConfidence,
                    )
                  : const SizedBox.shrink(),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type or tap 🎤 to speak...',
                          hintStyle: GoogleFonts.poppins(color: Colors.grey),
                          prefixIcon: _controller.text.isEmpty
                              ? Icon(Icons.mic_none_rounded,
                                  color: Colors.grey[400], size: 18)
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: Color(0xFF088771)),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChatMicButton(
                      isListening: _isChatListening,
                      onTap: _handleChatVoice,
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xFF088771),
                      radius: 24,
                      child: IconButton(
                        icon: const Icon(Icons.send,
                            color: Colors.white, size: 20),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
