import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/vendor_notification_bell.dart';

/// Test screen to verify vendor notification bell visual styling
class VendorNotificationStylingTest extends StatelessWidget {
  const VendorNotificationStylingTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Notification Styling Test'),
        backgroundColor: const Color(0xFF047A62),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Vendor Notification Bell Visual Test',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          
          // Test with different background colors
          _buildStylingTestCard(
            'Primary Header Background',
            const Color(0xFF047A62),
            Colors.white,
          ),
          
          _buildStylingTestCard(
            'Dark Header Background',
            const Color(0xFF1A1A1A),
            Colors.white,
          ),
          
          _buildStylingTestCard(
            'Blue Header Background',
            const Color(0xFF2563EB),
            Colors.white,
          ),
          
          _buildStylingTestCard(
            'Light Header Background',
            const Color(0xFFF3F4F6),
            const Color(0xFF1F2937),
          ),
          
          const SizedBox(height: 20),
          
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
                  'Visual Improvements Made:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  '✅ Created VendorNotificationBell widget',
                  '✅ Uses theme-aware onPrimary color',
                  '✅ Semi-transparent background (15% opacity)',
                  '✅ Subtle border (30% opacity)',
                  '✅ Brand green badge with theme-aware border',
                  '✅ Proper sizing and positioning',
                  '✅ Maintains functionality while fixing appearance',
                ].map((improvement) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    improvement,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
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
                  'Integration Details:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF047A62),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Replaced generic NotificationBell with VendorNotificationBell\n• Passes onPrimary color from vendor home screen theme\n• Maintains all functionality (tap navigation, unread badge)\n• Fixes visual appearance in colored header backgrounds\n• Ready for production use with proper theming',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylingTestCard(String title, Color backgroundColor, Color onPrimaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Header with background color
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: onPrimaryColor,
                  ),
                ),
                // Test notification bell with this theme
                VendorNotificationBell(
                  receiverType: 'vendor',
                  onPrimary: onPrimaryColor,
                ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Testing VendorNotificationBell with $title theme',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
