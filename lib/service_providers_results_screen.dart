import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../services/database_service.dart';

import 'customer_home_screen.dart';

import 'package:muawin_app/widgets/bottom_navigation_bar.dart';
import 'customer_provider_profile.dart';

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

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    try {
      final data =
          await DatabaseService().getProviders(category: widget.category);
      if (mounted) {
        setState(() {
          _providers = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading providers data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProviders {
    return _providers.where((provider) {
      final rating = provider['rating'] != null
          ? (provider['rating'] is String
              ? double.tryParse(provider['rating'].toString()) ?? 0.0
              : (provider['rating'] as num?)?.toDouble() ?? 0.0)
          : 0.0;
      if (_showHighRated && rating < 4.5) return false;
      if (rating < _minRating) return false;
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
          : _filteredProviders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No providers found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header with filters
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: const BoxDecoration(color: Color(0xFF047A62)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_filteredProviders.length} Providers found',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(36, 36),
                              padding: const EdgeInsets.all(8),
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
                                              setState(
                                                  () {}); // Refresh the list
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
                          final name =
                              provider['profiles']?['full_name']?.toString() ??
                                  'Provider';
                          final category =
                              provider['service_category']?.toString() ?? '';
                          final rating = (provider['rating'] is String
                              ? double.tryParse(
                                      provider['rating'].toString()) ??
                                  0.0
                              : (provider['rating'] as num?)?.toDouble() ??
                                  0.0);
                          final city = provider['city']?.toString() ?? '';
                          final area = provider['area']?.toString() ?? '';
                          final location =
                              area.isNotEmpty ? '$area, $city' : city;
                          final imageUrl = provider['profiles']
                                  ?['profile_image_url']
                              ?.toString();
                          final isPro = provider['is_pro'] == true;
                          final reviewCount =
                              (provider['review_count'] as num?)?.toInt() ?? 0;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerProviderProfileScreen(
                                    providerId:
                                        provider['id']?.toString() ?? '',
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
                              child: Row(
                                children: [
                                  // Profile image
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 36,
                                        backgroundColor: const Color(0xFF047A62)
                                            .withValues(alpha: 0.1),
                                        backgroundImage: imageUrl != null &&
                                                imageUrl.isNotEmpty
                                            ? NetworkImage(imageUrl)
                                            : null,
                                        child: imageUrl == null ||
                                                imageUrl.isEmpty
                                            ? Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : 'P',
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF047A62),
                                                ),
                                              )
                                            : null,
                                      ),
                                      if (isPro)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFD700),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'PRO',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  // Provider info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          category,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: const Color(0xFF047A62),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star,
                                                size: 14, color: Colors.amber),
                                            const SizedBox(width: 2),
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '($reviewCount reviews)',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (location.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on,
                                                  size: 13, color: Colors.grey),
                                              const SizedBox(width: 2),
                                              Expanded(
                                                child: Text(
                                                  location,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Arrow
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey),
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
          }
        },
      ),
    );
  }
}
