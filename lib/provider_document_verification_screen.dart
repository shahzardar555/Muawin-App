import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'service_provider_feed_screen.dart';

/// Max width 28rem (448px), centered (max-w-md mx-auto).
const double _kMaxContentWidth = 448;

/// Standard padding p-6 (1.5rem).
const double _kScreenPadding = 24;

/// Hero circle size for success state: 6rem (w-24 h-24).
const double _kSuccessHeroSize = 96;

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

  void _handleOpenCamera() {
    HapticFeedback.lightImpact();
    if (_stepIndex < _stepTitles.length - 1) {
      setState(() => _stepIndex++);
    } else {
      setState(() => _submitted = true);
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
      body: SafeArea(
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
                  if (!isSuccess)
                    _CaptureState(
                      stepTitle: _stepTitles[_stepIndex],
                      onOpenCamera: _handleOpenCamera,
                    )
                  else
                    _SuccessPendingState(
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
  });

  final String stepTitle;
  final VoidCallback onOpenCamera;

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
  });

  final Color primary;
  final Color muted;
  final Animation<double> pulseScale;

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
            width: _kSuccessHeroSize,
            height: _kSuccessHeroSize,
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
          (route) => route.isFirst,
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
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
