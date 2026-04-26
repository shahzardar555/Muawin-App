import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/vendor_notification_test_helper.dart';

/// Quick demo to test vendor notification badge
class VendorNotificationQuickTest extends StatelessWidget {
  const VendorNotificationQuickTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Badge Quick Test'),
        backgroundColor: const Color(0xFF047A62),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Vendor Notification Badge Test',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF047A62).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF047A62)),
              ),
              child: Column(
                children: [
                  Text(
                    'Current Unread Count: ${VendorNotificationTestHelper.getVendorUnreadCount()}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF047A62),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ElevatedButton(
                    onPressed: () {
                      VendorNotificationTestHelper.addVendorTestNotifications();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added 5 test notifications!'),
                          backgroundColor: Color(0xFF047A62),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047A62),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Test Notifications'),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ElevatedButton(
                    onPressed: () {
                      VendorNotificationTestHelper.clearVendorNotifications();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cleared all notifications!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Instructions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text('1. Click "Add Test Notifications" to add 5 notifications\n2. The badge should show "5" in the vendor home screen\n3. Click "Clear All" to reset to zero\n4. Test different notification counts and badge display'),
          ],
        ),
      ),
    );
  }
}
