import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Open chat with provider - creates or finds a thread in Supabase
  Future<void> _openChatWithProvider() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Get current user's profile_id
      final myProfile = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', currentUser.id)
          .single();
      final myProfileId = myProfile['id'].toString();

      // Get provider's profile_id
      final providerProfileId = _provider?['profile_id']?.toString() ?? '';
      if (providerProfileId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open chat. Please try again.'),
            ),
          );
        }
        return;
      }

      // Check if thread already exists
      String? threadId;

      final existing1 = await supabase
          .from('message_threads')
          .select('id')
          .eq('participant_1_id', myProfileId)
          .eq('participant_2_id', providerProfileId)
          .maybeSingle();

      if (existing1 != null) {
        threadId = existing1['id'].toString();
      } else {
        final existing2 = await supabase
            .from('message_threads')
            .select('id')
            .eq('participant_1_id', providerProfileId)
            .eq('participant_2_id', myProfileId)
            .maybeSingle();

        if (existing2 != null) {
          threadId = existing2['id'].toString();
        }
      }

      // Create new thread if none exists
      if (threadId == null) {
        final newThread = await supabase
            .from('message_threads')
            .insert({
              'participant_1_id': myProfileId,
              'participant_2_id': providerProfileId,
              'is_active': true,
            })
            .select('id')
            .single();
        threadId = newThread['id'].toString();
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatData: {
              'id': threadId,
              'name': _provider?['profiles']?['full_name']?.toString() ??
                  'Provider',
              'isOnline': true,
              'avatar':
                  _provider?['profiles']?['profile_image_url']?.toString() ??
                      '',
              'type': 'provider',
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open chat. Please try again.'),
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
                            Flexible(
                              fit: FlexFit.loose,
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
                                  // Achievement Badges — conditionally shown based on real provider data
                                  Builder(
                                    builder: (context) {
                                      final double rating = double.tryParse(
                                              _provider?['rating']
                                                      ?.toString() ??
                                                  '0') ??
                                          0.0;
                                      final int experienceYears = int.tryParse(
                                              _provider?['experience_years']
                                                      ?.toString() ??
                                                  '0') ??
                                          0;
                                      final bool isPro =
                                          _provider?['is_pro'] == true;

                                      final bool showTopRated = rating >= 4.0;
                                      final bool showExpert =
                                          experienceYears >= 2;
                                      final bool showFavorite = isPro;

                                      // If provider has earned no badges, show nothing
                                      final List<Widget> badges = [];

                                      if (showTopRated) {
                                        badges.add(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFF7ED),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.emoji_events,
                                                    color: Color(0xFFA16207),
                                                    size: 12),
                                                const SizedBox(width: 4),
                                                Text('Top Rated',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 10,
                                                        color: const Color(
                                                            0xFFA16207),
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      if (showExpert) {
                                        if (badges.isNotEmpty) {
                                          badges.add(const SizedBox(width: 8));
                                        }
                                        badges.add(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                    Icons.workspace_premium,
                                                    color: Color(0xFF1E40AF),
                                                    size: 12),
                                                const SizedBox(width: 4),
                                                Text('Expert',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 10,
                                                        color: const Color(
                                                            0xFF1E40AF),
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      if (showFavorite) {
                                        if (badges.isNotEmpty) {
                                          badges.add(const SizedBox(width: 8));
                                        }
                                        badges.add(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.thumb_up,
                                                    color: Color(0xFF166534),
                                                    size: 10),
                                                const SizedBox(width: 3),
                                                Text('Favorite',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 9,
                                                        color: const Color(
                                                            0xFF166534),
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      if (badges.isEmpty) {
                                        return const SizedBox.shrink();
                                      }

                                      return Row(children: badges);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // Availability Status Badge
                            const SizedBox(width: 8),
                            Builder(
                              builder: (context) {
                                final String status =
                                    _provider?['availability_status']
                                            ?.toString() ??
                                        'offline';

                                Color bgColor;
                                Color textColor;
                                Color dotColor;
                                String label;
                                IconData icon;

                                if (status == 'available') {
                                  bgColor = const Color(0xFFDCFCE7);
                                  textColor = const Color(0xFF166534);
                                  dotColor = const Color(0xFF22C55E);
                                  label = 'Available';
                                  icon = Icons.circle;
                                } else if (status == 'busy') {
                                  bgColor = const Color(0xFFFEF3C7);
                                  textColor = const Color(0xFF92400E);
                                  dotColor = const Color(0xFFF59E0B);
                                  label = 'Busy';
                                  icon = Icons.circle;
                                } else {
                                  bgColor = const Color(0xFFF3F4F6);
                                  textColor = const Color(0xFF6B7280);
                                  dotColor = const Color(0xFF9CA3AF);
                                  label = 'Offline';
                                  icon = Icons.circle;
                                }

                                return ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 90),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color:
                                              dotColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(icon, color: dotColor, size: 8),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            label,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                                  onPressed: _openChatWithProvider,
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
                                    final phone = _provider?['profiles']
                                                ?['phone_number']
                                            ?.toString() ??
                                        '';
                                    if (phone.isNotEmpty) {
                                      launchUrl(
                                        Uri.parse('tel:$phone'),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Phone number not available'),
                                        ),
                                      );
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
                                          _provider?['experience_years'] != null
                                              ? '${_provider!['experience_years']} ${_provider!['experience_years'] == 1 ? 'Year' : 'Years'}'
                                              : '0 Years',
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
                                            () {
                                              final area = _provider?['area']
                                                      ?.toString() ??
                                                  '';
                                              final city = _provider?['city']
                                                      ?.toString() ??
                                                  '';
                                              if (area.isNotEmpty &&
                                                  city.isNotEmpty) {
                                                return '$area, $city';
                                              }
                                              if (city.isNotEmpty) return city;
                                              if (area.isNotEmpty) return area;
                                              return 'Location not set';
                                            }(),
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
                          '${(_provider?['review_count'] as num?)?.toInt() ?? _reviews.length} Reviews',
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
                      totalReviews:
                          (_provider?['review_count'] as num?)?.toInt() ?? 0,
                      totalJobs:
                          (_provider?['job_count'] as num?)?.toInt() ?? 0,
                      category: _provider?['service_category'] as String? ??
                          'Service',
                      recentReviews: const [
                        'Very professional and punctual',
                        'Excellent service highly recommend',
                        'Clean and well maintained vehicle',
                      ],
                      profileId: _provider?['id']?.toString() ?? '',
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
                    _provider?['tagline']?.toString().isNotEmpty == true
                        ? _provider!['tagline'].toString()
                        : 'No description provided yet.',
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
                          username: review['customers']?['profiles']
                                      ?['full_name']
                                  ?.toString() ??
                              'Customer',
                          rating: (review['rating'] as num?)?.toInt() ?? 5,
                          date: _formatDate(review['created_at'] as String?),
                          review: review['review']?.toString() ?? '',
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

            // Description (new section)
            if (currentPackage['description'] != null &&
                currentPackage['description'].toString().isNotEmpty) ...[
              Text(
                "What's included:",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              ...currentPackage['description']
                  .toString()
                  .split('\n')
                  .where((line) => line.trim().isNotEmpty)
                  .map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: Color(0xFF047A62),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                line.trim(),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              const SizedBox(height: 12),
            ],

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

  // Build Service Location section with city, area and Google Maps link
  Widget _buildServiceAreas() {
    final mapsLink = _provider?['maps_link']?.toString() ?? '';
    final city = _provider?['city']?.toString() ?? '';
    final area = _provider?['area']?.toString() ?? '';

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
            'Where do I provide my Service ?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Show city/area as location text
          if (city.isNotEmpty || area.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF047A62).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 14,
                    color: Color(0xFF047A62),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [area, city].where((s) => s.isNotEmpty).join(', '),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (city.isNotEmpty || area.isNotEmpty) const SizedBox(height: 10),

          // Show Google Maps link button if available
          if (mapsLink.isNotEmpty)
            GestureDetector(
              onTap: () async {
                final uri = Uri.tryParse(mapsLink);
                if (uri != null) {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF047A62),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.map_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View on Google Maps',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),

          // If no location data at all
          if (mapsLink.isEmpty && city.isEmpty && area.isEmpty)
            Text(
              'No service location specified',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  // Build Availability Section
  Widget _buildAvailability() {
    final availabilityText = _provider?['availability_text']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF047A62).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Color(0xFF047A62),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Working Hours',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  availabilityText.isNotEmpty
                      ? availabilityText
                      : 'Not specified',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: availabilityText.isNotEmpty
                        ? Colors.black87
                        : Colors.grey[400],
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
    final profileImageUrl =
        _provider?['profiles']?['profile_image_url']?.toString() ?? '';

    if (profileImageUrl.isNotEmpty &&
        !profileImageUrl.contains('placeholder.com')) {
      return Image.network(
        profileImageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildDefaultProfilePhoto(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
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
    final coverUrl =
        _provider?['cover_photo_url']?.toString().isNotEmpty == true
            ? _provider!['cover_photo_url'].toString()
            : '';
    final profileImageUrl =
        _provider?['profiles']?['profile_image_url']?.toString() ?? '';

    // Prefer cover photo, fall back to profile image
    final imageUrl = coverUrl.isNotEmpty ? coverUrl : profileImageUrl;

    // If we have a network URL, load it directly
    if (imageUrl.isNotEmpty &&
        (imageUrl.startsWith('http') || imageUrl.startsWith('https'))) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: 250,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Cover image load error: $error');
          return _buildDefaultProviderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            height: 250,
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF047A62),
              ),
            ),
          );
        },
      );
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
