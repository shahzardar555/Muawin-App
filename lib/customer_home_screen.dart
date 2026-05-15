import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'services/featured_ad_manager.dart';
import 'services/pro_status_checker.dart';
import 'services/database_service.dart';
import 'widgets/customer_notification_bell.dart';
import 'customer_jobs_screen.dart';
import 'customer_messages_screen.dart';
import 'customer_profile_screen.dart';
import 'post_job_screen.dart';
import 'service_providers_results_screen.dart';
import 'vendor_results_screen.dart';
import 'customer_provider_profile.dart';
import 'customer_vendor_profile.dart';
import 'language_provider.dart';
import 'widgets/muawin_pro_overlay.dart';
import 'widgets/voice_search_overlay.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/chat_voice_input.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentNavIndex = 0;
  String _customerName = '';
  String _currentLocation = '';
  final TextEditingController _searchController = TextEditingController();

  // PRO status state
  bool _isProUser = false;

  // Service categories state
  List<Map<String, dynamic>> _providerCategories = [];
  List<Map<String, dynamic>> _vendorCategories = [];
  bool _providerCategoriesLoading = true;
  bool _vendorCategoriesLoading = true;

  // Featured ad state
  Map<String, dynamic>? _featuredAd;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkProStatus();
    _loadCategories();
    _loadFeaturedAd();
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

  // Load user profile from SharedPreferences
  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _customerName = prefs.getString('user_name') ?? 'Customer';
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      setState(() {
        _customerName = 'Customer';
      });
    }
  }

  // Load service categories from database
  Future<void> _loadCategories() async {
    try {
      setState(() {
        _providerCategoriesLoading = true;
        _vendorCategoriesLoading = true;
      });

      // Load both in parallel
      final results = await Future.wait([
        DatabaseService().getProviderCategories(),
        DatabaseService().getVendorCategories(),
      ]);

      if (mounted) {
        setState(() {
          _providerCategories = results[0];
          _vendorCategories = results[1];
          _providerCategoriesLoading = false;
          _vendorCategoriesLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _providerCategoriesLoading = false;
          _vendorCategoriesLoading = false;
        });
      }
    }
  }

  // Load featured ad from database
  Future<void> _loadFeaturedAd() async {
    try {
      final providers = await DatabaseService().getFeaturedProviders();
      final vendors = await DatabaseService().getFeaturedVendors();

      // Combine and pick first active ad
      final allAds = [...providers, ...vendors];

      if (mounted) {
        setState(() {
          _featuredAd = allAds.isNotEmpty ? allAds.first : null;
        });
      }
    } catch (e) {
      debugPrint('Error loading featured ad: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(primary),
          SliverToBoxAdapter(child: _buildBodyContent(primary)),
        ],
      ),
      floatingActionButton: Column(
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
              Provider.of<LanguageProvider>(context).translate('how_can_help'),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF088771),
              ),
            ),
          ),
          SizedBox(
            width: 80, // Set SizedBox width to match image
            height: 80, // Set SizedBox height to match image
            child: FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const _AIChatBottomSheet(),
                );
              },
              backgroundColor: Colors.transparent, // Remove background
              elevation: 0, // Remove shadow
              child: ClipOval(
                child: Image.asset(
                  'imagess/bot.png',
                  width: 80, // Reduced size for mobile
                  height: 80, // Reduced size for mobile
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MuawinBottomNavigationBar(
        currentIndex: _currentNavIndex,
        onItemTapped: (i) {
          if (i == 1) {
            // Navigate to My Jobs screen
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomerJobsScreen(),
            ));
            return;
          }
          if (i == 2) {
            // Navigate to Post Job screen
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const PostJobScreen(),
            ));
            return;
          }
          if (i == 3) {
            // Navigate to Chats screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CustomerMessagesScreen(),
              ),
            );
            return;
          }
          if (i == 4) {
            // Navigate to Profile screen
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomerProfileScreen(),
            ));
            return;
          }
          setState(() => _currentNavIndex = i);
        },
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          top: isSmallMobile ? 8 : 12,
          bottom: isSmallMobile ? 8 : 12,
          left: isSmallMobile ? 16 : (isMobile ? 20 : 24),
          right: isSmallMobile ? 16 : (isMobile ? 20 : 24),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF088771),
              primary,
              primary.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 40,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Modern Geometric Mesh & Luminous Blobs
            // 1. Cyan Glow (Left-Center)
            Positioned(
              top: -40,
              left: -80,
              child: Container(
                width: isSmallMobile ? 200 : (isMobile ? 260 : 320),
                height: isSmallMobile ? 200 : (isMobile ? 260 : 320),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.cyanAccent.withValues(alpha: 0.25),
                      Colors.cyanAccent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // 2. Purple Accent (Right-Top)
            Positioned(
              top: -60,
              right: -30,
              child: Container(
                width: isSmallMobile ? 160 : (isMobile ? 210 : 260),
                height: isSmallMobile ? 160 : (isMobile ? 210 : 260),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purpleAccent.withValues(alpha: 0.2),
                      Colors.purpleAccent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // 3. White Luminous Core (Bottom-Right)
            Positioned(
              bottom: -80,
              right: -40,
              child: Container(
                width: isSmallMobile ? 180 : (isMobile ? 240 : 300),
                height: isSmallMobile ? 180 : (isMobile ? 240 : 300),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // 4. Dot Matrix Pattern: Structured geometric overlay
            Positioned.fill(
              child: CustomPaint(
                painter: _HeaderPatternPainter(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            // Empty space to preserve header layout structure
            Center(
              child: SizedBox(
                width: isSmallMobile ? 100 : (isMobile ? 120 : 140),
                height: isSmallMobile ? 85 : (isMobile ? 100 : 120),
              ),
            ),
            // Main content column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Utility Row: Notifications on the right
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invisible container to preserve space of original notification button
                    SizedBox(
                      width: 48,
                      height: 48,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Greeting and Search Group: Independent shifts
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting and Location Row: Parallel alignment
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Greeting Section: Responsive vertical positioning
                        Transform.translate(
                          offset: Offset(
                              0,
                              isSmallMobile
                                  ? -7
                                  : -22), // Moved down from -15/-30 to -7/-22
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              // Welcome message
                              Text(
                                'Salaam, $_customerName',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification button at far right of same row
                        Transform.translate(
                          offset: const Offset(
                              0, -12), // Move up by 12 pixels (from -8 to -12)
                          child: const CustomerNotificationBell(
                              receiverType: 'customer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search and Location Row: Responsive layout
                    Transform.translate(
                      offset: Offset(0, isSmallMobile ? -10 : -18),
                      child: isSmallMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Location Selector: Full width on small screens
                                Container(
                                  width: double.infinity,
                                  height: 48, // Slightly smaller on mobile
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        width: 1.5),
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        _showLocationBottomSheet(context),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 20,
                                            color: Colors.yellow[400]),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _currentLocation.split(',')[0],
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              letterSpacing: 0.1,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.keyboard_arrow_down,
                                            size: 18,
                                            color: Colors.white
                                                .withValues(alpha: 0.5)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Search Field: Full width on small screens
                                const SizedBox(
                                  height: 48,
                                  child: _PrimarySearchField(),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // Location Selector: Positioned on the left side
                                Container(
                                  height: 56, // Match search bar height
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                        20), // Match search bar radius
                                    border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        width: 1.5),
                                  ),
                                  child: InkWell(
                                    onTap: () =>
                                        _showLocationBottomSheet(context),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 24,
                                            color: Colors.yellow[400]),
                                        const SizedBox(width: 8),
                                        Text(
                                          _currentLocation.isEmpty
                                              ? Provider.of<LanguageProvider>(
                                                      context)
                                                  .translate('current_location')
                                              : _currentLocation.split(',')[0],
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.keyboard_arrow_down,
                                            size: 20,
                                            color: Colors.white
                                                .withValues(alpha: 0.5)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                    width:
                                        12), // Space between location and search
                                // Search Field: Extended to far right of header
                                const Expanded(
                                  child: _PrimarySearchField(),
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
      ),
    );
  }

  Widget _buildBodyContent(Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Partners Section
          _FeaturedPartnersSection(primary: primary),
          const SizedBox(height: 24),

          // Service Categories Gradient Squircle
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF088771), // Muawin Primary Teal
                  Color(0xFF064e3b), // Tailwind Emerald 900
                ],
              ),
              borderRadius: BorderRadius.circular(32), // 2rem = 32px
            ),
            padding: const EdgeInsets.all(32), // 2rem = 32px
            child: Column(
              children: [
                // Section Header
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    Provider.of<LanguageProvider>(context)
                        .translate('service_categories'),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Service Categories - Dynamic from Database
                if (_providerCategoriesLoading)
                  _buildCategoriesShimmer()
                else if (_providerCategories.isEmpty)
                  Center(
                    child: Text(
                      'No categories available',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                else
                  _buildProviderCategoriesList(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Local Vendors Section
          _LocalVendorsSection(
            primary: primary,
            vendorCategories: _vendorCategories,
            vendorCategoriesLoading: _vendorCategoriesLoading,
          ),
          const SizedBox(height: 24),

          // Featured Ads Section - Hide for PRO users
          if (!_isProUser) ...[
            _FeaturedAdsSection(featuredAd: _featuredAd),
            const SizedBox(height: 24),
          ],

          // Top Rated Pros Section - PRO only
          if (_isProUser) ...[
            _TopRatedProsSection(primary: primary),
            const SizedBox(height: 24),
          ],

          // Vendors Nearby Section
          _VendorsNearbySection(primary: primary),
          const SizedBox(height: 24),

          // Muawin Pro Ad Section - Hide for PRO users
          if (!_isProUser) ...[
            const _MuawinProAd(primary: Color(0xFF047A62)),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // Build shimmer loading state for categories
  Widget _buildCategoriesShimmer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) => _buildShimmerIcon()),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(3, (index) => _buildShimmerIcon()),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) => _buildShimmerIcon()),
        ),
      ],
    );
  }

  // Single shimmer icon placeholder
  Widget _buildShimmerIcon() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  // Build provider categories list from database
  Widget _buildProviderCategoriesList() {
    // Define colors for categories in a cycle
    final colors = [
      const Color(0xFF1976D2),
      const Color(0xFF2E7D32),
      const Color(0xFFEA580C),
      const Color(0xFF7C3AED),
      const Color(0xFFDC2626),
      const Color(0xFFEC4899),
      const Color(0xFFF97316),
      const Color(0xFF14B8A6),
      const Color(0xFF4F46E5),
    ];

    // Split categories into rows of 3
    final rows = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < _providerCategories.length; i += 3) {
      rows.add(_providerCategories.skip(i).take(3).toList());
    }

    return Column(
      children: rows.map((row) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((category) {
                final colorIndex =
                    (_providerCategories.indexOf(category)) % colors.length;
                return Expanded(
                  child:
                      _buildProviderCategoryIcon(category, colors[colorIndex]),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        );
      }).toList(),
    );
  }

  // Build single provider category icon from database
  Widget _buildProviderCategoryIcon(
      Map<String, dynamic> category, Color iconColor) {
    final name = category['name'] as String? ?? '';
    final icon = category['icon'] as String? ?? '';

    // Use icon emoji if available, otherwise use first letter of name
    final displayIcon = icon.isNotEmpty
        ? icon
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceProvidersResultsScreen(category: name),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                displayIcon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showLocationBottomSheet(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32), // 2rem = 32px
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              blurRadius: 40, // shadow-2xl
              offset: Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Provider.of<LanguageProvider>(context)
                        .translate('select_location'),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Use Current Location Button - Updated Design
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity, // Full width
                height: 56, // 3.5rem = 56px
                decoration: BoxDecoration(
                  color: const Color(0xFF088771)
                      .withValues(alpha: 0.05), // 5% Primary Teal
                  borderRadius: BorderRadius.circular(16), // 1rem
                  border: Border.all(
                    color: const Color(0xFF088771), // Primary Teal
                    width: 1, // 1px solid
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    if (!mounted) return;

                    // Store context before any async operations
                    final currentContext = context;

                    // Store context-dependent values before async gap
                    final messenger = ScaffoldMessenger.of(currentContext);
                    final navigator = Navigator.of(currentContext);
                    final languageProvider = Provider.of<LanguageProvider>(
                        currentContext,
                        listen: false);
                    const primaryColor = Color(0xFF088771);

                    navigator.pop();

                    // Show loading state (could update a global state here)
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          languageProvider
                              .translate('getting_current_location'),
                          style: GoogleFonts.poppins(),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    // Check if location services are enabled
                    bool isLocationServiceEnabled =
                        await Geolocator.isLocationServiceEnabled();
                    if (!isLocationServiceEnabled) {
                      if (mounted && currentContext.mounted) {
                        bool? openSettings = await showDialog<bool>(
                          context: currentContext,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Location Services Disabled'),
                            content: const Text(
                                'Please enable location services to get your current location.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(true),
                                child: const Text('Open Settings'),
                              ),
                            ],
                          ),
                        );

                        // Check if still mounted after dialog
                        if (mounted && openSettings == true) {
                          await Geolocator.openLocationSettings();
                        }

                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Location services are disabled. Please enable them in settings.',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                      return;
                    }

                    // Request location permission and get current position
                    try {
                      LocationPermission permission =
                          await Geolocator.checkPermission();
                      if (permission == LocationPermission.denied) {
                        permission = await Geolocator.requestPermission();
                      }

                      if (permission == LocationPermission.denied ||
                          permission == LocationPermission.deniedForever) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Location permission denied. Please enable it in app settings.',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: Colors.red,
                              action: SnackBarAction(
                                label: 'Settings',
                                onPressed: () => Geolocator.openAppSettings(),
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      // Get current position with timeout
                      Position position = await Geolocator.getCurrentPosition(
                        desiredAccuracy: LocationAccuracy.high,
                        timeLimit: const Duration(seconds: 15),
                      ).timeout(
                        const Duration(seconds: 15),
                        onTimeout: () {
                          throw TimeoutException('Location request timed out',
                              const Duration(seconds: 15));
                        },
                      );

                      // Reverse geocoding to get address
                      try {
                        List<Placemark> placemarks =
                            await placemarkFromCoordinates(
                                position.latitude, position.longitude);

                        Placemark place = placemarks.first;
                        String address = '';

                        if (place.street?.isNotEmpty == true) {
                          address = place.street!;
                        } else if (place.name?.isNotEmpty == true) {
                          address = place.name!;
                        } else if (place.locality?.isNotEmpty == true) {
                          address = place.locality!;
                        } else {
                          address = 'Unknown Location';
                        }

                        // Update the current location state
                        setState(() {
                          _currentLocation = address;
                        });

                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Location updated: $address',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: primaryColor,
                            ),
                          );
                        }
                      } catch (geocodingError) {
                        // Fallback to coordinates if geocoding fails
                        setState(() {
                          _currentLocation =
                              'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
                        });

                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Location found but address unavailable',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    } on TimeoutException {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Location request timed out. Please try again.',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to get location: ${e.toString()}',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 16), // 1rem horizontal padding
                      const Icon(
                        Icons.navigation, // Navigation icon (1.25rem / w-5 h-5)
                        size: 20, // 1.25rem
                        color: Color(0xFF088771), // Solid Primary Teal
                      ),
                      const SizedBox(width: 16), // 1rem gap
                      Expanded(
                        child: Text(
                          Provider.of<LanguageProvider>(context)
                              .translate('use_current_location'),
                          style: GoogleFonts.poppins(
                            fontSize: 16, // text-base (1rem)
                            fontWeight: FontWeight.w600, // Semi-bold
                            color:
                                const Color(0xFF088771), // Solid Primary Teal
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Popular Areas Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                Provider.of<LanguageProvider>(context)
                    .translate('popular_areas'),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Areas List - Static for now, could be made dynamic
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  'Gulberg III, Lahore',
                  'DHA Phase 5, Lahore',
                  'Model Town, Lahore',
                  'Johar Town, Lahore',
                  'Bahria Town, Lahore',
                  'Cantt, Lahore',
                  'Faisal Town, Lahore',
                  'Ichhra, Lahore',
                  'Wapda Town, Lahore',
                  'Valencia Town, Lahore',
                ].map((area) {
                  final isSelected =
                      area == _currentLocation; // Show current selection

                  return GestureDetector(
                    onTap: () {
                      // Update the selected location directly
                      setState(() {
                        _currentLocation = area;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primary : Colors.grey[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: isSelected ? primary : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              area,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? primary : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimarySearchField extends StatelessWidget {
  const _PrimarySearchField();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < 400;

    return GestureDetector(
      onTap: () => _openSearchModal(context),
      child: Container(
        // Responsive height
        height: isSmallMobile ? 48 : 56,
        decoration: BoxDecoration(
          color: Colors.white, // Pure white solid background
          borderRadius: BorderRadius.circular(isSmallMobile ? 16 : 20),
          // shadow-2xl: Large diffused drop shadow
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        // Search icon positioned exactly 1rem (16px) from left
        padding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 12 : 16),
        child: Row(
          children: [
            // Muted Search icon
            Icon(
              Icons.search,
              size: isSmallMobile ? 18 : 20,
              color: Colors.grey[400],
            ),
            const SizedBox(width: 12),
            // Medium weight Poppins (text-sm = 14px), high-transparency gray
            Text(
              Provider.of<LanguageProvider>(context)
                  .translate('search_placeholder'),
              style: GoogleFonts.poppins(
                fontSize: isSmallMobile ? 12 : 14, // text-sm
                fontWeight: FontWeight.w500, // medium
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SearchResultsModal(),
    );
  }
}

class _SearchResultsModal extends StatefulWidget {
  const _SearchResultsModal();

  @override
  State<_SearchResultsModal> createState() => _SearchResultsModalState();
}

class _SearchResultsModalState extends State<_SearchResultsModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  String _selectedSort = 'recommended';

  // Voice search state
  bool _isListening = false;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechAvailable = false;

  // Urdu category mapping for voice search
  Map<String, String> _urduCategoryMap = {};

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeech();
      _loadUrduCategoryMap();
    });
  }

  // Sample data for search results - ONLY allowed categories
  // TODO: Load from Supabase
  final List<Map<String, dynamic>> _allResults = [
    // Vendors - Only: Milkshop, Supermarket, Gas Cylinder Shop, Bakery, Fruits and Vegetables Shop, Drinking Water Plant, Meatshop
    // TODO: Connect to Supabase
  ];

  // Filter options
  final List<String> _filters = [
    'all',
    'highest_rated',
    'nearest_to_you',
    'active_only',
    'expert',
    'new_service_providers',
  ];

  // Sort options
  final List<String> _sortOptions = [
    'recommended',
    'highest_to_lowest_fees',
    'lowest_to_highest_fees',
    'highest_to_lowest_rated',
    'a_to_z',
    'z_to_a',
    'highest_experience',
    'lowest_experience',
  ];

  List<Map<String, dynamic>> get _filteredResults {
    // Filter by search query
    var results = _allResults.where((item) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final name = item['name'].toString().toLowerCase();
      final category = item['category'].toString().toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();

    // Apply filter
    switch (_selectedFilter) {
      case 'highest_rated':
        results = results.where((r) => (r['rating'] as num) >= 4.5).toList();
        break;
      case 'nearest_to_you':
        results = results.where((r) {
          final distanceStr = r['distance'].toString();
          final distance =
              double.tryParse(distanceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                  999;
          return distance <= 2.0; // Within 2km
        }).toList();
        break;
      case 'active_only':
        results = results.where((r) {
          final status = r['status'].toString().toLowerCase();
          return status == 'available' || status == 'open';
        }).toList();
        break;
      case 'expert':
        results = results.where((r) {
          final exp = r['experience'].toString();
          final years =
              int.tryParse(RegExp(r'\d+').firstMatch(exp)?.group(0) ?? '0') ??
                  0;
          return years >= 5;
        }).toList();
        break;
      case 'new_service_providers':
        results = results.where((r) {
          final exp = r['experience'].toString();
          final years =
              int.tryParse(RegExp(r'\d+').firstMatch(exp)?.group(0) ?? '0') ??
                  0;
          return years <= 2;
        }).toList();
        break;
      default:
        // If no filter matches, return all results
        break;
    }

    // Apply sort
    switch (_selectedSort) {
      case 'highest_to_lowest_rated':
        results
            .sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
        break;
      case 'a_to_z':
        results.sort(
            (a, b) => a['name'].toString().compareTo(b['name'].toString()));
        break;
      case 'z_to_a':
        results.sort(
            (a, b) => b['name'].toString().compareTo(a['name'].toString()));
        break;
    }

    return results;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  // Initialize speech recognition
  void _initializeSpeech() async {
    _speechAvailable = await _speechToText.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  // Load Urdu category mapping from database
  Future<void> _loadUrduCategoryMap() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('service_categories')
          .select('name, name_urdu, category_type')
          .eq('is_active', true);

      final Map<String, String> urduMap = {};
      for (final cat in response) {
        if (cat['name_urdu'] != null) {
          urduMap[cat['name_urdu']] = cat['name'];
        }
      }

      setState(() => _urduCategoryMap = urduMap);
    } catch (e) {
      debugPrint('Error loading Urdu map: $e');
    }
  }

  // Voice Search Methods
  Future<void> _handleVoiceSearch() async {
    // Check if speech is available
    if (!_speechAvailable) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Speech recognition not available on this device',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check permission first
    final micPermission = await Permission.microphone.request();
    if (micPermission.isDenied) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Microphone permission needed for voice search',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF047A62),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If already listening stop it
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    // Show voice overlay
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        builder: (_) => VoiceSearchOverlay(
          speechToText: _speechToText,
          onResult: (String recognizedWords) {
            if (mounted) {
              setState(() {
                _isListening = false;
                _searchController.text = recognizedWords;
                _searchQuery = recognizedWords;
              });
            }
            Navigator.pop(context);
            _performVoiceSearch(recognizedWords);
          },
          onListeningStateChanged: (bool listening) {
            if (mounted) {
              setState(() => _isListening = listening);
            }
          },
          onCancel: () {
            if (mounted) {
              setState(() => _isListening = false);
            }
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  void _performVoiceSearch(String query) {
    // Urdu to English category mapping
    String searchQuery = query;
    _urduCategoryMap.forEach((urdu, english) {
      if (query.contains(urdu)) {
        searchQuery = english;
        _searchController.text = english;
        _searchQuery = english;
      }
    });

    // Show result banner
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mic, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Searching for: $searchQuery',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF047A62),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with title and close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Provider.of<LanguageProvider>(context).translate('search'),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Input Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.search, color: primary),
                        hintText: Provider.of<LanguageProvider>(context)
                            .translate('search_placeholder'),
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ChatMicButton(
                  isListening: _isListening,
                  onTap: _handleVoiceSearch,
                ),
              ],
            ),
          ),

          // Filter and Sort Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Filter Buttons
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedFilter = filter);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primary.withValues(alpha: 0.1)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected ? primary : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                Provider.of<LanguageProvider>(context)
                                    .translate(filter),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color:
                                      isSelected ? primary : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Sort Button
                GestureDetector(
                  onTap: () => _showSortBottomSheet(context, primary),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sort,
                          size: 18,
                          color: primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Provider.of<LanguageProvider>(context)
                              .translate('sort'),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredResults.length} ${Provider.of<LanguageProvider>(context).translate('results_found')}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Results List
          Expanded(
            child: _filteredResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Start typing to search'
                              : 'No results found',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredResults.length,
                    itemBuilder: (context, index) {
                      final result = _filteredResults[index];
                      final isVendor = result['type'] == 'vendor';
                      return _buildResultCard(result, isVendor, primary);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(
      Map<String, dynamic> result, bool isVendor, Color primary) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (isVendor) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerVendorProfileScreen(vendor: result),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  CustomerProviderProfileScreen(providerId: result['id'] ?? ''),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(result['avatar'].toString()),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Type Badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          result['name'].toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isVendor
                              ? Colors.blue.shade50
                              : primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isVendor ? 'Vendor' : 'Service',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isVendor ? Colors.blue.shade700 : primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Category
                  Text(
                    result['category'].toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rating and Distance
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        result['rating'].toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        result['distance'].toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
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
    );
  }

  void _showSortBottomSheet(BuildContext context, Color primary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    Provider.of<LanguageProvider>(context).translate('sort'),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Sort Options - Now scrollable
            SizedBox(
              height: 220, // Further reduced height to fix remaining overflow
              child: ListView.builder(
                itemCount: _sortOptions.length,
                itemBuilder: (context, index) {
                  final option = _sortOptions[index];
                  final isSelected = _selectedSort == option;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedSort = option);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.05)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[100]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              Provider.of<LanguageProvider>(context)
                                  .translate(option),
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? primary : Colors.black87,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Featured Partners Section
class _FeaturedPartnersSection extends StatefulWidget {
  const _FeaturedPartnersSection({required this.primary});

  final Color primary;

  @override
  State<_FeaturedPartnersSection> createState() =>
      _FeaturedPartnersSectionState();
}

class _FeaturedPartnersSectionState extends State<_FeaturedPartnersSection> {
  final ScrollController _scrollController = ScrollController();
  static const double _cardWidth = 280;
  static const double _cardMargin = 16;

  // Featured partners data
  List<FeaturedAd> _featuredPartners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeaturedPartners();
  }

  // Get current logged in user ID from Supabase
  String? _getCustomerId() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return user.id;
  }

  Future<void> _loadFeaturedPartners() async {
    try {
      final featuredManager = FeaturedAdManager();

      // Filter featured ads by location (within 5km radius) for current customer
      final featuredPartners = await featuredManager.getFeaturedAdsForCustomer(
        _getCustomerId() ?? '',
        5.0, // 5km radius
      );

      if (mounted) {
        setState(() {
          _featuredPartners = featuredPartners;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading featured partners: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header & Branding
        Padding(
          padding: const EdgeInsets.only(left: 4), // 0.25rem padding (px-1)
          child: Row(
            children: [
              Icon(
                Icons.flash_on, // Zap icon (1rem x 1rem / w-4 h-4)
                size: 16,
                color: Colors.amber.shade500, // text-amber-500
              ),
              const SizedBox(width: 8),
              Text(
                Provider.of<LanguageProvider>(context)
                    .translate('featured_partners'),
                style: GoogleFonts.poppins(
                  fontSize: 20, // 1.25rem / text-xl
                  fontWeight: FontWeight.w800, // Extra-bold
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16), // 1rem gap (space-y-4)

        // Carousel Architecture (Horizontal Scrolling with Buttons)
        Stack(
          children: [
            // Loading State
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF047A62),
                ),
              )
            else if (_featuredPartners.isEmpty)
              SizedBox(
                width: double.infinity,
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_center,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No featured partners available',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Scrollable Content
              SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable manual scrolling
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(
                    _featuredPartners.length,
                    (index) => Container(
                      width: _cardWidth, // Fixed width smaller than screen
                      margin: const EdgeInsets.only(right: _cardMargin),
                      child: _FeaturedPartnerCard(
                          primary: widget.primary,
                          featuredPartner: _featuredPartners[index],
                          index: index),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Featured Partner Card
class _FeaturedPartnerCard extends StatelessWidget {
  const _FeaturedPartnerCard(
      {required this.primary,
      required this.featuredPartner,
      required this.index});

  final Color primary;
  final FeaturedAd featuredPartner;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Extract real data from FeaturedAd
    final partner = featuredPartner;
    final userName = partner.userName;
    final userCategory = partner.userCategory;
    final userRating = partner.userRating;
    final userDistance = partner.userDistance;

    // Cycle through different base colors for variety
    final baseColors = [
      Colors.green.shade600, // Emerald-600 equivalent
      Colors.amber.shade600, // Amber-600
      Colors.blue.shade600, // Blue-600
    ];
    final baseColor = baseColors[index % baseColors.length];

    return GestureDetector(
      onTap: () {
        // Navigate to appropriate profile based on user type
        if (partner.userType == 'provider') {
          // Create properly structured provider data
          final providerData = {
            'id': partner.userId,
            'name': partner.userName,
            'category': partner.userCategory,
            'rating': partner.userRating,
            'distance': '${partner.userDistance.toStringAsFixed(1)} km',
            'tagline': partner.tagline,
            'profileImageUrl': partner.profileImageUrl,
            'verified': true,
            'completedJobs': 156,
            'experience': '10+ years',
            'location': 'Karachi',
            'latitude': partner.userLatitude,
            'longitude': partner.userLongitude,
          };

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerProviderProfileScreen(
                providerId: providerData['id']?.toString() ?? '',
              ),
            ),
          );
        } else if (partner.userType == 'vendor') {
          // Create properly structured vendor data
          final vendorData = {
            'id': partner.userId,
            'name': partner.userName,
            'category': partner.userCategory,
            'rating': partner.userRating,
            'distance': '${partner.userDistance.toStringAsFixed(1)} km',
            'tagline': partner.tagline,
            'profileImageUrl': partner.profileImageUrl,
            'verified': true,
            'completedJobs': 156,
            'experience': '10+ years',
            'location': 'Karachi',
            'latitude': partner.userLatitude,
            'longitude': partner.userLongitude,
          };

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerVendorProfileScreen(
                vendor: vendorData,
              ),
            ),
          );
        }
      },
      child: Container(
        height: 192, // 12rem / h-48
        decoration: BoxDecoration(
          color: baseColor, // Base color background
          borderRadius: BorderRadius.circular(32), // rounded-[32px]
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16, // shadow-lg
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias, // Clip to rounded shape
        child: Stack(
          children: [
            // Image Layer - High-res placeholder with 40% opacity
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: partner.profileImageUrl.isNotEmpty
                        ? NetworkImage(partner.profileImageUrl) as ImageProvider
                        : const AssetImage('images/laundry.jpg')
                            as ImageProvider,
                    fit: BoxFit.cover, // object-cover
                    opacity: 0.4, // 40% opacity to allow base color tint
                  ),
                ),
              ),
            ),
            // Horizontal Gradient Overlay (from-black/70 via-black/30 to-transparent)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(32), // Match card border radius
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.7), // from-black/70
                      Colors.black.withValues(alpha: 0.3), // via-black/30
                      Colors.transparent, // to-transparent
                    ],
                  ),
                ),
              ),
            ),
            // Featured Badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2), // px-2 py-0.5
                decoration: BoxDecoration(
                  color: Colors.yellow.shade400, // Yellow-400
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'FEATURED',
                  style: GoogleFonts.inter(
                    fontSize: 9, // text-[9px]
                    fontWeight: FontWeight.w800, // Extra-bold
                    color: Colors.black,
                    letterSpacing: 0.1 * 9, // tracking-widest (0.1em)
                    textBaseline: TextBaseline.alphabetic,
                  ),
                ),
              ),
            ),
            // Content Area
            Padding(
              padding: const EdgeInsets.only(
                top: 60, // Increased top padding to move text down
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partner Name - Hero typography
                  Text(
                    userName,
                    style: GoogleFonts.poppins(
                      fontSize: 20, // text-xl
                      fontWeight: FontWeight.w800, // Hero-weight
                      color: Colors.white,
                      height: 1.0, // leading-tight
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Category Label
                  Text(
                    userCategory,
                    style: GoogleFonts.poppins(
                      fontSize: 10, // text-[10px]
                      fontWeight: FontWeight.w500, // Medium
                      color: Colors.white.withValues(alpha: 0.8), // 80% white
                      letterSpacing: 1.0, // uppercase tracking
                    ).copyWith(
                      textBaseline: TextBaseline.alphabetic,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Tagline
                  Text(
                    partner.tagline,
                    style: GoogleFonts.poppins(
                      fontSize: 12, // text-xs
                      fontWeight: FontWeight.w500, // Medium
                      color: Colors.white.withValues(alpha: 0.9), // 90% white
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1, // line-clamp-1
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  // Metadata Info-Pills
                  Row(
                    children: [
                      // Star Rating Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withValues(alpha: 0.3), // bg-black/30
                          borderRadius:
                              BorderRadius.circular(4), // 0.5rem radius
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber.shade400, // Amber fill
                              size: 12, // 0.75rem
                            ),
                            const SizedBox(width: 3),
                            Text(
                              userRating.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10, // text-[10px]
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12), // 0.75rem gap
                      // Distance Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withValues(alpha: 0.3), // bg-black/30
                          borderRadius:
                              BorderRadius.circular(4), // 0.5rem radius
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_pin,
                              color: Colors.white, // White
                              size: 12, // 0.75rem
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${userDistance.toStringAsFixed(1)} km',
                              style: GoogleFonts.poppins(
                                fontSize: 10, // text-[10px]
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
      ),
    );
  }
}

// Local Vendors Section
class _LocalVendorsSection extends StatefulWidget {
  const _LocalVendorsSection({
    required this.primary,
    required this.vendorCategories,
    required this.vendorCategoriesLoading,
  });

  final Color primary;
  final List<Map<String, dynamic>> vendorCategories;
  final bool vendorCategoriesLoading;

  @override
  State<_LocalVendorsSection> createState() => _LocalVendorsSectionState();
}

class _LocalVendorsSectionState extends State<_LocalVendorsSection> {
  final ScrollController _scrollController = ScrollController();
  static const double _cardMargin = 16;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading shimmer while loading vendor categories
    if (widget.vendorCategoriesLoading) {
      return _buildVendorCategoriesShimmer();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.only(left: 4), // 0.25rem padding (px-1)
          child: Text(
            Provider.of<LanguageProvider>(context).translate('local_vendors'),
            style: GoogleFonts.poppins(
              fontSize: 20, // 1.25rem / text-xl
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16), // 1rem gap (space-y-4)

        // Horizontal Scroll Container with Buttons
        Stack(
          children: [
            // Scrollable Content
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Dynamic Vendor Categories from Database
                  ...widget.vendorCategories.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: _cardMargin),
                      child: _vendorCategoryCard(
                        primary: widget.primary,
                        category: category,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build shimmer loading state for vendor categories
  Widget _buildVendorCategoriesShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header shimmer
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Container(
            width: 120,
            height: 20,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 16),
        // Vendor cards shimmer
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(
                4,
                (index) => Padding(
                      padding: const EdgeInsets.only(right: _cardMargin),
                      child: _buildVendorCardShimmer(),
                    )),
          ),
        ),
      ],
    );
  }

  // Single vendor card shimmer
  Widget _buildVendorCardShimmer() {
    return Container(
      width: 120,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // Build vendor category card from database
  Widget _vendorCategoryCard({
    required Color primary,
    required Map<String, dynamic> category,
  }) {
    final name = category['name'] as String? ?? '';
    final icon = category['icon'] as String? ?? '';

    // Use icon emoji if available, otherwise use first letter of name
    final displayIcon = icon.isNotEmpty
        ? icon
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VendorResultsScreen(category: name),
          ),
        );
      },
      child: Container(
        width: 120,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon container
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    displayIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ),
            // Title container
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Top Rated Pros Section
class _TopRatedProsSection extends StatelessWidget {
  const _TopRatedProsSection({required this.primary});

  final Color primary;

  // Sample provider IDs for demonstration - in real app these would come from a backend
  // TODO: Load from Supabase
  static const List<String> _providerIds = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION HEADER & BRANDING
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 4), // 0.25rem left/right gutter (px-1)
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events, // Trophy icon
                      color: Colors.amber
                          .shade500, // High-Saturation Amber (text-yellow-500)
                      size: 20, // 1.25rem x 1.25rem / w-5 h-5
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Provider.of<LanguageProvider>(context)
                            .translate('top_rated_pros_nearby'),
                        style: GoogleFonts.poppins(
                          fontSize: 18, // Reduced from 20 to 18
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16), // 1rem gap (space-y-4)

        // ITEMS LIST CONTAINER
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _providerIds.isEmpty ? 0 : 3,
          itemBuilder: (context, index) {
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: 16), // 1rem gap (space-y-4)
              child: _TopRatedProCard(primary: primary, index: index),
            );
          },
        ),
      ],
    );
  }
}

class _TopRatedProCard extends StatefulWidget {
  const _TopRatedProCard({required this.primary, required this.index});

  final Color primary;
  final int index;

  @override
  State<_TopRatedProCard> createState() => _TopRatedProCardState();
}

class _TopRatedProCardState extends State<_TopRatedProCard> {
  Map<String, dynamic>? _providerData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    try {
      // Since providerIds is now empty, this won't be called
      // TODO: Load from Supabase when data is available
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading provider data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to build profile image with cross-platform support
  Widget _buildProfileImage() {
    if (_providerData != null && _providerData!['profile_image_path'] != null) {
      final profileImagePath = _providerData!['profile_image_path'] as String;

      // Check if it's a local file or web URL
      if (profileImagePath.startsWith('blob:')) {
        // Web: Use Image.network with blob URL
        return Image.network(
          profileImagePath,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      } else {
        // Mobile: Use Image.file
        return Image.file(
          File(profileImagePath),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      }
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    // Use real profile_image_url from provider data
    final profileImageUrl =
        _providerData?['profiles']?['profile_image_url'] ?? '';

    if (profileImageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          profileImageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: const Icon(Icons.person_rounded, color: Colors.grey),
            );
          },
        ),
      );
    } else {
      // Show placeholder icon if profile_image_url is empty
      return Container(
        width: 60,
        height: 60,
        color: Colors.grey[300],
        child: const Icon(Icons.person_rounded, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while loading data
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 16,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.grey[200],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Use real provider data if available, otherwise fallback to mock data
    // TODO: Load from Supabase
    final providerName = _providerData?['provider_name'] ?? '';
    final serviceType = _providerData?['service_type'] ?? '';
    final rating = _providerData?['rating'] ?? 0.0;
    final location = _providerData?['location'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerProviderProfileScreen(
              providerId: _providerData?['id']?.toString() ?? '',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Main content row
            Row(
              children: [
                // Avatar - using real profile image
                ClipOval(
                  child: _buildProfileImage(),
                ),
                const SizedBox(width: 16),

                // Provider details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and rating row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              providerName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Service type
                      Text(
                        serviceType,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Location row
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Vendors Nearby Section
class _VendorsNearbySection extends StatelessWidget {
  const _VendorsNearbySection({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION HEADER & BRANDING
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 4), // 0.25rem left/right gutter (px-1)
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.storefront, // Storefront icon for vendors
                    color: Colors.amber
                        .shade500, // High-Saturation Amber (text-yellow-500)
                    size: 20, // 1.25rem x 1.25rem / w-5 h-5
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Provider.of<LanguageProvider>(context)
                        .translate('vendors_nearby'),
                    style: GoogleFonts.poppins(
                      fontSize: 20, // 1.25rem / text-xl
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              // Threshold Badge: Enhanced premium pill design for consistency
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'Within 5km',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.amber.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16), // 1rem gap (space-y-4)

        // ITEMS LIST CONTAINER
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: 16), // 1rem gap (space-y-4)
              child: _VendorNearbyCard(primary: primary, index: index),
            );
          },
        ),
      ],
    );
  }
}

class _MuawinProAd extends StatefulWidget {
  const _MuawinProAd({required this.primary});

  final Color primary;

  @override
  State<_MuawinProAd> createState() => _MuawinProAdState();
}

class _MuawinProAdState extends State<_MuawinProAd>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.20944, // -12 degrees in radians
      end: 0.0, // 0 degrees
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovering) {
    if (isHovering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: Container(
        // Primary Container: Full-width premium card
        width: double.infinity,
        // Background: High-fidelity diagonal linear gradient
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E293B), // slate-800
              Color(0xFF0F172A), // slate-900
              Color(0xFF1E293B), // slate-800
            ],
          ),
          // Geometry: Exactly 2rem (32px) corner radius
          borderRadius: BorderRadius.circular(32),
          // Elevation: Ultra-high diffusion drop shadow (shadow-2xl)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 50,
              offset: const Offset(0, 25),
              spreadRadius: 0,
            ),
          ],
        ),
        // Padding: Fixed internal gutter of 2rem (32px) on all sides
        padding: const EdgeInsets.all(32),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main Content Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Component: Premium Badge
                Container(
                  // Architecture: Inline Flexbox pill
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2), // px-2 py-0.5
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade400, // Yellow-400
                    // Geometry: Full Round
                    borderRadius: BorderRadius.circular(9999), // rounded-full
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: BackdropFilter(
                      // Effect: Subtle backdrop-blur-sm
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon: Sparkles at 1rem (w-4 h-4)
                          const Icon(
                            Icons.auto_awesome, // Sparkles icon
                            size: 16, // 1rem
                            color: Colors.black87, // Dark color for visibility
                          ),
                          const SizedBox(width: 6),
                          // Typography: "PREMIUM UPGRADE"
                          Text(
                            'PREMIUM UPGRADE',
                            style: GoogleFonts.inter(
                              fontSize: 10, // 0.625rem (10px)
                              fontWeight: FontWeight
                                  .w700, // Bold weight (reduced from Black)
                              color: Colors
                                  .black87, // Dark text for better visibility
                              letterSpacing: 0.2, // 0.2em tracking
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24), // space-y-6 equivalent

                // Typography and Messaging Block
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Headline: "Muawin PRO"
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Muawin ',
                            style: GoogleFonts.poppins(
                              fontSize: 30, // 1.875rem (30px)
                              fontWeight: FontWeight
                                  .w700, // Bold weight (reduced from Black)
                              color: Colors.white, // Pure White (#FFFFFF)
                              letterSpacing:
                                  -0.025, // -0.025em (tracking-tight)
                              height: 1.0, // leading-none
                            ),
                          ),
                          TextSpan(
                            text: 'PRO',
                            style: GoogleFonts.poppins(
                              fontSize: 30, // 1.875rem (30px)
                              fontWeight: FontWeight
                                  .w700, // Bold weight (reduced from Black)
                              color: Colors.yellow, // Yellow-400 (#FACC15)
                              letterSpacing:
                                  -0.025, // -0.025em (tracking-tight)
                              height: 1.0, // leading-none
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtitle
                    Container(
                      constraints:
                          const BoxConstraints(maxWidth: 220), // 13.75rem
                      child: Text(
                        'Unlock elite features and save more on every task.',
                        style: GoogleFonts.poppins(
                          fontSize: 14, // 0.875rem
                          fontWeight: FontWeight.w500, // Medium weight
                          color: Colors.grey.shade300, // slate-300
                          height: 1.4, // Better line height for readability
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24), // space-y-6

                // Feature Checklist: Tactical List
                Column(
                  children: [
                    // Feature items with 0.5rem (8px) spacing
                    _buildFeatureItem('Priority customer support'),
                    const SizedBox(height: 8),
                    _buildFeatureItem('Exclusive discounts on services'),
                    const SizedBox(height: 8),
                    _buildFeatureItem('Advanced booking features'),
                    const SizedBox(height: 8),
                    _buildFeatureItem('Premium verification badges'),
                  ],
                ),
                const SizedBox(height: 32), // space-y-8

                // Primary CTA: Upgrade Now Button
                Container(
                  width: double.infinity, // Full-width block button
                  height: 56, // 3.5rem (56px)
                  decoration: BoxDecoration(
                    color: Colors.yellow, // Solid Yellow-400 (reverted)
                    borderRadius: BorderRadius.circular(16), // 1rem (16px)
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withValues(
                            alpha: 0.2), // shadow-yellow-400/20 (reverted)
                        blurRadius: 8, // shadow-lg equivalent
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const MuawinProOverlay(),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: Text(
                          'Upgrade Now',
                          style: GoogleFonts.inter(
                            // Changed to premium Inter font
                            fontSize: 16, // text-base
                            fontWeight: FontWeight
                                .w700, // Bold weight (reduced from Black)
                            color: Colors
                                .grey.shade900, // Deep Dark Gray (slate-900)
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Trophy Icon: Absolutely anchored trophy
            Positioned(
              top: 50,
              right: 0,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Icon(
                        Icons.emoji_events, // Trophy icon
                        size: 160, // 10rem wide
                        color: Colors.white.withValues(
                            alpha: 0.1), // Pure White at 10% opacity
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Row(
      children: [
        // Check Icon Anchor: Fixed 1rem x 1rem perfect circle
        Container(
          width: 16, // 1rem
          height: 16, // 1rem
          decoration: const BoxDecoration(
            color: Colors.yellow, // Solid Yellow-400
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 10, // 0.625rem (w-2.5 h-2.5)
            color: Colors.black, // Pure black for maximum visibility
            // stroke-[4px] equivalent would be thicker stroke, but Icon doesn't support this directly
          ),
        ),
        const SizedBox(width: 12), // 0.5rem gap
        // Feature Text
        Text(
          feature,
          style: GoogleFonts.inter(
            // Changed to premium Inter font
            fontSize: 11, // 0.68rem (11px)
            fontWeight: FontWeight.w500, // Medium weight (reduced from Bold)
            color: Colors.grey.shade200, // slate-200
          ),
        ),
      ],
    );
  }
}

// Featured Ads Section
class _FeaturedAdsSection extends StatelessWidget {
  const _FeaturedAdsSection({this.featuredAd});

  final Map<String, dynamic>? featuredAd;

  @override
  Widget build(BuildContext context) {
    if (featuredAd == null) {
      return const SizedBox.shrink();
    }

    // Extract data from featured ad
    final isProvider = featuredAd!['provider_id'] != null;
    final providerData = featuredAd!['providers'] as Map<String, dynamic>?;
    final vendorData = featuredAd!['vendors'] as Map<String, dynamic>?;
    final providerName = providerData?['profiles']?['full_name'];
    final vendorName = vendorData?['business_name'];
    final providerCategory = providerData?['service_category'];
    final vendorCategory = vendorData?['business_type'];
    final providerRating = providerData?['rating'];
    final vendorRating = vendorData?['rating'];
    final name = (isProvider == true && providerData != null)
        ? (providerName ?? 'Featured Professional')
        : (vendorName ?? 'Featured Professional');
    final category = (isProvider == true && providerData != null)
        ? (providerCategory ?? 'Service Professional')
        : (vendorCategory ?? 'Service Professional');
    final tagline = featuredAd!['tagline'] ?? 'Trusted Expert Near You';
    final rating = (isProvider == true && providerData != null)
        ? (providerRating?.toString() ?? '5.0')
        : (vendorRating?.toString() ?? '5.0');
    // Get distance from provider/vendor data
    final distance = providerData?['distance']?.toString() ??
        vendorData?['distance']?.toString() ??
        (providerData?['city'] != null
            ? providerData!['city'].toString()
            : vendorData?['city'] != null
                ? vendorData!['city'].toString()
                : 'Nearby');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF047A62), Color(0xFF035C4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.campaign_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Provider of the Day',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Top-rated professional in your area',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Provider/Vendor Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Category
                  Text(
                    category,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Tagline
                  Text(
                    tagline,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Rating and Distance
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$distance km',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      // Arrow button
                      GestureDetector(
                        onTap: () {
                          if (featuredAd == null) return;

                          final isProvider = featuredAd!['provider_id'] != null;

                          if (isProvider) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerProviderProfileScreen(
                                  providerId:
                                      featuredAd!['provider_id']?.toString() ??
                                          '',
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerVendorProfileScreen(
                                  vendor: featuredAd!['vendors'],
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF047A62),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
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
    );
  }
}

class _VendorNearbyCard extends StatelessWidget {
  const _VendorNearbyCard({required this.primary, required this.index});

  final Color primary;
  final int index;

  @override
  Widget build(BuildContext context) {
    // TODO: Connect to Supabase
    final List<Map<String, dynamic>> vendors = [];

    // Handle empty vendors list to prevent RangeError
    if (vendors.isEmpty) {
      return Container(); // Return empty container if no vendors
    }

    final vendor = vendors[index % vendors.length];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerVendorProfileScreen(vendor: vendor),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(vendor['avatar'] as String),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor['name'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vendor['category'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        vendor['rating'].toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        vendor['distance'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Status indicator on the far right
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: vendor['statusColor'] as Color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                vendor['status'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
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

        // Urdu to English mapping for chatbot
        final urduChatPhrases = {
          'مجھے مدد چاہیے': 'I need help',
          'خانہ دار بھیجو': 'Send a maid',
          'ڈرائیور چاہیے': 'I need a driver',
          'استاد چاہیے': 'I need a tutor',
          'باورچی بھیجو': 'Send a cook',
          'باغبان چاہیے': 'I need a gardener',
          'قیمت بتاؤ': 'Tell me the price',
          'بکنگ کرو': 'Make a booking',
          'مدد کرو': 'Please help me',
          'منسوخ کرو': 'Cancel my booking',
          'تبدیل کرو': 'Reschedule my booking',
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
        padding: const EdgeInsets.all(20),
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
              height: _isChatListening ? 80 : 0,
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

/// Custom painter for the geometric dot matrix background pattern
class _HeaderPatternPainter extends CustomPainter {
  final Color color;

  _HeaderPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    const double spacing = 18.0;
    const double dotSize = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
