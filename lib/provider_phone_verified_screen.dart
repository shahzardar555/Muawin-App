import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'provider_document_verification_screen.dart';

/// Max width 28rem (448px), centered (max-w-md mx-auto).
const double _kMaxContentWidth = 448;

/// Standard padding p-6 (1.5rem).
const double _kScreenPadding = 24;

/// Success hero circle: 6rem (w-24 h-24).
const double _kSuccessHeroSize = 96;

/// Phone Verified success screen after provider phone verification.
/// Document onboarding entry — next step is document verification.
class ProviderPhoneVerifiedScreen extends StatefulWidget {
  const ProviderPhoneVerifiedScreen({super.key});

  @override
  State<ProviderPhoneVerifiedScreen> createState() =>
      _ProviderPhoneVerifiedScreenState();
}

class _ProviderPhoneVerifiedScreenState extends State<ProviderPhoneVerifiedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.elasticOut,
      ),
    );
    _bounceController.forward();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
            child: Padding(
              padding: const EdgeInsets.all(_kScreenPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success State: Bouncing 6rem Primary circle with white CheckCircle2 icon
                  AnimatedBuilder(
                    animation: _bounceScale,
                    builder: (context, child) => Transform.scale(
                      scale: _bounceScale.value,
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
                        Icons.check_circle_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Headline: "Phone Verified!"
                  Text(
                    'Phone Verified!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Body text
                  Text(
                    "Great! Your contact details are verified. Now let's complete your professional profile with document verification.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Final CTA: "Continue to Verification"
                  _ContinueToVerificationButton(),
                  const SizedBox(height: 48),
                  // Trust Footer: Mail icon + micro-typography (0.625rem / text-[10px], bold, uppercase, 0.1em tracking)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 14,
                        color: muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Verification ensures account security',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1 * 10,
                          color: muted,
                        ),
                      ),
                    ],
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

/// Continue to Verification button: full-width, h-14, rounded-2xl.
class _ContinueToVerificationButton extends StatefulWidget {
  @override
  State<_ContinueToVerificationButton> createState() =>
      _ContinueToVerificationButtonState();
}

class _ContinueToVerificationButtonState
    extends State<_ContinueToVerificationButton>
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
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ProviderDocumentVerificationScreen(),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Continue to Verification',
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
