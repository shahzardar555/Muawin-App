import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'provider_phone_verified_screen.dart';
import 'vendor_verified_success_screen.dart';

/// Verification flow type: vendor goes to Store Verified, provider goes to Phone Verified.
enum VerificationType { vendor, provider }

/// Max width 28rem (448px), centered. Mobile-optimized (max-w-md mx-auto).
const double _kMaxContentWidth = 448;

/// Standard padding p-6 (1.5rem).
const double _kScreenPadding = 24;

/// OTP box: w-14 h-16 (3.5rem x 4rem).
const double _kOtpBoxWidth = 56;
const double _kOtpBoxHeight = 64;

/// Squircle icon: 5rem x 5rem (w-20 h-20).
const double _kHeroIconSize = 80;
const double _kHeroIconRadius = 24; // rounded-3xl

/// Phone verification screen — shared by vendor and provider registration.
class VendorVerifyPhoneScreen extends StatefulWidget {
  const VendorVerifyPhoneScreen({
    super.key,
    this.phoneNumber = '',
    this.verificationType = VerificationType.vendor,
  });

  final String phoneNumber;
  final VerificationType verificationType;

  @override
  State<VendorVerifyPhoneScreen> createState() =>
      _VendorVerifyPhoneScreenState();
}

class _VendorVerifyPhoneScreenState extends State<VendorVerifyPhoneScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onVerifyCode() {
    HapticFeedback.lightImpact();
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length == 4 && mounted) {
      final isProvider = widget.verificationType == VerificationType.provider;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => isProvider
              ? const ProviderPhoneVerifiedScreen()
              : const VendorVerifiedSuccessScreen(),
        ),
      );
    }
  }

  void _onResend() {
    HapticFeedback.lightImpact();
    // Clear previous OTP entries
    for (final controller in _otpControllers) {
      controller.clear();
    }
    // Reset focus to first field
    _otpFocusNodes[0].requestFocus();
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'OTP resent to ${widget.phoneNumber}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_kScreenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Visual Hero: 5rem x 5rem squircle, primary 10% opacity, subtle shadow. Icon 2.5rem.
                Center(
                  child: Container(
                    width: _kHeroIconSize,
                    height: _kHeroIconSize,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(_kHeroIconRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.phone_android_rounded,
                      size: 40, // 2.5rem
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Headline: "Verify Phone" — text-3xl, bold Poppins
                Text(
                  'Verify Phone',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                // Instructional: "We've sent a 4-digit code to your registered mobile number."
                Text(
                  "We've sent a 4-digit code to your registered mobile number.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                // OTP Input: 4 boxes, w-14 h-16, white, rounded-2xl, shadow-sm, text-2xl
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: i == 0 ? 0 : 8,
                        right: i == 3 ? 0 : 8,
                      ),
                      child: Container(
                        width: _kOtpBoxWidth,
                        height: _kOtpBoxHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _otpControllers[i],
                          focusNode: _otpFocusNodes[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: GoogleFonts.poppins(
                            fontSize: 24, // 1.5rem / text-2xl
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: primary.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (v) {
                            if (v.length == 1 && i < 3) {
                              _otpFocusNodes[i + 1].requestFocus();
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                // Primary Button: "Verify Code" — full-width, h-14, rounded-2xl
                _VerifyCodeButton(onPressed: _onVerifyCode),
                const SizedBox(height: 24),
                // Resend: "Didn't receive the code? Resend" (Resend = bold primary link)
                GestureDetector(
                  onTap: _onResend,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: muted,
                      ),
                      children: [
                        const TextSpan(text: "Didn't receive the code? "),
                        TextSpan(
                          text: 'Resend',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Security footer: Mail icon + micro-text (0.625rem, bold, uppercase, 0.1em tracking)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline_rounded, size: 14, color: muted),
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Verify Code button: h-14, rounded-2xl, primary.
class _VerifyCodeButton extends StatefulWidget {
  const _VerifyCodeButton({required this.onPressed});

  final VoidCallback onPressed;

  static const double _height = 56;
  static const double _radius = 16;

  @override
  State<_VerifyCodeButton> createState() => _VerifyCodeButtonState();
}

class _VerifyCodeButtonState extends State<_VerifyCodeButton>
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
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: _VerifyCodeButton._height,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(_VerifyCodeButton._radius),
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
            'Verify Code',
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
