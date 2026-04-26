import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'customer_vendor_profile.dart';
import 'customer_home_screen.dart';
import 'customer_jobs_screen.dart';
import 'post_job_screen.dart';
import 'customer_messages_screen.dart';
import 'customer_profile_screen.dart';
import 'widgets/bottom_navigation_bar.dart';

class VendorResultsScreen extends StatefulWidget {
  const VendorResultsScreen({super.key, required this.category});

  final String category;

  @override
  State<VendorResultsScreen> createState() => _VendorResultsScreenState();
}

class _VendorResultsScreenState extends State<VendorResultsScreen> {
  // Sample vendor data
  final List<Map<String, dynamic>> _vendors = [
    {
      'name': 'Fresh Market Grocery',
      'category': 'Supermarket',
      'rating': 4.8,
      'distance': '0.3 km',
      'experience': '5 years',
      'hourlyRate': 'Rs. 600',
      'dailyRate': 'Rs. 9000',
      'avatar': 'https://picsum.photos/100/100?random=1',
      'reviews': 156,
      'about':
          'One-stop shop for all your grocery needs. Fresh produce, imported items, and daily essentials at competitive prices.',
      'status': 'OPEN',
      'statusColor': Colors.green,
    },
    {
      'name': 'Corner Dairy Shop',
      'category': 'Milkshop',
      'rating': 4.6,
      'distance': '0.8 km',
      'experience': '4 years',
      'hourlyRate': 'Rs. 500',
      'dailyRate': 'Rs. 8000',
      'avatar': 'https://picsum.photos/100/100?random=2',
      'reviews': 85,
      'about':
          'Premium quality fresh milk and dairy products delivered daily. Trusted by thousands of customers for purity and freshness.',
      'status': 'OPEN',
      'statusColor': Colors.green,
    },
    {
      'name': 'City Bakery & Cafe',
      'category': 'Bakery',
      'rating': 4.9,
      'distance': '1.2 km',
      'experience': '6 years',
      'hourlyRate': 'Rs. 550',
      'dailyRate': 'Rs. 8500',
      'avatar': 'https://picsum.photos/100/100?random=3',
      'reviews': 112,
      'about':
          'Artisan breads, custom cakes, and fresh pastries daily. Specializing in celebration cakes and traditional baked goods.',
      'status': 'CLOSING SOON',
      'statusColor': Colors.orange,
    },
    {
      'name': 'Premium Meat Shop',
      'category': 'Meatshop',
      'rating': 4.7,
      'distance': '2.1 km',
      'experience': '3 years',
      'hourlyRate': 'Rs. 450',
      'dailyRate': 'Rs. 7000',
      'avatar': 'https://picsum.photos/100/100?random=4',
      'reviews': 42,
      'about':
          'Fresh halal meat daily. Specializing in beef, mutton, and chicken cuts. Clean and hygienic processing.',
      'status': 'CLOSED',
      'statusColor': Colors.red,
    },
    {
      'name': 'Pure Water Station',
      'category': 'Drinking Water Plant',
      'rating': 4.5,
      'distance': '3.5 km',
      'experience': '4 years',
      'hourlyRate': 'Rs. 300',
      'dailyRate': 'Rs. 5000',
      'avatar': 'https://picsum.photos/100/100?random=5',
      'reviews': 68,
      'about':
          'Premium quality mineral water with state-of-the-art purification. Home delivery available. ISO certified facility.',
      'status': 'OPEN',
      'statusColor': Colors.green,
    },
    {
      'name': 'Quick Gas Services',
      'category': 'Gas Cylinder Shop',
      'rating': 4.4,
      'distance': '2.8 km',
      'experience': '6 years',
      'hourlyRate': 'Rs. 200',
      'dailyRate': 'Rs. 3000',
      'avatar': 'https://picsum.photos/100/100?random=6',
      'reviews': 92,
      'about':
          'Authorized dealer of LPG cylinders. Quick refill service and home delivery. All safety standards maintained.',
      'status': 'CLOSED',
      'statusColor': Colors.red,
    },
    {
      'name': 'Green Grocer Market',
      'category': 'Fruits and Vegetables Shop',
      'rating': 4.8,
      'distance': '1.5 km',
      'experience': '3 years',
      'hourlyRate': 'Rs. 400',
      'dailyRate': 'Rs. 6000',
      'avatar': 'https://picsum.photos/100/100?random=7',
      'reviews': 78,
      'about':
          'Farm-fresh fruits and vegetables delivered daily. Organic options available. Supporting local farmers.',
      'status': 'OPEN',
      'statusColor': Colors.green,
    },
    {
      'name': 'Organic Green Market',
      'category': 'Supermarket',
      'rating': 4.8,
      'distance': '4.2 km',
      'experience': '7 years',
      'hourlyRate': 'Rs. 650',
      'dailyRate': 'Rs. 9500',
      'avatar': 'https://picsum.photos/100/100?random=8',
      'reviews': 189,
      'about':
          'Organic and natural products. Wide selection of health foods, supplements, and eco-friendly household items.',
      'status': 'CLOSING SOON',
      'statusColor': Colors.orange,
    },
    {
      'name': 'Daily Dairy Express',
      'category': 'Milkshop',
      'rating': 4.5,
      'distance': '3.1 km',
      'experience': '2 years',
      'hourlyRate': 'Rs. 480',
      'dailyRate': 'Rs. 7500',
      'avatar': 'https://picsum.photos/100/100?random=9',
      'reviews': 56,
      'about':
          'Fresh dairy products delivered to your doorstep. Milk, yogurt, cheese, and butter from local farms.',
      'status': 'CLOSED',
      'statusColor': Colors.red,
    },
    {
      'name': 'Sweet Treats Bakery',
      'category': 'Bakery',
      'rating': 4.6,
      'distance': '2.5 km',
      'experience': '5 years',
      'hourlyRate': 'Rs. 520',
      'dailyRate': 'Rs. 8200',
      'avatar': 'https://picsum.photos/100/100?random=10',
      'reviews': 94,
      'about':
          'Delicious pastries, cakes, and bread. Custom orders for birthdays, weddings, and special occasions.',
      'status': 'OPEN',
      'statusColor': Colors.green,
    },
    {
      'name': 'Halal Meat Center',
      'category': 'Meatshop',
      'rating': 4.7,
      'distance': '1.8 km',
      'experience': '8 years',
      'hourlyRate': 'Rs. 470',
      'dailyRate': 'Rs. 7200',
      'avatar': 'https://picsum.photos/100/100?random=11',
      'reviews': 103,
      'about':
          'Certified halal meat supplier. Fresh cuts daily with home delivery service available.',
      'status': 'CLOSING SOON',
      'statusColor': Colors.orange,
    },
    {
      'name': 'Crystal Water Supply',
      'category': 'Drinking Water Plant',
      'rating': 4.3,
      'distance': '4.5 km',
      'experience': '5 years',
      'hourlyRate': 'Rs. 280',
      'dailyRate': 'Rs. 4500',
      'avatar': 'https://picsum.photos/100/100?random=12',
      'reviews': 45,
      'about':
          'Clean drinking water with multi-stage purification. Bulk orders and subscription plans available.',
      'status': 'CLOSED',
      'statusColor': Colors.red,
    },
    {
      'name': 'Emergency Gas Hub',
      'category': 'Gas Cylinder Shop',
      'rating': 4.5,
      'distance': '3.8 km',
      'experience': '7 years',
      'hourlyRate': 'Rs. 220',
      'dailyRate': 'Rs. 3200',
      'avatar': 'https://picsum.photos/100/100?random=13',
      'reviews': 87,
      'about':
          '24/7 gas cylinder service. Emergency deliveries and cylinder exchange program available.',
      'status': 'OPEN',
      'statusColor': Colors.green,
    },
    {
      'name': 'Fresh Harvest Produce',
      'category': 'Fruits and Vegetables Shop',
      'rating': 4.9,
      'distance': '0.9 km',
      'experience': '4 years',
      'hourlyRate': 'Rs. 380',
      'dailyRate': 'Rs. 5800',
      'avatar': 'https://picsum.photos/100/100?random=14',
      'reviews': 121,
      'about':
          'Premium quality fruits and vegetables. Seasonal produce, exotic imports, and organic options.',
      'status': 'CLOSING SOON',
      'statusColor': Colors.orange,
    },
  ];

  // Filter state
  bool _showHighRated = false;
  double _minRating = 0.0;
  double _maxDistance = 5.0;

  List<Map<String, dynamic>> get _filteredVendors {
    return _vendors.where((vendor) {
      // Filter by category
      if (vendor['category'] != widget.category) return false;

      final rating = vendor['rating'] as double;

      final distanceStr = vendor['distance'] as String;
      final distance = double.parse(distanceStr.replaceAll(' km', ''));

      if (_showHighRated && rating < 4.5) return false;
      if (rating < _minRating) return false;
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
      body: Column(
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
                                  title:
                                      const Text('Show only high rated (4.5+)'),
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
                                  onChanged: (value) =>
                                      setModalState(() => _maxDistance = value),
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
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredVendors.length,
              itemBuilder: (context, index) {
                final vendor = _filteredVendors[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerVendorProfileScreen(vendor: vendor),
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
                          backgroundImage: NetworkImage(vendor['avatar']),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendor['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vendor['category'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.amber),
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
                                    vendor['distance'],
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
                            color: vendor['statusColor'],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            vendor['status'],
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
