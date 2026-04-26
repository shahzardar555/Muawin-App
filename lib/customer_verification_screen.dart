import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'customer_registration_successful_screen.dart';

/// Max width 28rem (448px), centered (max-w-md mx-auto).
const double _kMaxContentWidth = 448;

/// Standard padding p-6 (1.5rem).
const double _kScreenPadding = 24;

/// Hero circle size for success state: 6rem (w-24 h-24).
const double _kSuccessHeroSize = 96;

/// Improved Color System
class VerificationColors {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
}

/// Enhanced Typography Hierarchy
class _TextStyles {
  static TextStyle get titleStyle => GoogleFonts.poppins(
        fontSize: 32, // Increased from 30
        fontWeight: FontWeight.w800, // Increased from 700
        color: VerificationColors.textDark,
        height: 1.1, // Tighter line height
        letterSpacing: -0.5, // Slight letter spacing
      );

  static TextStyle get subtitleStyle => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500, // Increased from 400
        color: VerificationColors.textLight,
        height: 1.5,
      );
}

/// Micro-Animated Button
class _AnimatedButton extends StatefulWidget {
  const _AnimatedButton({
    required this.child,
    required this.onPressed,
    this.style,
  });

  final Widget child;
  final VoidCallback onPressed;
  final ButtonStyle? style;

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: FilledButton(
        onPressed: () {
          setState(() => _isPressed = true);
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) setState(() => _isPressed = false);
          });
          widget.onPressed();
        },
        style: widget.style,
        child: widget.child,
      ),
    );
  }
}

/// Standardized button styles
class _ButtonStyles {
  static ButtonStyle primaryButton(Color color) => FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      );

  static ButtonStyle textButton(Color color) => TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}

/// Customer verification flow:
/// - Email verification
/// - Phone verification (optional)
/// - Profile picture (optional)
/// - Success state: Verification Complete
class CustomerVerificationScreen extends StatefulWidget {
  const CustomerVerificationScreen({super.key});

  @override
  State<CustomerVerificationScreen> createState() =>
      _CustomerVerificationScreenState();
}

