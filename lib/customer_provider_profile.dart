import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'customer_home_screen.dart';
import 'customer_jobs_screen.dart';
import 'post_job_step1_screen.dart';
import 'customer_messages_screen.dart';
import 'customer_profile_screen.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/semantic_analysis_card.dart';
import 'chat_screen.dart';
import 'direct_request.dart';
import 'services/pro_status_checker.dart';
import 'services/database_service.dart';

class CustomerProviderProfileScreen extends StatefulWidget {
  const CustomerProviderProfileScreen({super.key, required this.providerId});

  final String providerId;

  @override
  State<CustomerProviderProfileScreen> createState() =>
      _CustomerProviderProfileScreenState();
}

class _CustomerProviderProfileScreenState
    extends State<CustomerProviderProfileScreen> {
  // Track if job request has been accepted
  bool _isRequestAccepted = false;

  // Track selected package tab for pricing
  String _selectedPackageTab = 'Basic';

  // Provider data from database
  Map<String, dynamic>? _provider;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;

  // Provider data loaded from service
  Map<String, dynamic>? _providerData;

  // Pricing packages from Supabase
  List<Map<String, dynamic>> _packages = [];

  // PRO status
  bool _isProUser = false;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
    _checkProStatus();
  }

  // Load provider data from database
  Future<void> _loadProviderData() async {
    try {
      final results = await Future.wait([
        DatabaseService().getProviderById(widget.providerId),
        DatabaseService().getProviderReviews(widget.providerId),
        DatabaseService().getProviderPricingPackages(widget.providerId),
      ]);

      if (mounted) {
        setState(() {
          _provider = results[0] as Map<String, dynamic>?;
          _reviews = results[1] as List<Map<String, dynamic>>;
          _packages = results[2] as List<Map<String, dynamic>>;
          _isLoading = false;
          // Check if request is already accepted from provider data
          _isRequestAccepted =
              (results[0] as Map<String, dynamic>?)?['isRequestAccepted'] ??
                  false;
        });
      }
    } catch (e) {
      debugPrint('Error loading provider data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _provider = null;
          _reviews = [];
          _packages = [];
        });
      }
    }
  }

  // Check if user is a PRO user
  Future<void> _checkProStatus() async {
    final isPro = await ProStatusChecker.isProUser();
    if (mounted) {
      setState(() {
        _isProUser = isPro;
      });
    }
  }

  // Format date for reviews
  String _formatDate(String? dateString) {
    if (dateString == null) return 'RECENTLY';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'TODAY';
      } else if (difference.inDays == 1) {
        return 'YESTERDAY';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} DAYS AGO';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return weeks == 1 ? '1 WEEK AGO' : '$weeks WEEKS AGO';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return months == 1 ? '1 MONTH AGO' : '$months MONTHS AGO';
      } else {
        final years = (difference.inDays / 365).floor();
        return years == 1 ? '1 YEAR AGO' : '$years YEARS AGO';
      }
    } catch (e) {
      return 'RECENTLY';
    }
  }

  // Method to navigate to job request screen
  Future<void> _sendDirectRequest() async {
    try {
      // Check if user can send direct request based on PRO status and provider rating
      final providerRating = (_provider?['rating'] as num?)?.toDouble() ?? 0.0;

      // Basic users cannot send requests to providers with 4.8+ rating
      if (!_isProUser && providerRating >= 4.8) {
        _showProUpgradeDialog();
        return;
      }

      // Navigate to Direct Request screen with provider data
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DirectRequestScreen(
            providerData: _provider ?? {},
          ),
        ),
      );

      debugPrint(
          'Navigating to Direct Request for provider ${_provider?['profiles']?['full_name']}');
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Show PRO upgrade dialog for restricted providers
  void _showProUpgradeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFFFD700)),
              const SizedBox(width: 8),
              Text(
                'Upgrade to Muawin PRO',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This provider requires a Muawin PRO account to send direct job requests.',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                'PRO Benefits:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...[
                '• Send requests to top-rated providers (4.8+)',
                '• Unlimited job requests per day',
                '• Access to Top Rated Professionals',
                '• Custom job options and extended durations',
              ].map((benefit) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(
                      benefit,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Maybe Later',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to subscription purchase screen
                Navigator.of(context).pushNamed('/subscription_purchase');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047A62),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Upgrade Now',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Method to toggle request status for testing
  void _toggleRequestStatus() {
    setState(() {
      _isRequestAccepted = !_isRequestAccepted;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading shimmer while loading provider data
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        body: _buildLoadingShimmer(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // Mint-tinted off-white
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Header Section
            Stack(
              children: [
                // Media Container
                SizedBox(
                  width: double.infinity,
                  height: 288, // 18rem (h-72)
                  child: Stack(
                    children: [
                      // Hero Image - Dynamic profile image
                      _buildProviderImage(),
                      // Gradient Overlay
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0xB3000000), // from-black/70
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Back Navigation
                Positioned(
                  top: 48, // top-12
                  left: 24, // left-6
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 40, // 2.5rem
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24, // w-6 h-6
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Main Content
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24), // px-6
              transform: Matrix4.translationValues(0, -64, 0), // -mt-16
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20), // Reduced from 32
                  // Primary Identity Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24), // 1.5rem
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header Grid
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Photo
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF047A62),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: _buildProfilePhoto(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Identity Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Name with Verification
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _provider?['profiles']?['full_name']
                                                  as String? ??
                                              'Provider',
                                          style: GoogleFonts.poppins(
                                            fontSize: 24, // 1.5rem
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.verified,
                                        color:
                                            Color(0xFF047A62), // Primary Teal
                                        size: 20, // 1.25rem
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  // Category
                                  Text(
                                    _provider?['service_category'] as String? ??
                                        'Service',
                                    style: GoogleFonts.inter(
                                      fontSize: 14, // 0.875rem
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      letterSpacing: 1.0, // widest tracking
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Achievement Badges
                                  Row(
                                    children: [
                                      // Top Rated Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                              0xFFFFF7ED), // Yellow-100
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.emoji_events,
                                              color: Color(
                                                  0xFFA16207), // Yellow-700
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Top Rated',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: const Color(0xFFA16207),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Expert Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                              0xFFEFF6FF), // Blue-100
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.workspace_premium,
                                              color:
                                                  Color(0xFF1E40AF), // Blue-700
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Expert',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: const Color(0xFF1E40AF),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Customer Favorite Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2), // Reduced from 8 to 6
                                        decoration: BoxDecoration(
                                          color: const Color(
                                              0xFFF0FDF4), // Green-100
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.thumb_up,
                                              color: Color(
                                                  0xFF166534), // Green-700
                                              size: 10, // Reduced from 12
                                            ),
                                            const SizedBox(
                                                width: 3), // Reduced from 4
                                            Text(
                                              'Favorite', // Shortened from 'Customer Favorite'
                                              style: GoogleFonts.poppins(
                                                fontSize: 9, // Reduced from 10
                                                color: const Color(0xFF166534),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Action Architecture
                        SizedBox(
                          width: double.infinity,
                          height: 56, // 3.5rem
                          child: ElevatedButton(
                            onPressed: _sendDirectRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF047A62), // Primary Teal
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16), // 1rem
                              ),
                            ),
                            child: Text(
                              'Send Job Request',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16), // Reduced from 20
                        if (!_isRequestAccepted)
                          // Show status banner when request not accepted
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey
                                  .withValues(alpha: 0.3), // bg-muted/30
                              borderRadius:
                                  BorderRadius.circular(12), // rounded-xl
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Job request not yet accepted',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to simulate acceptance (testing)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Test button to toggle request status
                                GestureDetector(
                                  onTap: _toggleRequestStatus,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF047A62),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Toggle Chat/Call Buttons',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // Show chat and call buttons when request is accepted
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          chatData: {
                                            'name': _provider?['profiles']
                                                        ?['full_name']
                                                    ?.toString() ??
                                                'Provider',
                                            'isOnline': true,
                                            'avatar': _provider?['profiles']
                                                        ?['profile_image_url']
                                                    ?.toString() ??
                                                '',
                                            'type': 'provider',
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.chat,
                                      color: Colors.white),
                                  label: Text(
                                    'Chat',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF047A62),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Launch phone call
                                    final phone =
                                        _provider?['phone']?.toString() ?? '';
                                    if (phone.isNotEmpty) {
                                      launchUrl(Uri.parse('tel:$phone'));
                                    }
                                  },
                                  icon: const Icon(Icons.phone,
                                      color: Color(0xFF047A62)),
                                  label: Text(
                                    'Call',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF047A62),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFF047A62)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // Experience Grid
                        Row(
                          children: [
                            // Experience
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4), // Teal box
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF047A62), // Primary Teal
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Experience',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          _provider?['experience']
                                                  ?.toString() ??
                                              '3 Years',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Location
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4), // Teal box
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Color(0xFF047A62), // Primary Teal
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Location',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            _provider?['city']?.toString() ??
                                                'City',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
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
                  ),
                  const SizedBox(height: 16), // Reduced from 24

                  // Ratings Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _provider?['rating']?.toString() ?? '0.0',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_provider?['review_count'] as int? ?? _reviews.length} Reviews',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Semantic Analysis AI Card - PRO Only
                  if (_isProUser)
                    SemanticAnalysisCard(
                      providerName:
                          _provider?['profiles']?['full_name'] as String? ??
                              'Provider',
                      overallRating:
                          (_provider?['rating'] as num?)?.toDouble() ?? 0.0,
                      totalReviews: _provider?['review_count'] as int? ?? 0,
                      totalJobs: _provider?['job_count'] as int? ?? 0,
                      category: _provider?['service_category'] as String? ??
                          'Service',
                      recentReviews: const [
                        'Very professional and punctual',
                        'Excellent service highly recommend',
                        'Clean and well maintained vehicle',
                      ],
                      isVendor: false,
                    ),
                  const SizedBox(height: 16),

                  // Fiverr-style Pricing Packages
                  _buildPricingPackagesCard(),
                  const SizedBox(height: 16), // Reduced from 24

                  // About Me Section
                  Text(
                    'About Me',
                    style: GoogleFonts.poppins(
                      fontSize: 18, // 1.125rem
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _provider?['description']?.toString() ??
                        'Professional service provider with experience. '
                            'Passionate about delivering exceptional service and ensuring customer satisfaction. '
                            'Available for both residential and commercial services with flexible scheduling. '
                            'Trustworthy, reliable, and committed to excellence in every job.',
                    style: GoogleFonts.inter(
                      fontSize: 14, // 0.875rem
                      color: Colors.grey[600], // muted-foreground
                      height: 1.6, // leading-relaxed
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service Areas Section
                  _buildServiceAreas(),

                  const SizedBox(height: 16),

                  // Availability Section
                  _buildAvailability(),

                  const SizedBox(height: 24),

                  // Reviews Section
                  Text(
                    'Customer Reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 18, // 1.125rem
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Customer reviews from database
                  ..._reviews.map((review) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildReviewCard(
                          username:
                              review['profiles']?['full_name']?.toString() ??
                                  'Customer',
                          rating: review['rating'] as int? ?? 5,
                          date: _formatDate(review['created_at'] as String?),
                          review: review['review_text']?.toString() ??
                              'Great service!',
                        ),
                      )),

                  // Show empty state if no reviews
                  if (_reviews.isEmpty)
                    Column(
                      children: [
                        Icon(
                          Icons.reviews_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No reviews yet',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to review this provider',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),

                  // Bottom Padding to clear navigation bar
                  const SizedBox(height: 96), // Reduced from 128 to 96
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MuawinBottomNavigationBar(
        currentIndex: 0, // Home tab selected
        onItemTapped: (i) {
          if (i == 0) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
            );
          } else if (i == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerJobsScreen()),
            );
          } else if (i == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PostJobStep1Screen()),
            );
          } else if (i == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerMessagesScreen()),
            );
          } else if (i == 4) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerProfileScreen()),
            );
          }
        },
      ),
    );
  }

  // Fiverr-style Pricing Packages Card
  Widget _buildPricingPackagesCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Pricing & Packages',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPackageTab = 'Basic'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedPackageTab == 'Basic'
                            ? const Color(0xFF047A62)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Basic',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedPackageTab == 'Basic'
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPackageTab = 'Standard'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedPackageTab == 'Standard'
                            ? const Color(0xFF047A62)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Standard',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedPackageTab == 'Standard'
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPackageTab = 'Premium'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedPackageTab == 'Premium'
                            ? const Color(0xFF047A62)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Premium',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedPackageTab == 'Premium'
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Package Content with Animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_selectedPackageTab),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF047A62).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF047A62).withValues(alpha: 0.1),
                ),
              ),
              child: _buildPackageContent(),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Build package content based on selected tab
  Widget _buildPackageContent() {
    // Handle case when provider has not set packages yet
    if (_packages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'This provider has not set their packages yet',
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Get each package type
    final basicPkg =
        _packages.where((p) => p['package_type'] == 'basic').firstOrNull;

    final standardPkg =
        _packages.where((p) => p['package_type'] == 'standard').firstOrNull;

    final premiumPkg =
        _packages.where((p) => p['package_type'] == 'premium').firstOrNull;

    // Get current package based on selected tab
    Map<String, dynamic>? currentPackage;
    switch (_selectedPackageTab.toLowerCase()) {
      case 'basic':
        currentPackage = basicPkg;
        break;
      case 'standard':
        currentPackage = standardPkg;
        break;
      case 'premium':
        currentPackage = premiumPkg;
        break;
    }

    if (currentPackage == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No $_selectedPackageTab package available',
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Package Name and Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentPackage['package_name'] ?? _selectedPackageTab,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF047A62),
              ),
            ),
            const SizedBox(height: 16),

            // Description Items
            ...getIncludes(currentPackage).map<Widget>((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2, right: 12),
                        child: const Icon(
                          Icons.check_circle,
                          color: Color(0xFF047A62),
                          size: 16,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 16),

            // Duration
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF047A62).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFF047A62),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentPackage['duration'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF047A62),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Price (moved below duration)
            Text(
              'Rs. ${currentPackage['price'] ?? 0}',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper function to parse includes field
  List<String> getIncludes(Map<String, dynamic>? pkg) {
    if (pkg == null) return [];
    final includes = pkg['includes'];
    if (includes == null) return [];
    if (includes is List) {
      return List<String>.from(includes);
    }
    if (includes is String) {
      try {
        return List<String>.from(jsonDecode(includes));
      } catch (e) {
        return [includes];
      }
    }
    return [];
  }

  Widget _buildReviewCard({
    required String username,
    required int rating,
    required String date,
    required String review,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // 1rem
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metadata
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                username,
                style: GoogleFonts.poppins(
                  fontSize: 14, // text-sm
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                date,
                style: GoogleFonts.poppins(
                  fontSize: 10, // text-[10px]
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Star Rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: const Color(0xFFEAB308), // Yellow-500
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 8),
          // Review Content
          Text(
            review,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Build Service Areas Section
  Widget _buildServiceAreas() {
    final areas = _providerData?['service_areas'] as List<String>? ?? [];
    if (areas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Areas',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No service areas specified',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Areas',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: areas
                .map((area) => Chip(
                      label: Text(
                        area,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      backgroundColor:
                          const Color(0xFF047A62).withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Build Availability Section
  Widget _buildAvailability() {
    final availability = _providerData?['availability'] ?? 'Not specified';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Availability',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  availability,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build loading shimmer for provider profile
  Widget _buildLoadingShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header shimmer
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
            ),
          ),
          // Profile info shimmer
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Name shimmer
                Container(
                  width: double.infinity,
                  height: 24,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                // Category shimmer
                Container(
                  width: 100,
                  height: 16,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(bottom: 16),
                ),
                // Stats shimmer
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 60,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.only(right: 8),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 60,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.only(left: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // About section shimmer
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 18,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(bottom: 12),
                ),
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(bottom: 4),
                ),
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build profile photo for circular container
  Widget _buildProfilePhoto() {
    final profileImagePath =
        _provider?['profiles']?['profile_image_path'] as String?;
    final profilePhotoUrl =
        _provider?['profiles']?['profile_photo_url'] as String?;
    final avatar = _provider?['profiles']?['profile_image_url'] as String?;

    const isWeb = kIsWeb;

    // Try to load profile photo with better error handling
    if (profilePhotoUrl != null &&
        profilePhotoUrl.isNotEmpty &&
        !profilePhotoUrl.contains('placeholder.com')) {
      return Image.network(
        profilePhotoUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildDefaultProfilePhoto();
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Profile image load error: $error');
          return _buildDefaultProfilePhoto();
        },
      );
    } else if (profileImagePath != null && !isWeb) {
      try {
        if (File(profileImagePath).existsSync()) {
          return Image.file(
            File(profileImagePath),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Profile file load error: $error');
              return _buildDefaultProfilePhoto();
            },
          );
        }
      } catch (e) {
        debugPrint('Profile file access error: $e');
        return _buildDefaultProfilePhoto();
      }
    }

    if (avatar != null &&
        avatar.isNotEmpty &&
        !avatar.contains('placeholder.com')) {
      return Image.network(
        avatar,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildDefaultProfilePhoto();
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Avatar image load error: $error');
          return _buildDefaultProfilePhoto();
        },
      );
    }

    return _buildDefaultProfilePhoto();
  }

  Widget _buildDefaultProfilePhoto() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF047A62).withValues(alpha: 0.8),
            const Color(0xFF047A62).withValues(alpha: 0.6),
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        size: 32,
        color: Colors.white,
      ),
    );
  }

  // Build provider image with cover photo support
  Widget _buildProviderImage() {
    final coverPhotoPath = _providerData?['cover_photo_path'] as String?;
    final profileImagePath = _providerData?['profile_image_path'] as String?;

    // Check if we're on web platform
    const isWeb = kIsWeb;

    // Try to load cover photo first, then fall back to profile photo
    final imagePath = coverPhotoPath ?? profileImagePath;

    // On web, we can't use File.existsSync(), so we'll handle it differently
    if (imagePath != null) {
      if (isWeb) {
        // On web, try to use the path as a URL or show default
        if (imagePath.startsWith('http') ||
            imagePath.startsWith('blob:') ||
            imagePath.startsWith('data:')) {
          return Image.network(
            imagePath,
            width: double.infinity,
            height: 250,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultProviderImage();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: double.infinity,
                height: 250,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          );
        }
      } else {
        // On mobile/desktop, check if file exists
        try {
          if (File(imagePath).existsSync()) {
            return Image.file(
              File(imagePath),
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultProviderImage();
              },
            );
          }
        } catch (e) {
          // Handle any file system errors gracefully
          debugPrint('Error checking file existence: $e');
        }
      }
    }

    // Fallback to default image
    return _buildDefaultProviderImage();
  }

  // Build default provider image
  Widget _buildDefaultProviderImage() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              size: 80,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 16),
            Text(
              _providerData?['provider_name'] ??
                  _providerData?['name'] ??
                  'Service Provider',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _providerData?['service_type'] ?? 'Professional Service',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Job Request Screen
class JobRequestScreen extends StatelessWidget {
  const JobRequestScreen({
    super.key,
    required this.providerData,
    this.isDirectRequest = false,
  });

  final Map<String, dynamic> providerData;
  final bool isDirectRequest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isDirectRequest ? 'Send Job Request' : 'Job Request'),
        backgroundColor: const Color(0xFF047A62),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Job request functionality will be implemented here.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              'Provider: ${providerData['name'] ?? 'Provider'}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job request submitted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}
