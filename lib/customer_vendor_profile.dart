import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer_home_screen.dart';
import 'customer_jobs_screen.dart';
import 'post_job_step1_screen.dart';
import 'customer_messages_screen.dart';
import 'customer_profile_screen.dart';
import 'vendor_home_screen.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/semantic_analysis_card.dart';
import 'chat_screen.dart';
import 'services/pro_status_checker.dart';
import 'services/database_service.dart';

class CustomerVendorProfileScreen extends StatefulWidget {
  const CustomerVendorProfileScreen({super.key, required this.vendor});

  final Map<String, dynamic> vendor;

  @override
  State<CustomerVendorProfileScreen> createState() =>
      _CustomerVendorProfileScreenState();
}

class _CustomerVendorProfileScreenState
    extends State<CustomerVendorProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  // PRO status
  bool _isProUser = false;

  // Service-based state management
  bool _isLoadingVendorData = true;
  Map<String, dynamic>? _vendorData;
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _supabaseReviews = [];
  bool _isLoadingReviews = true;

  Future<void> _loadVendorData() async {
    try {
      // Get vendor ID from the passed vendor map
      final vendorId = widget.vendor['id']?.toString();
      if (vendorId == null) {
        setState(() => _isLoadingVendorData = false);
        return;
      }

      // Fetch full vendor details from Supabase
      final data = await _databaseService.getVendorById(vendorId);
      setState(() {
        _vendorData = data;
        _isLoadingVendorData = false;
      });

      // Also load reviews
      await _loadReviews(vendorId);
    } catch (e) {
      debugPrint('Error loading vendor data: $e');
      setState(() => _isLoadingVendorData = false);
    }
  }

  Future<void> _loadReviews(String vendorId) async {
    try {
      final reviews = await _databaseService.getVendorReviews(vendorId);
      setState(() {
        _supabaseReviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      setState(() => _isLoadingReviews = false);
    }
  }

  // Check if there are more than 5 reviews
  bool get _hasMoreReviews {
    return _supabaseReviews.length > 5;
  }

  @override
  void initState() {
    super.initState();
    _loadVendorData();
    _checkProStatus();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
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

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF047A62);

    // Show loading indicator while vendor data is loading
    if (_isLoadingVendorData) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF047A62)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading vendor profile...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Vendor data from Supabase with fallback to passed widget.vendor
    final vendorName = _vendorData?['business_name']?.toString() ??
        widget.vendor['business_name']?.toString() ??
        widget.vendor['name']?.toString() ??
        '';
    final category = _vendorData?['business_type']?.toString() ??
        widget.vendor['business_type']?.toString() ??
        widget.vendor['category']?.toString() ??
        '';
    final rating = (_vendorData?['rating'] as num?)?.toDouble() ??
        (widget.vendor['rating'] as num?)?.toDouble() ??
        0.0;
    final about = _vendorData?['description']?.toString() ??
        widget.vendor['about']?.toString() ??
        'No description available';
    final reviewCount = (_vendorData?['review_count'] as num?)?.toInt() ??
        (widget.vendor['review_count'] as num?)?.toInt() ??
        0;
    final vendorCity = _vendorData?['city']?.toString() ??
        widget.vendor['city']?.toString() ??
        '';

    // Keep these for backward compatibility
    final distance = widget.vendor['distance']?.toString() ?? vendorCity;
    final experience = widget.vendor['experience']?.toString() ?? '';
    final reviews = reviewCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Visual Header
            _buildHeroHeader(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Primary Identity Card
                  _buildIdentityCard(primaryColor, vendorName, category, rating,
                      experience, reviews),

                  const SizedBox(height: 24),

                  // 3. Action Architecture
                  _buildActionButtons(primaryColor),

                  const SizedBox(height: 24),

                  // Semantic Analysis AI Card - PRO Only
                  if (_isProUser)
                    SemanticAnalysisCard(
                      providerName: widget.vendor['name'] as String? ??
                          'Khan Electronics',
                      overallRating: double.tryParse(
                              _vendorData?['rating']?.toString() ?? '') ??
                          (widget.vendor['rating'] as num?)?.toDouble() ??
                          4.6,
                      totalReviews:
                          widget.vendor['totalReviews'] as int? ?? 123,
                      totalJobs: widget.vendor['totalOrders'] as int? ?? 340,
                      category: widget.vendor['category'] as String? ??
                          'Electronics Vendor',
                      recentReviews: const [
                        'Quality products fast delivery',
                        'Very responsive seller',
                        'Exactly as described great value',
                      ],
                      isVendor: true,
                    ),
                  const SizedBox(height: 24),

                  // 4. Detail Information Grid
                  _buildDetailGrid(primaryColor, distance),

                  const SizedBox(height: 32),

                  // 5. About Section
                  _buildAboutSection(about),

                  const SizedBox(height: 32),

                  // 6. Reviews Section
                  _buildReviewsSection(primaryColor),

                  const SizedBox(height: 128),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: MuawinBottomNavigationBar(
        currentIndex: 0,
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

  Widget _buildHeroHeader() {
    // Get cover photo from vendor data
    final coverPhotoUrl = _vendorData?['coverPhotoUrl']?.toString();
    final coverPhotoPath = _vendorData?['coverPhotoPath']?.toString();

    return SizedBox(
      width: double.infinity,
      height: 288,
      child: Stack(
        children: [
          // Use cover photo if available, otherwise use avatar as fallback
          if (coverPhotoUrl != null || coverPhotoPath != null)
            coverPhotoPath != null
                ? Image.file(
                    File(coverPhotoPath),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackImage();
                    },
                  )
                : Image.network(
                    coverPhotoUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFallbackImage();
                    },
                  )
          else
            _buildFallbackImage(),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xB3000000)],
              ),
            ),
          ),
          Positioned(
            top: 48,
            left: 24,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Image.network(
      widget.vendor['avatar']?.toString() ??
          'https://picsum.photos/seed/ven-supermarket/800/600',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }

  Widget _buildIdentityCard(Color primaryColor, String vendorName,
      String category, double rating, String experience, int reviews) {
    return Transform.translate(
      offset: const Offset(0, -64),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile Photo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _buildVendorProfilePhoto(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    vendorName,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                Icon(Icons.verified, color: primaryColor, size: 24),
                const SizedBox(width: 16),
                // Vendor Status Display
                if (_vendorData != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                                _vendorData!['status']?.toString() ?? 'open'),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getStatusIcon(
                                _vendorData!['status']?.toString() ?? 'open'),
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusLabel(
                              _vendorData!['status']?.toString() ?? 'open'),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.store, color: primaryColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Verified Vendor',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (rating >= 4.8)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.thumb_up,
                            color: Color(0xFF166534), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Customer Favorite',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              category.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '• Verified Ratings',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Color primaryColor) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Calling vendor...'),
                      backgroundColor: Colors.blue),
                );
              },
              icon: const Icon(Icons.phone, color: Color(0xFF2563EB)),
              label: Text(
                'Call Now',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF6FF),
                foregroundColor: const Color(0xFF2563EB),
                elevation: 0,
                side: const BorderSide(color: Color(0xFFBFDBFE), width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => ChatScreen(
                            chatData: {
                              'name': _vendorData?['business_name']
                                      ?.toString() ??
                                  widget.vendor['business_name']?.toString() ??
                                  widget.vendor['name']?.toString() ??
                                  '',
                              'isOnline': true,
                              'avatar': _vendorData?['avatar']?.toString() ??
                                  widget.vendor['avatar']?.toString() ??
                                  '',
                              'type': 'vendor',
                            },
                          )),
                );
              },
              icon: const Icon(Icons.chat_bubble, color: Colors.white),
              label: Text(
                'Chat',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailGrid(Color primaryColor, String distance) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADDRESS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        distance,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'away',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    // Check if vendor has a custom Google Maps link
                    final vendorMapsLink =
                        widget.vendor['mapsLink']?.toString();

                    String googleMapsUrl;

                    if (vendorMapsLink != null && vendorMapsLink.isNotEmpty) {
                      // Use the vendor's custom Google Maps link
                      googleMapsUrl = vendorMapsLink;
                    } else {
                      // Fallback: Create Google Maps URL with vendor location search
                      final vendorName =
                          _vendorData?['business_name']?.toString() ??
                              widget.vendor['business_name']?.toString() ??
                              widget.vendor['name']?.toString() ??
                              '';
                      final vendorCategory =
                          _vendorData?['business_type']?.toString() ??
                              widget.vendor['business_type']?.toString() ??
                              widget.vendor['category']?.toString() ??
                              '';
                      final vendorAddress =
                          _vendorData?['address']?.toString() ??
                              widget.vendor['address']?.toString();

                      // Create a search query for Google Maps
                      String searchQuery = '$vendorName $vendorCategory';
                      if (vendorAddress != null && vendorAddress.isNotEmpty) {
                        searchQuery = '$searchQuery, $vendorAddress';
                      } else {
                        searchQuery = '$searchQuery near me';
                      }

                      // Google Maps URL
                      googleMapsUrl =
                          'https://www.google.com/maps/search/?api=1&query=$searchQuery';
                    }

                    // Try to launch Google Maps
                    try {
                      final uri = Uri.parse(googleMapsUrl);
                      if (await launcher.canLaunchUrl(uri)) {
                        await launcher.launchUrl(uri,
                            mode: launcher.LaunchMode.externalApplication);
                      } else {
                        // Fallback: Launch Google Maps without search
                        const fallbackUrl = 'https://www.google.com/maps';
                        final fallbackUri = Uri.parse(fallbackUrl);
                        if (await launcher.canLaunchUrl(fallbackUri)) {
                          await launcher.launchUrl(fallbackUri,
                              mode: launcher.LaunchMode.externalApplication);
                        }
                      }
                    } catch (e) {
                      // Show error message if Google Maps fails to launch
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch Google Maps'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: Text(
                    'View Map',
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side:
                        BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: Colors.grey.shade200,
              indent: 16,
              endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.access_time, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATUS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF22C55E).withValues(
                                        alpha: 0.5 * _pulseController.value,
                                      ),
                                      blurRadius:
                                          4 + (4 * _pulseController.value),
                                      spreadRadius: 1 * _pulseController.value,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Open Now',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF16A34A),
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
        ],
      ),
    );
  }

  Widget _buildAboutSection(String about) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Text(
              'About the Store',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          about,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customer Reviews',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                _showReviewDialog(context);
              },
              child: Text(
                'Write a Review',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Dynamic reviews list from Supabase
        if (_isLoadingReviews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: Color(0xFF047A62)),
            ),
          )
        else if (_supabaseReviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'No reviews yet. Be the first!',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
              ),
            ),
          )
        else
          ...List.generate(
            _supabaseReviews.length > 5 ? 5 : _supabaseReviews.length,
            (index) {
              final review = _supabaseReviews[index];
              final customerName =
                  review['customers']?['profiles']?['full_name']?.toString() ??
                      'Customer';
              final reviewRating = (review['rating'] as num?)?.toInt() ?? 0;
              final reviewText = review['review']?.toString() ?? '';
              final createdAt = review['created_at']?.toString() ?? '';
              String dateStr = '';
              if (createdAt.isNotEmpty) {
                try {
                  final date = DateTime.parse(createdAt);
                  dateStr = '${date.day}/${date.month}/${date.year}';
                } catch (_) {
                  dateStr = createdAt.substring(0, 10);
                }
              }
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index <
                          (_supabaseReviews.length > 5
                              ? 4
                              : _supabaseReviews.length - 1)
                      ? 12
                      : 0,
                ),
                child: _buildReviewCard(
                  username: customerName,
                  rating: reviewRating,
                  date: dateStr,
                  comment: reviewText,
                ),
              );
            },
          ),
        // Add View All Reviews button if there are more than 5 reviews
        if (_hasMoreReviews) ...[
          Container(
            margin: const EdgeInsets.only(top: 16),
            child: Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VendorHomeScreen(),
                      ),
                    );
                  },
                  icon:
                      const Icon(Icons.arrow_forward, color: Color(0xFF047A62)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewCard({
    required String username,
    required int rating,
    required String date,
    required String comment,
  }) {
    return Container(
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
                username,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"$comment"',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    const primaryColor = Color(0xFF047A62);
    final reviewController = TextEditingController();
    int selectedRating = 5;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Write a Review',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rating',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Review',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reviewController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reviewController.text.trim().isEmpty) return;

                final vendorId = widget.vendor['id']?.toString();
                if (vendorId == null) return;

                // Capture ScaffoldMessenger before any async gaps
                final messenger = ScaffoldMessenger.of(context);

                Navigator.pop(context);

                // Get current customer ID
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) return;

                try {
                  // Get customer record
                  final customerRecord = await Supabase.instance.client
                      .from('customers')
                      .select('id')
                      .eq(
                          'profile_id',
                          (await Supabase.instance.client
                              .from('profiles')
                              .select('id')
                              .eq('user_id', user.id)
                              .single())['id'])
                      .single();

                  // Insert review into Supabase
                  await Supabase.instance.client.from('reviews').insert({
                    'vendor_id': vendorId,
                    'customer_id': customerRecord['id'],
                    'rating': selectedRating,
                    'review': reviewController.text.trim(),
                    'is_verified': false,
                  });

                  // Reload reviews
                  await _loadReviews(vendorId);

                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Review submitted successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Error submitting review: $e');
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content:
                            Text('Failed to submit review. Please try again.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Submit',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Status display helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFF4ADE80); // Green
      case 'busy':
        return const Color(0xFFFBBF24); // Amber
      case 'break_':
        return const Color(0xFF60A5FA); // Blue
      case 'closed':
        return const Color(0xFF94A3B8); // Slate
      default:
        return const Color(0xFF4ADE80); // Default to green
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.circle; // Open circle
      case 'busy':
        return Icons.schedule; // Clock/schedule
      case 'break_':
        return Icons.pause_circle; // Pause
      case 'closed':
        return Icons.power_settings_new; // Settings/closed
      default:
        return Icons.circle; // Default circle
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'busy':
        return 'Busy';
      case 'break_':
        return 'Break';
      case 'closed':
        return 'Closed';
      default:
        return 'Open';
    }
  }

  // Build vendor profile photo for circular container
  Widget _buildVendorProfilePhoto() {
    final coverPhotoPath = _vendorData?['coverPhotoPath'] as String?;
    final coverPhotoUrl = _vendorData?['coverPhotoUrl'] as String?;
    final avatar = widget.vendor['avatar'] as String?;

    const isWeb = kIsWeb;

    // Try to load cover photo first, then avatar
    if (coverPhotoPath != null && !isWeb) {
      try {
        if (File(coverPhotoPath).existsSync()) {
          return Image.file(
            File(coverPhotoPath),
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultVendorProfilePhoto();
            },
          );
        }
      } catch (e) {
        return _buildDefaultVendorProfilePhoto();
      }
    }

    if (coverPhotoUrl != null && coverPhotoUrl.isNotEmpty) {
      return Image.network(
        coverPhotoUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultVendorProfilePhoto();
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
          return _buildDefaultVendorProfilePhoto();
        },
      );
    }

    return _buildDefaultVendorProfilePhoto();
  }

  Widget _buildDefaultVendorProfilePhoto() {
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
        Icons.store,
        size: 32,
        color: Colors.white,
      ),
    );
  }
}
