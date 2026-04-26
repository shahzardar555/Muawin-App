import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'dart:io';

import 'customer_home_screen.dart';

import 'customer_jobs_screen.dart';

import 'post_job_screen.dart';

import 'customer_messages_screen.dart';

import 'customer_profile_screen.dart';

import 'customer_provider_profile.dart';

import 'services/provider_data_service.dart';

import 'package:muawin_app/widgets/bottom_navigation_bar.dart';

class ServiceProvidersResultsScreen extends StatefulWidget {
  const ServiceProvidersResultsScreen({super.key, required this.category});

  final String category;

  @override
  State<ServiceProvidersResultsScreen> createState() =>
      _ServiceProvidersResultsScreenState();
}

class _ServiceProvidersResultsScreenState
    extends State<ServiceProvidersResultsScreen> {
  // Filter state
  bool _showHighRated = false;
  double _maxPrice = 1000.0;
  double _minRating = 0.0;
  double _minExperience = 0.0;
  double _maxDistance = 5.0;

  // Real provider data state
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;

  // Sample provider IDs for demonstration
  final List<String> _providerIds = [
    'provider_001',
    'provider_002',
    'provider_003',
    'provider_004',
    'provider_005',
  ];

  @override
  void initState() {
    super.initState();
    _loadProvidersData();
  }

  Future<void> _loadProvidersData() async {
    try {
      final List<Map<String, dynamic>> loadedProviders = [];

      for (final providerId in _providerIds) {
        try {
          final data = await ProviderDataService.getProviderData(providerId);
          loadedProviders.add(data);
        } catch (e) {
          debugPrint('Error loading provider $providerId: $e');
          // Add fallback data for this provider
          loadedProviders.add(_createFallbackProvider(providerId));
        }
      }

      setState(() {
        _providers = loadedProviders;
        _isLoading = false;
      });

      // Listen for real-time service details changes
      ProviderDataService.addProviderDataChangeListener((updatedData) {
        if (mounted) {
          _loadProvidersData(); // Refresh all providers when data changes
        }
      });
    } catch (e) {
      debugPrint('Error loading providers data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _createFallbackProvider(String providerId) {
    final index = _providerIds.indexOf(providerId);
    final experiences = [
      '3 years',
      '5 years',
      '7 years',
      '10 years',
      '12 years'
    ];
    final rates = ['Rs. 400', 'Rs. 500', 'Rs. 600', 'Rs. 700', 'Rs. 800'];

    return {
      'id': providerId,
      'provider_name':
          'Provider ${index + 1}', // Will be updated with real data
      'name': 'Provider ${index + 1}', // Fallback name
      'category': widget.category,
      'rating': 4.5 + (index % 5) * 0.1,
      'distance': '${(1 + index * 0.5).toStringAsFixed(1)} km',
      'experience': experiences[index % experiences.length],
      'hourly_rate': rates[index % rates.length],
      'service_type': widget.category,
      'reviews': 50 + index * 25,
      'about': 'Professional service provider with extensive experience.',
      'service_area': 'Service Area ${index + 1}', // Default service area
      'maps_location':
          'https://maps.google.com/?q=Area${index + 1}', // Default maps location
      'description':
          'Professional ${widget.category.toLowerCase()} services available.',
      'profile_image_path': null, // Will be updated with real data
    };
  }

  // Helper method to build profile image with cross-platform support
  Widget _buildProfileImage(Map<String, dynamic> provider) {
    if (provider['profile_image_path'] != null) {
      final profileImagePath = provider['profile_image_path'] as String;

      if (profileImagePath.startsWith('blob:')) {
        // Web: Use Image.network with blob URL
        return Image.network(
          profileImagePath,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(provider);
          },
        );
      } else {
        // Mobile: Use Image.file
        return Image.file(
          File(profileImagePath),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(provider);
          },
        );
      }
    } else {
      return _buildDefaultAvatar(provider);
    }
  }

  Widget _buildDefaultAvatar(Map<String, dynamic> provider) {
    // Generate consistent avatar based on provider ID
    final seed = provider['id'] ?? provider['name'] ?? 'default';
    return ClipOval(
      child: Image.network(
        'https://picsum.photos/seed/$seed/100/100',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 50,
            height: 50,
            color: Colors.grey[300],
            child: Icon(Icons.person, color: Colors.grey[600], size: 24),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredProviders {
    return _providers.where((provider) {
      // Safe parsing with null checks
      final rating = provider['rating'] != null
          ? (provider['rating'] is String
              ? double.tryParse(provider['rating'].toString()) ?? 0.0
              : (provider['rating'] as num?)?.toDouble() ?? 0.0)
          : 0.0;

      final hourlyRateStr = provider['hourly_rate'] as String? ?? '0';
      final hourlyRate =
          double.tryParse(hourlyRateStr.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0;

      final experienceStr = provider['experience'] as String? ?? '0 years';
      final experience =
          double.tryParse(experienceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0;

      final distanceStr = provider['distance'] as String? ?? '0 km';
      final distance =
          double.tryParse(distanceStr.replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0;

      if (_showHighRated && rating < 4.5) return false;
      if (hourlyRate > _maxPrice) return false;
      if (rating < _minRating) return false;
      if (experience < _minExperience) return false;
      if (distance > _maxDistance) return false;

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF047A62),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Results for "${widget.category}"',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF047A62)),
            )
          : Column(
              children: [
                // Header with filters
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16), // Reduced horizontal padding
                  decoration: const BoxDecoration(color: Color(0xFF047A62)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_filteredProviders.length} Providers found',
                          style: GoogleFonts.poppins(
                            fontSize: 15, // Reduced from 16
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8), // Reduced spacing
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(36, 36), // Fixed size button
                          padding: const EdgeInsets.all(8), // Reduced padding
                        ),
                        child: const Icon(Icons.filter_list,
                            color: Colors.white, size: 20),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => StatefulBuilder(
                              builder: (context, setModalState) =>
                                  SingleChildScrollView(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Filters',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      CheckboxListTile(
                                        title: const Text(
                                            'Show only high rated (4.5+)'),
                                        value: _showHighRated,
                                        onChanged: (value) => setModalState(
                                            () => _showHighRated = value!),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                          'Maximum Price: Rs. ${_maxPrice.toStringAsFixed(0)}'),
                                      Slider(
                                        value: _maxPrice,
                                        min: 1.0,
                                        max: 20000.0,
                                        onChanged: (value) => setModalState(
                                            () => _maxPrice = value),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                          'Minimum Rating: ${_minRating.toStringAsFixed(1)}'),
                                      Slider(
                                        value: _minRating,
                                        min: 0.0,
                                        max: 5.0,
                                        divisions: 10,
                                        onChanged: (value) => setModalState(
                                            () => _minRating = value),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                          'Minimum Experience: ${_minExperience.toStringAsFixed(0)} years'),
                                      Slider(
                                        value: _minExperience,
                                        min: 0.0,
                                        max: 10.0,
                                        divisions: 10,
                                        onChanged: (value) => setModalState(
                                            () => _minExperience = value),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                          'Maximum Distance: ${_maxDistance.toStringAsFixed(1)} km'),
                                      Slider(
                                        value: _maxDistance,
                                        min: 0.0,
                                        max: 5.0,
                                        divisions: 10,
                                        onChanged: (value) => setModalState(
                                            () => _maxDistance = value),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          setState(() {}); // Refresh the list
                                        },
                                        child: const Text('Apply Filters'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Providers list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProviders.length,
                    itemBuilder: (context, index) {
                      final provider = _filteredProviders[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerProviderProfileScreen(
                                  provider: provider),
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
                                    child: _buildProfileImage(provider),
                                  ),
                                  const SizedBox(width: 16),
                                  // Provider details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              provider['provider_name'] ??
                                                  provider['name'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            // Badges - Show only 1 badge per provider to avoid clutter
                                            // Top Rated Badge (highest priority)
                                            if (provider['rating'] != null &&
                                                (provider['rating'] is num
                                                        ? (provider['rating']
                                                                as num)
                                                            .toDouble()
                                                        : double.tryParse(provider[
                                                                    'rating']
                                                                .toString()) ??
                                                            0.0) >=
                                                    4.9)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    left: 6),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                      0xFFFFF7ED), // Yellow-100
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.emoji_events,
                                                      color: Color(
                                                          0xFFA16207), // Yellow-700
                                                      size: 10,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      'Top Rated',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 9,
                                                        color: const Color(
                                                            0xFFA16207),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            // Expert Badge (second priority - only if not top rated)
                                            else if (provider['rating'] !=
                                                    null &&
                                                (provider['rating'] is num
                                                        ? (provider['rating']
                                                                as num)
                                                            .toDouble()
                                                        : double.tryParse(provider[
                                                                    'rating']
                                                                .toString()) ??
                                                            0.0) >=
                                                    4.5 &&
                                                double.parse(((provider[
                                                                    'experience']
                                                                as String?) ??
                                                            '0 years')
                                                        .replaceAll(
                                                            ' years', '')) >=
                                                    5)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    left: 6),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                      0xFFEFF6FF), // Blue-100
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.workspace_premium,
                                                      color: Color(
                                                          0xFF1E40AF), // Blue-700
                                                      size: 10,
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      'Expert',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 9,
                                                        color: const Color(
                                                            0xFF1E40AF),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              provider['rating'] != null
                                                  ? (provider['rating'] is num
                                                      ? (provider['rating']
                                                              as num)
                                                          .toString()
                                                      : provider['rating']
                                                          .toString())
                                                  : 'N/A',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.amber,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            const Icon(Icons.location_on,
                                                color: Colors.grey, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              provider['distance'] ??
                                                  'Unknown distance',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${provider['experience'] ?? 'N/A'} experience',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Price display at bottom right
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  child: Text(
                                    'Rs. ${((provider['hourly_rate'] as String?) ?? '0').replaceAll('Rs. ', '')}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green.shade800,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: MuawinBottomNavigationBar(
        currentIndex: 2, // Post Job tab selected
        onItemTapped: (i) {
          if (i == 0) {
            // Navigate to Home screen
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomerHomeScreen(),
            ));
          } else if (i == 1) {
            // Navigate to My Jobs screen
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomerJobsScreen(),
            ));
          } else if (i == 2) {
            // Navigate to Post Job screen
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const PostJobScreen(),
            ));
          } else if (i == 3) {
            // Navigate to Messages screen
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomerMessagesScreen(),
            ));
          } else if (i == 4) {
            // Navigate to Profile screen
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const CustomerProfileScreen(),
            ));
          }
        },
      ),
    );
  }
}
