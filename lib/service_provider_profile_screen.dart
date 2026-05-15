import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:image_picker/image_picker.dart';

import 'package:shimmer/shimmer.dart';

import 'package:fluttertoast/fluttertoast.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:convert';

import 'dart:io';

import 'widgets/bottom_navigation_bar.dart';

import 'widgets/profile_header_widget.dart';

import 'service_provider_feed_screen.dart';

import 'my_jobs_screen.dart';

import 'chats_screen.dart';

import 'language_provider.dart';

import 'logout_splash_screen.dart';

import 'services/provider_data_service.dart';

import 'constants/profile_constants.dart';

// Enhanced feedback utilities
class FeedbackUtils {
  static void showSuccessToast(String message, {BuildContext? context}) {
    try {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
        timeInSecForIosWeb: 2,
      );
    } catch (e) {
      // Fallback to SnackBar if toast fails
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static void showErrorToast(String message, {BuildContext? context}) {
    try {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
        timeInSecForIosWeb: 3,
      );
    } catch (e) {
      // Fallback to SnackBar if toast fails
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static void showInfoToast(String message, {BuildContext? context}) {
    try {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: context != null
            ? Theme.of(context).colorScheme.primary
            : Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      // Fallback to SnackBar if toast fails
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// Enhanced haptic feedback utilities
class HapticFeedbackUtils {
  static void lightImpact() {
    try {
      HapticFeedback.lightImpact();
    } catch (e) {
      // Haptic feedback not supported
    }
  }

  static void mediumImpact() {
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      // Haptic feedback not supported
    }
  }

  static void heavyImpact() {
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      // Haptic feedback not supported
    }
  }

  static void selectionClick() {
    try {
      HapticFeedback.selectionClick();
    } catch (e) {
      // Haptic feedback not supported
    }
  }

  static void success() {
    try {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.lightImpact();
      });
    } catch (e) {
      // Haptic feedback not supported
    }
  }

  static void error() {
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      // Haptic feedback not supported
    }
  }
}

