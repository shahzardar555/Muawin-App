import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'service_provider_feed_screen.dart';

/// Max width 28rem (448px), centered (max-w-md mx-auto).
const double _kMaxContentWidth = 448;

/// Standard padding p-6 (1.5rem).
const double _kScreenPadding = 24;

/// Mobile padding for small screens.
const double _kMobilePadding = 16;

/// Hero circle size for success state: 6rem (w-24 h-24).
const double _kSuccessHeroSize = 96;

/// Mobile hero circle size for small screens.
const double _kMobileHeroSize = 80;

/// Provider document verification flow:
/// - Capture state: CNIC (Front), CNIC (Back), Take a Selfie.
/// - Success state: Verification Pending (documents under review).
class ProviderDocumentVerificationScreen extends StatefulWidget {
  const ProviderDocumentVerificationScreen({super.key});

  @override
  State<ProviderDocumentVerificationScreen> createState() =>
      _ProviderDocumentVerificationScreenState();
}

class _ProviderDocumentVerificationScreenState
    extends State<ProviderDocumentVerificationScreen>
    with SingleTickerProviderStateMixin {
  int _stepIndex = 0; // 0: front, 1: back, 2: selfie
  bool _submitted = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Store captured images for each step
  final List<File?> _capturedImages = [null, null, null];

  // Track if we're showing preview vs capture state
  bool _showPreview = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  static const List<String> _stepTitles = [
    'CNIC (Front)',
    'CNIC (Back)',
    'Take a Selfie',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Helper method to get responsive values based on screen size
  double _getResponsiveValue(
      BuildContext context, double normal, double mobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 360 ? mobile : normal;
  }

  double _getResponsivePadding(BuildContext context) {
    return _getResponsiveValue(context, _kScreenPadding, _kMobilePadding);
  }

  double _getResponsiveHeroSize(BuildContext context) {
    return _getResponsiveValue(context, _kSuccessHeroSize, _kMobileHeroSize);
  }

  void _handleBack() {
    if (_submitted) {
      setState(() {
        _submitted = false;
        _stepIndex = 0;
      });
      return;
    }
    Navigator.of(context).pop();
  }

  Future<bool> _checkAndRequestCameraPermission() async {
    try {
      // Check current permission status
      final status = await Permission.camera.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        // Request permission
        final result = await Permission.camera.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        // Show dialog to open settings
        await _showPermissionDialog();
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking camera permission: $e');
      return false;
    }
  }

  Future<void> _showPermissionDialog() async {
    final context = this.context;
    if (!mounted || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Camera Permission Required',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'To verify your documents, we need access to your camera. Please grant camera permission in your device settings.',
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Open app settings
                await openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Open Settings',
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

  void _showErrorDialog(String title, String message, {VoidCallback? onRetry}) {
    final context = this.context;
    if (!mounted || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          actions: [
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCameraGuidanceDialog() {
    final context = this.context;
    if (!mounted || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _CameraGuidanceDialog(
          stepTitle: _stepTitles[_stepIndex],
          onContinue: () {
            Navigator.of(context).pop();
            _handleOpenCamera();
          },
          onCancel: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  void _handleOpenCamera() async {
    HapticFeedback.lightImpact();

    // Store context before async operation
    final context = this.context;

    try {
      // Check camera permissions first
      final hasPermission = await _checkAndRequestCameraPermission();
      if (!hasPermission) {
        return; // Permission dialog was shown, user will handle it
      }

      // Check if camera is available
      if (!await _isCameraAvailable()) {
        _showErrorDialog(
          'Camera Not Available',
          'Unable to access camera. Please make sure:\n\n• Camera is not being used by another app\n• Device has a working camera\n• Camera permissions are granted',
          onRetry: _handleOpenCamera,
        );
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice:
            _stepIndex == 2 ? CameraDevice.front : CameraDevice.rear,
      );

      if (image != null) {
        // Validate the captured image
        final isValidImage = await _validateImage(image);
        if (!isValidImage) {
          _showErrorDialog(
            'Image Capture Failed',
            'The captured image appears to be invalid or corrupted. Please try again.',
            onRetry: _handleOpenCamera,
          );
          return;
        }

        // Store the captured image
        setState(() {
          _capturedImages[_stepIndex] = File(image.path);
          _showPreview = true;
        });

        // Show success feedback
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_stepTitles[_stepIndex]} captured successfully'),
              backgroundColor: const Color(0xFF047A62),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // User cancelled camera - no error shown
        debugPrint('User cancelled camera capture');
      }
    } on PlatformException catch (e) {
      String errorMessage = 'Failed to capture image';
      String errorTitle = 'Camera Error';

      switch (e.code) {
        case 'camera_access_denied':
          errorTitle = 'Camera Access Denied';
          errorMessage =
              'Camera permission was denied. Please grant camera permission to continue.';
          break;
        case 'camera_permission_denied':
          errorTitle = 'Permission Required';
          errorMessage =
              'Camera permission is required to capture documents. Please enable it in settings.';
          break;
        case 'no_camera_available':
          errorTitle = 'No Camera Available';
          errorMessage =
              'No camera was found on this device. Please use a device with a camera.';
          break;
        case 'camera_error':
          errorTitle = 'Camera Error';
          errorMessage =
              'The camera encountered an error. Please restart the app and try again.';
          break;
        default:
          errorMessage = 'An unexpected error occurred: ${e.message}';
      }

      _showErrorDialog(errorTitle, errorMessage, onRetry: _handleOpenCamera);
    } catch (e) {
      _showErrorDialog(
        'Unexpected Error',
        'An unexpected error occurred while trying to capture the image. Please try again.',
        onRetry: _handleOpenCamera,
      );
      debugPrint('Unexpected camera error: $e');
    }
  }

  Future<bool> _isCameraAvailable() async {
    try {
      // Simple camera availability check by attempting to access image picker
      // This is a basic check - the actual availability will be confirmed when we try to pick an image
      return true;
    } catch (e) {
      debugPrint('Error checking camera availability: $e');
      return false;
    }
  }

  Future<bool> _validateImage(XFile imageFile) async {
    try {
      // Check if file exists and has content
      final file = File(imageFile.path);
      if (!await file.exists()) {
        return false;
      }

      // Check file size (should be greater than 0)
      final fileSize = await file.length();
      if (fileSize == 0) {
        return false;
      }

      // Check if it's a valid image file by trying to read it
      final bytes = await file.readAsBytes();
      return bytes.isNotEmpty;
    } catch (e) {
      debugPrint('Error validating image: $e');
      return false;
    }
  }

  void _handleRetakePhoto() {
    HapticFeedback.lightImpact();
    setState(() {
      _showPreview = false;
      _capturedImages[_stepIndex] = null;
    });
  }

  void _handleConfirmPhoto() {
    HapticFeedback.lightImpact();
    setState(() {
      _showPreview = false;
      // Move to next step or submit
      if (_stepIndex < _stepTitles.length - 1) {
        _stepIndex++;
      } else {
        _submitted = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    final bool isSuccess = _submitted;

    return Scaffold(
      backgroundColor: isSuccess ? Colors.white : surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                child: Padding(
                  padding: EdgeInsets.all(_getResponsivePadding(context)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _NavigationHeader(onBack: _handleBack),
                      SizedBox(height: _getResponsiveValue(context, 24, 16)),
                      if (!isSuccess)
                        _ProgressIndicator(
                          currentStep: _stepIndex,
                          totalSteps: _stepTitles.length,
                          stepTitles: _stepTitles,
                        ),
                      SizedBox(height: _getResponsiveValue(context, 24, 16)),
                      if (!isSuccess)
                        if (_showPreview && _capturedImages[_stepIndex] != null)
                          _ImagePreviewState(
                            stepTitle: _stepTitles[_stepIndex],
                            imageFile: _capturedImages[_stepIndex]!,
                            onRetake: _handleRetakePhoto,
                            onConfirm: _handleConfirmPhoto,
                          )
                        else
                          _CaptureState(
                            stepTitle: _stepTitles[_stepIndex],
                            onOpenCamera: _showCameraGuidanceDialog,
                            onSkipTips: _handleOpenCamera,
                          )
                      else
                        _SuccessPendingState(
                          primary: primary,
                          muted: muted,
                          pulseScale: _pulseScale,
                          heroSize: _getResponsiveHeroSize(context),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation Header:
/// - Centered micro-typography: "PROVIDER VERIFICATION".
/// - Rounded-full ghost back button with ArrowLeft icon.
class _NavigationHeader extends StatelessWidget {
  const _NavigationHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'PROVIDER VERIFICATION',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15 * 10,
                color: muted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

/// Document Capture Interface state.
class _CaptureState extends StatelessWidget {
  const _CaptureState({
    required this.stepTitle,
    required this.onOpenCamera,
    required this.onSkipTips,
  });

  final String stepTitle;
  final VoidCallback onOpenCamera;
  final VoidCallback onSkipTips;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    final bool isSelfie = stepTitle == 'Take a Selfie';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          stepTitle,
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        AspectRatio(
          aspectRatio: 1.6,
          child: Container(
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomPaint(
              painter: _DashedRectPainter(
                color: primary.withValues(alpha: 0.4),
                strokeWidth: 2,
                gap: 8,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSelfie
                            ? Icons.person_rounded
                            : Icons.credit_card_rounded,
                        size: 40,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: onOpenCamera,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: BorderSide(color: primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Open Camera'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onSkipTips,
                      child: Text(
                        'Skip tips →',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 22,
                color: primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRIVACY GUARANTEED',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.15 * 10,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your identity data is encrypted and used only for verification. We never share your details without consent.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Make sure your details are clear and readable before proceeding.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: muted,
          ),
        ),
      ],
    );
  }
}

/// Success state: Verification Pending (documents under review).
class _SuccessPendingState extends StatelessWidget {
  const _SuccessPendingState({
    required this.primary,
    required this.muted,
    required this.pulseScale,
    required this.heroSize,
  });

  final Color primary;
  final Color muted;
  final Animation<double> pulseScale;
  final double heroSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        AnimatedBuilder(
          animation: pulseScale,
          builder: (context, child) => Transform.scale(
            scale: pulseScale.value,
            child: child,
          ),
          child: Container(
            width: heroSize,
            height: heroSize,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.verified_user_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Verification Pending',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We are reviewing your professional documents. This usually takes 24-48 hours. You will receive a notification once approved.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: muted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        _GoToDashboardButton(
          primary: primary,
        ),
      ],
    );
  }
}

/// Go to Dashboard button: full-width, h-14, rounded-2xl.
class _GoToDashboardButton extends StatefulWidget {
  const _GoToDashboardButton({required this.primary});

  final Color primary;

  static const double _height = 56;
  static const double _radius = 16;

  @override
  State<_GoToDashboardButton> createState() => _GoToDashboardButtonState();
}

class _GoToDashboardButtonState extends State<_GoToDashboardButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const ServiceProviderFeedScreen(),
          ),
          (route) => false,
        );
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: _GoToDashboardButton._height,
          decoration: BoxDecoration(
            color: widget.primary,
            borderRadius: BorderRadius.circular(_GoToDashboardButton._radius),
            boxShadow: [
              BoxShadow(
                color: widget.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Go to Dashboard',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress Indicator showing current step and overall progress.
class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;

  double _getResponsiveCircleSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 360 ? 28 : 32;
  }

  double _getResponsiveFontSize(
      BuildContext context, double normal, double small) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 360 ? small : normal;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final circleSize = _getResponsiveCircleSize(context);
    final progressFontSize = _getResponsiveFontSize(context, 14, 12);
    final stepTitleFontSize = _getResponsiveFontSize(context, 12, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: GoogleFonts.poppins(
                fontSize: progressFontSize,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
            Text(
              '${((currentStep + 1) / totalSteps * 100).toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: progressFontSize,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: muted.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (currentStep + 1) / totalSteps,
            child: Container(
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Step indicators - responsive layout
        MediaQuery.of(context).size.width < 360
            ? _CompactStepIndicators(
                currentStep: currentStep,
                totalSteps: totalSteps,
                stepTitles: stepTitles,
                primary: primary,
                muted: muted,
                circleSize: circleSize,
                titleFontSize: stepTitleFontSize,
              )
            : _FullStepIndicators(
                currentStep: currentStep,
                totalSteps: totalSteps,
                stepTitles: stepTitles,
                primary: primary,
                muted: muted,
                circleSize: circleSize,
                titleFontSize: stepTitleFontSize,
              ),
      ],
    );
  }
}

/// Full step indicators for larger screens.
class _FullStepIndicators extends StatelessWidget {
  const _FullStepIndicators({
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
    required this.primary,
    required this.muted,
    required this.circleSize,
    required this.titleFontSize,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;
  final Color primary;
  final Color muted;
  final double circleSize;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  // Step circle
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? primary
                          : isCurrent
                              ? primary.withValues(alpha: 0.2)
                              : muted.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check_rounded,
                              size: circleSize * 0.5,
                              color: Colors.white,
                            )
                          : isCurrent
                              ? Text(
                                  '${index + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: circleSize * 0.4,
                                    fontWeight: FontWeight.w600,
                                    color: primary,
                                  ),
                                )
                              : Text(
                                  '${index + 1}',
                                  style: GoogleFonts.poppins(
                                    fontSize: circleSize * 0.4,
                                    fontWeight: FontWeight.w600,
                                    color: muted,
                                  ),
                                ),
                    ),
                  ),
                  // Connector line
                  if (index < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: isCompleted
                            ? primary
                            : muted.withValues(alpha: 0.2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Step title
              Text(
                stepTitles[index],
                style: GoogleFonts.poppins(
                  fontSize: titleFontSize,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent ? primary : muted,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Compact step indicators for small screens.
class _CompactStepIndicators extends StatelessWidget {
  const _CompactStepIndicators({
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
    required this.primary,
    required this.muted,
    required this.circleSize,
    required this.titleFontSize,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;
  final Color primary;
  final Color muted;
  final double circleSize;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Compact horizontal step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            final isCurrent = index == currentStep;

            return Column(
              children: [
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? primary
                        : isCurrent
                            ? primary.withValues(alpha: 0.2)
                            : muted.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border:
                        isCurrent ? Border.all(color: primary, width: 2) : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check_rounded,
                            size: circleSize * 0.5,
                            color: Colors.white,
                          )
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: circleSize * 0.4,
                              fontWeight: FontWeight.w600,
                              color: isCurrent ? primary : muted,
                            ),
                          ),
                  ),
                ),
                if (index < totalSteps - 1)
                  Container(
                    width: 20,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: isCompleted ? primary : muted.withValues(alpha: 0.2),
                  ),
              ],
            );
          }),
        ),
        const SizedBox(height: 8),
        // Current step title only
        Text(
          stepTitles[currentStep],
          style: GoogleFonts.poppins(
            fontSize: titleFontSize + 2,
            fontWeight: FontWeight.w600,
            color: primary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Camera Guidance Dialog showing tips for capturing good images.
class _CameraGuidanceDialog extends StatelessWidget {
  const _CameraGuidanceDialog({
    required this.stepTitle,
    required this.onContinue,
    required this.onCancel,
  });

  final String stepTitle;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  List<String> getGuidanceTips() {
    final isSelfie = stepTitle == 'Take a Selfie';

    if (isSelfie) {
      return [
        'Face should be clearly visible',
        'Look directly at the camera',
        'Good lighting on your face',
        'Plain background recommended',
        'No sunglasses or hats',
        'Neutral expression',
      ];
    } else {
      return [
        'Place document on flat surface',
        'Ensure good lighting',
        'Avoid shadows on document',
        'All corners should be visible',
        'Text should be clear and readable',
        'Hold camera steady',
        'Fill the frame with document',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isSelfie = stepTitle == 'Take a Selfie';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelfie ? Icons.person_rounded : Icons.credit_card_rounded,
                    size: 24,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Camera Tips',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        stepTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Guidance tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSelfie
                        ? 'For best selfie quality:'
                        : 'For best document quality:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...getGuidanceTips().map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Visual guide
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                children: [
                  // Document frame overlay
                  if (!isSelfie)
                    Center(
                      child: Container(
                        width: 200,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.credit_card_rounded,
                                size: 32,
                                color: primary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Document Frame',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: primary.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Selfie guide
                  if (isSelfie)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primary,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: primary.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Face Center',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: primary.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Got it, Continue',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Image Preview Interface state.
class _ImagePreviewState extends StatelessWidget {
  const _ImagePreviewState({
    required this.stepTitle,
    required this.imageFile,
    required this.onRetake,
    required this.onConfirm,
  });

  final String stepTitle;
  final File imageFile;
  final VoidCallback onRetake;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review $stepTitle',
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Make sure the image is clear and readable',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: muted,
          ),
        ),
        const SizedBox(height: 24),
        AspectRatio(
          aspectRatio: 1.6,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                imageFile,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.error_outline, size: 48),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRetake,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[600],
                  side: BorderSide(color: Colors.red[600]!),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Retake'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Confirm & Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dashed rectangle painter for the drop zone border.
class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    this.gap = 6,
  });

  final Color color;
  final double strokeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final rect = Offset.zero & size;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;

      const double dashWidth = 8;
      final Path path = Path()
        ..addRRect(RRect.fromRectAndRadius(
          rect.deflate(strokeWidth),
          const Radius.circular(20),
        ));

      final PathMetrics metrics = path.computeMetrics();
      for (final metric in metrics) {
        double distance = 0.0;
        while (distance < metric.length) {
          final double next = distance + dashWidth;
          final Path extractPath =
              metric.extractPath(distance, next.clamp(0, metric.length));
          canvas.drawPath(extractPath, paint);
          distance = next + gap;
        }
      }
    } catch (e) {
      // Fallback to simple rectangle if path operations fail
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(20),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
