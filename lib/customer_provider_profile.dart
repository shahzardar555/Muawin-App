import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'dart:ui';

import 'package:google_fonts/google_fonts.dart';

import 'package:url_launcher/url_launcher.dart';

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

import 'services/provider_data_service.dart';

import 'services/pro_status_checker.dart';

class CustomerProviderProfileScreen extends StatefulWidget {
  const CustomerProviderProfileScreen({super.key, required this.provider});

  final Map<String, dynamic> provider;

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

  // Provider data loaded from service
  Map<String, dynamic>? _providerData;

  // PRO status
  bool _isProUser = false;

  @override
  void initState() {
    super.initState();
    // Check if request is already accepted from provider data
    _isRequestAccepted = widget.provider['requestAccepted'] == true;
    // Load real provider data
    _loadProviderData();
    // Check PRO status
    _checkProStatus();
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

  // Load real provider data instead of using mock data
  Future<void> _loadProviderData() async {
    try {
      final data = await ProviderDataService.getProviderData(
          widget.provider['id'] ?? 'provider_001');
      if (mounted) {
        setState(() {
          _providerData = data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _providerData = null;
        });
      }
    }
  }

  // Method to navigate to job request screen
  Future<void> _sendDirectRequest() async {
    try {
      // Check if user can send direct request based on PRO status and provider rating
      final providerRating =
          (widget.provider['rating'] as num?)?.toDouble() ?? 0.0;

      // Basic users cannot send requests to providers with 4.8+ rating
      if (!_isProUser && providerRating >= 4.8) {
        _showProUpgradeDialog();
        return;
      }

      // Navigate to Direct Request screen with provider data
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DirectRequestScreen(
            providerData: widget.provider,
          ),
        ),
      );

      debugPrint(
          'Navigating to Direct Request for provider ${widget.provider['name']}');
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
                                          widget.provider['name'] as String? ??
                                              'Ahmed Hassan',
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
                                    widget.provider['category'] as String? ??
                                        'DRIVER',
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
                                            'name': widget.provider['name']
                                                    ?.toString() ??
                                                'Provider',
                                            'isOnline': true,
                                            'avatar': widget.provider['avatar']
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
                                        widget.provider['phone']?.toString() ??
                                            '';
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
                                          _providerData?['experience'] ??
                                              widget.provider['experience']
                                                  as String? ??
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
                                            widget.provider['distance']
                                                    as String? ??
                                                'Gulberg III, Lahore',
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
                          (widget.provider['rating'] as num?)
                                  ?.toStringAsFixed(1) ??
                              '4.9',
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
                          '124 Reviews',
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
                          widget.provider['name'] as String? ?? 'Ahmed Khan',
                      overallRating:
                          (widget.provider['rating'] as num?)?.toDouble() ??
                              4.8,
                      totalReviews:
                          widget.provider['totalReviews'] as int? ?? 47,
                      totalJobs: widget.provider['totalJobs'] as int? ?? 52,
                      category:
                          widget.provider['category'] as String? ?? 'Driver',
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
                    _providerData?['description'] ??
                        widget.provider['about'] as String? ??
                        'Professional ${widget.provider['category'] as String? ?? 'service provider'} with ${_providerData?['experience'] ?? widget.provider['experience'] as String? ?? '3+ years'} of experience. '
                            'Passionate about delivering exceptional service and ensuring customer satisfaction. '
                            'Available for both residential and commercial ${widget.provider['category'] as String? ?? 'services'} with flexible scheduling. '
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

                  // Sample customer reviews after job completion
                  _buildReviewCard(
                    username: 'Ahmed R.',
                    rating: 5,
                    date: '2 DAYS AGO',
                    review:
                        'Excellent service! Very professional and completed the job on time. Highly recommended!',
                  ),
                  const SizedBox(height: 12),
                  _buildReviewCard(
                    username: 'Fatima K.',
                    rating: 5,
                    date: '1 WEEK AGO',
                    review:
                        'Great communication throughout the project. Delivered exactly what was promised.',
                  ),
                  const SizedBox(height: 12),
                  _buildReviewCard(
                    username: 'Muhammad A.',
                    rating: 4,
                    date: '2 WEEKS AGO',
                    review:
                        'Good work overall. Minor delays but satisfactory result.',
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
    final packageData = _getPackageData(_selectedPackageTab);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Package Name and Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedPackageTab,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF047A62),
              ),
            ),
            const SizedBox(height: 16),

            // Description Items
            ...packageData['description']
                .map<Widget>((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2, right: 12),
                            child: const Icon(
                              Icons.check_circle,
                              color: Color(0xFF047A62),
                              size: 18,
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
                    ))
                .toList(),

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
                    packageData['duration'],
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
              packageData['price'],
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

  // Get package data based on provider category and selected tab
  Map<String, dynamic> _getPackageData(String packageType) {
    final category = widget.provider['category'] as String? ?? 'DRIVER';

    // Default package data structure - can be enhanced based on actual provider data
    switch (category) {
      case 'MAID':
        return _getMaidPackageData(packageType);
      case 'DRIVER':
        return _getDriverPackageData(packageType);
      case 'GARDENER':
        return _getGardenerPackageData(packageType);
      case 'COOK':
        return _getCookPackageData(packageType);
      case 'DOMESTIC HELPER':
        return _getDomesticHelperPackageData(packageType);
      case 'SECURITY GUARD':
        return _getSecurityGuardPackageData(packageType);
      case 'BABYSITTER':
        return _getBabysitterPackageData(packageType);
      case 'WASHERMAN':
        return _getWashermanPackageData(packageType);
      case 'TUTOR':
        return _getTutorPackageData(packageType);
      default:
        return _getDefaultPackageData(packageType);
    }
  }

  // Package data methods for different categories
  Map<String, dynamic> _getMaidPackageData(String packageType) {
    switch (packageType) {
      case 'Basic':
        return {
          'price': 'Rs. 800',
          'description': [
            'Sweep, mop, and dust all rooms',
            'Clean kitchen surfaces',
            'Basic bathroom cleaning'
          ],
          'duration': '2-3 hours'
        };
      case 'Standard':
        return {
          'price': 'Rs. 1,200',
          'description': [
            'Basic cleaning + deep kitchen cleaning',
            'Bathroom sanitization',
            'Window cleaning'
          ],
          'duration': '4-5 hours'
        };
      case 'Premium':
        return {
          'price': 'Rs. 2,000',
          'description': [
            'Complete deep cleaning',
            'Cupboard organization',
            'Post-construction cleanup'
          ],
          'duration': '6-8 hours'
        };
      default:
        return _getDefaultPackageData(packageType);
    }
  }

  Map<String, dynamic> _getDriverPackageData(String packageType) {
    switch (packageType) {
      case 'Basic':
        return {
          'price': 'Rs. 400',
          'description': [
            '1-2 hours of driving service',
            'Local trips within city',
            'Vehicle provided by family'
          ],
          'duration': '1-2 hours'
        };
      case 'Standard':
        return {
          'price': 'Rs. 1,000',
          'description': [
            'Half day driving service',
            'Multiple destinations',
            'Flexible scheduling'
          ],
          'duration': '4-6 hours'
        };
      case 'Premium':
        return {
          'price': 'Rs. 2,500',
          'description': [
            'Full day dedicated service',
            'Out-of-city trips available',
            'Priority booking'
          ],
          'duration': '8-12 hours'
        };
      default:
        return _getDefaultPackageData(packageType);
    }
  }

  Map<String, dynamic> _getGardenerPackageData(String packageType) {
    switch (packageType) {
      case 'Basic':
        return {
          'price': 'Rs. 600',
          'description': [
            'Lawn mowing and edging',
            'Basic weed control',
            'Plant watering'
          ],
          'duration': '2-3 hours'
        };
      case 'Standard':
        return {
          'price': 'Rs. 1,000',
          'description': [
            'Complete lawn care',
            'Hedge trimming and pruning',
            'Seasonal planting'
          ],
          'duration': '4-5 hours'
        };
      case 'Premium':
        return {
          'price': 'Rs. 3,000',
          'description': [
            'Full garden makeover',
            'Landscape design consultation',
            'Fertilization program'
          ],
          'duration': 'Full day'
        };
      default:
        return _getDefaultPackageData(packageType);
    }
  }

  Map<String, dynamic> _getCookPackageData(String packageType) {
    switch (packageType) {
      case 'Basic':
        return {
          'price': 'Rs. 600',
          'description': [
            'Single meal preparation',
            'Kitchen cleanup included',
            'Ingredients shopping'
          ],
          'duration': '2-3 hours'
        };
      case 'Standard':
        return {
          'price': 'Rs. 2,500',
          'description': [
            'Full day meal prep',
            'Multiple cuisines',
            'Special dietary requirements'
          ],
          'duration': '6-8 hours'
        };
      case 'Premium':
        return {
          'price': 'Rs. 7,000',
          'description': [
            'Event catering service',
            'Custom menu planning',
            'Wait staff coordination'
          ],
          'duration': 'Full event'
        };
      default:
        return _getDefaultPackageData(packageType);
    }
  }

  Map<String, dynamic> _getDomesticHelperPackageData(String packageType) {
    switch (packageType) {
      case 'Basic':
        return {
          'price': 'Rs. 1,300',
          'description': [
            'General household assistance',
            'Basic cleaning tasks',
            'Grocery shopping'
          ],
          'duration': '3-4 hours'
        };
      case 'Standard':
        return {
          'price': 'Rs. 2,000',
          'description': [
            'Complete home management',
            'Child care assistance',
            'Elder care support'
          ],
          'duration': '6-8 hours'
        };
      case 'Premium':
        return {
          'price': 'Rs. 3,500',
          'description': [
            '24/7 availability',
            'Event management',
            'Moving assistance'
          ],
          'duration': 'As needed'
        };
      default:
        return _getDefaultPackageData(packageType);
    }
  }

  Map<String, dynamic> _getSecurityGuardPackageData(String packageType) {
    switch (packageType) {
      case 'Basic':
        return {
          'price': 'Rs. 3,000',
          'description': [
            'Day shift security',
            'Access control',
            'Regular patrols'
          ],
          'duration': '8-10 hours'
        };
      case 'Standard':
        return {
          'price': 'Rs. 4,000',
          'description': [
            'Night shift surveillance',
            'Emergency response',
            'Security reporting'
          ],
          'duration': '8-10 hours'
        };
      case 'Premium':
        return {
          'price': 'Rs. 10,000',
          'description': [
            '24/7 protection',
            'Advanced security systems',
            'Risk assessment'
          ],
          'duration': '24 hours'
        };
      default:
        return _getDefaultPackageData(packageType);
    }
  }

  Map<String, dynamic> _getBabysitterPackageData(String packageType) {
    switch (packageType) {
      case 'Basic':
        return {
          'price': 'Rs. 1,200',
          'description': [
            'Regular childcare',
            'Age-appropriate activities',
            'Light meal prep'
          ],
          'duration': '2-4 hours'
        };
      case 'Standard':
        return {
          'price': 'Rs. 2,000',
          'description': [
            'Extended childcare',
            'Educational activities',
            'Homework assistance'
          ],
          'duration': '6-8 hours'
        };
      case 'Premium':
        return {
          'price': 'Rs. 3,500',
          'description': [
            'Full day care',
            'Overnight options',
            'Special needs experience'
          ],
          'duration': 'Full day'
        };
      default:
        return _getDefaultPackageData(packageType);
    }
  }

  Map<String, dynamic> _getWashermanPackageData(String packageType) {
    switch (packageType) {
      case 'Basic':
        return {
          'price': 'Rs. 700',
          'description': [
            '10-20 items bundle wash',
            'Regular washing and drying',
            'Folding service'
          ],
          'duration': 'Same day'
        };
      case 'Standard':
        return {
          'price': 'Rs. 1,500',
          'description': [
            '20-40 items bundle wash',
            'Stain treatment',
            'Ironing included'
          ],
          'duration': '1-2 days'
        };
      case 'Premium':
        return {
          'price': 'Rs. 3,000',
          'description': [
            '50+ items bulk wash',
            'Premium fabric care',
            'Express delivery'
          ],
          'duration': 'Same day express'
        };
      default:
        return _getDefaultPackageData(packageType);
    }
  }

  Map<String, dynamic> _getTutorPackageData(String packageType) {
    switch (packageType) {
      case 'Basic':
        return {
          'price': 'Rs. 1,500',
          'description': [
            'Nursery to Intermediate level',
            '1 hour personalized session',
            'Study materials provided'
          ],
          'duration': '1 hour'
        };
      case 'Standard':
        return {
          'price': 'Rs. 4,000',
          'description': [
            'O/A levels preparation',
            'Advanced teaching methods',
            'Progress tracking'
          ],
          'duration': '1 hour'
        };
      case 'Premium':
        return {
          'price': 'Rs. 8,500',
          'description': [
            'University level tutoring',
            'Specialized subjects',
            'Exam preparation'
          ],
          'duration': '1 hour'
        };
      default:
        return _getDefaultPackageData(packageType);
    }
  }

  Map<String, dynamic> _getDefaultPackageData(String packageType) {
    switch (packageType) {
      case 'Basic':
        return {
          'price': 'Rs. 800',
          'description': [
            'Basic service features',
            'Standard support',
            'Regular availability'
          ],
          'duration': '2-3 hours'
        };
      case 'Standard':
        return {
          'price': 'Rs. 1,500',
          'description': [
            'Enhanced service features',
            'Priority support',
            'Flexible scheduling'
          ],
          'duration': '4-5 hours'
        };
      case 'Premium':
        return {
          'price': 'Rs. 3,000',
          'description': [
            'Premium service features',
            'Dedicated support',
            'Customized solutions'
          ],
          'duration': 'Full day'
        };
      default:
        return {
          'price': 'Rs. 800',
          'description': [
            'Service features',
            'Customer support',
            'Quality assurance'
          ],
          'duration': '2-3 hours'
        };
    }
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

  // Build profile photo for circular container
  Widget _buildProfilePhoto() {
    final profileImagePath = _providerData?['profile_image_path'] as String?;
    final profilePhotoUrl = _providerData?['profile_photo_url'] as String?;
    final avatar = widget.provider['avatar'] as String?;

    const isWeb = kIsWeb;

    // Try to load profile photo
    if (profileImagePath != null && !isWeb) {
      try {
        if (File(profileImagePath).existsSync()) {
          return Image.file(
            File(profileImagePath),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultProfilePhoto();
            },
          );
        }
      } catch (e) {
        return _buildDefaultProfilePhoto();
      }
    }

    if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
      return Image.network(
        profilePhotoUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultProfilePhoto();
        },
      );
    }

    if (avatar != null && avatar.isNotEmpty) {
      return Image.network(
        avatar,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
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
              'Provider: ${providerData['name']}',
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