class _CustomerVerificationScreenState extends State<CustomerVerificationScreen>
    with SingleTickerProviderStateMixin {
  int _stepIndex = 0; // 0: email, 1: phone, 2: profile, 3: success
  bool _submitted = false;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  final _verificationCodeController = TextEditingController();

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  static const List<String> _stepTitles = [
    'Verify Email',
    'Verify Phone',
    'Complete',
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
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_submitted) {
      setState(() {
        _submitted = false;
        _stepIndex = 0;
      });
      return;
    }
    if (_stepIndex > 0) {
      setState(() => _stepIndex--);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleNext() {
    HapticFeedback.lightImpact();

    // Show loading state
    setState(() => _isLoading = true);

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // If phone verification is complete (step 1), go to registration successful screen
      if (_stepIndex == 1) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                const CustomerRegistrationSuccessfulScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
          (route) => false,
        );
      } else if (_stepIndex < _stepTitles.length - 1) {
        setState(() => _stepIndex++);
      } else {
        setState(() => _submitted = true);
      }
    });
  }

  void _handleSkip() {
    HapticFeedback.lightImpact();
    if (_stepIndex < _stepTitles.length - 1) {
      setState(() => _stepIndex++);
    } else {
      setState(() => _submitted = true);
    }
  }

  Future<void> _handleTakePhoto() async {
    HapticFeedback.lightImpact();

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture captured successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        _handleNext();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open camera: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: Padding(
                padding: const EdgeInsets.all(_kScreenPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NavigationHeader(onBack: _handleBack),
                    const SizedBox(height: 24),
                    if (!isSuccess) ...[
                      _StepProgressIndicator(
                        currentStep: _stepIndex,
                        totalSteps: _stepTitles.length,
                        primaryColor: primary,
                      ),
                      const SizedBox(height: 32),
                      _isLoading
                          ? const _LoadingStateWidget()
                          : _StepContent(
                              stepIndex: _stepIndex,
                              stepTitle: _stepTitles[_stepIndex],
                              onNext: _handleNext,
                              onSkip: _handleSkip,
                              onTakePhoto: _handleTakePhoto,
                              verificationController:
                                  _verificationCodeController,
                            ),
                    ] else
                      _SuccessState(
                        primary: primary,
                        muted: muted,
                        pulseScale: _pulseScale,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation Header
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
              'CUSTOMER VERIFICATION',
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

/// Consistent Skip Button Widget
class _ConsistentSkipButton extends StatelessWidget {
  const _ConsistentSkipButton({
    required this.stepIndex,
    required this.onSkip,
  });

  final int stepIndex;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final canSkip = stepIndex != 0; // Can't skip email verification

    return canSkip
        ? TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onSkip();
            },
            style: _ButtonStyles.textButton(Colors.grey[600]!),
            child: Text(
              'Skip for Now',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          )
        : const SizedBox(height: 48); // Maintain consistent spacing
  }
}

/// Loading State Widget
class _LoadingStateWidget extends StatelessWidget {
  const _LoadingStateWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Skeleton for title
        Container(
          width: 200,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        // Skeleton for input field
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 24),
        // Skeleton for button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

/// Enhanced Input Field with Focus States
class _EnhancedInputField extends StatefulWidget {
  const _EnhancedInputField({
    required this.controller,
    required this.primaryColor,
    this.semanticLabel,
    this.semanticHint,
    this.validator,
  });

  final TextEditingController controller;
  final Color primaryColor;
  final String? semanticLabel;
  final String? semanticHint;
  final String? Function(String?)? validator;

  @override
  State<_EnhancedInputField> createState() => _EnhancedInputFieldState();
}

class _EnhancedInputFieldState extends State<_EnhancedInputField> {
  bool _hasFocus = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _hasFocus
              ? widget.primaryColor
              : widget.primaryColor.withValues(alpha: 0.3),
          width: _hasFocus ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _hasFocus
                ? widget.primaryColor.withValues(alpha: 0.2)
                : widget.primaryColor.withValues(alpha: 0.1),
            blurRadius: _hasFocus ? 16 : 12,
            offset: Offset(0, _hasFocus ? 6 : 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Semantics(
        label: widget.semanticLabel ?? 'Verification code input',
        hint: widget.semanticHint ?? 'Enter 6 digit verification code',
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 12,
            color: widget.primaryColor,
          ),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 12,
              color: Colors.grey[300],
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 28,
            ),
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}

/// Step Progress Indicator
class _StepProgressIndicator extends StatelessWidget {
  const _StepProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.primaryColor,
  });

  final int currentStep;
  final int totalSteps;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Step dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final isActive = index <= currentStep;
            final isCurrentStep = index == currentStep;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrentStep ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? primaryColor : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // Step labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (index) {
            final isActive = index <= currentStep;
            final stepLabels = ['Email', 'Phone', 'Done'];

            return Expanded(
              child: Text(
                stepLabels[index],
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? primaryColor : Colors.grey[500],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Step Content based on current step
class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.stepIndex,
    required this.stepTitle,
    required this.onNext,
    required this.onSkip,
    required this.onTakePhoto,
    required this.verificationController,
  });

  final int stepIndex;
  final String stepTitle;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onTakePhoto;
  final TextEditingController verificationController;

  @override
  Widget build(BuildContext context) {
    switch (stepIndex) {
      case 0:
        return _EmailVerificationStep(
          stepTitle: stepTitle,
          onNext: onNext,
          controller: verificationController,
        );
      case 1:
        return _PhoneVerificationStep(
          stepTitle: stepTitle,
          onNext: onNext,
          onSkip: onSkip,
          controller: verificationController,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Email Verification Step
class _EmailVerificationStep extends StatefulWidget {
  const _EmailVerificationStep({
    required this.stepTitle,
    required this.onNext,
    required this.controller,
  });

  final String stepTitle;
  final VoidCallback onNext;
  final TextEditingController controller;

  @override
  State<_EmailVerificationStep> createState() => _EmailVerificationStepState();
}

class _EmailVerificationStepState extends State<_EmailVerificationStep> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.stepTitle,
          style: _TextStyles.titleStyle,
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent a verification code to your email address.',
          style: _TextStyles.subtitleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _EnhancedInputField(
                controller: widget.controller,
                primaryColor: primary,
                semanticLabel: 'Email verification code input',
                semanticHint:
                    'Enter 6 digit verification code sent to your email address',
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Please enter 6-digit code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _AnimatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onNext();
                  }
                },
                style: _ButtonStyles.primaryButton(primary),
                child: Text(
                  'Verify Email',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            // Resend email logic
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification code resent!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          style: _ButtonStyles.textButton(primary),
          child: Text(
            'Resend Code',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Phone Verification Step
class _PhoneVerificationStep extends StatefulWidget {
  const _PhoneVerificationStep({
    required this.stepTitle,
    required this.onNext,
    required this.onSkip,
    required this.controller,
  });

  final String stepTitle;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final TextEditingController controller;

  @override
  State<_PhoneVerificationStep> createState() => _PhoneVerificationStepState();
}

class _PhoneVerificationStepState extends State<_PhoneVerificationStep> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.stepTitle,
          style: _TextStyles.titleStyle,
        ),
        const SizedBox(height: 16),
        Text(
          'Verify your phone number for better security and communication.',
          style: _TextStyles.subtitleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            children: [
              _EnhancedInputField(
                controller: widget.controller,
                primaryColor: Colors.green,
                semanticLabel: 'Phone verification code input',
                semanticHint:
                    'Enter 6 digit verification code sent to your phone number',
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Please enter 6-digit code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _AnimatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    widget.onNext();
                  }
                },
                style: _ButtonStyles.primaryButton(Colors.green),
                child: Text(
                  'Verify Phone',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ConsistentSkipButton(
          stepIndex: 1, // Phone verification step
          onSkip: widget.onSkip,
        ),
      ],
    );
  }
}

/// Success State
class _SuccessState extends StatelessWidget {
  const _SuccessState({
    required this.primary,
    required this.muted,
    required this.pulseScale,
  });

  final Color primary;
  final Color muted;
  final Animation<double> pulseScale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: pulseScale,
          builder: (context, child) => Transform.scale(
            scale: pulseScale.value,
            child: Container(
              width: _kSuccessHeroSize,
              height: _kSuccessHeroSize,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 48,
                color: primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Verification Complete!',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your account has been verified successfully. You can now start using Muawin.',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _AnimatedButton(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    const CustomerRegistrationSuccessfulScreen(),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 300),
              ),
              (route) => false,
            );
          },
          style: _ButtonStyles.primaryButton(primary),
          child: Text(
            'Get Started',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
