import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'theme_provider.dart';
import 'language_provider.dart';
import 'widgets/bottom_navigation_bar.dart';
import 'widgets/muawin_pro_badge.dart';
import 'services/pro_status_checker.dart';
import 'customer_home_screen.dart';
import 'customer_jobs_screen.dart';
import 'customer_messages_screen.dart';
import 'logout_splash_screen.dart';
import 'post_job_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<Map<String, String>> _emergencyContacts = [];

  // Profile data state
  String _userName = 'Ahmed Hassan';
  String _userEmail = 'ahmed@example.com';
  String _userPhone = '+92 300 123 4567';
  String _profileImagePath = '';
  Uint8List? _profileImageBytes;
  bool _isProfileLoaded = false;

  // Notification preferences state
  bool _jobUpdatesEnabled = true;
  bool _newMessagesEnabled = true;
  bool _paymentUpdatesEnabled = true;

  // PRO status state
  bool _isProUser = false;
  bool _testProMode = false; // Testing toggle

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadEmergencyContacts();
    _loadUserProfile();
    _checkProStatus();
    _loadTestProMode();
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

  // Load test PRO mode preference
  Future<void> _loadTestProMode() async {
    final prefs = await SharedPreferences.getInstance();
    final testMode = prefs.getBool('test_pro_mode') ?? false;
    if (mounted) {
      setState(() {
        _testProMode = testMode;
      });
    }
  }

  // Toggle test PRO mode
  Future<void> _toggleTestProMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('test_pro_mode', value);

    if (value) {
      // Enable test PRO mode
      await ProStatusChecker.markSubscriptionCompleted(
        subscriptionType: 'pro',
        startDate: '2026-04-26',
        endDate: '2027-04-26',
      );
    } else {
      // Disable test PRO mode
      await ProStatusChecker.clearSubscriptionData();
    }

    if (mounted) {
      setState(() {
        _testProMode = value;
      });
      await _checkProStatus();
    }
  }

  // Load user profile from SharedPreferences
  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Ahmed Hassan';
        _userEmail = prefs.getString('user_email') ?? 'ahmed@example.com';
        _userPhone = prefs.getString('user_phone') ?? '+92 300 123 4567';
        _profileImagePath = prefs.getString('profile_image_path') ?? '';
        _isProfileLoaded = true;
      });

      // Initialize default password if not set
      if (!prefs.containsKey('user_password')) {
        await prefs.setString('user_password', 'password123');
      }

      // Load notification preferences with explicit null checks
      setState(() {
        _jobUpdatesEnabled = prefs.getBool('notification_job_updates') ?? true;
        _newMessagesEnabled =
            prefs.getBool('notification_new_messages') ?? true;
        _paymentUpdatesEnabled =
            prefs.getBool('notification_payment_updates') ?? true;
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // Ensure default values on error
      setState(() {
        _userName = 'Ahmed Hassan';
        _userEmail = 'ahmed@example.com';
        _userPhone = '+92 300 123 4567';
        _profileImagePath = '';
        _isProfileLoaded = true;
        _jobUpdatesEnabled = true;
        _newMessagesEnabled = true;
        _paymentUpdatesEnabled = true;
      });
    }
  }

  // Save notification preferences
  Future<void> _saveNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_job_updates', _jobUpdatesEnabled);
      await prefs.setBool('notification_new_messages', _newMessagesEnabled);
      await prefs.setBool(
          'notification_payment_updates', _paymentUpdatesEnabled);
    } catch (e) {
      debugPrint('Error saving notification preferences: $e');
    }
  }

  // Image picker methods
  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image != null) {
        // For web, we need to handle the image differently
        if (kIsWeb) {
          // For web, we'll store the image bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _profileImagePath = 'web_image_${image.name}';
            _profileImageBytes = bytes;
          });
          await _saveProfileImagePath('web_image_${image.name}');
        } else {
          // For mobile, use the file path
          setState(() {
            _profileImagePath = image.path;
            _profileImageBytes = null;
          });
          await _saveProfileImagePath(image.path);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile picture updated successfully!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      _showErrorSnackBar('Failed to pick image from gallery: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image != null) {
        // For web, we need to handle the image differently
        if (kIsWeb) {
          // For web, we'll store the image bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _profileImagePath = 'web_image_${image.name}';
            _profileImageBytes = bytes;
          });
          await _saveProfileImagePath('web_image_${image.name}');
        } else {
          // For mobile, use the file path
          setState(() {
            _profileImagePath = image.path;
            _profileImageBytes = null;
          });
          await _saveProfileImagePath(image.path);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile picture updated successfully!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      _showErrorSnackBar('Failed to pick image from camera');
    }
  }

  Future<void> _saveProfileImagePath(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', imagePath);
    } catch (e) {
      debugPrint('Error saving profile image path: $e');
    }
  }

  void _showImagePickerOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Change Profile Picture',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? Colors.white
                : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue[600]),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.green[600]),
              title: Text(
                'Take a Photo',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromCamera();
              },
            ),
            if (_profileImagePath.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red[600]),
                title: Text(
                  'Remove Photo',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Provider.of<ThemeProvider>(context, listen: false)
                            .isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _profileImagePath = '';
                    _profileImageBytes = null;
                  });
                  _saveProfileImagePath('');
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to show error snack bar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Password strength helper methods
  String _getPasswordStrength(String password) {
    if (password.length < 8) return 'Weak';
    if (password.length < 12) return 'Medium';
    if (_hasSpecialChars(password) &&
        _hasNumbers(password) &&
        _hasUppercase(password)) {
      return 'Strong';
    }
    return 'Good';
  }

  Color _getPasswordStrengthColor(String password) {
    final strength = _getPasswordStrength(password);
    switch (strength) {
      case 'Weak':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Good':
        return Colors.blue;
      case 'Strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _getPasswordStrengthValue(String password) {
    final strength = _getPasswordStrength(password);
    switch (strength) {
      case 'Weak':
        return 0.25;
      case 'Medium':
        return 0.5;
      case 'Good':
        return 0.75;
      case 'Strong':
        return 1.0;
      default:
        return 0.0;
    }
  }

  bool _hasSpecialChars(String password) {
    return password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  bool _hasNumbers(String password) {
    return password.contains(RegExp(r'[0-9]'));
  }

  bool _hasUppercase(String password) {
    return password.contains(RegExp(r'[A-Z]'));
  }

  void _addEmergencyContact(String name, String phone) {
    setState(() {
      _emergencyContacts.add({'name': name, 'phone': phone});
    });
    _saveEmergencyContacts();
  }

  void _removeEmergencyContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
    _saveEmergencyContacts();
  }

  void _loadEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('emergency_contacts');

      if (contactsJson != null) {
        // Parse the JSON string back to list of maps
        final contactsList = jsonDecode(contactsJson) as List<dynamic>;
        final contacts = contactsList
            .map((contact) => {
                  'name': contact['name'] as String? ?? '',
                  'phone': contact['phone'] as String? ?? '',
                })
            .toList();

        setState(() {
          _emergencyContacts = contacts;
        });
      }
    } catch (e) {
      // Handle error silently in production
      debugPrint('Error loading emergency contacts: $e');
    }
  }

  void _saveEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert the list of maps to JSON string
      final contactsJson = jsonEncode(_emergencyContacts);
      await prefs.setString('emergency_contacts', contactsJson);
    } catch (e) {
      // Handle error silently in production
      debugPrint('Error saving emergency contacts: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    // Show loading indicator while profile data is being loaded
    if (!_isProfileLoaded) {
      return Scaffold(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
            ? const Color(0xFF121212)
            : Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode
          ? const Color(0xFF121212)
          : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and info
              Container(
                padding: const EdgeInsets.only(
                    top: 48, bottom: 40, left: 24, right: 24),
                decoration: BoxDecoration(
                  // 135-degree diagonal gradient (bg-gradient-to-br)
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF088771), // Muawin Primary Teal
                      primary,
                      primary.withValues(alpha: 0.9), // primary/90
                    ],
                  ),
                  // rounded-b-[40px]
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  // shadow-2xl
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: _profileImagePath.isNotEmpty
                            ? kIsWeb && _profileImageBytes != null
                                ? Image.memory(
                                    _profileImageBytes!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        decoration: const BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                                'assets/muawin_logo.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : kIsWeb
                                    ? Container(
                                        width: 80,
                                        height: 80,
                                        decoration: const BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage(
                                                'assets/muawin_logo.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    : Image.file(
                                        File(_profileImagePath),
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            decoration: const BoxDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(
                                                    'assets/muawin_logo.png'),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        },
                                      )
                            : Container(
                                width: 80,
                                height: 80,
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage('assets/muawin_logo.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName.isNotEmpty
                                ? _userName
                                : Provider.of<LanguageProvider>(context)
                                    .translate('welcome_message'),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Show PRO badge for PRO users, otherwise show "Verified Customer"
                          _isProUser
                              ? const MuawinProBadge(
                                  size: MuawinProBadgeSize.medium)
                              : Text(
                                  Provider.of<LanguageProvider>(context)
                                      .translate('verified_customer'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _userEmail,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _userPhone,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8),
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

              // Content section
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Provider.of<ThemeProvider>(context).isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Settings Header
                      Text(
                        Provider.of<LanguageProvider>(context)
                            .translate('account_settings'),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Provider.of<ThemeProvider>(context).isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Menu Items
                      _buildMenuSection(
                        Provider.of<LanguageProvider>(context)
                            .translate('account'),
                        [
                          _buildModernMenuCard(
                            Icons.person,
                            Provider.of<LanguageProvider>(context)
                                .translate('edit_profile'),
                            Provider.of<LanguageProvider>(context)
                                .translate('edit_profile_desc'),
                            Colors.blue,
                            () => _showEditProfileDialog(context, primary),
                          ),
                          _buildModernMenuCard(
                            Icons.shield,
                            Provider.of<LanguageProvider>(context)
                                .translate('security'),
                            Provider.of<LanguageProvider>(context)
                                .translate('security_desc'),
                            Colors.orange,
                            () => _showSecurityDialog(context, primary),
                          ),
                          _buildModernMenuCard(
                            Icons.notifications,
                            Provider.of<LanguageProvider>(context)
                                .translate('notifications'),
                            Provider.of<LanguageProvider>(context)
                                .translate('notifications_desc'),
                            Colors.purple,
                            () => _showNotificationsDialog(context, primary),
                          ),
                          _buildModernMenuCard(
                            Icons.contact_emergency,
                            Provider.of<LanguageProvider>(context)
                                .translate('emergency_contacts'),
                            Provider.of<LanguageProvider>(context)
                                .translate('manage_contacts_sos_alerts'),
                            Colors.red,
                            () =>
                                _showEmergencyContactsDialog(context, primary),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Preferences Header
                      Text(
                        Provider.of<LanguageProvider>(context)
                            .translate('preferences'),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Provider.of<ThemeProvider>(context).isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Preferences Items
                      _buildMenuSection('Display', [
                        _buildDarkModeCard(primary,
                            Provider.of<ThemeProvider>(context, listen: false)),
                        _buildModernMenuCard(
                          Icons.language,
                          Provider.of<LanguageProvider>(context)
                              .translate('language'),
                          Provider.of<LanguageProvider>(context)
                              .translate('language_desc'),
                          Colors.purple,
                          () => _showLanguageDialog(context),
                        ),
                        _buildModernMenuCard(
                          Icons.help_outline,
                          'Help & Support',
                          'Get help and support',
                          Colors.green,
                          () => _showHelpSupportDialog(context, primary),
                        ),
                      ]),

                      const SizedBox(height: 32),

                      // Sign Out Button
                      _buildSignOutCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MuawinBottomNavigationBar(
        currentIndex: 4, // Profile tab is selected (index 4)
        onItemTapped: (i) {
          if (i == 0) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
              (route) => false,
            );
          } else if (i == 1) {
            // Navigate to Jobs
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerJobsScreen()),
            );
          } else if (i == 2) {
            // Navigate to Post Job
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PostJobScreen()),
            );
          } else if (i == 3) {
            // Navigate to Messages
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerMessagesScreen()),
            );
          }
          // Profile (index 4) is current screen, no navigation needed
        },
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...children,
      ],
    );
  }

  Widget _buildModernMenuCard(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Provider.of<ThemeProvider>(context).isDarkMode
            ? const Color(0xFF2A2A2A)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Provider.of<ThemeProvider>(context).isDarkMode
              ? const Color(0xFF424242)
              : Colors.grey[200]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Provider.of<ThemeProvider>(context).isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Provider.of<ThemeProvider>(context).isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Provider.of<ThemeProvider>(context).isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkModeCard(Color primary, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Provider.of<ThemeProvider>(context).isDarkMode
            ? const Color(0xFF2A2A2A)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Provider.of<ThemeProvider>(context).isDarkMode
              ? const Color(0xFF424242)
              : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Provider.of<LanguageProvider>(context)
                        .translate('dark_mode'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Provider.of<ThemeProvider>(context).isDarkMode
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    themeProvider.isDarkMode
                        ? Provider.of<LanguageProvider>(context)
                            .translate('switch_to_light_mode')
                        : Provider.of<LanguageProvider>(context)
                            .translate('switch_to_dark_mode'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Provider.of<ThemeProvider>(context).isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
              activeThumbColor: Colors.amber,
              activeTrackColor: Colors.amber.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSignOutDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Provider.of<LanguageProvider>(context)
                            .translate('sign_out'),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Provider.of<LanguageProvider>(context)
                            .translate('sign_out_account'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.red.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, Color primary) {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);
    final phoneController = TextEditingController(text: _userPhone);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          backgroundColor:
              Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.person,
                color: primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                // Profile Picture
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Provider.of<ThemeProvider>(context,
                                        listen: false)
                                    .isDarkMode
                                ? const Color(0xFF424242)
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _profileImagePath.isNotEmpty
                              ? kIsWeb && _profileImageBytes != null
                                  ? Image.memory(
                                      _profileImageBytes!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 100,
                                          height: 100,
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                  'assets/muawin_logo.png'),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : kIsWeb
                                      ? Container(
                                          width: 100,
                                          height: 100,
                                          decoration: const BoxDecoration(
                                            image: DecorationImage(
                                              image: AssetImage(
                                                  'assets/muawin_logo.png'),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : Image.file(
                                          File(_profileImagePath),
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: 100,
                                              height: 100,
                                              decoration: const BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage(
                                                      'assets/muawin_logo.png'),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          },
                                        )
                              : Container(
                                  width: 100,
                                  height: 100,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image:
                                          AssetImage('assets/muawin_logo.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showImagePickerOptions(context),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Form Fields
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validation
                if (nameController.text.trim().isEmpty) {
                  _showErrorSnackBar('Please enter your name');
                  return;
                }

                if (emailController.text.trim().isEmpty) {
                  _showErrorSnackBar('Please enter your email');
                  return;
                }

                if (phoneController.text.trim().isEmpty) {
                  _showErrorSnackBar('Please enter your phone number');
                  return;
                }

                // Update profile data
                setState(() {
                  _userName = nameController.text.trim();
                  _userEmail = emailController.text.trim();
                  _userPhone = phoneController.text.trim();
                });

                // Save to SharedPreferences
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('user_name', _userName);
                  await prefs.setString('user_email', _userEmail);
                  await prefs.setString('user_phone', _userPhone);
                } catch (e) {
                  debugPrint('Error saving profile: $e');
                }

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Profile updated successfully!',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.language,
              color: Colors.purple,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              languageProvider.translate('language'),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _buildLanguageOption(
              context,
              AppLanguage.english,
              languageProvider.translate('english'),
              languageProvider.currentLanguage == AppLanguage.english,
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              context,
              AppLanguage.bilingual,
              languageProvider.translate('bilingual'),
              languageProvider.currentLanguage == AppLanguage.bilingual,
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              context,
              AppLanguage.urdu,
              languageProvider.translate('urdu'),
              languageProvider.currentLanguage == AppLanguage.urdu,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              languageProvider.translate('close'),
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, AppLanguage language,
      String title, bool isSelected) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          languageProvider.setLanguage(language);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Language changed to $title',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.purple.withValues(alpha: 0.1)
                : Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.purple
                  : Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? const Color(0xFF424242)
                      : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.purple : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Colors.purple : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Provider.of<ThemeProvider>(context, listen: false)
                            .isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSecurityDialog(BuildContext context, Color primary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.shield,
              color: Colors.orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Security Settings',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildSecurityOption(
                icon: Icons.lock,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: () => _showChangePasswordDialog(context, primary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF2A2A2A)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                      ? const Color(0xFF424242)
                      : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            Provider.of<ThemeProvider>(context, listen: false)
                                    .isDarkMode
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color:
                            Provider.of<ThemeProvider>(context, listen: false)
                                    .isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, Color primary) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor:
              Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.lock,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Change Password',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                    helperText: 'Password must be at least 8 characters',
                  ),
                  onChanged: (value) {
                    setState(
                        () {}); // Trigger rebuild to update password strength
                  },
                ),
                const SizedBox(height: 8),
                // Password strength indicator
                if (newPasswordController.text.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Strength: ${_getPasswordStrength(newPasswordController.text)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _getPasswordStrengthColor(
                              newPasswordController.text),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _getPasswordStrengthValue(
                            newPasswordController.text),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getPasswordStrengthColor(newPasswordController.text),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Capture the dialog context
                final dialogContext = context;

                // Validate inputs
                if (currentPasswordController.text.isEmpty) {
                  _showErrorSnackBar('Please enter your current password');
                  return;
                }

                if (newPasswordController.text.isEmpty) {
                  _showErrorSnackBar('Please enter a new password');
                  return;
                }

                if (newPasswordController.text.length < 8) {
                  _showErrorSnackBar(
                      'Password must be at least 8 characters long');
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  _showErrorSnackBar('Passwords do not match!');
                  return;
                }

                if (currentPasswordController.text ==
                    newPasswordController.text) {
                  _showErrorSnackBar(
                      'New password must be different from current password');
                  return;
                }

                // Show loading indicator
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text('Updating password...'),
                      ],
                    ),
                  ),
                );

                try {
                  // Verify current password and update new password
                  final prefs = await SharedPreferences.getInstance();
                  final storedPassword = prefs.getString('user_password') ??
                      'password123'; // Default password for demo

                  if (currentPasswordController.text != storedPassword) {
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop(); // Close loading dialog
                      _showErrorSnackBar('Current password is incorrect');
                    }
                    return;
                  }

                  // Simulate API call delay
                  await Future.delayed(const Duration(seconds: 2));

                  // Update password in storage
                  await prefs.setString(
                      'user_password', newPasswordController.text);

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(); // Close loading dialog

                    // Show success message
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Password updated successfully!',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    Navigator.of(dialogContext)
                        .pop(); // Close change password dialog
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(); // Close loading dialog
                    _showErrorSnackBar(
                        'Failed to update password. Please try again.');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Update Password',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context, Color primary) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor:
              Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.notifications,
                color: Colors.purple,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Notification Settings',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _buildNotificationSection(
                  title: 'Push Notifications',
                  icon: Icons.notifications_active,
                  iconColor: Colors.blue,
                  children: [
                    _buildNotificationToggle(
                      title: 'Job Updates',
                      subtitle: 'Get notified about job status changes',
                      value: _jobUpdatesEnabled,
                      onChanged: (value) {
                        setState(() {
                          _jobUpdatesEnabled = value;
                        });
                      },
                    ),
                    _buildNotificationToggle(
                      title: 'New Messages',
                      subtitle: 'Receive notifications for new messages',
                      value: _newMessagesEnabled,
                      onChanged: (value) {
                        setState(() {
                          _newMessagesEnabled = value;
                        });
                      },
                    ),
                    _buildNotificationToggle(
                      title: 'Payment Updates',
                      subtitle: 'Notifications about payments and earnings',
                      value: _paymentUpdatesEnabled,
                      onChanged: (value) {
                        setState(() {
                          _paymentUpdatesEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Test PRO Mode Section
                _buildNotificationSection(
                  title: 'Developer Options',
                  icon: Icons.bug_report,
                  iconColor: Colors.orange,
                  children: [
                    _buildNotificationToggle(
                      title: 'Test PRO Mode',
                      subtitle:
                          'Toggle PRO features for testing (restart required)',
                      value: _testProMode,
                      onChanged: (value) async {
                        await _toggleTestProMode(value);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save notification preferences
                await _saveNotificationPreferences();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Notification settings saved!',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save Settings',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyContactsDialog(BuildContext context, Color primary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.contact_emergency, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            Text(
              Provider.of<LanguageProvider>(context)
                  .translate('emergency_contacts'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These contacts will receive emergency alerts when you tap the SOS button.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? Colors.grey[300]
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                Provider.of<LanguageProvider>(context)
                    .translate('emergency_contacts'),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              // Emergency contacts list
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Provider.of<ThemeProvider>(context, listen: false)
                            .isDarkMode
                        ? const Color(0xFF424242)
                        : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _emergencyContacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.contact_phone,
                                size: 48,
                                color: Provider.of<ThemeProvider>(context,
                                            listen: false)
                                        .isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              Provider.of<LanguageProvider>(context)
                                  .translate('no_emergency_contacts_added'),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Provider.of<ThemeProvider>(context,
                                            listen: false)
                                        .isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Provider.of<LanguageProvider>(context)
                                  .translate('add_contacts_sos_alerts'),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Provider.of<ThemeProvider>(context,
                                            listen: false)
                                        .isDarkMode
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _emergencyContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _emergencyContacts[index];
                          return _buildEmergencyContactTile(contact, index);
                        },
                      ),
              ),
              const SizedBox(height: 16),
              // Add contact button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddContactDialog(context, primary),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Add Emergency Contact',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
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

  Widget _buildEmergencyContactTile(Map<String, String> contact, int index) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red[100],
        child: Icon(Icons.person, color: Colors.red[600]),
      ),
      title: Text(
        contact['name'] ?? '',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
              ? Colors.white
              : Colors.black87,
        ),
      ),
      subtitle: Text(
        contact['phone'] ?? '',
        style: GoogleFonts.poppins(
          color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
              ? Colors.grey[400]
              : Colors.grey[600],
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Colors.red[400]),
        onPressed: () => _showDeleteConfirmationDialog(
            context, contact['name'] ?? '', index),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, String contactName, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Contact',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? Colors.white
                : Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to delete $contactName from your emergency contacts?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? Colors.grey[300]
                : Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _removeEmergencyContact(index);
              Navigator.of(context).pop();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Emergency contact removed',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, Color primary) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Add Emergency Contact',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? Colors.white
                : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Contact Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
                hintText: 'Enter contact name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone),
                hintText: 'Enter phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();

              // Validation
              if (name.isEmpty) {
                _showErrorSnackBar('Please enter contact name');
                return;
              }

              if (phone.isEmpty) {
                _showErrorSnackBar('Please enter phone number');
                return;
              }

              if (name.length < 2) {
                _showErrorSnackBar('Name must be at least 2 characters');
                return;
              }

              if (phone.length < 10) {
                _showErrorSnackBar('Please enter a valid phone number');
                return;
              }

              // Check if contact already exists
              final existingContact = _emergencyContacts.firstWhere(
                (contact) =>
                    contact['name']?.toLowerCase() == name.toLowerCase() ||
                    contact['phone'] == phone,
                orElse: () => {},
              );

              if (existingContact.isNotEmpty) {
                _showErrorSnackBar('Contact already exists');
                return;
              }

              // Add the contact
              _addEmergencyContact(name, phone);
              Navigator.of(context).pop();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Emergency contact added successfully!',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Add Contact',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
            ? const Color(0xFF2A2A2A)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
              ? const Color(0xFF424242)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Provider.of<ThemeProvider>(context, listen: false)
                            .isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF424242)
                : Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
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
                    color: Provider.of<ThemeProvider>(context, listen: false)
                            .isDarkMode
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Provider.of<ThemeProvider>(context, listen: false)
                            .isDarkMode
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.blue,
            activeTrackColor: Colors.blue.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context, Color primary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.help_outline,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Help & Support',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              // Quick Help Options
              _buildHelpOption(
                icon: Icons.question_answer,
                title: 'Frequently Asked Questions',
                subtitle: 'Find answers to common questions',
                onTap: () => _showFAQDialog(context, primary),
              ),
              const SizedBox(height: 16),
              _buildHelpOption(
                icon: Icons.chat_bubble_outline,
                title: 'Contact Support',
                subtitle: 'Get help from our support team',
                onTap: () => _showContactSupportDialog(context, primary),
              ),
              const SizedBox(height: 16),
              _buildHelpOption(
                icon: Icons.phone,
                title: 'Call Us',
                subtitle: '+92 300 123 4567',
                onTap: () async {
                  final Uri phoneUri =
                      Uri(scheme: 'tel', path: '+923001234567');
                  try {
                    if (await canLaunchUrl(phoneUri)) {
                      await launchUrl(phoneUri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not launch phone dialer',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error launching phone dialer',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildHelpOption(
                icon: Icons.email,
                title: 'Email Support',
                subtitle: 'support@muawin.com',
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'support@muawin.com',
                    query:
                        'subject=Muawin App Support&body=Please describe your issue here...',
                  );
                  try {
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not launch email client',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error launching email client',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
              // App Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Provider.of<ThemeProvider>(context, listen: false)
                            .isDarkMode
                        ? const Color(0xFF424242)
                        : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'App Information',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Provider.of<ThemeProvider>(context,
                                          listen: false)
                                      .isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildAppInfoItem('Version', '1.0.0'),
                    const SizedBox(height: 8),
                    _buildAppInfoItem('Last Updated', 'March 2026'),
                    const SizedBox(height: 8),
                    _buildAppInfoItem('Platform', 'Flutter Web/Mobile'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF2A2A2A)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                      ? const Color(0xFF424242)
                      : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            Provider.of<ThemeProvider>(context, listen: false)
                                    .isDarkMode
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color:
                            Provider.of<ThemeProvider>(context, listen: false)
                                    .isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfoItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showFAQDialog(BuildContext context, Color primary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.question_answer,
              color: Colors.blue,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildFAQItem(
                question: 'How do I post a job?',
                answer:
                    'Go to the home screen and tap the "Post a Job" button in the center of the navigation bar. Fill in the job details and submit.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                question: 'How can I contact a worker?',
                answer:
                    'Once you find a suitable worker, tap on their profile and use the message button to start a conversation.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                question: 'How do I track my job progress?',
                answer:
                    'Go to "My Jobs" in the navigation bar to see all your posted jobs and their current status.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                question: 'What payment methods are accepted?',
                answer:
                    'We accept various payment methods including credit cards, debit cards, and digital wallets.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
            ? const Color(0xFF2A2A2A)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode
              ? const Color(0xFF424242)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color:
                  Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                      ? Colors.white
                      : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color:
                  Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showContactSupportDialog(BuildContext context, Color primary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Contact Support',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'Choose how you\'d like to contact our support team:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final Uri whatsappUri = Uri(
                          scheme: 'https',
                          host: 'wa.me',
                          path: '923001234567',
                          query: 'text=Hello! I need help with the Muawin app.',
                        );
                        try {
                          if (await canLaunchUrl(whatsappUri)) {
                            await launchUrl(whatsappUri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not launch WhatsApp',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error launching WhatsApp',
                                  style:
                                      GoogleFonts.poppins(color: Colors.white),
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.chat),
                      label: Text(
                        'WhatsApp',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Show live chat form
                        _showLiveChatDialog(context, primary);
                      },
                      icon: const Icon(Icons.support_agent),
                      label: Text(
                        'Live Chat',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Support Hours: 9:00 AM - 6:00 PM (PKT)\nAverage response time: 2-4 hours',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? Colors.grey[500]
                      : Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.logout,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              Provider.of<LanguageProvider>(context).translate('sign_out'),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to sign out of your account?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? const Color(0xFF2A2A2A)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? const Color(0xFF424242)
                      : Colors.grey[200]!,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will need to sign in again to access your account.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color:
                            Provider.of<ThemeProvider>(context, listen: false)
                                    .isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Here you would typically sign out the user
              // For now, just show a snackbar and close all dialogs
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Signed out successfully!',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              // Navigate to logout splash screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LogoutSplashScreen(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLiveChatDialog(BuildContext context, Color primary) {
    final messageController = TextEditingController();
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.support_agent,
              color: Colors.blue,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Live Chat Support',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Provider.of<ThemeProvider>(context, listen: false)
                        .isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                'Start a conversation with our support team. We typically respond within minutes during business hours.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Provider.of<ThemeProvider>(context, listen: false)
                          .isDarkMode
                      ? Colors.grey[300]
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Your Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.message),
                  helperText: 'Describe your issue in detail',
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final message = messageController.text.trim();

              // Validation
              if (name.isEmpty) {
                _showErrorSnackBar('Please enter your name');
                return;
              }

              if (email.isEmpty) {
                _showErrorSnackBar('Please enter your email');
                return;
              }

              if (message.isEmpty) {
                _showErrorSnackBar('Please enter your message');
                return;
              }

              if (message.length < 10) {
                _showErrorSnackBar('Message must be at least 10 characters');
                return;
              }

              // Close dialog and show success
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Chat request submitted! We\'ll respond within minutes.',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Start Chat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
