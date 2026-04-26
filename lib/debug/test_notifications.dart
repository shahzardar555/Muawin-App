import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/notification_manager.dart' as nm;

class DebugNotificationsPanel extends StatelessWidget {
  const DebugNotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<nm.NotificationManager>(
      builder: (context, notificationManager, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Debug Notifications Panel',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF047A62),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildDebugButton(
                      'New Job Request',
                      Icons.work_rounded,
                      Colors.blue,
                      () => notificationManager.simulateNotification(
                        nm.NotificationType.jobRequestReceived,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      'Payment Received',
                      Icons.payments_rounded,
                      Colors.green,
                      () => notificationManager.simulateNotification(
                        nm.NotificationType.paymentReceived,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      'New Chat Message',
                      Icons.chat_rounded,
                      Colors.purple,
                      () => notificationManager.simulateNotification(
                        nm.NotificationType.chatMessageReceived,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      'Emergency SOS Alert',
                      Icons.emergency_rounded,
                      Colors.red,
                      () => notificationManager.simulateNotification(
                        nm.NotificationType.emergencySosAlert,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      'Job Completed',
                      Icons.work_rounded,
                      Colors.blue,
                      () => notificationManager.simulateNotification(
                        nm.NotificationType.jobCompleted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      'Profile Verified',
                      Icons.verified_user_rounded,
                      Colors.orange,
                      () => notificationManager.simulateNotification(
                        nm.NotificationType.profileVerificationApproved,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDebugButton(
                      'Featured Ad Expiring',
                      Icons.campaign_rounded,
                      Colors.pink,
                      () => notificationManager.simulateNotification(
                        nm.NotificationType.featuredAdExpiring,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDebugButton(
                      'Customer → Vendor Message',
                      Icons.chat_rounded,
                      Colors.purple,
                      () => notificationManager.sendNotification(
                        receiverId: 'vendor_123',
                        receiverType: 'vendor',
                        type: nm.NotificationType.chatMessageReceived,
                        title: 'New Message from Customer',
                        body:
                            'Hi! I\'m interested in your services. Can we discuss pricing?',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                notificationManager.clearAll('customer');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Customer notifications cleared'),
                                    backgroundColor: Color(0xFF047A62),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                'Clear Customer',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                notificationManager.clearAll('provider');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Provider notifications cleared'),
                                    backgroundColor: Color(0xFF047A62),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                'Clear Provider',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                notificationManager.clearAll('vendor');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Vendor notifications cleared'),
                                    backgroundColor: Color(0xFF047A62),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                              ),
                              child: Text(
                                'Clear Vendor',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
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
      },
    );
  }

  Widget _buildDebugButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