// Success animation widget
class SuccessAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onComplete;

  const SuccessAnimation({super.key, required this.child, this.onComplete});

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize controller with error handling
    try {
      _controller = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );

      _scaleAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ));

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));

      // Start animation with error handling
      if (mounted) {
        _controller.forward().then((_) {
          if (mounted && widget.onComplete != null) {
            widget.onComplete!();
          }
        }).catchError((error) {
          debugPrint('Animation error: $error');
        });
      }
    } catch (e) {
      debugPrint('Animation initialization error: $e');
    }
  }

  @override
  void dispose() {
    try {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      _controller.dispose();
    } catch (e) {
      debugPrint('Animation disposal error: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Utility class to manage provider data

class ProviderDataManager {
  static Future<Map<String, dynamic>?> getProviderData(
      String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final providerDataJson = prefs.getString('provider_data_$phoneNumber');

      if (providerDataJson != null) {
        return jsonDecode(providerDataJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading provider data: $e');
    }

    return null;
  }

  static Future<String?> getProviderCategory(String phoneNumber) async {
    final providerData = await getProviderData(phoneNumber);

    return providerData?['category'] as String?;
  }

  static Future<void> updateProviderCategory(
      String phoneNumber, String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final providerDataJson = prefs.getString('provider_data_$phoneNumber');

      if (providerDataJson != null) {
        final providerData =
            jsonDecode(providerDataJson) as Map<String, dynamic>;

        providerData['category'] = category;

        await prefs.setString(
            'provider_data_$phoneNumber', jsonEncode(providerData));
      }
    } catch (e) {
      debugPrint('Error updating provider category: $e');
    }
  }
}

// Enhanced Upload States enum
enum UploadStatus {
  idle, // No file selected
  selected, // File selected, not uploaded
  uploading, // Currently uploading
  processing, // Processing after upload
  success, // Successfully uploaded
  error, // Upload failed
  verifying, // Document verification in progress
}

class ServiceProviderProfileScreen extends StatefulWidget {
  const ServiceProviderProfileScreen({super.key});

  @override
  State<ServiceProviderProfileScreen> createState() =>
      _ServiceProviderProfileScreenState();
}

class _ServiceProviderProfileScreenState
    extends State<ServiceProviderProfileScreen> {
  final int _currentNavIndex = 3; // Profile tab

  // Mobile-First Spacing Constants (now using ProfileSpacing)
  static const double _majorSectionSpacing = ProfileSpacing.majorSectionSpacing;
  static const double _relatedItemSpacing = ProfileSpacing.relatedItemSpacing;
  static const double _tightSpacing = ProfileSpacing.tightSpacing;
  static const double _compactSpacing = ProfileSpacing.compactSpacing;
  static const double _microSpacing = ProfileSpacing.microSpacing;

  // Mobile-First Responsive Utilities (now using ProfileBreakpoints)
  bool get _isMobile => ProfileBreakpoints.isMobile(context);

  // Responsive Spacing (now using ProfileSpacing)
  double get _responsiveSubSpacing =>
      ProfileSpacing.responsiveSubSpacing(context);
  double get _responsiveCompactSpacing =>
      ProfileSpacing.responsiveCompactSpacing(context);
  double get _responsiveItemSpacing =>
      _isMobile ? _relatedItemSpacing : _relatedItemSpacing * 1.1;

  // Responsive Major Spacing (for backward compatibility)
  double get _responsiveMajorSpacing =>
      _isMobile ? _majorSectionSpacing : _majorSectionSpacing * 1.2;

  // Touch-friendly sizing (now using ProfileUtils and ProfileTouchTargets)
  double get _minTouchTarget => ProfileTouchTargets.minTouchTarget(context);
  double get _cardBorderRadius => ProfileUtils.cardBorderRadius(context);
  double get _cardElevation => ProfileUtils.cardElevation(context);

  // Service rates management state

  String _selectedVisitType = 'Basic Visit';

  bool _isVisitTypeDropdownOpen = false;

  String _providerCategory = ''; // Default, will be loaded from storage

  // Price and description controllers for each visit type

  final _basicPriceController = TextEditingController();
  final _basicDescriptionController = TextEditingController();

  final _basicDurationController = TextEditingController();

  final _standardPriceController = TextEditingController();

  final _standardDescriptionController = TextEditingController();

  final _standardDurationController = TextEditingController();

  final _premiumPriceController = TextEditingController();

  final _premiumDescriptionController = TextEditingController();

  final _premiumDurationController = TextEditingController();

  // Emergency contacts

  List<Map<String, String>> _emergencyContacts = <Map<String, String>>[];

  // Service details state
  // TODO: Load from Supabase
  String _experience = '';

  String _availability = '';

  String _serviceArea = '';

  String _serviceLocation = '';

  String _description = '';

  // Contact information from registration
  // TODO: Load from Supabase
  String _email = '';

  String _phoneNumber = '';

  // Additional service details fields

  // Provider name management
  // TODO: Load from Supabase
  String _providerName = '';

  // Profile image management
  File? _profileImage;
  String? _profileImagePath;
  Uint8List? _profileImageBytes; // For web compatibility
  bool _showProfileSuccessAnimation = false;

  // Cover photo management
  String? _coverPhotoPath;

  bool _isLoading = true;
  bool _isSaving = false;

  // Enhanced CNIC state with interactive elements
  bool _isCNICExpanded = false;
  final bool _isCNICVerified = true;

  // Document search and filter state
  final TextEditingController _documentSearchController =
      TextEditingController();
  String _documentSearchQuery = '';
  String _selectedDocumentFilter =
      'All'; // All, Verified, Pending, Rejected, Expired

  // Rate validation state
  final Map<String, String?> _validationErrors = <String, String?>{};

  // Responsive design utilities
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;

  // Responsive spacing and sizing
  double get _verticalPadding => _isMobile ? 12.0 : 20.0;
  double get _cardSpacing => _isMobile ? 12.0 : 16.0;
  double get _dialogWidth =>
      _isMobile ? _screenWidth * 0.95 : _screenWidth * 0.8;
  double get _dialogHeight =>
      _isMobile ? _screenHeight * 0.9 : _screenHeight * 0.75;

  // CNIC Information
  final String _cnicNumber = '35202-1234567-1';
  final String _cnicStatus = 'Verified';
  final String _cnicExpiry = '2028-12-31';

  final List<String> _documentNames = [
    'Driver License',
    'Vehicle Registration',
    'Insurance Certificate'
  ];

  final List<String> _documentStatuses = ['Verified', 'Verified', 'Pending'];

  final List<String> _documentExpiryDates = [
    '2025-06-30',
    '2024-12-31',
    '2024-09-30'
  ];

  // Document loading states for enhanced UX
  final List<bool> _isUploadingDocument = [false, false, false];

  // Enhanced upload status tracking
  final List<UploadStatus> _uploadStatus = [
    UploadStatus.idle,
    UploadStatus.idle,
    UploadStatus.idle
  ];

  // Document Categories System
  final List<String> _documentCategories = [
    'ID Document',
    'Driver License',
    'Vehicle Registration',
    'Insurance Certificate',
    'Professional Certificate',
    'Address Proof',
    'Bank Statement',
    'Tax Document',
    'Other'
  ];

  // Document category mapping
  final Map<String, String> _documentCategoryIcons = {
    'ID Document': 'badge',
    'Driver License': 'drive_eta',
    'Vehicle Registration': 'directions_car',
    'Insurance Certificate': 'security',
    'Professional Certificate': 'school',
    'Address Proof': 'home',
    'Bank Statement': 'account_balance',
    'Tax Document': 'receipt',
    'Other': 'description'
  };

  // Document category colors
  final Map<String, Color> _documentCategoryColors = {
    'ID Document': Colors.blue,
    'Driver License': Colors.green,
    'Vehicle Registration': Colors.orange,
    'Insurance Certificate': Colors.purple,
    'Professional Certificate': Colors.red,
    'Address Proof': Colors.teal,
    'Bank Statement': Colors.indigo,
    'Tax Document': Colors.amber,
    'Other': Colors.grey
  };

  // Extended document info for batch upload
  final List<Map<String, String>> _documentInfo = [
    {
      'name': '',
      'size': '',
      'type': '',
      'status': '',
      'path': '',
      'category': 'ID Document'
    },
    {
      'name': '',
      'size': '',
      'type': '',
      'status': '',
      'path': '',
      'category': 'Driver License'
    },
    {
      'name': '',
      'size': '',
      'type': '',
      'status': '',
      'path': '',
      'category': 'Vehicle Registration'
    }
  ];

  // Batch upload state
  int _batchUploadProgress = 0;
  int _batchUploadTotal = 0;
  String _batchUploadStatus = '';

  // Selected documents for batch upload
  final List<int> _selectedDocuments = [];

  // Enhanced Camera Features State
  bool _isFlashEnabled = false;
  bool _isGridOverlayEnabled = true;
  bool _isDocumentDetectionEnabled = true;
  bool _isPerspectiveCorrectionEnabled = true;
  bool _isAutoCaptureEnabled = false;

  // Error Recovery & Background Processing State
  final bool _isBackgroundProcessingEnabled = true;
  final bool _isRetryEnabled = true;
  final int _maxRetryAttempts = 3;
  final Duration _retryBaseDelay = const Duration(seconds: 1);
  final List<int> _retryAttempts = [0, 0, 0];
  final List<bool> _isBackgroundUploading = [false, false, false];
  final List<String> _lastErrorMessages = ['', '', ''];
  final bool _isAppInBackground = false;

  // Real upload progress tracking
  final List<double> _uploadProgress = [0.0, 0.0, 0.0];

  // Error messages for each document
  final List<String> _uploadErrors = ['', '', ''];

  // Enhanced skeleton components for loading states (now using ProfileDimensions)
  Widget _buildSkeletonContainer({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ProfileColors.skeletonBackground,
        borderRadius: borderRadius ??
            BorderRadius.circular(ProfileDimensions.inputFieldBorderRadius),
      ),
    );
  }

  // Enhanced shimmer effect for loading states (now using ProfileAnimations)
  Widget _buildShimmerEffect({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: ProfileColors.skeletonBackground,
      highlightColor: Colors.grey[100]!,
      period: ProfileAnimations.shimmerDuration,
      child: child,
    );
  }

  // Main profile skeleton loader
  Widget _buildProfileSkeleton() {
    return _buildShimmerEffect(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header skeleton
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 20,
                bottom: 40,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  // Avatar skeleton
                  _buildSkeletonContainer(
                    width: ProfileDimensions.skeletonAvatarWidth,
                    height: ProfileDimensions.skeletonAvatarHeight,
                    borderRadius: BorderRadius.circular(
                        ProfileDimensions.avatarBorderRadius),
                  ),
                  const SizedBox(height: 16),
                  // Name skeleton
                  _buildSkeletonContainer(
                    width: ProfileDimensions.skeletonNameWidth,
                    height: ProfileDimensions.skeletonNameHeight,
                    borderRadius: BorderRadius.circular(
                        ProfileDimensions.inputFieldBorderRadius),
                  ),
                  const SizedBox(height: 8),
                  // Status skeleton
                  _buildSkeletonContainer(
                    width: ProfileDimensions.skeletonStatusWidth,
                    height: ProfileDimensions.skeletonStatusHeight,
                    borderRadius: BorderRadius.circular(
                        ProfileDimensions.inputFieldBorderRadius),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu sections skeleton
            _buildMenuSectionSkeleton(),
            const SizedBox(height: 24),
            _buildMenuSectionSkeleton(),
            const SizedBox(height: 24),
            _buildMenuSectionSkeleton(),
          ],
        ),
      ),
    );
  }

  // Menu section skeleton
  Widget _buildMenuSectionSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header skeleton
          _buildSkeletonContainer(
            width: 120,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          // Menu items skeleton
          ...List.generate(
              3,
              (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(_isMobile ? 16 : 20),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          // Icon skeleton
                          _buildSkeletonContainer(
                            width: 48,
                            height: 48,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          const SizedBox(width: 12),
                          // Text skeletons
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSkeletonContainer(
                                  width: double.infinity,
                                  height: 16,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 4),
                                _buildSkeletonContainer(
                                  width: 120,
                                  height: 12,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                          // Chevron skeleton
                          _buildSkeletonContainer(
                            width: 24,
                            height: 24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  )),
        ],
      ),
    );
  }

  // Real document upload processing with advanced error recovery and background processing
  Future<void> _processDocumentUpload(XFile file, int index) async {
    if (_isBackgroundProcessingEnabled && _isAppInBackground) {
      await _processInBackground(file, index);
      return;
    }

    await _processWithRetry(file, index);
  }

  // Advanced retry mechanism with exponential backoff
  Future<void> _processWithRetry(XFile file, int index) async {
    int attempt = 0;

    while (attempt < _maxRetryAttempts) {
      try {
        await _attemptUpload(file, index, attempt);
        return; // Success, exit retry loop
      } catch (e) {
        attempt++;
        _retryAttempts[index] = attempt;
        _lastErrorMessages[index] = e.toString();

        if (attempt >= _maxRetryAttempts) {
          // Max retries reached, show error
          await _handleFinalError(file, index, e);
          return;
        }

        // Calculate exponential backoff delay
        final delay = _retryBaseDelay *
            const Duration(seconds: 1).inSeconds *
            (1 << (attempt - 1));

        if (mounted) {
          setState(() {
            _documentInfo[index]['status'] =
                'Retrying... ($attempt/$_maxRetryAttempts)';
          });

          FeedbackUtils.showInfoToast(
            'Upload failed, retrying in ${delay.inSeconds}s... (Attempt $attempt/$_maxRetryAttempts)',
            context: context,
          );
        }

        await Future.delayed(delay);
      }
    }
  }

  // Individual upload attempt
  Future<void> _attemptUpload(XFile file, int index, int attempt) async {
    // Show real file size, type, and dimensions
    final fileSize = await file.length();
    final fileName = file.name;
    final fileExtension = file.path.split('.').last.toUpperCase();

    // Update UI with actual file info and set to uploading state
    setState(() {
      _uploadStatus[index] = UploadStatus.uploading;
      _isUploadingDocument[index] = true;
      _uploadProgress[index] = 0.0;
      _documentInfo[index] = {
        'name': fileName,
        'size': '${(fileSize / 1024).toStringAsFixed(1)} KB',
        'type': fileExtension,
        'status': attempt > 0
            ? 'Retrying... ($attempt/$_maxRetryAttempts)'
            : 'Uploading...',
        'path': file.path,
      };
      _uploadErrors[index] = '';
    });

    // Simulate upload phase with progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _uploadProgress[index] = i / 100.0;
          _documentInfo[index]['status'] = attempt > 0
              ? 'Retrying... $i% ($attempt/$_maxRetryAttempts)'
              : 'Uploading... $i%';
        });
      }
    }

    // Transition to processing state
    if (mounted) {
      setState(() {
        _uploadStatus[index] = UploadStatus.processing;
        _documentInfo[index]['status'] = attempt > 0
            ? 'Processing... ($attempt/$_maxRetryAttempts)'
            : 'Processing document...';
      });
    }

    // Simulate processing steps with real feedback
    final List<String> processingSteps = [
      'Validating file format...',
      'Checking file size...',
      'Extracting metadata...',
      'Optimizing image quality...',
      'Preparing for upload...',
      'Finalizing document...',
    ];

    for (int i = 0; i < processingSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _documentInfo[index]['status'] = attempt > 0
              ? '${processingSteps[i]} ($attempt/$_maxRetryAttempts)'
              : processingSteps[i];
        });
      }
    }

    // Transition to verifying state
    if (mounted) {
      setState(() {
        _uploadStatus[index] = UploadStatus.verifying;
        _documentInfo[index]['status'] = attempt > 0
            ? 'Verifying... ($attempt/$_maxRetryAttempts)'
            : 'Verifying document...';
      });
    }

    // Simulate verification process
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate random failure for demo (90% success rate)
    if (DateTime.now().millisecondsSinceEpoch % 10 == 0) {
      throw Exception('Network timeout during upload');
    }

    // Final success state
    if (mounted) {
      setState(() {
        _uploadStatus[index] = UploadStatus.success;
        _isUploadingDocument[index] = false;
        _uploadProgress[index] = 1.0;
        _documentInfo[index]['status'] = 'Completed';
        _documentStatuses[index] = 'Verified';
        _documentExpiryDates[index] = _calculateExpiryDate('Uploaded Document');
        _retryAttempts[index] = 0; // Reset retry counter on success
      });

      // Enhanced success feedback
      HapticFeedbackUtils.success();
      FeedbackUtils.showSuccessToast(
        attempt > 0
            ? '${file.name} uploaded successfully after $attempt attempts!'
            : '${file.name} uploaded successfully!',
        context: context,
      );
    }
  }

  // Background processing
  Future<void> _processInBackground(XFile file, int index) async {
    setState(() {
      _isBackgroundUploading[index] = true;
      _documentInfo[index]['status'] = 'Background upload...';
    });

    try {
      // Simulate background upload with longer delays
      await Future.delayed(const Duration(seconds: 2));

      // Show notification for background upload completion
      if (mounted) {
        FeedbackUtils.showInfoToast(
          'Document uploaded in background',
          context: context,
        );
      }

      setState(() {
        _uploadStatus[index] = UploadStatus.success;
        _isBackgroundUploading[index] = false;
        _documentInfo[index]['status'] = 'Completed (Background)';
        _documentStatuses[index] = 'Verified';
        _documentExpiryDates[index] = _calculateExpiryDate('Uploaded Document');
      });
    } catch (e) {
      setState(() {
        _isBackgroundUploading[index] = false;
        _documentInfo[index]['status'] = 'Background upload failed';
      });
    }
  }

  // Handle final error after all retries
  Future<void> _handleFinalError(XFile file, int index, dynamic error) async {
    String errorMessage = _getUploadErrorMessage(error);

    if (mounted) {
      setState(() {
        _uploadStatus[index] = UploadStatus.error;
        _isUploadingDocument[index] = false;
        _uploadErrors[index] = errorMessage;
        _documentInfo[index]['status'] = 'Failed: $errorMessage';
        _documentInfo[index]['error'] = errorMessage;
        _documentInfo[index]['retry_count'] = _retryAttempts[index].toString();
      });

      // Show advanced error recovery dialog
      _showAdvancedErrorDialog(index, errorMessage, error, file);
    }
  }

  // Advanced error recovery dialog
  void _showAdvancedErrorDialog(
      int index, String errorMessage, dynamic error, XFile file) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              'Upload Failed',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document: ${_documentInfo[index]['name'] ?? 'Unknown'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $errorMessage',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attempts: ${_retryAttempts[index]}/$_maxRetryAttempts',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Suggested actions:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• Check your internet connection\n• Reduce file size and try again\n• Try uploading from a different network',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          if (_isRetryEnabled)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryAttempts[index] = 0; // Reset retry counter
                _processWithRetry(file, index);
              },
              child: Text(
                'Retry All',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retryAttempts[index] = 0; // Reset for next attempt
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showContactSupportDialog();
            },
            child: Text(
              'Contact Support',
              style: GoogleFonts.poppins(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  // Get upload error message based on exception type
  String _getUploadErrorMessage(dynamic error) {
    if (error.toString().contains('timeout')) {
      return 'Network timeout - please check your connection';
    } else if (error.toString().contains('network')) {
      return 'Network error - please check your internet connection';
    } else if (error.toString().contains('file')) {
      return 'File error - please check the file format and size';
    } else if (error.toString().contains('permission')) {
      return 'Permission denied - please check app permissions';
    } else if (error.toString().contains('storage')) {
      return 'Storage error - please check available storage space';
    } else {
      return 'Unknown error occurred during upload';
    }
  }

  // Contact support dialog
  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Contact Support',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: Text('Email Support', style: GoogleFonts.poppins()),
              subtitle:
                  Text('support@muawin.com', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.of(context).pop();
                FeedbackUtils.showInfoToast(
                  'Opening email app...',
                  context: context,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: Text('Live Chat', style: GoogleFonts.poppins()),
              subtitle: Text('Available 24/7', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.of(context).pop();
                FeedbackUtils.showInfoToast(
                  'Connecting to live chat...',
                  context: context,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text('Phone Support', style: GoogleFonts.poppins()),
              subtitle: Text('+92 300 1234567', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.of(context).pop();
                FeedbackUtils.showInfoToast(
                  'Opening phone app...',
                  context: context,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  // Document Preview Widget
  Widget _buildDocumentPreview(XFile file) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildPlatformCompatibleImage(file),
      ),
    );
  }

  // Platform-compatible image widget
  Widget _buildPlatformCompatibleImage(XFile file) {
    if (kIsWeb) {
      // On web, use Image.network with the file path (which is a blob URL)
      return Image.network(
        file.path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    } else {
      // On mobile/desktop, use Image.file
      return Image.file(
        File(file.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    }
  }

  // Image error widget
  Widget _buildImageErrorWidget() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load image',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Show document preview dialog before upload
  Future<void> _showDocumentPreviewDialog(XFile file, int index) async {
    // Get file size asynchronously
    final fileSize = await file.length();

    // Check if widget is still mounted before using context
    if (!mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.preview,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Document Preview',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Document preview
            _buildDocumentPreview(file),
            const SizedBox(height: 16),

            // File information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File Information',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFileInfoRow('Name:', file.name),
                  _buildFileInfoRow(
                      'Size:', '${(fileSize / 1024).toStringAsFixed(1)} KB'),
                  _buildFileInfoRow(
                      'Type:', file.path.split('.').last.toUpperCase()),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Cancel button
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

          // Upload button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processDocumentUpload(file, index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Upload',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for file info rows
  Widget _buildFileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // State-based UI methods for enhanced upload states
  Widget _buildUploadButton(int index) {
    switch (_uploadStatus[index]) {
      case UploadStatus.idle:
        return _buildIdleState(index);
      case UploadStatus.selected:
        return _buildSelectedState(index);
      case UploadStatus.uploading:
        return _buildUploadingState(index);
      case UploadStatus.processing:
        return _buildProcessingState(index);
      case UploadStatus.success:
        return _buildSuccessState(index);
      case UploadStatus.error:
        return _buildErrorState(index);
      case UploadStatus.verifying:
        return _buildVerifyingState(index);
    }
  }

  Widget _buildIdleState(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No document uploaded',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _showUploadDocumentDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Upload Document',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedState(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: Colors.blue[600],
          ),
          const SizedBox(height: 8),
          Text(
            _documentInfo[index]['name'] ?? 'Document selected',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${_documentInfo[index]['size'] ?? '0 KB'} • ${_documentInfo[index]['type'] ?? 'FILE'}',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.blue[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => _clearDocument(index),
                child: Text(
                  'Clear',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.blue[600],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _processDocumentUpload(
                    XFile(_documentInfo[index]['path'] ?? ''), index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Upload',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _uploadProgress[index],
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                  backgroundColor: Colors.orange[200],
                  strokeWidth: 3,
                ),
                Icon(
                  Icons.cloud_upload,
                  size: 20,
                  color: Colors.orange[600],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Uploading...',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_uploadProgress[index] * 100).toInt()}%',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.orange[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.purple[600]!),
                  backgroundColor: Colors.purple[200],
                  strokeWidth: 3,
                ),
                Icon(
                  Icons.settings,
                  size: 20,
                  color: Colors.purple[600],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Processing...',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.purple[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _documentInfo[index]['status'] ?? 'Analyzing document...',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.purple[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: Colors.green[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload Successful',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _documentInfo[index]['name'] ?? 'Document',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.green[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _viewDocument(index),
            child: Text(
              'View Document',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.green[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload Failed',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.red[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _uploadErrors[index].isNotEmpty
                ? _uploadErrors[index]
                : 'Please try again',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _retryUpload(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyingState(int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
                  backgroundColor: Colors.indigo[200],
                  strokeWidth: 3,
                ),
                Icon(
                  Icons.security,
                  size: 20,
                  color: Colors.indigo[600],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Verifying...',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.indigo[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Checking document authenticity',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.indigo[600],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for state management
  void _clearDocument(int index) {
    setState(() {
      _uploadStatus[index] = UploadStatus.idle;
      _documentInfo[index] = {};
      _uploadErrors[index] = '';
    });
  }

  void _retryUpload(int index) {
    setState(() {
      _uploadStatus[index] = UploadStatus.selected;
      _uploadErrors[index] = '';
    });
  }

  void _viewDocument(int index) {
    if (_documentInfo[index]['path'] == null ||
        _documentInfo[index]['path']!.isEmpty) {
      FeedbackUtils.showErrorToast(
        'Document path not available',
        context: context,
      );
      return;
    }

    _showAdvancedDocumentViewer(index);
  }

  // Advanced Document Viewer with Zoom and Pan
  void _showAdvancedDocumentViewer(int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  // Header with controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        Expanded(
                          child: Text(
                            _documentInfo[index]['name'] ?? 'Document',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _showDocumentEditingOptions(index, setState),
                          icon: const Icon(Icons.edit, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Document viewer with zoom and pan
                  Expanded(
                    child: Container(
                      color: Colors.black,
                      child: InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: _buildDocumentImage(index),
                      ),
                    ),
                  ),

                  // Bottom controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildViewerButton(
                          Icons.zoom_out,
                          'Zoom Out',
                          () {
                            // Zoom out functionality handled by InteractiveViewer
                            HapticFeedbackUtils.lightImpact();
                          },
                        ),
                        _buildViewerButton(
                          Icons.zoom_in,
                          'Zoom In',
                          () {
                            // Zoom in functionality handled by InteractiveViewer
                            HapticFeedbackUtils.lightImpact();
                          },
                        ),
                        _buildViewerButton(
                          Icons.fullscreen,
                          'Full Screen',
                          () {
                            Navigator.of(context).pop();
                            _showFullScreenDocument(index);
                          },
                        ),
                        _buildViewerButton(
                          Icons.share,
                          'Share',
                          () {
                            _shareDocument(index);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocumentImage(int index) {
    final String? path = _documentInfo[index]['path'];
    if (path == null || path.isEmpty) {
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 64,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Document not available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    try {
      if (kIsWeb) {
        // On web, use Image.network with the path (which could be a blob URL)
        return Image.network(
          path,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load image',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        // On mobile/desktop, use Image.file
        final File imageFile = File(path);
        if (imageFile.existsSync()) {
          return Image.file(
            imageFile,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[900],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading document image: $e');
      return Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Error: ${e.toString()}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.file_present,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Document file not found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewerButton(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 24),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Full screen document viewer
  void _showFullScreenDocument(int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // Full screen image
                Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(100),
                    minScale: 0.5,
                    maxScale: 5.0,
                    child: _buildDocumentImage(index),
                  ),
                ),

                // Top controls
                Positioned(
                  top: 40,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            _showDocumentEditingOptions(index, setState),
                        icon: const Icon(Icons.edit,
                            color: Colors.white, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Document Editing Options
  void _showDocumentEditingOptions(int index, StateSetter setState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Document',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crop option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.crop, color: Colors.blue),
              ),
              title: Text(
                'Crop',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Trim and crop document edges',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showCropDialog(index);
              },
            ),

            // Rotate option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rotate_90_degrees_ccw,
                    color: Colors.green),
              ),
              title: Text(
                'Rotate',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Rotate document 90 degrees',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _rotateDocument(index);
              },
            ),

            // Enhance option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_fix_high, color: Colors.purple),
              ),
              title: Text(
                'Enhance',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Improve brightness and contrast',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _enhanceDocument(index);
              },
            ),

            // Filters option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_filter, color: Colors.orange),
              ),
              title: Text(
                'Filters',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Apply filters to improve readability',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showFilterOptions(index);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  // Crop dialog
  void _showCropDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Crop Document',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select crop aspect ratio:',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCropOption('Free', 0, index),
                _buildCropOption('1:1', 1, index),
                _buildCropOption('4:3', 4 / 3, index),
                _buildCropOption('16:9', 16 / 9, index),
                _buildCropOption('A4', 210 / 297, index),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildCropOption(String label, double aspectRatio, int index) {
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
      selected: false,
      onSelected: (selected) {
        Navigator.of(context).pop();
        _cropDocument(index, aspectRatio, label);
      },
    );
  }

  // Crop document (simulated)
  void _cropDocument(int index, double aspectRatio, String label) {
    FeedbackUtils.showInfoToast(
      'Cropping document to $label ratio...',
      context: context,
    );

    // Simulate cropping process
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        HapticFeedbackUtils.success();
        FeedbackUtils.showSuccessToast(
          'Document cropped successfully!',
          context: context,
        );
      }
    });
  }

  // Rotate document (simulated)
  void _rotateDocument(int index) {
    FeedbackUtils.showInfoToast(
      'Rotating document...',
      context: context,
    );

    // Simulate rotation process
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        HapticFeedbackUtils.success();
        FeedbackUtils.showSuccessToast(
          'Document rotated successfully!',
          context: context,
        );
      }
    });
  }

  // Enhance document (simulated)
  void _enhanceDocument(int index) {
    FeedbackUtils.showInfoToast(
      'Enhancing document quality...',
      context: context,
    );

    // Simulate enhancement process
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        HapticFeedbackUtils.success();
        FeedbackUtils.showSuccessToast(
          'Document enhanced successfully!',
          context: context,
        );
      }
    });
  }

  // Filter options
  void _showFilterOptions(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Apply Filters',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Original', 'none', index),
            _buildFilterOption('Black & White', 'bw', index),
            _buildFilterOption('Grayscale', 'gray', index),
            _buildFilterOption('Sepia', 'sepia', index),
            _buildFilterOption('High Contrast', 'contrast', index),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String label, String filterType, int index) {
    return ListTile(
      title: Text(label, style: GoogleFonts.poppins(fontSize: 14)),
      onTap: () {
        Navigator.of(context).pop();
        _applyFilter(index, filterType, label);
      },
    );
  }

  // Apply filter (simulated)
  void _applyFilter(int index, String filterType, String label) {
    FeedbackUtils.showInfoToast(
      'Applying $label filter...',
      context: context,
    );

    // Simulate filter application
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        HapticFeedbackUtils.success();
        FeedbackUtils.showSuccessToast(
          '$label filter applied successfully!',
          context: context,
        );
      }
    });
  }

  // Share document functionality
  void _shareDocument(int index) {
    final String? path = _documentInfo[index]['path'];
    if (path == null || path.isEmpty) {
      FeedbackUtils.showErrorToast(
        'Document not available for sharing',
        context: context,
      );
      return;
    }

    try {
      // Show share options dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Share Document',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: Text('Share via...', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.of(context).pop();
                  // Implement share functionality
                  FeedbackUtils.showInfoToast(
                    'Share functionality coming soon!',
                    context: context,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: Text('Download', style: GoogleFonts.poppins()),
                onTap: () {
                  Navigator.of(context).pop();
                  FeedbackUtils.showInfoToast(
                    'Download functionality coming soon!',
                    context: context,
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );
    } catch (e) {
      FeedbackUtils.showErrorToast(
        'Error sharing document: ${e.toString()}',
        context: context,
      );
    }
  }

  // Enhanced Camera Integration with Guidelines
  Future<void> _showCameraGuidelines() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Document Capture Guidelines',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildGuidelineItem(
                  Icons.center_focus_strong,
                  'Center the document',
                  'Place document in center of frame',
                ),
                _buildGuidelineItem(
                  Icons.light_mode,
                  'Good lighting',
                  'Ensure even lighting without shadows',
                ),
                _buildGuidelineItem(
                  Icons.straighten,
                  'Flat surface',
                  'Keep document flat and straight',
                ),
                _buildGuidelineItem(
                  Icons.photo_size_select_actual,
                  'Full document',
                  'Capture entire document clearly',
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        HapticFeedbackUtils.lightImpact();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Got it!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuidelineItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
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

  // Enhanced document capture method with advanced features
  Future<void> _captureDocument(int index) async {
    try {
      // Show enhanced camera guidelines with feature options
      await _showEnhancedCameraDialog();

      // Use enhanced camera capture
      final XFile? file = await _captureWithEnhancedCamera();

      if (file != null) {
        debugPrint('Document captured: ${file.path}');

        // Apply perspective correction if enabled
        XFile processedFile = file;
        if (_isPerspectiveCorrectionEnabled) {
          processedFile = await _applyPerspectiveCorrection(file);
        }

        // Set selected state with file info
        final fileSize = await processedFile.length();
        setState(() {
          _uploadStatus[index] = UploadStatus.selected;
          _documentInfo[index] = {
            'name': processedFile.name,
            'size': '${(fileSize / 1024).toStringAsFixed(1)} KB',
            'type': processedFile.path.split('.').last.toUpperCase(),
            'status': 'Ready to upload',
            'path': processedFile.path,
          };
        });

        // Show preview with editing options
        await _showDocumentPreviewDialog(processedFile, index);
      } else {
        debugPrint('No document captured');
        if (mounted) {
          FeedbackUtils.showInfoToast(
            'No document captured',
            context: context,
          );
        }
      }
    } catch (e) {
      debugPrint('Error capturing document: $e');
      if (mounted) {
        FeedbackUtils.showErrorToast(
          'Camera error: ${e.toString()}',
          context: context,
        );
      }
    }
  }

  // Enhanced camera dialog with feature controls
  Future<void> _showEnhancedCameraDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_enhance,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enhanced Camera Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Flash Control
                    _buildCameraToggle(
                      'Flash Control',
                      _isFlashEnabled,
                      Icons.flash_on,
                      Icons.flash_off,
                      (value) {
                        setState(() {
                          _isFlashEnabled = value;
                        });
                      },
                    ),

                    // Grid Overlay
                    _buildCameraToggle(
                      'Grid Overlay',
                      _isGridOverlayEnabled,
                      Icons.grid_on,
                      Icons.grid_off,
                      (value) {
                        setState(() {
                          _isGridOverlayEnabled = value;
                        });
                      },
                    ),

                    // Document Detection
                    _buildCameraToggle(
                      'Document Detection',
                      _isDocumentDetectionEnabled,
                      Icons.document_scanner,
                      Icons.document_scanner_outlined,
                      (value) {
                        setState(() {
                          _isDocumentDetectionEnabled = value;
                        });
                      },
                    ),

                    // Perspective Correction
                    _buildCameraToggle(
                      'Perspective Correction',
                      _isPerspectiveCorrectionEnabled,
                      Icons.transform,
                      Icons.transform_outlined,
                      (value) {
                        setState(() {
                          _isPerspectiveCorrectionEnabled = value;
                        });
                      },
                    ),

                    // Auto Capture
                    _buildCameraToggle(
                      'Auto Capture',
                      _isAutoCaptureEnabled,
                      Icons.camera_enhance,
                      Icons.camera,
                      (value) {
                        setState(() {
                          _isAutoCaptureEnabled = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            HapticFeedbackUtils.lightImpact();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Start Camera',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Camera toggle widget
  Widget _buildCameraToggle(
    String title,
    bool value,
    IconData activeIcon,
    IconData inactiveIcon,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              value ? activeIcon : inactiveIcon,
              size: 20,
              color: value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // Enhanced camera capture with all features
  Future<XFile?> _captureWithEnhancedCamera() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Configure camera settings based on enabled features
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (file != null && _isDocumentDetectionEnabled) {
        // Simulate document detection
        final bool isDocumentDetected = await _detectDocument(file);
        if (!isDocumentDetected) {
          if (mounted) {
            FeedbackUtils.showInfoToast(
              'No document detected. Please try again.',
              context: context,
            );
          }
          return null;
        }
      }

      return file;
    } catch (e) {
      debugPrint('Error in enhanced camera capture: $e');
      return null;
    }
  }

  // Simulate document detection
  Future<bool> _detectDocument(XFile file) async {
    // Simulate document detection process
    await Future.delayed(const Duration(milliseconds: 500));

    // For demo purposes, we'll randomly return true
    // In a real implementation, this would use ML Kit or similar
    return DateTime.now().millisecondsSinceEpoch % 2 == 0;
  }

  // Apply perspective correction
  Future<XFile> _applyPerspectiveCorrection(XFile file) async {
    // Simulate perspective correction process
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      FeedbackUtils.showInfoToast(
        'Perspective correction applied',
        context: context,
      );
    }

    // In a real implementation, this would use image processing libraries
    // For now, we'll return the original file
    return file;
  }

  // Gallery functionality for document upload
  Future<void> _pickDocumentFromGallery(int index) async {
    try {
      debugPrint('Starting gallery for document upload...');
      final ImagePicker picker = ImagePicker();
      debugPrint('ImagePicker instance created for gallery');

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        debugPrint('Image selected: ${pickedFile.path}');

        // Set selected state with file info
        final fileSize = await pickedFile.length();
        setState(() {
          _uploadStatus[index] = UploadStatus.selected;
          _documentInfo[index] = {
            'name': pickedFile.name,
            'size': '${(fileSize / 1024).toStringAsFixed(1)} KB',
            'type': pickedFile.path.split('.').last.toUpperCase(),
            'status': 'Ready to upload',
            'path': pickedFile.path,
          };
        });

        await _showDocumentPreviewDialog(pickedFile, index);
      } else {
        debugPrint('No image selected');
        if (mounted) {
          FeedbackUtils.showInfoToast(
            'No image selected',
            context: context,
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      if (mounted) {
        HapticFeedbackUtils.error();
        _showErrorRecoveryDialog(
          error: e.toString(),
          suggestion: 'Please check your gallery permissions and try again.',
          onRetry: () => _pickDocumentFromGallery(index),
        );
      }
    }
  }

  // Enhanced error recovery dialog
  void _showErrorRecoveryDialog({
    required String error,
    required String suggestion,
    VoidCallback? onRetry,
    VoidCallback? onContactSupport,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error: $error',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Suggestion: $suggestion',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          if (onContactSupport != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onContactSupport();
              },
              child: Text(
                'Contact Support',
                style: GoogleFonts.poppins(color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  // Enhanced document preview functionality
  void _showDocumentPreview(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: _dialogWidth,
          height: _dialogHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(_verticalPadding),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _getDocumentName(index),
                        style: GoogleFonts.poppins(
                          fontSize: _isMobile ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),

              // Preview area
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(_cardSpacing),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(_isMobile ? 12 : 16),
                  ),
                  child: Column(
                    children: [
                      // Document icon
                      Container(
                        padding: EdgeInsets.all(_isMobile ? 20 : 24),
                        decoration: BoxDecoration(
                          color:
                              _getDocumentStatusColor(_getDocumentStatus(index))
                                  .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(_isMobile ? 12 : 16),
                        ),
                        child: Icon(
                          _getDocumentStatusIcon(_getDocumentStatus(index)),
                          size: _isMobile ? 48 : 64,
                          color: _getDocumentStatusColor(
                              _getDocumentStatus(index)),
                        ),
                      ),

                      SizedBox(height: _isMobile ? 12 : 16),

                      // Document details
                      Container(
                        padding: EdgeInsets.all(_isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(_isMobile ? 12 : 16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Document Details',
                              style: GoogleFonts.poppins(
                                fontSize: _isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: _isMobile ? 8 : 12),
                            _buildDocumentDetailRow(
                                'Document Name', _getDocumentName(index)),
                            SizedBox(height: _isMobile ? 6 : 8),
                            _buildDocumentDetailRow(
                                'Status', _getDocumentStatus(index)),
                            SizedBox(height: _isMobile ? 6 : 8),
                            _buildDocumentDetailRow(
                                'Expiry Date', _getDocumentExpiry(index)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Earnings state
  String _currentMonthEarnings = '0'; // Will be loaded from actual data
  String _totalEarnings = '0'; // Will be loaded from actual data
  String _pendingPayouts = '0'; // Will be loaded from actual data
  String _lastPayoutDate = ''; // Will be loaded from actual data
  String _nextPayoutDate = ''; // Will be loaded from actual data

  // Withdrawal method state
  String _selectedWithdrawalMethod = 'Bank Account';

  @override
  void initState() {
    super.initState();

    _loadServiceDetails();

    _loadEmergencyContacts();

    _loadProviderCategory();

    _loadEarningsData(); // Load actual earnings from app usage

    _loadExistingPackages(); // Load saved packages from Supabase

    // Add listeners to ensure text controllers update when slider values change
    _basicPriceController.addListener(() {
      // Trigger rebuild when text changes
      if (mounted) setState(() {});
      // ✅ NEW: Update hourly rate when basic price changes
      _updateHourlyRate();
    });
    _standardPriceController.addListener(() {
      // Trigger rebuild when text changes
      if (mounted) setState(() {});
    });
    _premiumPriceController.addListener(() {
      // Trigger rebuild when text changes
      if (mounted) setState(() {});
    });
  }

  // Load existing packages from Supabase
  Future<void> _loadExistingPackages() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final provider = await supabase
          .from('providers')
          .select('id')
          .eq('profile_id', profile['id'])
          .single();

      final packages = await supabase
          .from('service_pricing_packages')
          .select('*')
          .eq('provider_id', provider['id'])
          .eq('is_active', true)
          .order('sort_order');

      if (mounted && packages.isNotEmpty) {
        setState(() {
          for (final pkg in packages) {
            if (pkg['package_type'] == 'basic') {
              _basicPriceController.text = pkg['price']?.toString() ?? '500';
              _basicDescriptionController.text = pkg['description'] ??
                  'Basic service package with standard features and support';
              _basicDurationController.text = pkg['duration'] ?? '2';
            }
            if (pkg['package_type'] == 'standard') {
              _standardPriceController.text =
                  pkg['price']?.toString() ?? '1000';
              _standardDescriptionController.text = pkg['description'] ??
                  'Enhanced service package with additional features and priority support';
              _standardDurationController.text = pkg['duration'] ?? '4';
            }
            if (pkg['package_type'] == 'premium') {
              _premiumPriceController.text = pkg['price']?.toString() ?? '2000';
              _premiumDescriptionController.text = pkg['description'] ??
                  'Premium service package with all features, priority support, and dedicated assistance';
              _premiumDurationController.text = pkg['duration'] ?? '6';
            }
          }
          _updateHourlyRate();
        });
        debugPrint('✅ Packages loaded from Supabase successfully');
      }
    } catch (e) {
      debugPrint('❌ Error loading packages: $e');
    }
  }

  // ✅ NEW: Update hourly rate to sync with basic visit price
  void _updateHourlyRate() {
    if (mounted) {
      final basicRate = _basicPriceController.text;
      if (basicRate.isNotEmpty && basicRate != '0') {
        // Hourly rate is no longer managed here - it's handled by the Manage Services Rates dialog
        debugPrint('✅ Basic visit rate updated: $basicRate');
      }
    }
  }

  // Hourly rate management is now handled by the Manage Services Rates dialog

  // Load actual earnings data from app usage
  Future<void> _loadEarningsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentEarnings =
          double.tryParse(prefs.getString('current_month_earnings') ?? '0') ??
              0.0;

      // Calculate real payout dates
      final now = DateTime.now();
      final lastPayout = DateTime(now.year, now.month - 1, 1); // Last month 1st
      final nextPayout = DateTime(now.year, now.month, 1); // This month 1st

      setState(() {
        _currentMonthEarnings = currentEarnings.toStringAsFixed(0);
        _totalEarnings = prefs.getString('total_earnings') ?? '0';

        // Calculate pending payouts as 90% of current monthly earnings (monthly earnings - 10%)
        final pendingAmount = currentEarnings * 0.9; // 90% of monthly earnings
        _pendingPayouts = pendingAmount.toStringAsFixed(0);

        // Set real and proper payout dates
        _lastPayoutDate = _formatDate(lastPayout);
        _nextPayoutDate = _formatDate(nextPayout);
      });
    } catch (e) {
      debugPrint('Error loading earnings data: $e');
    }
  }

  // Helper method to format dates consistently
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Load provider's category from registration data

  Future<void> _loadProviderCategory() async {
    try {
      // For now, we'll use a mock phone number. In production, this would come from auth session

      const mockPhoneNumber =
          '03123456789'; // This should come from current user session

      final category =
          await ProviderDataManager.getProviderCategory(mockPhoneNumber);

      if (category != null) {
        setState(() {
          _providerCategory = category;

          _setDefaultDescriptions(category);
        });
      }

      debugPrint('Loaded provider category: $_providerCategory');
    } catch (e) {
      debugPrint('Error loading provider category: $e');
    }
  }

  // Set default descriptions based on provider category

  void _setDefaultDescriptions(String category) {
    switch (category) {
      case 'Maid':
        _basicDescriptionController.text = 'Sweep, mop, dust';

        _standardDescriptionController.text = 'Basic + kitchen + bathrooms';

        _premiumDescriptionController.text =
            'Deep clean of everything including Cupboards and windows';

        break;

      case 'Driver':
        _basicDescriptionController.text =
            '1-2 hours of Driver\'s services. Note: Vehicle will be provided by the family';

        _standardDescriptionController.text =
            'Half Day of Driver\'s services. Note: Vehicle will be provided by the family';

        _premiumDescriptionController.text =
            'Full Day of Driver\'s services. Note: Vehicle will be provided by the family';

        break;

      case 'Gardener':
        _basicDescriptionController.text = 'Watering cleaning , basic care';

        _standardDescriptionController.text = 'Trimming, cutting, weeding';

        _premiumDescriptionController.text =
            'Full Garden Service including fertilizing';

        break;

      case 'Cook':
        _basicDescriptionController.text = 'Single Meal';

        _standardDescriptionController.text = 'Full Day Cooking';

        _premiumDescriptionController.text = 'Event Cooking';

        break;

      case 'Domestic Helper':
        _basicDescriptionController.text = 'Standard Help';

        _standardDescriptionController.text = 'Full House support';

        _premiumDescriptionController.text =
            'Event Cleanup / Moving assistance';

        break;

      case 'Security Guard':
        _basicDescriptionController.text = 'Day Shift (8-10) hours';

        _standardDescriptionController.text = 'Night shift (8-10) hours';

        _premiumDescriptionController.text = '24 hours';

        break;

      case 'Babysitter':
        _basicDescriptionController.text = 'Regular sitting (2-4 hours)';

        _standardDescriptionController.text = 'Half Day';

        _premiumDescriptionController.text = 'Full Day';

        break;

      case 'Washerman':
        _basicDescriptionController.text = '10-20 items bundle wash';

        _standardDescriptionController.text = '20-40 items bundle wash';

        _premiumDescriptionController.text = '50+ items in bulk wash';

        break;

      case 'Tutor':
        _basicDescriptionController.text =
            'Nursery to Intermediate 1 hour session';

        _standardDescriptionController.text = 'O/A levels 1 hour session';

        _premiumDescriptionController.text =
            'University level or higher 1 hour session';

        break;

      default:

        // Default descriptions for other categories

        _basicDescriptionController.text =
            'Basic service offering with standard features and regular support.';

        _standardDescriptionController.text =
            'Enhanced service with additional features and priority support.';

        _premiumDescriptionController.text =
            'Premium service with all features, dedicated support, and customized solutions.';
    }
  }

  @override
  void dispose() {
    // Dispose service rates controllers

    _basicPriceController.dispose();

    _basicDescriptionController.dispose();

    _basicDurationController.dispose();

    _standardPriceController.dispose();

    _standardDescriptionController.dispose();

    _standardDurationController.dispose();

    _premiumPriceController.dispose();

    _premiumDescriptionController.dispose();

    _premiumDurationController.dispose();

    super.dispose();
  }

  Future<void> _loadServiceDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        // TODO: Load from Supabase
        _experience = prefs.getString('experience') ?? '';

        _availability = prefs.getString('availability') ?? '';

        _description = prefs.getString('description') ?? '';

        // Load contact information from registration
        _email = prefs.getString('provider_email') ?? '';
        _phoneNumber = prefs.getString('provider_phone') ?? '';

        // Load service location
        _serviceLocation = prefs.getString('service_location') ?? '';

        // Load provider name
        // TODO: Load from Supabase
        _providerName = prefs.getString('provider_name') ?? '';

        // Load profile image path
        final savedImagePath = prefs.getString('profile_image_path');
        if (savedImagePath != null && File(savedImagePath).existsSync()) {
          _profileImagePath = savedImagePath;
          _profileImage = File(savedImagePath);
        }

        // Load cover photo path
        final savedCoverPhotoPath = prefs.getString('cover_photo_path');
        if (savedCoverPhotoPath != null &&
            File(savedCoverPhotoPath).existsSync()) {
          _coverPhotoPath = savedCoverPhotoPath;
        }

        // Alternative: Use ProviderDataService for consistency
        // final providerData = await ProviderDataService.getProviderData('current_provider');
        // if (providerData['profile_image_path'] != null && File(providerData['profile_image_path']).existsSync()) {
        //   _profileImagePath = providerData['profile_image_path'];
        //   _profileImage = File(providerData['profile_image_path']);
        // }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Input validation for service details

  // Profile image picker method
  Future<void> _pickProfileImage() async {
    try {
      debugPrint('Starting image picker...');
      final ImagePicker picker = ImagePicker();
      debugPrint('ImagePicker instance created');

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 85,
      );

      debugPrint('Image picker completed. Picked file: ${pickedFile?.path}');

      if (pickedFile != null) {
        if (kIsWeb) {
          // For web, read the image as bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _profileImageBytes = bytes;
            _profileImagePath = pickedFile.path;
          });
          debugPrint(
              'Profile image bytes loaded for web: ${bytes.length} bytes');
        } else {
          // For mobile/desktop, use file path
          setState(() {
            _profileImage = File(pickedFile.path);
            _profileImagePath = pickedFile.path;
          });
          debugPrint('Profile image file set for mobile: ${pickedFile.path}');
        }

        // Save the image path to SharedPreferences
        await _saveProfileImagePath();

        debugPrint('Profile image selected and saved: ${pickedFile.path}');

        // Show success feedback
        if (mounted) {
          // Enhanced feedback with toast, haptic, and animation
          HapticFeedbackUtils.success();
          FeedbackUtils.showSuccessToast(
              'Profile picture updated successfully!',
              context: context);

          // Trigger success animation
          setState(() {
            _showProfileSuccessAnimation = true;
          });

          // Reset animation flag after delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showProfileSuccessAnimation = false;
              });
            }
          });
        }
      } else {
        debugPrint('No image selected');
      }
    } catch (e, stackTrace) {
      debugPrint('Error picking image: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        // Enhanced error feedback with haptic and recovery dialog
        HapticFeedbackUtils.error();
        _showErrorRecoveryDialog(
          error: e.toString(),
          suggestion: 'Please check your camera permissions and try again.',
          onRetry: () => _pickProfileImage(),
        );
      }
    }
  }

  // Save profile image path to SharedPreferences
  Future<void> _saveProfileImagePath() async {
    try {
      // Use ProviderDataService for consistency
      await ProviderDataService.updateProviderData({
        'profile_image_path': _profileImagePath,
      });

      // Alternative: Direct SharedPreferences access
      // final prefs = await SharedPreferences.getInstance();
      // if (_profileImagePath != null) {
      //   await prefs.setString('profile_image_path', _profileImagePath!);
      // }

      debugPrint('Profile image path saved via ProviderDataService');
    } catch (e) {
      debugPrint('Error saving profile image path: $e');
    }
  }

  // Cover photo picker method
  Future<void> _pickCoverPhoto() async {
    try {
      debugPrint('Starting cover photo picker...');
      final ImagePicker picker = ImagePicker();
      debugPrint('ImagePicker instance created for cover photo');

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        debugPrint('Cover photo selected: ${pickedFile.path}');

        // Save the cover photo path
        setState(() {
          _coverPhotoPath = pickedFile.path;
        });
        await _saveCoverPhotoPath();

        debugPrint('Cover photo selected and saved: ${pickedFile.path}');

        // Show success feedback
        if (mounted) {
          HapticFeedbackUtils.success();
          FeedbackUtils.showSuccessToast(
            'Cover photo updated successfully!',
            context: context,
          );
        }
      } else {
        debugPrint('No cover photo selected');
        if (mounted) {
          FeedbackUtils.showInfoToast(
            'No cover photo selected',
            context: context,
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking cover photo: $e');
      if (mounted) {
        HapticFeedbackUtils.error();
        _showErrorRecoveryDialog(
          error: e.toString(),
          suggestion: 'Please check your camera permissions and try again.',
          onRetry: () => _pickCoverPhoto(),
        );
      }
    }
  }

  // Save cover photo path to SharedPreferences
  Future<void> _saveCoverPhotoPath() async {
    try {
      // Use ProviderDataService for consistency
      await ProviderDataService.updateProviderData({
        'cover_photo_path': _coverPhotoPath,
      });

      debugPrint('Cover photo path saved via ProviderDataService');
    } catch (e) {
      debugPrint('Error saving cover photo path: $e');
    }
  }

  // Show edit name dialog
  void _showEditNameDialog() {
    final nameController = TextEditingController(text: _providerName);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Edit Your Name',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Your Name',
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF047A62)),
              ),
            ),
            style: GoogleFonts.poppins(),
            maxLength: 50,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();

                // Close dialog first before async operations
                Navigator.pop(dialogContext);

                if (newName.isNotEmpty && newName != _providerName) {
                  setState(() {
                    _providerName = newName;
                  });

                  // Save to ProviderDataService
                  await ProviderDataService.updateProviderData({
                    'provider_name': _providerName,
                  });

                  // Show success feedback
                  if (mounted) {
                    // Enhanced feedback with toast, haptic, and animation
                    HapticFeedbackUtils.success();
                    FeedbackUtils.showSuccessToast('Name updated successfully!',
                        context: context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047A62),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Build profile image widget with web/mobile compatibility
  Widget _buildProfileImageWidget() {
    if (kIsWeb) {
      // For web, use Image.memory if bytes are available
      if (_profileImageBytes != null) {
        return Image.memory(
          _profileImageBytes!,
          fit: BoxFit.cover,
          width: 90,
          height: 90,
        );
      }
    } else {
      // For mobile/desktop, use Image.file
      if (_profileImage != null) {
        return Image.file(
          _profileImage!,
          fit: BoxFit.cover,
          width: 90,
          height: 90,
        );
      }
    }

    // Fallback to default icon with camera overlay
    return Stack(
      children: [
        Icon(Icons.person_rounded,
            size: 50, color: Theme.of(context).colorScheme.primary),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }

  // Safe method to get document name at index

  String _getDocumentName(int index) {
    try {
      if (index < 0 || index >= _documentNames.length) {
        return 'Document ${index + 1}';
      }

      return _documentNames[index];
    } catch (e) {
      debugPrint('Error getting document name at index $index: $e');

      return 'Document ${index + 1}';
    }
  }

  // Safe method to get document status at index

  String _getDocumentStatus(int index) {
    try {
      if (index < 0 || index >= _documentStatuses.length) {
        return 'Unknown';
      }

      return _documentStatuses[index];
    } catch (e) {
      debugPrint('Error getting document status at index $index: $e');

      return 'Unknown';
    }
  }

  // Safe method to get document expiry at index

  String _getDocumentExpiry(int index) {
    try {
      if (index < 0 || index >= _documentExpiryDates.length) {
        return '2024-12-31';
      }

      return _documentExpiryDates[index];
    } catch (e) {
      debugPrint('Error getting document expiry at index $index: $e');

      return '2024-12-31';
    }
  }

  Widget _buildDocumentCard(int index) {
    return GestureDetector(
      onTap: () => _showDocumentPreview(index),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildUploadButton(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primary = theme.colorScheme.primary;

    final surface = theme.colorScheme.surface;

    final onSurface = theme.colorScheme.onSurface;

    final muted = onSurface.withValues(alpha: 0.6);

    // Show enhanced loading skeleton while data is loading

    if (_isLoading) {
      return Scaffold(
        backgroundColor: surface,
        body: _buildProfileSkeleton(),
      );
    }

    return Scaffold(
      backgroundColor: surface,
      body: FocusScope(
        autofocus: true,
        child: Stack(
          children: [
            // ─── Scrollable Content ───

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Premium Header ───

                  ProfileHeaderWidget(
                    providerName: _providerName,
                    profileImagePath: _profileImagePath,
                    profileImageBytes: _profileImageBytes,
                    coverPhotoPath: _coverPhotoPath,
                    isCNICVerified: _isCNICVerified,
                    rating: 4.9,
                    reviewCount: 124,
                    showProfileSuccessAnimation: _showProfileSuccessAnimation,
                    isMobile: _isMobile,
                    onPickProfileImage: _pickProfileImage,
                    onEditName: _showEditNameDialog,
                    buildProfileImageWidget: _buildProfileImageWidget,
                  ),

                  const SizedBox(height: 24),

                  // ─── Menu Sections ───

                  _buildSectionHeader('PROFESSIONAL INFO', muted),

                  _buildMenuItem(Icons.badge_outlined, 'Service Details',
                      '$_email • Experience: $_experience', onSurface, primary,
                      onTap: () => _showServiceDetailsDialog()),

                  _buildMenuItem(
                      Icons.image_outlined,
                      'Cover Photo',
                      _coverPhotoPath != null
                          ? 'Cover photo set'
                          : 'Set your profile cover photo',
                      onSurface,
                      primary,
                      onTap: () => _pickCoverPhoto()),

                  _buildMenuItem(
                      Icons.attach_money_rounded,
                      'Manage Services Rates',
                      'Set rates for different services',
                      onSurface,
                      primary,
                      onTap: () => _showManageServicesRatesDialog()),

                  _buildMenuItem(Icons.description_outlined, 'CNIC & Documents',
                      'Verified', onSurface, primary,
                      onTap: () => _showDocumentsDialog()),

                  _buildMenuItem(
                      Icons.account_balance_wallet_outlined,
                      'Earnings & Payouts',
                      'Rs. 12,450 this month',
                      onSurface,
                      primary,
                      onTap: () => _showEarningsDialog()),

                  // Priority Earnings Highlight Card
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: _isMobile ? 16 : 24,
                      vertical: _responsiveCompactSpacing,
                    ),
                    padding: EdgeInsets.all(_isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF047A62),
                          const Color(0xFF047A62).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(_cardBorderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF047A62).withValues(alpha: 0.3),
                          blurRadius: _cardElevation * 3,
                          offset: Offset(0, _cardElevation * 1.5),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: _cardElevation * 2,
                          offset: Offset(0, _cardElevation),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current Earnings',
                              style: GoogleFonts.poppins(
                                fontSize: _isMobile ? 12 : 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: _responsiveCompactSpacing,
                                vertical: _microSpacing,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(_tightSpacing),
                              ),
                              child: Text(
                                'This Month',
                                style: GoogleFonts.poppins(
                                  fontSize: _isMobile ? 10 : 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: _responsiveCompactSpacing),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rs. 12,450',
                              style: GoogleFonts.poppins(
                                fontSize: _isMobile ? 24 : 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Container(
                              padding:
                                  EdgeInsets.all(_responsiveCompactSpacing),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.9),
                                borderRadius:
                                    BorderRadius.circular(_tightSpacing),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.trending_up_rounded,
                                size: _isMobile ? 16 : 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: _responsiveMajorSpacing),

                  _buildSectionHeader('SETTINGS', muted),

                  _buildMenuItem(Icons.security_outlined, 'Security',
                      'Password & Biometrics', onSurface, primary,
                      onTap: () => _showSecurityDialog()),

                  _buildMenuItem(Icons.language_outlined, 'Language', 'English',
                      onSurface, primary,
                      onTap: () => _showLanguageDialog()),

                  SizedBox(height: _responsiveMajorSpacing),

                  _buildSectionHeader('SUPPORT', muted),

                  _buildMenuItem(Icons.help_outline_rounded, 'Help Center',
                      'FAQs & Guides', onSurface, primary,
                      onTap: () => _showHelpSupportDialog()),

                  _buildMenuItem(Icons.contact_emergency, 'Emergency Contacts',
                      'Manage contacts for SOS alerts', onSurface, primary,
                      onTap: () => _showEmergencyContactsDialog()),

                  SizedBox(height: _responsiveMajorSpacing),

                  // ─── Logout ───

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: OutlinedButton.icon(
                      onPressed: () async {
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
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LogoutSplashScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: Text(
                        'Logout',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Muawin Pro v1.2.0',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Sticky Bottom Navigation Bar ───

            Align(
              alignment: Alignment.bottomCenter,
              child: MuawinBottomNavigationBar(
                currentIndex: _currentNavIndex,
                isProvider: true,
                onItemTapped: (index) {
                  if (index == 0) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const ServiceProviderFeedScreen()),
                      (route) => false,
                    );

                    return;
                  }

                  if (index == 1) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const MyJobsScreen(),
                    ));

                    return;
                  }

                  if (index == 2) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ChatsScreen(),
                    ));

                    return;
                  }

                  // Index 3 is current screen
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Section Header with Visual Separator
  Widget _buildSectionHeader(String title, Color color) {
    return Column(
      children: [
        // Visual divider line
        Container(
          height: 1,
          margin: EdgeInsets.symmetric(horizontal: _isMobile ? 16 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                color.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),

        SizedBox(height: _responsiveSubSpacing),

        // Section title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _isMobile ? 16 : 24),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: _responsiveCompactSpacing,
                  vertical: _microSpacing,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(_tightSpacing),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: _isMobile ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: _responsiveItemSpacing),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle,
      Color onSurface, Color primary,
      {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: _isMobile ? 16 : 24, vertical: _responsiveCompactSpacing),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedbackUtils.selectionClick();
            if (onTap != null) onTap();
          },
          borderRadius: BorderRadius.circular(_cardBorderRadius),
          splashColor: primary.withValues(alpha: 0.1),
          highlightColor: primary.withValues(alpha: 0.05),
          child: Container(
            constraints: BoxConstraints(
              minHeight: _minTouchTarget,
            ),
            padding: EdgeInsets.all(_isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_cardBorderRadius),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: _cardElevation * 2,
                  offset: Offset(0, _cardElevation),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: _cardElevation * 4,
                  offset: Offset(0, _cardElevation * 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(_responsiveCompactSpacing),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(_cardBorderRadius - 2),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: _isMobile ? 22 : 24,
                    color: primary,
                  ),
                ),
                SizedBox(width: _responsiveCompactSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: _isMobile ? 15 : 16,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: _microSpacing),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: _isMobile ? 13 : 14,
                            fontWeight: FontWeight.w400,
                            color: onSurface.withValues(alpha: 0.7),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: _responsiveCompactSpacing),
                Icon(
                  Icons.arrow_forward_ios,
                  size: _isMobile ? 16 : 18,
                  color: onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showServiceDetailsDialog() {
    if (_isLoading) {
      // Enhanced info feedback with toast
      HapticFeedbackUtils.lightImpact();
      FeedbackUtils.showInfoToast('Please wait while data loads...',
          context: context);

      return;
    }

    int currentStep = 1;
    const totalSteps = 2; // Reduced from 3 to 2 (removed Service Rates)

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: _isMobile ? double.maxFinite : 500,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wizard Header with Progress - Fixed at top
                Container(
                  padding: EdgeInsets.all(_isMobile ? 20 : 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Step Progress Indicator
                      Row(
                        children: [
                          for (int i = 1; i <= totalSteps; i++) ...[
                            Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(
                                    right: i < totalSteps ? 2 : 0),
                                decoration: BoxDecoration(
                                  color: i <= currentStep
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      SizedBox(height: _responsiveSubSpacing),

                      // Step Title
                      Text(
                        _getStepTitle(currentStep),
                        style: GoogleFonts.poppins(
                          fontSize: _isMobile ? 18 : 20,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: _compactSpacing),

                      // Step Subtitle
                      Text(
                        _getStepSubtitle(currentStep),
                        style: GoogleFonts.poppins(
                          fontSize: _isMobile ? 13 : 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Step Content - Scrollable to prevent overflow
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(_isMobile ? 20 : 24),
                    child: _buildStepContent(currentStep, setState),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Navigation Buttons Container
            Container(
              padding: EdgeInsets.all(_isMobile ? 16 : 20),
              child: Column(
                children: [
                  // Main Navigation Row
                  Row(
                    children: [
                      // Previous Button
                      if (currentStep > 1)
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: _responsiveCompactSpacing),
                            child: OutlinedButton(
                              onPressed: () {
                                HapticFeedbackUtils.lightImpact();
                                setState(() => currentStep--);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: _responsiveCompactSpacing),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(_cardBorderRadius),
                                ),
                              ),
                              child: Text(
                                'Previous',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Next/Save Button - Reduced size
                      if (currentStep > 1)
                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedbackUtils.lightImpact();
                              if (currentStep < totalSteps) {
                                setState(() => currentStep++);
                              } else {
                                _saveWizardServiceDetails();
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  vertical: _responsiveCompactSpacing),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_cardBorderRadius),
                              ),
                            ),
                            child: Text(
                              currentStep < totalSteps ? 'Next' : 'Save',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        // Next/Save Button - Full width when no Previous button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedbackUtils.lightImpact();
                              if (currentStep < totalSteps) {
                                setState(() => currentStep++);
                              } else {
                                _saveWizardServiceDetails();
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  vertical: _responsiveCompactSpacing),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(_cardBorderRadius),
                              ),
                            ),
                            child: Text(
                              currentStep < totalSteps ? 'Next' : 'Save',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Cancel Button - Separate row with proper spacing
                  if (currentStep > 1)
                    SizedBox(height: _responsiveCompactSpacing),

                  // Cancel Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          HapticFeedbackUtils.lightImpact();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Basic Information';
      case 2:
        return 'Availability';
      default:
        return '';
    }
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 1:
        return 'View your contact information and update experience and service description';
      case 2:
        return 'Set your availability schedule';
      default:
        return '';
    }
  }

  Widget _buildStepContent(int step, StateSetter setState) {
    switch (step) {
      case 1:
        return _buildBasicInfoStep(setState);
      case 2:
        return _buildAvailabilityStep(setState);
      default:
        return Container();
    }
  }

  Widget _buildBasicInfoStep(StateSetter setState) {
    final experienceController = TextEditingController(text: _experience);
    final descriptionController = TextEditingController(text: _description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email Field (Read-only from registration)
        Text(
          'Email Address',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: _compactSpacing),
        TextField(
          controller: TextEditingController(text: _email),
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Email from registration',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_cardBorderRadius),
            ),
            prefixIcon: const Icon(Icons.email),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          style: GoogleFonts.poppins(),
          enabled: false, // Read-only - from registration
        ),
        SizedBox(height: _responsiveItemSpacing),

        // Phone Number Field (Read-only from registration)
        Text(
          'Phone Number',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: _compactSpacing),
        TextField(
          controller: TextEditingController(text: _phoneNumber),
          decoration: InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Phone from registration',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_cardBorderRadius),
            ),
            prefixIcon: const Icon(Icons.phone),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          style: GoogleFonts.poppins(),
          enabled: false, // Read-only - from registration
        ),
        SizedBox(height: _responsiveItemSpacing),

        // Experience Field (Editable)
        Text(
          'Experience',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: _compactSpacing),
        TextField(
          controller: experienceController,
          decoration: InputDecoration(
            labelText: 'Years of Experience',
            hintText: 'e.g., 3 years',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_cardBorderRadius),
            ),
            prefixIcon: const Icon(Icons.timeline),
          ),
          style: GoogleFonts.poppins(),
          onChanged: (value) => _experience = value,
        ),
        SizedBox(height: _responsiveItemSpacing),

        // Description Field (Editable)
        Text(
          'Description',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: _compactSpacing),
        TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Service Description',
            hintText: 'Describe your services...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_cardBorderRadius),
            ),
            prefixIcon: const Icon(Icons.description),
          ),
          style: GoogleFonts.poppins(),
          onChanged: (value) => _description = value,
        ),
      ],
    );
  }

  Widget _buildAvailabilityStep(StateSetter setState) {
    final availabilityController = TextEditingController(text: _availability);
    final serviceAreaController = TextEditingController(text: _serviceArea);
    final serviceLocationController =
        TextEditingController(text: _serviceLocation);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability Status',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: _compactSpacing),
        TextField(
          controller: availabilityController,
          decoration: InputDecoration(
            labelText: 'Availability',
            hintText: 'e.g., Full-time, Part-time, Weekends',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_cardBorderRadius),
            ),
            prefixIcon: const Icon(Icons.schedule),
          ),
          style: GoogleFonts.poppins(),
          onChanged: (value) => _availability = value,
        ),
        SizedBox(height: _responsiveItemSpacing),
        Text(
          'Service Area',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: _compactSpacing),
        TextField(
          controller: serviceAreaController,
          decoration: InputDecoration(
            labelText: 'Primary Service Area',
            hintText: 'e.g., Lahore, Karachi, Islamabad',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_cardBorderRadius),
            ),
            prefixIcon: const Icon(Icons.location_on),
          ),
          style: GoogleFonts.poppins(),
          onChanged: (value) => _serviceArea = value,
        ),
        SizedBox(height: _responsiveItemSpacing),
        Text(
          'Service Location *',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: _compactSpacing),
        TextField(
          controller: serviceLocationController,
          decoration: InputDecoration(
            labelText: 'Google Maps Location Link',
            hintText: 'https://maps.google.com/?q=...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_cardBorderRadius),
            ),
            prefixIcon: const Icon(Icons.map),
            suffixIcon: IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('How to get Google Maps link',
                        style: GoogleFonts.poppins()),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Open Google Maps',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '2. Search and select your service location',
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '3. Tap "Share" and copy the link',
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '4. Paste the link here',
                          style: GoogleFonts.poppins(),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber,
                                  color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'This location is required to determine if you are within 5km of service requests.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.orange[700],
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
                        onPressed: () => Navigator.pop(context),
                        child: Text('Got it', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          style: GoogleFonts.poppins(),
          onChanged: (value) => _serviceLocation = value,
        ),
        SizedBox(height: _responsiveItemSpacing),
        Container(
          padding: EdgeInsets.all(_responsiveItemSpacing),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(_cardBorderRadius),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[700],
                size: 20,
              ),
              SizedBox(width: _responsiveCompactSpacing),
              Expanded(
                child: Text(
                  'Your service location will be used to match you with customers within 5km radius.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.blue[700],
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveWizardServiceDetails() async {
    try {
      // Show loading feedback
      HapticFeedbackUtils.lightImpact();

      // Validate service location (required field)
      if (_serviceLocation.trim().isEmpty) {
        if (mounted) {
          HapticFeedbackUtils.error();
          FeedbackUtils.showErrorToast('Service location is required',
              context: context);
        }
        return;
      }

      // Validate Google Maps link format
      if (!_serviceLocation.startsWith('https://maps.google.com/') &&
          !_serviceLocation.startsWith('https://www.google.com/maps/')) {
        if (mounted) {
          HapticFeedbackUtils.error();
          FeedbackUtils.showErrorToast('Please enter a valid Google Maps link',
              context: context);
        }
        return;
      }

      // Save to ProviderDataService (email, phone, and hourly_rate are read-only from registration)
      await ProviderDataService.updateProviderData({
        'experience': _experience,
        'availability': _availability,
        'service_area': _serviceArea,
        'service_location': _serviceLocation, // New field
        'description': _description,
        // Note: email, phone, and hourly_rate are not saved here as they are from registration
      });

      // Show success feedback
      if (mounted) {
        HapticFeedbackUtils.success();
        FeedbackUtils.showSuccessToast('Service details updated successfully!',
            context: context);
      }
    } catch (e) {
      // Show error feedback
      if (mounted) {
        HapticFeedbackUtils.error();
        FeedbackUtils.showErrorToast('Error updating service details',
            context: context);
      }
    }
  }

  void _showDocumentsDialog() {
    if (_isLoading) {
      // Enhanced info feedback with toast
      HapticFeedbackUtils.lightImpact();
      FeedbackUtils.showInfoToast('Please wait while data loads...',
          context: context);

      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: _dialogWidth,
            constraints: BoxConstraints(
              maxHeight: _dialogHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(_verticalPadding),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CNIC & Documents',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(_isMobile ? 8 : 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(_isMobile ? 8 : 10),
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[600],
                            size: _isMobile ? 20 : 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(_verticalPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CNIC Section
                        _buildCNICSection(setState),

                        const SizedBox(height: 20),

                        // Other Documents Section
                        Text(
                          'Additional Documents',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Search and filter functionality
                        _buildDocumentSearchBar(setState),
                        _buildFilterSummary(setState),

                        // Filtered documents list
                        _buildFilteredDocumentsList(),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: EdgeInsets.all(_verticalPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(width: _isMobile ? 8 : 12),
                      ElevatedButton(
                        onPressed: () => _showUploadDocumentDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Upload Document',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getDocumentStatusColor(String status) {
    switch (status) {
      case 'Verified':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      case 'Expired':
        return Colors.red;
      case 'Processing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getDocumentStatusIcon(String status) {
    switch (status) {
      case 'Verified':
        return Icons.check_circle;
      case 'Pending':
        return Icons.pending_actions;
      case 'Rejected':
        return Icons.cancel;
      case 'Expired':
        return Icons.error;
      case 'Processing':
        return Icons.sync;
      default:
        return Icons.help_outline;
    }
  }

  // CNIC Section Widget
  Widget _buildCNICSection(StateSetter setState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CNIC Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isCNICVerified
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isCNICVerified ? Icons.check_circle : Icons.pending_actions,
                  size: 20,
                  color: _isCNICVerified ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CNIC Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'National Identity Card',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedbackUtils.selectionClick();
                  setState(() {
                    _isCNICExpanded = !_isCNICExpanded;
                  });
                },
                icon: Icon(
                  _isCNICExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // CNIC Details (conditionally shown)
          if (_isCNICExpanded) ...[
            // CNIC Number
            _buildDocumentDetail('CNIC Number', _cnicNumber),
            const SizedBox(height: 8),

            // Status
            _buildDocumentDetail('Status', _cnicStatus),
            const SizedBox(height: 8),

            // Expiry Date
            _buildDocumentDetail('Expiry Date', _cnicExpiry),
            const SizedBox(height: 12),

            // Verification Status Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isCNICVerified
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isCNICVerified ? Colors.green : Colors.orange,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCNICVerified ? Icons.check_circle : Icons.info_outline,
                    size: 20,
                    color: _isCNICVerified ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isCNICVerified
                          ? 'Your CNIC has been verified by Muawin'
                          : 'Your CNIC verification is pending review by Muawin admin',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _isCNICVerified
                            ? Colors.green[800]
                            : Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Calculate expiry date based on document type
  String _calculateExpiryDate(String documentType) {
    final now = DateTime.now();
    switch (documentType) {
      case 'Driver License':
        return DateTime(now.year + 5, now.month, now.day)
            .toString()
            .split(' ')[0];
      case 'Vehicle Registration':
        return DateTime(now.year + 3, now.month, now.day)
            .toString()
            .split(' ')[0];
      case 'Insurance Certificate':
        return DateTime(now.year + 1, now.month, now.day)
            .toString()
            .split(' ')[0];
      case 'National ID':
        return DateTime(now.year + 10, now.month, now.day)
            .toString()
            .split(' ')[0];
      case 'Passport':
        return DateTime(now.year + 10, now.month, now.day)
            .toString()
            .split(' ')[0];
      case 'Work Permit':
        return DateTime(now.year + 2, now.month, now.day)
            .toString()
            .split(' ')[0];
      case 'Professional Certificate':
        return DateTime(now.year + 3, now.month, now.day)
            .toString()
            .split(' ')[0];
      case 'Background Check':
        return DateTime(now.year + 1, now.month, now.day)
            .toString()
            .split(' ')[0];
      case 'Medical Certificate':
        return DateTime(now.year + 2, now.month, now.day)
            .toString()
            .split(' ')[0];
      default:
        return DateTime(now.year + 1, now.month, now.day)
            .toString()
            .split(' ')[0];
    }
  }

  // Document search and filter functionality
  List<int> _getFilteredDocumentIndices() {
    final List<int> filteredIndices = [];

    for (int i = 0; i < _documentNames.length; i++) {
      final documentName = _documentNames[i].toLowerCase();
      final documentStatus = _documentStatuses[i].toLowerCase();
      final searchQuery = _documentSearchQuery.toLowerCase();

      // Apply search filter
      final matchesSearch = searchQuery.isEmpty ||
          documentName.contains(searchQuery) ||
          documentStatus.contains(searchQuery);

      // Apply status filter
      final matchesFilter = _selectedDocumentFilter == 'All' ||
          _documentStatuses[i] == _selectedDocumentFilter;

      if (matchesSearch && matchesFilter) {
        filteredIndices.add(i);
      }
    }

    return filteredIndices;
  }

  void _updateDocumentSearch(String query, StateSetter setState) {
    setState(() {
      _documentSearchQuery = query;
    });
  }

  void _updateDocumentFilter(String filter, StateSetter setState) {
    setState(() {
      _selectedDocumentFilter = filter;
    });
  }

  void _clearDocumentSearch(StateSetter setState) {
    setState(() {
      _documentSearchQuery = '';
      _documentSearchController.clear();
    });
  }

  // Document search bar widget
  Widget _buildDocumentSearchBar(StateSetter setState) {
    return Container(
      margin: EdgeInsets.only(bottom: _cardSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_isMobile ? 10 : 12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _documentSearchController,
              onChanged: (query) => _updateDocumentSearch(query, setState),
              decoration: InputDecoration(
                hintText: 'Search documents...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: _isMobile ? 14 : 16,
                  color: Colors.grey[600],
                ),
                prefixIcon: Icon(Icons.search,
                    color: Colors.grey, size: _isMobile ? 20 : 24),
                suffixIcon: _documentSearchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () => _clearDocumentSearch(setState),
                        icon: Icon(Icons.clear,
                            color: Colors.grey, size: _isMobile ? 20 : 24),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _isMobile ? 12 : 16,
                  vertical: _isMobile ? 10 : 12,
                ),
              ),
              style: GoogleFonts.poppins(
                fontSize: _isMobile ? 14 : 16,
                color: Colors.black87,
              ),
            ),
          ),

          SizedBox(height: _isMobile ? 8 : 12),

          // Filter chips
          SizedBox(
            height: _isMobile ? 32 : 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All', Icons.apps, setState),
                _buildFilterChip('Verified', Icons.check_circle, setState),
                _buildFilterChip('Pending', Icons.pending_actions, setState),
                _buildFilterChip('Rejected', Icons.cancel, setState),
                _buildFilterChip('Expired', Icons.error, setState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filter chip widget
  Widget _buildFilterChip(String filter, IconData icon, StateSetter setState) {
    final isSelected = _selectedDocumentFilter == filter;
    final color = _getDocumentStatusColor(filter);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              filter,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _updateDocumentFilter(filter, setState);
          }
        },
        backgroundColor: color.withValues(alpha: 0.1),
        selectedColor: color,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  // Filter summary widget
  Widget _buildFilterSummary(StateSetter setState) {
    final filteredIndices = _getFilteredDocumentIndices();
    final totalDocuments = _documentNames.length;
    final filteredCount = filteredIndices.length;

    if (_documentSearchQuery.isEmpty && _selectedDocumentFilter == 'All') {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 16,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing $filteredCount of $totalDocuments documents'
              '${_documentSearchQuery.isNotEmpty ? ' matching "$_documentSearchQuery"' : ''}'
              '${_selectedDocumentFilter != 'All' ? ' with status "$_selectedDocumentFilter"' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_documentSearchQuery.isNotEmpty ||
              _selectedDocumentFilter != 'All')
            GestureDetector(
              onTap: () {
                _clearDocumentSearch(setState);
                _updateDocumentFilter('All', setState);
              },
              child: Icon(
                Icons.clear,
                size: 16,
                color: Colors.blue[700],
              ),
            ),
        ],
      ),
    );
  }

  // Filtered documents list widget
  Widget _buildFilteredDocumentsList() {
    final filteredIndices = _getFilteredDocumentIndices();

    // Only show documents that actually have content (not empty slots)
    final validDocumentIndices = filteredIndices.where((index) {
      return _documentInfo[index]['name']?.isNotEmpty == true ||
          _uploadStatus[index] == UploadStatus.selected ||
          _uploadStatus[index] == UploadStatus.uploading ||
          _uploadStatus[index] == UploadStatus.processing ||
          _uploadStatus[index] == UploadStatus.verifying ||
          _uploadStatus[index] == UploadStatus.success;
    }).toList();

    if (validDocumentIndices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.folder_open,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              'No additional documents',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use the Upload Document button below to add documents',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: validDocumentIndices.length,
      itemBuilder: (context, index) {
        final documentIndex = validDocumentIndices[index];
        return _buildDocumentCard(documentIndex);
      },
    );
  }

  void _showUploadDocumentDialog() {
    Navigator.of(context).pop(); // Close current dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Upload Document',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Document category selection option
            ListTile(
              leading: Icon(Icons.category,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Choose Document Category',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Select from available document categories',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showDocumentCategorySelectionDialog();
              },
            ),
            const Divider(),

            // Batch upload option
            ListTile(
              leading: Icon(Icons.upload_file,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Batch Upload',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Upload multiple documents at once',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showBatchUploadDialog();
              },
            ),
            const Divider(),

            // Quick upload options
            ListTile(
              leading: Icon(Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Take Photo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Upload document using camera',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _captureDocument(
                    0); // Upload first document using enhanced camera
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Select document from device gallery',
                style:
                    GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickDocumentFromGallery(
                    1); // Upload second document using gallery
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  // Document Category Selection Dialog
  void _showDocumentCategorySelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Select Document Category',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _documentCategories.length,
            itemBuilder: (context, index) {
              final category = _documentCategories[index];
              final icon = _documentCategoryIcons[category] ?? 'description';
              final color = _documentCategoryColors[category] ?? Colors.grey;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconFromString(icon),
                    color: color,
                    size: 20,
                  ),
                ),
                title: Text(
                  category,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showCategorySpecificUpload(category);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  // Category-specific upload
  void _showCategorySpecificUpload(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Upload $category',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Take Photo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _captureDocumentWithCategory(category);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickDocumentFromGalleryWithCategory(category);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  // Batch Upload Dialog
  void _showBatchUploadDialog() {
    setState(() {
      _selectedDocuments.clear();
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Batch Upload Documents',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select documents to upload:',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(3, (index) {
                    return CheckboxListTile(
                      value: _selectedDocuments.contains(index),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedDocuments.add(index);
                          } else {
                            _selectedDocuments.remove(index);
                          }
                        });
                      },
                      title: Text(
                        _documentInfo[index]['category'] ??
                            'Document ${index + 1}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        _documentInfo[index]['name']?.isNotEmpty == true
                            ? _documentInfo[index]['name']!
                            : 'No file selected',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_documentCategoryColors[_documentInfo[index]
                                      ['category']] ??
                                  Colors.grey)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconFromString(
                            _documentCategoryIcons[_documentInfo[index]
                                    ['category']] ??
                                'description',
                          ),
                          color: _documentCategoryColors[_documentInfo[index]
                                  ['category']] ??
                              Colors.grey,
                          size: 20,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: _selectedDocuments.isNotEmpty
                    ? () {
                        Navigator.of(context).pop();
                        _startBatchUpload();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Upload Selected (${_selectedDocuments.length})',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Start Batch Upload
  void _startBatchUpload() async {
    setState(() {
      _batchUploadProgress = 0;
      _batchUploadTotal = _selectedDocuments.length;
      _batchUploadStatus = 'Starting batch upload...';
    });

    // Show batch upload progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Batch Upload Progress',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            content: SizedBox(
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: _batchUploadTotal > 0
                        ? _batchUploadProgress / _batchUploadTotal
                        : 0.0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_batchUploadProgress / $_batchUploadTotal documents uploaded',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _batchUploadStatus,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Process each selected document
    for (int i = 0; i < _selectedDocuments.length; i++) {
      final documentIndex = _selectedDocuments[i];

      setState(() {
        _batchUploadProgress = i;
        _batchUploadStatus =
            'Uploading ${_documentInfo[documentIndex]['category']}...';
      });

      // Simulate upload process
      await _processDocumentUpload(
        XFile(_documentInfo[documentIndex]['path'] ?? ''),
        documentIndex,
      );

      // Small delay between uploads
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Complete batch upload
    setState(() {
      _batchUploadProgress = _batchUploadTotal;
      _batchUploadStatus = 'Batch upload completed!';
    });

    // Close progress dialog and show success
    if (mounted) {
      Navigator.of(context).pop();

      HapticFeedbackUtils.success();
      FeedbackUtils.showSuccessToast(
        'Batch upload completed! $_batchUploadTotal documents uploaded successfully.',
        context: context,
      );
    }
  }

  // Helper method to get icon from string
  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'badge':
        return Icons.badge;
      case 'drive_eta':
        return Icons.drive_eta;
      case 'directions_car':
        return Icons.directions_car;
      case 'security':
        return Icons.security;
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'account_balance':
        return Icons.account_balance;
      case 'receipt':
        return Icons.receipt;
      case 'description':
      default:
        return Icons.description;
    }
  }

  // Category-specific capture methods
  void _captureDocumentWithCategory(String category) async {
    try {
      await _showCameraGuidelines();

      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (file != null) {
        final fileSize = await file.length();
        const index = 0; // Use first available slot

        setState(() {
          _uploadStatus[index] = UploadStatus.selected;
          _documentInfo[index] = {
            'name': file.name,
            'size': '${(fileSize / 1024).toStringAsFixed(1)} KB',
            'type': file.path.split('.').last.toUpperCase(),
            'status': 'Ready to upload',
            'path': file.path,
            'category': category,
          };
        });

        await _showDocumentPreviewDialog(file, index);
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showErrorToast(
          'Camera error: ${e.toString()}',
          context: context,
        );
      }
    }
  }

  void _pickDocumentFromGalleryWithCategory(String category) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (file != null) {
        final fileSize = await file.length();
        const index = 1; // Use second slot

        setState(() {
          _uploadStatus[index] = UploadStatus.selected;
          _documentInfo[index] = {
            'name': file.name,
            'size': '${(fileSize / 1024).toStringAsFixed(1)} KB',
            'type': file.path.split('.').last.toUpperCase(),
            'status': 'Ready to upload',
            'path': file.path,
            'category': category,
          };
        });

        await _showDocumentPreviewDialog(file, index);
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showErrorToast(
          'Gallery error: ${e.toString()}',
          context: context,
        );
      }
    }
  }

  void _showEarningsDialog() {
    if (_isLoading) {
      // Enhanced info feedback with toast
      HapticFeedbackUtils.lightImpact();
      FeedbackUtils.showInfoToast('Please wait while data loads...',
          context: context);

      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Earnings & Payouts',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Current Month Earnings

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.trending_up,
                            color: Colors.green[700],
                            size: 18), // Reduced from 20 to 18
                        const SizedBox(width: 8),
                        Text(
                          'Current Month Earnings',
                          style: GoogleFonts.poppins(
                            fontSize: 14, // Reduced from 16 to 14
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Rs. $_currentMonthEarnings',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As of ${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Summary Cards

              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Earnings',
                      'Rs. $_totalEarnings', // Will be calculated from actual app usage data
                      Icons.account_balance,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Pending Payouts',
                      'Rs. $_pendingPayouts',
                      Icons.hourglass_empty,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Payout Schedule

              Text(
                'Payout Schedule',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: Colors.grey[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last Payout',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _lastPayoutDate,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Next Payout',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _nextPayoutDate,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Recent Earnings

              Text(
                'Recent Earnings',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              _buildSafeEarningsCard('March 2024', '12,450', 'Completed'),

              _buildSafeEarningsCard('February 2024', '11,800', 'Completed'),

              _buildSafeEarningsCard('January 2024', '13,200', 'Completed'),
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
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _showWithdrawDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Request Withdrawal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeEarningsCard(String period, String amount, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getPayoutStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPayoutStatusIcon(status),
                size: 20,
                color: _getPayoutStatusColor(status),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. $amount',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPayoutStatusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getPayoutStatusColor(status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return months[month - 1];
  }

  Color _getPayoutStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;

      case 'pending':
        return Colors.orange;

      case 'processing':
        return Colors.blue;

      case 'failed':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  IconData _getPayoutStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;

      case 'pending':
        return Icons.hourglass_empty;

      case 'processing':
        return Icons.sync;

      case 'failed':
        return Icons.cancel;

      default:
        return Icons.help_outline;
    }
  }

  void _showWithdrawDialog() {
    Navigator.of(context).pop(); // Close current dialog

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Request Withdrawal',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          content: SizedBox(
            width: _dialogWidth,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Available Balance: Rs. $_pendingPayouts',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Withdrawal Amount (Rs)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        child: Text(
                          '₨',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedWithdrawalMethod,
                        isExpanded: true,
                        hint: Text(
                          'Select withdrawal method',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Bank Account',
                            child: Row(
                              children: [
                                Icon(Icons.account_balance,
                                    color: Colors.blue, size: 20),
                                SizedBox(width: 12),
                                Text('Bank Account'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Jazzcash',
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_wallet,
                                    color: Colors.green, size: 20),
                                SizedBox(width: 12),
                                Text('Jazzcash'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Easypaisa',
                            child: Row(
                              children: [
                                Icon(Icons.phone_android,
                                    color: Colors.orange, size: 20),
                                SizedBox(width: 12),
                                Text('Easypaisa'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              _selectedWithdrawalMethod = value;
                            });
                          }
                        },
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        borderRadius: BorderRadius.circular(12),
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Account Holder Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(
                        _selectedWithdrawalMethod == 'Bank Account'
                            ? Icons.account_balance
                            : _selectedWithdrawalMethod == 'Jazzcash'
                                ? Icons.account_balance_wallet
                                : Icons.phone_android,
                        color: _selectedWithdrawalMethod == 'Bank Account'
                            ? Colors.blue
                            : _selectedWithdrawalMethod == 'Jazzcash'
                                ? Colors.green
                                : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Enhanced feedback with toast, haptic, and animation
                HapticFeedbackUtils.success();
                FeedbackUtils.showSuccessToast(
                    'Withdrawal request submitted successfully!',
                    context: context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Submit Request',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSecurityDialog() {
    if (_isLoading) {
      // Enhanced info feedback with toast
      HapticFeedbackUtils.lightImpact();
      FeedbackUtils.showInfoToast('Please wait while data loads...',
          context: context);

      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
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
                color: Colors.black87,
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
                onTap: () => _showChangePasswordDialog(),
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
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    Navigator.of(context).pop(); // Close security dialog

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
          backgroundColor: Colors.white,
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
                  color: Colors.black87,
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
                        HapticFeedbackUtils.selectionClick();
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
                        HapticFeedbackUtils.selectionClick();
                        setState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
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
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        HapticFeedbackUtils.selectionClick();
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Password must be at least 8 characters long',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
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
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (currentPasswordController.text.isEmpty ||
                    newPasswordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty) {
                  // Enhanced error feedback with haptic and toast
                  HapticFeedbackUtils.error();
                  FeedbackUtils.showErrorToast('Please fill all fields',
                      context: context);
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  // Enhanced error feedback with haptic and toast
                  HapticFeedbackUtils.error();
                  FeedbackUtils.showErrorToast('Passwords do not match',
                      context: context);
                  return;
                }

                if (newPasswordController.text.length < 8) {
                  // Enhanced error feedback with haptic and toast
                  HapticFeedbackUtils.error();
                  FeedbackUtils.showErrorToast(
                      'Password must be at least 8 characters long',
                      context: context);
                  return;
                }

                Navigator.of(context).pop();

                // Enhanced feedback with toast, haptic, and animation
                HapticFeedbackUtils.success();
                FeedbackUtils.showSuccessToast('Password changed successfully!',
                    context: context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Update Password',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    if (_isLoading) {
      // Enhanced info feedback with toast
      HapticFeedbackUtils.lightImpact();
      FeedbackUtils.showInfoToast('Please wait while data loads...',
          context: context);

      return;
    }

    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
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
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _buildLanguageOption(
              AppLanguage.english,
              languageProvider.translate('english'),
              languageProvider.currentLanguage == AppLanguage.english,
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              AppLanguage.bilingual,
              languageProvider.translate('bilingual'),
              languageProvider.currentLanguage == AppLanguage.bilingual,
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
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

  Widget _buildLanguageOption(
      AppLanguage language, String title, bool isSelected) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          languageProvider.setLanguage(language);

          Navigator.of(context).pop();

          // Enhanced feedback with toast, haptic, and animation
          HapticFeedbackUtils.success();
          FeedbackUtils.showSuccessToast('Language changed to $title',
              context: context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.purple.withValues(alpha: 0.1)
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.purple.withValues(alpha: 0.3)
                  : Colors.grey[200]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.purple.withValues(alpha: 0.2)
                      : Colors.grey[300]!.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.language,
                  size: 20,
                  color: isSelected ? Colors.purple : Colors.grey[600],
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSelected ? 'Currently selected' : 'Tap to select',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isSelected ? Colors.purple : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.purple,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSupportDialog() {
    if (_isLoading) {
      // Enhanced info feedback with toast
      HapticFeedbackUtils.lightImpact();
      FeedbackUtils.showInfoToast('Please wait while data loads...',
          context: context);

      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
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
                color: Colors.black87,
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
                onTap: () => _showFAQDialog(),
              ),

              const SizedBox(height: 16),

              _buildHelpOption(
                icon: Icons.chat_bubble_outline,
                title: 'Contact Support',
                subtitle: 'Get help from our support team',
                onTap: () => _showContactSupportDialog(),
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
                        // Enhanced error feedback with haptic and toast
                        HapticFeedbackUtils.error();
                        FeedbackUtils.showErrorToast(
                            'Could not launch phone dialer',
                            context: context);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      // Enhanced error feedback with haptic and toast
                      HapticFeedbackUtils.error();
                      FeedbackUtils.showErrorToast(
                          'Error launching phone dialer',
                          context: context);
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
                    query: 'subject=Muawin App Support Request',
                  );

                  try {
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      if (context.mounted) {
                        // Enhanced error feedback with haptic and toast
                        HapticFeedbackUtils.error();
                        FeedbackUtils.showErrorToast(
                            'Could not launch email app',
                            context: context);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      // Enhanced error feedback with haptic and toast
                      HapticFeedbackUtils.error();
                      FeedbackUtils.showErrorToast('Error launching email app',
                          context: context);
                    }
                  }
                },
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
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
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
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFAQDialog() {
    Navigator.of(context).pop(); // Close help dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.question_answer,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFAQItem(
                'How do I update my profile?',
                'Go to Profile > Edit Profile to update your personal information, service details, and availability.',
              ),
              _buildFAQItem(
                'How do I receive job requests?',
                'Job requests will appear in My Jobs section. You can accept, decline, or negotiate.',
              ),
              _buildFAQItem(
                'How do I update my earnings?',
                'Go to Profile > Earnings & Payouts to view your current earnings, payout history, and request withdrawals.',
              ),
              _buildFAQItem(
                'How do I change my password?',
                'Go to Profile > Security > Change Password to update your account password for security.',
              ),
              _buildFAQItem(
                'How do I contact support?',
                'You can reach us through the Help & Support section via phone, email, or live chat.',
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
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ],
      ),
    );
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

  Future<void> _loadEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final contactsJson = prefs.getString('emergency_contacts') ?? '[]';

      final List<dynamic> contactsList = jsonDecode(contactsJson);

      final contacts = contactsList.map((contact) {
        return Map<String, String>.from(contact);
      }).toList();

      setState(() {
        _emergencyContacts = contacts;
      });
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
    }
  }

  Future<void> _saveEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final contactsJson = jsonEncode(_emergencyContacts);

      await prefs.setString('emergency_contacts', contactsJson);
    } catch (e) {
      debugPrint('Error saving emergency contacts: $e');
    }
  }

  void _showEmergencyContactsDialog() {
    if (_isLoading) {
      // Enhanced info feedback with toast
      HapticFeedbackUtils.lightImpact();
      FeedbackUtils.showInfoToast('Please wait while data loads...',
          context: context);

      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.contact_emergency, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            Text(
              'Emergency Contacts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
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
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Emergency Contacts:',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Emergency contacts list

              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _emergencyContacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.contact_phone,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No emergency contacts added',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add contacts below to receive SOS alerts',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[400],
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
                width: double.maxFinite,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEmergencyContactDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Emergency Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
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
                color: Colors.grey[600],
                fontSize: 14,
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
        contact['name'] ?? 'Unknown',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        contact['phone'] ?? 'No phone',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Colors.red[400]),
        onPressed: () =>
            _showDeleteContactDialog(index, contact['name'] ?? 'Unknown'),
      ),
    );
  }

  void _showDeleteContactDialog(int index, String contactName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Contact',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: Text(
          'Are you sure you want to delete $contactName from your emergency contacts?',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
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
              Navigator.of(context).pop();

              _removeEmergencyContact(index);

              // Enhanced feedback with toast, haptic, and animation
              HapticFeedbackUtils.success();
              FeedbackUtils.showSuccessToast(
                  '$contactName removed from emergency contacts',
                  context: context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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

  void _showAddEmergencyContactDialog() {
    final nameController = TextEditingController();

    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.person_add, color: Colors.red[600], size: 28),
            const SizedBox(width: 12),
            Text(
              'Add Emergency Contact',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Contact Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
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
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();

              final phone = phoneController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                // Enhanced error feedback with haptic and toast
                HapticFeedbackUtils.error();
                FeedbackUtils.showErrorToast('Please fill all fields',
                    context: context);
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
                // Enhanced error feedback with haptic and toast
                HapticFeedbackUtils.error();
                FeedbackUtils.showErrorToast('This contact already exists',
                    context: context);
                return;
              }

              Navigator.of(context).pop();

              _addEmergencyContact(name, phone);

              // Enhanced feedback with toast, haptic, and animation
              HapticFeedbackUtils.success();
              FeedbackUtils.showSuccessToast(
                  '$name added to emergency contacts',
                  context: context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
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

  void _showManageServicesRatesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: _dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: _dialogHeight,
                ),
                child: Stack(
                  children: [
                    // Main Content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Enhanced Header with Professional Design
                        Container(
                          padding: EdgeInsets.all(_verticalPadding),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.grey[50]!],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Professional header with icon
                              Row(
                                children: [
                                  Container(
                                    padding:
                                        EdgeInsets.all(_isMobile ? 10 : 12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                          _isMobile ? 10 : 12),
                                    ),
                                    child: Icon(
                                      Icons.monetization_on,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: _isMobile ? 24 : 28,
                                    ),
                                  ),
                                  SizedBox(width: _isMobile ? 12 : 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Manage Service Rates',
                                          style: GoogleFonts.poppins(
                                            fontSize: _isMobile ? 18 : 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: _isMobile ? 2 : 4),
                                        Text(
                                          'Set your pricing for different service types',
                                          style: GoogleFonts.poppins(
                                            fontSize: _isMobile ? 11 : 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: Container(
                                      padding:
                                          EdgeInsets.all(_isMobile ? 8 : 10),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                            _isMobile ? 8 : 10),
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.grey[600],
                                        size: _isMobile ? 20 : 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Visit Type Dropdown with proper overlay
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Visit Type',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isVisitTypeDropdownOpen =
                                            !_isVisitTypeDropdownOpen;
                                      });
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _selectedVisitType,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Icon(
                                            _isVisitTypeDropdownOpen
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: Colors.grey.shade600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Price and Description Fields (always visible)
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(_verticalPadding),
                            child: _buildPriceAndDescriptionFields(setState),
                          ),
                        ),

                        // Action Buttons
                        Container(
                          padding: EdgeInsets.all(_verticalPadding),
                          child: Column(
                            children: [
                              // Top row with Save Rates and Reset buttons
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Reset to Defaults Button
                                  OutlinedButton.icon(
                                    onPressed: _resetToDefaults,
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: Text(
                                      'Reset to Defaults',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(
                                          color: Colors.orange),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: _isMobile ? 12 : 16,
                                        vertical: _isMobile ? 8 : 12,
                                      ),
                                    ),
                                  ),

                                  // Save Packages Button
                                  ElevatedButton(
                                    onPressed: (_hasErrors || _isSaving)
                                        ? null
                                        : () {
                                            _saveRates();
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (_hasErrors || _isSaving)
                                          ? Colors.grey.shade300
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary,
                                      foregroundColor: (_hasErrors || _isSaving)
                                          ? Colors.grey.shade600
                                          : Colors.white,
                                      elevation:
                                          (_hasErrors || _isSaving) ? 0 : 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: _isMobile ? 20 : 24,
                                        vertical: _isMobile ? 10 : 12,
                                      ),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Save Packages',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ],
                              ),

                              // Spacing between rows
                              SizedBox(height: _isMobile ? 12 : 16),

                              // Centered Cancel Button
                              Center(
                                child: TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
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

                    // Dropdown Overlay (rendered above content)
                    if (_isVisitTypeDropdownOpen)
                      Positioned(
                        top: 120, // Adjust based on header height
                        left: 20,
                        right: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildVisitTypeOption('Basic Visit', setState),
                              _buildVisitTypeOption('Standard Visit', setState),
                              _buildVisitTypeOption('Premium Visit', setState),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Check for validation errors
  bool get _hasErrors {
    return _validationErrors.values.any((error) => error != null);
  }

  // Reset rates to defaults
  void _resetToDefaults() {
    if (!mounted) return;

    setState(() {
      _basicPriceController.text = '500';
      _standardPriceController.text = '1000';
      _premiumPriceController.text = '2000';
      _validationErrors.clear();
    });

    // Enhanced info feedback with toast
    HapticFeedbackUtils.mediumImpact();
    FeedbackUtils.showInfoToast('Rates reset to defaults', context: context);
  }

  // Enhanced save rates with validation
  void _saveRates() async {
    if (_hasErrors) {
      if (mounted) {
        // Enhanced error feedback with haptic and toast
        HapticFeedbackUtils.error();
        FeedbackUtils.showErrorToast(
            'Please fix validation errors before saving',
            context: context);
      }
      return;
    }

    try {
      // Save to Supabase
      await _savePackages();

      // Sync hourly rate with basic price after save
      _updateHourlyRate();

      if (mounted) {
        _showSuccessAnimation();
      }
    } catch (e) {
      debugPrint('Error saving service rates: $e');

      if (mounted) {
        // Enhanced error feedback with haptic and toast
        HapticFeedbackUtils.error();
        FeedbackUtils.showErrorToast('Error saving rates. Please try again.',
            context: context);
      }
    }
  }

  // Animated success feedback
  void _showSuccessAnimation() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(_isMobile ? 24 : 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: _isMobile ? 64 : 80,
                      height: _isMobile ? 64 : 80,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(_isMobile ? 32 : 40),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: _isMobile ? 36 : 48,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: _isMobile ? 12 : 16),
              Text(
                'Rates Updated Successfully!',
                style: GoogleFonts.poppins(
                  fontSize: _isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: _isMobile ? 6 : 8),
              Text(
                'Your new rates are now active',
                style: GoogleFonts.poppins(
                  fontSize: _isMobile ? 12 : 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Widget _buildVisitTypeOption(String visitType, StateSetter setState) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVisitType = visitType;
          _isVisitTypeDropdownOpen = false;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              visitType,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: _selectedVisitType == visitType
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (_selectedVisitType == visitType)
              const Icon(Icons.check, color: Colors.blue, size: 20),
          ],
        ),
      ),
    );
  }

  // Rate validation with real-time feedback
  String? _validateRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a rate';
    }

    final rate = double.tryParse(value);
    if (rate == null) {
      return 'Please enter a valid number';
    }

    if (rate <= 0) {
      return 'Rate must be greater than 0';
    }

    if (rate > 50000) {
      return 'Rate seems too high. Please check.';
    }

    return null;
  }

  // Save packages to Supabase
  Future<void> _savePackages() async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final provider = await supabase
          .from('providers')
          .select('id')
          .eq('profile_id', profile['id'])
          .single();

      final providerId = provider['id'] as String;

      // Delete existing packages first
      await supabase
          .from('service_pricing_packages')
          .delete()
          .eq('provider_id', providerId);

      // Build packages list to insert
      final packages = [
        {
          'provider_id': providerId,
          'package_type': 'basic',
          'price': double.tryParse(_basicPriceController.text) ?? 0,
          'description': _basicDescriptionController.text.trim(),
          'duration': _basicDurationController.text.trim(),
          'is_active': true,
          'sort_order': 1,
          'currency': 'PKR',
        },
        {
          'provider_id': providerId,
          'package_type': 'standard',
          'price': double.tryParse(_standardPriceController.text) ?? 0,
          'description': _standardDescriptionController.text.trim(),
          'duration': _standardDurationController.text.trim(),
          'is_active': true,
          'sort_order': 2,
          'currency': 'PKR',
        },
        {
          'provider_id': providerId,
          'package_type': 'premium',
          'price': double.tryParse(_premiumPriceController.text) ?? 0,
          'description': _premiumDescriptionController.text.trim(),
          'duration': _premiumDurationController.text.trim(),
          'is_active': true,
          'sort_order': 3,
          'currency': 'PKR',
        },
      ];

      // Insert all packages to Supabase
      await supabase.from('service_pricing_packages').insert(packages);

      if (mounted) {
        setState(() => _isSaving = false);
        HapticFeedbackUtils.success();
        FeedbackUtils.showSuccessToast('Packages saved successfully!',
            context: context);
      }
    } catch (e) {
      debugPrint('Save packages error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        HapticFeedbackUtils.error();
        FeedbackUtils.showErrorToast('Failed to save packages: $e',
            context: context);
      }
    }
  }

  // Professional Rate Card Widget
  Widget _buildRateCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required TextEditingController controller,
    required Color color,
    required StateSetter setState,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: _cardSpacing),
      padding: EdgeInsets.all(_isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(_isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: _isMobile ? 18 : 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: _isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: _isMobile ? 11 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: _isMobile ? 12 : 16),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setState(() {
                _validationErrors['${title}Rate'] = _validateRate(value);
              });
            },
            style: GoogleFonts.poppins(
              fontSize: _isMobile ? 18 : 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              prefixText: 'Rs. ',
              prefixStyle: GoogleFonts.poppins(
                fontSize: _isMobile ? 18 : 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              hintText: 'Enter rate',
              hintStyle: GoogleFonts.poppins(
                fontSize: _isMobile ? 16 : 14,
                color: Colors.grey[500],
              ),
              errorText: _validationErrors['${title}Rate'],
              errorStyle: GoogleFonts.poppins(
                fontSize: _isMobile ? 13 : 12,
                color: Colors.red,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _validationErrors['${title}Rate'] != null
                      ? Colors.red
                      : color.withValues(alpha: 0.3),
                  width: _validationErrors['${title}Rate'] != null ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _validationErrors['${title}Rate'] != null
                      ? Colors.red
                      : color,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: color.withValues(alpha: 0.05),
              contentPadding: EdgeInsets.symmetric(
                horizontal: _isMobile ? 20 : 20,
                vertical: _isMobile ? 16 : 16,
              ),
            ),
            textAlign: TextAlign.start,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: _isMobile ? 12 : 16),
          // Swipe-to-Adjust Rates Control
          GestureDetector(
            onPanUpdate: (details) {
              final delta = details.delta.dx / 100; // Sensitivity
              final currentRate = double.tryParse(controller.text) ?? 0;
              final newRate = (currentRate + delta).clamp(0, 50000);
              controller.text = newRate.toStringAsFixed(0);
              setState(() {
                _validationErrors['${title}Rate'] =
                    _validateRate(controller.text);
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: _isMobile ? 16 : 20,
                vertical: _isMobile ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(
                    Icons.remove,
                    color: Colors.red,
                    size: _isMobile ? 20 : 24,
                  ),
                  Text(
                    'Swipe to adjust',
                    style: GoogleFonts.poppins(
                      fontSize: _isMobile ? 11 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Icon(
                    Icons.add,
                    color: Colors.green,
                    size: _isMobile ? 20 : 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get visit type color helper
  Color _getVisitTypeColor(String visitTypeName) {
    switch (visitTypeName) {
      case 'Basic':
        return Colors.green;
      case 'Standard':
        return Colors.blue;
      case 'Premium':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildPriceAndDescriptionFields(StateSetter setState) {
    TextEditingController priceController;

    TextEditingController descriptionController;

    TextEditingController durationController;

    String visitTypeName;

    switch (_selectedVisitType) {
      case 'Basic Visit':
        priceController = _basicPriceController;

        descriptionController = _basicDescriptionController;

        durationController = _basicDurationController;

        visitTypeName = 'Basic';

        break;

      case 'Standard Visit':
        priceController = _standardPriceController;

        descriptionController = _standardDescriptionController;

        durationController = _standardDurationController;

        visitTypeName = 'Standard';

        break;

      case 'Premium Visit':
        priceController = _premiumPriceController;

        descriptionController = _premiumDescriptionController;

        durationController = _premiumDurationController;

        visitTypeName = 'Premium';

        break;

      default:
        priceController = _basicPriceController;

        descriptionController = _basicDescriptionController;

        durationController = _basicDurationController;

        visitTypeName = 'Basic';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price Field

        Text(
          '$visitTypeName Price',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 8),

        if (_providerCategory == 'Maid' &&
            _selectedVisitType == 'Basic Visit') ...[
          // Maid Basic Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.600',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _basicPriceController.text.isEmpty
                          ? 'Rs.700'
                          : 'Rs.${_basicPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.800',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _basicPriceController.text.isEmpty
                      ? 700.0
                      : double.tryParse(_basicPriceController.text) ?? 700.0,

                  min: 600.0,

                  max: 800.0,

                  divisions: 20, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _basicPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Basic Visit price between Rs.600-800',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Driver' &&
            _selectedVisitType == 'Basic Visit') ...[
          // Driver Basic Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.200',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _basicPriceController.text.isEmpty
                          ? 'Rs.300'
                          : 'Rs.${_basicPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.400',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _basicPriceController.text.isEmpty
                      ? 300.0
                      : double.tryParse(_basicPriceController.text) ?? 300.0,

                  min: 200.0,

                  max: 400.0,

                  divisions: 20, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _basicPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Basic Visit price between Rs.200-400',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Gardener' &&
            _selectedVisitType == 'Basic Visit') ...[
          // Gardener Basic Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.350',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _basicPriceController.text.isEmpty
                          ? 'Rs.475'
                          : 'Rs.${_basicPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.600',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _basicPriceController.text.isEmpty
                      ? 475.0
                      : double.tryParse(_basicPriceController.text) ?? 475.0,

                  min: 350.0,

                  max: 600.0,

                  divisions: 25, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _basicPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Basic Visit price between Rs.350-600',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Cook' &&
            _selectedVisitType == 'Basic Visit') ...[
          // Cook Basic Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.350',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _basicPriceController.text.isEmpty
                          ? 'Rs.475'
                          : 'Rs.${_basicPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.600',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _basicPriceController.text.isEmpty
                      ? 475.0
                      : double.tryParse(_basicPriceController.text) ?? 475.0,

                  min: 350.0,

                  max: 600.0,

                  divisions: 25, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _basicPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Basic Visit price between Rs.350-600',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Domestic Helper' &&
            _selectedVisitType == 'Basic Visit') ...[
          // Domestic Helper Basic Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.400',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _basicPriceController.text.isEmpty
                          ? 'Rs.850'
                          : 'Rs.${_basicPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.1,300',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _basicPriceController.text.isEmpty
                      ? 850.0
                      : double.tryParse(_basicPriceController.text) ?? 850.0,

                  min: 400.0,

                  max: 1300.0,

                  divisions: 90, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _basicPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Basic Visit price between Rs.400-1,300',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Security Guard' &&
            _selectedVisitType == 'Basic Visit') ...[
          // Security Guard Basic Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.1,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _basicPriceController.text.isEmpty
                          ? 'Rs.2,000'
                          : 'Rs.${_basicPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.3,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _basicPriceController.text.isEmpty
                      ? 2000.0
                      : double.tryParse(_basicPriceController.text) ?? 2000.0,

                  min: 1000.0,

                  max: 3000.0,

                  divisions: 200, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _basicPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Basic Visit price between Rs.1,000-3,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Babysitter' &&
            _selectedVisitType == 'Basic Visit') ...[
          // Babysitter Basic Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.600',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _basicPriceController.text.isEmpty
                          ? 'Rs.900'
                          : 'Rs.${_basicPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.1,200',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _basicPriceController.text.isEmpty
                      ? 900.0
                      : double.tryParse(_basicPriceController.text) ?? 900.0,

                  min: 600.0,

                  max: 1200.0,

                  divisions: 60, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _basicPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Basic Visit price between Rs.600-1,200',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Washerman' &&
            _selectedVisitType == 'Basic Visit') ...[
          // Washerman Basic Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.450',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _basicPriceController.text.isEmpty
                          ? 'Rs.575'
                          : 'Rs.${_basicPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.700',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _basicPriceController.text.isEmpty
                      ? 575.0
                      : double.tryParse(_basicPriceController.text) ?? 575.0,

                  min: 450.0,

                  max: 700.0,

                  divisions: 25, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _basicPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Basic Visit price between Rs.450-700',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Tutor' &&
            _selectedVisitType == 'Basic Visit') ...[
          // Tutor Basic Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.250',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _basicPriceController.text.isEmpty
                          ? 'Rs.1,625'
                          : 'Rs.${_basicPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.3,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _basicPriceController.text.isEmpty
                      ? 1625.0
                      : double.tryParse(_basicPriceController.text) ?? 1625.0,

                  min: 250.0,

                  max: 3000.0,

                  divisions: 275, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _basicPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Basic Visit price between Rs.250-3,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Maid' &&
            _selectedVisitType == 'Standard Visit') ...[
          // Maid Standard Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.800',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _standardPriceController.text.isEmpty
                          ? 'Rs.1000'
                          : 'Rs.${_standardPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.1,200',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _standardPriceController.text.isEmpty
                      ? 1000.0
                      : double.tryParse(_standardPriceController.text) ??
                          1000.0,

                  min: 800.0,

                  max: 1200.0,

                  divisions: 40, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _standardPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Standard Visit price between Rs.800-1,200',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Driver' &&
            _selectedVisitType == 'Standard Visit') ...[
          // Driver Standard Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.800',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _standardPriceController.text.isEmpty
                          ? 'Rs.900'
                          : 'Rs.${_standardPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.1,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _standardPriceController.text.isEmpty
                      ? 900.0
                      : double.tryParse(_standardPriceController.text) ?? 900.0,

                  min: 800.0,

                  max: 1000.0,

                  divisions: 20, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _standardPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Standard Visit price between Rs.800-1,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Gardener' &&
            _selectedVisitType == 'Standard Visit') ...[
          // Gardener Standard Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.600',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _standardPriceController.text.isEmpty
                          ? 'Rs.800'
                          : 'Rs.${_standardPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.1,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _standardPriceController.text.isEmpty
                      ? 800.0
                      : double.tryParse(_standardPriceController.text) ?? 800.0,

                  min: 600.0,

                  max: 1000.0,

                  divisions: 40, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _standardPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Standard Visit price between Rs.600-1,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Cook' &&
            _selectedVisitType == 'Standard Visit') ...[
          // Cook Standard Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.1,200',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _standardPriceController.text.isEmpty
                          ? 'Rs.1,850'
                          : 'Rs.${_standardPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.2,500',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _standardPriceController.text.isEmpty
                      ? 1850.0
                      : double.tryParse(_standardPriceController.text) ??
                          1850.0,

                  min: 1200.0,

                  max: 2500.0,

                  divisions: 130, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _standardPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Standard Visit price between Rs.1,200-2,500',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Domestic Helper' &&
            _selectedVisitType == 'Standard Visit') ...[
          // Domestic Helper Standard Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.1,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _standardPriceController.text.isEmpty
                          ? 'Rs.1,500'
                          : 'Rs.${_standardPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.2,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _standardPriceController.text.isEmpty
                      ? 1500.0
                      : double.tryParse(_standardPriceController.text) ??
                          1500.0,

                  min: 1000.0,

                  max: 2000.0,

                  divisions: 100, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _standardPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Standard Visit price between Rs.1,000-2,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Security Guard' &&
            _selectedVisitType == 'Standard Visit') ...[
          // Security Guard Standard Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.2,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _standardPriceController.text.isEmpty
                          ? 'Rs.3,000'
                          : 'Rs.${_standardPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.4,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _standardPriceController.text.isEmpty
                      ? 3000.0
                      : double.tryParse(_standardPriceController.text) ??
                          3000.0,

                  min: 2000.0,

                  max: 4000.0,

                  divisions: 200, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _standardPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Standard Visit price between Rs.2,000-4,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Babysitter' &&
            _selectedVisitType == 'Standard Visit') ...[
          // Babysitter Standard Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.1,200',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _standardPriceController.text.isEmpty
                          ? 'Rs.1,600'
                          : 'Rs.${_standardPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.2,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _standardPriceController.text.isEmpty
                      ? 1600.0
                      : double.tryParse(_standardPriceController.text) ??
                          1600.0,

                  min: 1200.0,

                  max: 2000.0,

                  divisions: 80, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _standardPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Standard Visit price between Rs.1,200-2,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Washerman' &&
            _selectedVisitType == 'Standard Visit') ...[
          // Washerman Standard Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.700',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _standardPriceController.text.isEmpty
                          ? 'Rs.1,100'
                          : 'Rs.${_standardPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.1,500',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _standardPriceController.text.isEmpty
                      ? 1100.0
                      : double.tryParse(_standardPriceController.text) ??
                          1100.0,

                  min: 700.0,

                  max: 1500.0,

                  divisions: 80, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _standardPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Standard Visit price between Rs.700-1,500',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Tutor' &&
            _selectedVisitType == 'Standard Visit') ...[
          // Tutor Standard Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.1,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _standardPriceController.text.isEmpty
                          ? 'Rs.4,000'
                          : 'Rs.${_standardPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.7,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _standardPriceController.text.isEmpty
                      ? 4000.0
                      : double.tryParse(_standardPriceController.text) ??
                          4000.0,

                  min: 1000.0,

                  max: 7000.0,

                  divisions: 600, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _standardPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Standard Visit price between Rs.1,000-7,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Maid' &&
            _selectedVisitType == 'Premium Visit') ...[
          // Maid Premium Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.1,200',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _premiumPriceController.text.isEmpty
                          ? 'Rs.1,600'
                          : 'Rs.${_premiumPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.2,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _premiumPriceController.text.isEmpty
                      ? 1600.0
                      : double.tryParse(_premiumPriceController.text) ?? 1600.0,

                  min: 1200.0,

                  max: 2000.0,

                  divisions: 80, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _premiumPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Premium Visit price between Rs.1,200-2,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Driver' &&
            _selectedVisitType == 'Premium Visit') ...[
          // Driver Premium Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.1,500',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _premiumPriceController.text.isEmpty
                          ? 'Rs.2,000'
                          : 'Rs.${_premiumPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.2,500',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _premiumPriceController.text.isEmpty
                      ? 2000.0
                      : double.tryParse(_premiumPriceController.text) ?? 2000.0,

                  min: 1500.0,

                  max: 2500.0,

                  divisions: 100, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _premiumPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Premium Visit price between Rs.1,500-2,500',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Gardener' &&
            _selectedVisitType == 'Premium Visit') ...[
          // Gardener Premium Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.1,500',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _premiumPriceController.text.isEmpty
                          ? 'Rs.2,250'
                          : 'Rs.${_premiumPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.3,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _premiumPriceController.text.isEmpty
                      ? 2250.0
                      : double.tryParse(_premiumPriceController.text) ?? 2250.0,

                  min: 1500.0,

                  max: 3000.0,

                  divisions: 150, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _premiumPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Premium Visit price between Rs.1,500-3,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Cook' &&
            _selectedVisitType == 'Premium Visit') ...[
          // Cook Premium Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.2,500',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _premiumPriceController.text.isEmpty
                          ? 'Rs.4,750'
                          : 'Rs.${_premiumPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.7,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _premiumPriceController.text.isEmpty
                      ? 4750.0
                      : double.tryParse(_premiumPriceController.text) ?? 4750.0,

                  min: 2500.0,

                  max: 7000.0,

                  divisions: 450, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _premiumPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Premium Visit price between Rs.2,500-7,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Domestic Helper' &&
            _selectedVisitType == 'Premium Visit') ...[
          // Domestic Helper Premium Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.2,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _premiumPriceController.text.isEmpty
                          ? 'Rs.2,750'
                          : 'Rs.${_premiumPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.3,500',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _premiumPriceController.text.isEmpty
                      ? 2750.0
                      : double.tryParse(_premiumPriceController.text) ?? 2750.0,

                  min: 2000.0,

                  max: 3500.0,

                  divisions: 150, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _premiumPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Premium Visit price between Rs.2,000-3,500',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Security Guard' &&
            _selectedVisitType == 'Premium Visit') ...[
          // Security Guard Premium Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.3,500',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _premiumPriceController.text.isEmpty
                          ? 'Rs.6,750'
                          : 'Rs.${_premiumPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.10,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _premiumPriceController.text.isEmpty
                      ? 6750.0
                      : double.tryParse(_premiumPriceController.text) ?? 6750.0,

                  min: 3500.0,

                  max: 10000.0,

                  divisions: 650, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _premiumPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Premium Visit price between Rs.3,500-10,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Babysitter' &&
            _selectedVisitType == 'Premium Visit') ...[
          // Babysitter Premium Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.2,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _premiumPriceController.text.isEmpty
                          ? 'Rs.2,750'
                          : 'Rs.${_premiumPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.3,500',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _premiumPriceController.text.isEmpty
                      ? 2750.0
                      : double.tryParse(_premiumPriceController.text) ?? 2750.0,

                  min: 2000.0,

                  max: 3500.0,

                  divisions: 150, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _premiumPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Premium Visit price between Rs.2,000-3,500',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Washerman' &&
            _selectedVisitType == 'Premium Visit') ...[
          // Washerman Premium Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.1,500',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _premiumPriceController.text.isEmpty
                          ? 'Rs.2,250'
                          : 'Rs.${_premiumPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.3,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _premiumPriceController.text.isEmpty
                      ? 2250.0
                      : double.tryParse(_premiumPriceController.text) ?? 2250.0,

                  min: 1500.0,

                  max: 3000.0,

                  divisions: 150, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _premiumPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Premium Visit price between Rs.1,500-3,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else if (_providerCategory == 'Tutor' &&
            _selectedVisitType == 'Premium Visit') ...[
          // Tutor Premium Visit - Price Range Slider

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs.1,500',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _premiumPriceController.text.isEmpty
                          ? 'Rs.5,750'
                          : 'Rs.${_premiumPriceController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Rs.10,000',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _premiumPriceController.text.isEmpty
                      ? 5750.0
                      : double.tryParse(_premiumPriceController.text) ?? 5750.0,

                  min: 1500.0,

                  max: 10000.0,

                  divisions: 850, // Steps of 10

                  activeColor: Theme.of(context).colorScheme.primary,

                  inactiveColor: Colors.grey.shade300,

                  onChanged: (value) {
                    setState(() {
                      _premiumPriceController.text = value.round().toString();
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Slide to set your Premium Visit price between Rs.1,500-10,000',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Professional Rate Card for Standard/Premium visits
          _buildRateCard(
            title: '$visitTypeName Price',
            subtitle: 'Set your rate for $visitTypeName service',
            icon: Icons.attach_money,
            controller: priceController,
            color: _getVisitTypeColor(visitTypeName),
            setState: setState,
          ),
        ],

        const SizedBox(height: 16),

        // Job Description Field

        Text(
          '$visitTypeName Job Description',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: TextField(
            controller: descriptionController,
            decoration: InputDecoration(
              hintText: 'Describe what $visitTypeName service includes...',
              prefixIcon: const Icon(Icons.description, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: 3,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Duration of Job Field

        Text(
          'Duration of Job',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: TextField(
            controller: durationController,
            decoration: const InputDecoration(
              hintText: 'e.g., 45 mins, 1hr 30 mins, 2 hours',
              prefixIcon: Icon(Icons.schedule, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
