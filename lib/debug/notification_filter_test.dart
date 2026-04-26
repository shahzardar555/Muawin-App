import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/notification_screen.dart';

/// Test screen for notification filtering UI
class NotificationFilterTest extends StatelessWidget {
  const NotificationFilterTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Filter Test'),
        backgroundColor: const Color(0xFF047A62),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Notification Filtering UI Test',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),

          // Test button to open notification screen with filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF047A62), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Notification Filtering',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This test opens the NotificationScreen with filtering capabilities. You can:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  '1. Tap the filter icon in the AppBar',
                  '2. Select different filter chips',
                  '3. Apply filters with the Apply button',
                  '4. Reset filters with the Reset button',
                  '5. Switch tabs to see different filter options',
                  '6. Filters persist per tab',
                ].map((instruction) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        instruction,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047A62),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Open Notification Screen',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Filter Features Overview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter Features Overview:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFeatureItem('🎯 Tab-Specific Filters',
                    'Different filter sets for each notification category'),
                _buildFeatureItem('💾 Persistent Settings',
                    'Filters saved per tab using SharedPreferences'),
                _buildFeatureItem('🔄 Combined Filtering',
                    'Multiple filters can be applied simultaneously'),
                _buildFeatureItem('📍 Strategic Placement',
                    'Filter bar positioned between AppBar and TabBar'),
                _buildFeatureItem('✨ Visual Feedback',
                    'Clear indication of active filters and selection counts'),
                _buildFeatureItem('🔧 Easy Reset',
                    'Quick reset button to clear all active filters'),
                _buildFeatureItem('📱 Responsive Design',
                    'Works across different screen sizes'),
                _buildFeatureItem('🎨 Consistent Styling',
                    'Follows existing app design patterns'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Available Filter Types
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Filter Types:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFilterCategory('Universal Filters',
                    ['Unread/Read', 'Today/This Week/This Month']),
                _buildFilterCategory('Jobs Tab',
                    ['Active/Completed/Cancelled/Pending', 'Priority Levels']),
                _buildFilterCategory('Payments Tab',
                    ['Paid/Pending/Failed/Refunded', 'Amount Ranges']),
                _buildFilterCategory('Reviews Tab',
                    ['Rating Levels', 'Positive/Negative/Neutral']),
                _buildFilterCategory(
                    'Alerts Tab', ['Priority Levels', 'Alert Types']),
                _buildFilterCategory(
                    'Chat Tab', ['Read Status', 'Sender Types']),
                _buildFilterCategory(
                    'Calls Tab', ['Call Status', 'Call Types']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCategory(String category, List<String> filters) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF047A62),
            ),
          ),
          const SizedBox(height: 4),
          ...filters.map((filter) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '• $filter',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
