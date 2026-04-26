import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NotificationSettingsService _settingsService;
  String _userType = 'customer'; // Default
  Map<String, bool> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _settingsService = NotificationSettingsService();
    _loadUserTypeAndSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserTypeAndSettings() async {
    // Get user type from navigation arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        setState(() {
          _userType = args;
        });
      }
    });

    // Initialize settings service with user type
    await _settingsService.initialize(_userType);

    // Load all settings
    final settings = await _settingsService.getAllSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0FDF4),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF047A62),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF047A62),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          _buildUserTypeSelector(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesTab(),
                _buildAdvancedTab(),
                _buildEmergencyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Type',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildUserTypeOption('customer', 'Customer'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUserTypeOption('provider', 'Service Provider'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildUserTypeOption('vendor', 'Business Owner'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeOption(String type, String label) {
    final isSelected = _userType == type;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _userType = type;
          _isLoading = true;
        });

        await _settingsService.initialize(type);
        await _loadUserTypeAndSettings();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF047A62)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF047A62)
                : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF2C3E50),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Notification Categories',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),
        _buildCategorySwitch('jobs', 'Job Notifications', Icons.work_rounded),
        _buildCategorySwitch(
            'payments', 'Payment Notifications', Icons.payments_rounded),
        _buildCategorySwitch(
            'reviews', 'Review Notifications', Icons.star_rounded),
        _buildCategorySwitch(
            'alerts', 'Alert Notifications', Icons.notifications_rounded),
        _buildCategorySwitch('verification', 'Verification Notifications',
            Icons.verified_user_rounded),
        _buildCategorySwitch(
            'ads', 'Advertisement Notifications', Icons.campaign_rounded),
        _buildCategorySwitch('chat', 'Chat Notifications', Icons.chat_rounded),
        _buildCategorySwitch(
            'calls', 'Call Notifications', Icons.phone_rounded),
        _buildCategorySwitch(
            'documents', 'Document Notifications', Icons.description_rounded),
        _buildCategorySwitch(
            'system', 'System Notifications', Icons.system_update_rounded),
      ],
    );
  }

  Widget _buildCategorySwitch(String key, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: _settings['${key}_enabled'] == true
                  ? const Color(0xFF047A62)
                  : Colors.grey.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
        value: _settings['${key}_enabled'] ?? true,
        onChanged: (value) async {
          setState(() {
            _settings['${key}_enabled'] = value;
          });
          await _settingsService.setCategoryEnabled(key, value);
        },
        activeThumbColor: const Color(0xFF047A62),
        inactiveThumbColor: Colors.grey.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Advanced Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),
        _buildAdvancedSwitch('priority_filter', 'Priority Filter',
            'Show only high priority notifications'),
        _buildAdvancedSwitch(
            'sound_enabled', 'Sound Effects', 'Enable notification sounds'),
        _buildAdvancedSwitch(
            'haptic_enabled', 'Haptic Feedback', 'Enable vibration feedback'),
      ],
    );
  }

  Widget _buildAdvancedSwitch(String key, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2C3E50),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.withValues(alpha: 0.8),
          ),
        ),
        value: _settings[key] ?? true,
        onChanged: (value) async {
          setState(() {
            _settings[key] = value;
          });
          await _settingsService.setSetting(key, value);
        },
        activeThumbColor: const Color(0xFF047A62),
        inactiveThumbColor: Colors.grey.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildEmergencyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Emergency Settings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.emergency_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Emergency Banner Overlays',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Emergency notifications appear as floating overlays at the top of your screen for immediate attention.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(
                  'Enable Emergency Banners',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                subtitle: Text(
                  'Show critical alerts as floating overlays',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.withValues(alpha: 0.8),
                  ),
                ),
                value: _settings['emergency_banners_enabled'] ?? true,
                onChanged: (value) async {
                  setState(() {
                    _settings['emergency_banners_enabled'] = value;
                  });
                  await _settingsService.setEmergencyBannersEnabled(value);
                },
                activeThumbColor: Colors.red,
                inactiveThumbColor: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _settingsService.resetToDefaults();
                  await _loadUserTypeAndSettings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings reset to defaults'),
                        backgroundColor: Color(0xFF047A62),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Reset All Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
