import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'customer_vendor_profile.dart';
import 'customer_home_screen.dart';
import 'customer_jobs_screen.dart';
import 'post_job_screen.dart';
import 'customer_messages_screen.dart';
import 'customer_profile_screen.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'services/database_service.dart';

class VendorResultsScreen extends StatefulWidget {
  const VendorResultsScreen({super.key, required this.category});

  final String category;

  @override
  State<VendorResultsScreen> createState() => _VendorResultsScreenState();
}

class _VendorResultsScreenState extends State<VendorResultsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = true;
  String? _error;

  // Filter state
  bool _showHighRated = false;
  double _minRating = 0.0;
  double _maxDistance = 5.0;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final vendors = await _databaseService.getVendors(
        businessType: widget.category,
      );
      setState(() {
        _vendors = vendors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredVendors {
    return _vendors.where((vendor) {
      final rating = (vendor['rating'] ?? 0.0) as num;
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
      body: RefreshIndicator(
        onRefresh: _loadVendors,
        child: Column(
          children: [
            // Header with filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFF047A62)),
              child: Row(
                children: [
                  Text(
                    '${_filteredVendors.length} Vendors found near you',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.filter_list, color: Colors.white),
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
                                      'Minimum Rating: ${_minRating.toStringAsFixed(1)}'),
                                  Slider(
                                    value: _minRating,
                                    min: 0.0,
                                    max: 5.0,
                                    divisions: 10,
                                    onChanged: (value) =>
                                        setModalState(() => _minRating = value),
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
            // Vendor list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF047A62)))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 64, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load vendors',
                                style: GoogleFonts.poppins(
                                    fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadVendors,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF047A62)),
                                child: const Text('Retry',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : _filteredVendors.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.store_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No vendors found',
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
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredVendors.length,
                              itemBuilder: (context, index) {
                                final vendor = _filteredVendors[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CustomerVendorProfileScreen(
                                                vendor: vendor),
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
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 40,
                                          backgroundImage: NetworkImage(
                                            vendor['profiles']
                                                    ?['profile_image_url'] ??
                                                'https://ui-avatars.com/api/?name=${Uri.encodeComponent(vendor['business_name'] ?? 'V')}&background=047A62&color=fff',
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                vendor['business_name'] ??
                                                    vendor['profiles']
                                                        ?['full_name'] ??
                                                    'Unknown',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                vendor['business_type'] ?? '',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star,
                                                      size: 16,
                                                      color: Colors.amber),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    (vendor['rating'] ?? 0.0)
                                                        .toString(),
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
                                                      size: 16,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    vendor['area'] ??
                                                        vendor['city'] ??
                                                        '',
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
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Open',
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
                              },
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
                MaterialPageRoute(builder: (_) => const CustomerHomeScreen()));
          } else if (i == 1) {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerJobsScreen()));
          } else if (i == 2) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PostJobScreen()));
          } else if (i == 3) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CustomerMessagesScreen()));
          } else if (i == 4) {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const CustomerProfileScreen()));
          }
        },
      ),
    );
  }
}
