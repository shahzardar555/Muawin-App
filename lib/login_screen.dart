import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'service_provider_feed_screen.dart';
import 'vendor_home_screen.dart';
import 'get_started_screen.dart';

/// Max width 28rem (448px), centered.
const double _kMaxContentWidth = 448;

/// Standard screen padding p-6.
const double _kScreenPadding = 24;

/// Login screen shown when user taps "I already have an account".
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final primary = theme.colorScheme.primary;

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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Branding: Logo Hero
                  _LogoHero(primary: primary),
                  const SizedBox(height: 40),
                  // Labels: 0.75rem bold uppercase tracking-widest
                  Text(
                    'EMAIL',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1 * 12, // 0.1em ≈ tracking-widest
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _LoginInput(
                    controller: _emailController,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    obscureText: false,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your email'
                        : null,
                  ),
                  const SizedBox(height: 16), // space-y-4
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'PASSWORD',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1 * 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const _ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _LoginInput(
                    controller: _passwordController,
                    hint: '••••••••',
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your password'
                        : null,
                  ),
                  const SizedBox(height: 28),
                  _LoginButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (_formKey.currentState?.validate() ?? false) {
                        final email =
                            _emailController.text.trim().toLowerCase();
                        if (email == 'am@pro.com') {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(
                              builder: (_) => const ServiceProviderFeedScreen(),
                            ),
                            (route) => route.isFirst,
                          );
                        } else if (email == 'am@vendor.com') {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute<void>(
                              builder: (_) => const VendorHomeScreen(),
                            ),
                            (route) => route.isFirst,
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  // Don't have an account? Sign Up
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const GetStartedScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo hero: primary squircle + gradient + accent badge.
class _LogoHero extends StatelessWidget {
  const _LogoHero({required this.primary});

  final Color primary;

  static const double _squircleSize = 96; // w-24 h-24 = 6rem
  static const double _squircleRadius = 40; // 2.5rem
  static const double _badgeSize = 40; // w-10 h-10 = 2.5rem
  static const double _badgeOffset = 8; // -top-2 -right-2

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _squircleSize + _badgeOffset * 2,
        height: _squircleSize + _badgeOffset * 2,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Primary squircle: gradient + shadow
            Positioned(
              left: _badgeOffset,
              top: _badgeOffset,
              child: Container(
                width: _squircleSize,
                height: _squircleSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_squircleRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary,
                      primary.withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_squircleRadius),
                  child: Center(
                    child: Image.asset(
                      'assets/muawin_logo.png',
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            // Accent badge: yellow, rotated, -top-2 -right-2, white border
            Positioned(
              top: -_badgeOffset,
              right: -_badgeOffset,
              child: Transform.rotate(
                angle: 0.2,
                child: Container(
                  width: _badgeSize,
                  height: _badgeSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tall input field: h-14, rounded-2xl, bg-surface, no border.
class _LoginInput extends StatelessWidget {
  const _LoginInput({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.obscureText,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;

  static const double _height = 56; // h-14 = 3.5rem
  static const double _radius = 16; // rounded-2xl = 1rem

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: _height,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: onSurface,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 15,
            color: onSurface.withValues(alpha: 0.45),
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: BorderSide(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.5),
                width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}

/// Full-width login button: h-14, rounded-[20px], shadow primary/20, active:scale-95.
class _LoginButton extends StatefulWidget {
  const _LoginButton({required this.onPressed});

  final VoidCallback onPressed;

  static const double _height = 56; // h-14
  static const double _radius = 20; // 1.25rem

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
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
    _scale = Tween<double>(begin: 1, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
          height: _LoginButton._height,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(_LoginButton._radius),
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
            'Log in',
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

/// Forgot password recovery screen.
class _ForgotPasswordScreen extends StatefulWidget {
  const _ForgotPasswordScreen();

  @override
  State<_ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<_ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  int _stage = 0; // 0: email, 1: verification code, 2: new password

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final primary = theme.colorScheme.primary;

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
          constraints: const BoxConstraints(maxWidth: 448),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    _stage == 0
                        ? 'Reset Password'
                        : _stage == 1
                            ? 'Verify Email'
                            : 'Create New Password',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _stage == 0
                        ? 'Enter the email address associated with your account.'
                        : _stage == 1
                            ? 'We\'ve sent a verification code to your email.'
                            : 'Enter your new password below.',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_stage == 0) ...[
                    Text(
                      'EMAIL',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LoginInput(
                      controller: _emailController,
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      obscureText: false,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your email'
                          : null,
                    ),
                  ] else if (_stage == 1) ...[
                    Text(
                      'VERIFICATION CODE',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LoginInput(
                      controller: TextEditingController(),
                      hint: '000000',
                      keyboardType: TextInputType.number,
                      obscureText: false,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter verification code'
                          : null,
                    ),
                  ] else ...[
                    Text(
                      'NEW PASSWORD',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LoginInput(
                      controller: TextEditingController(),
                      hint: '••••••••',
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter new password'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 56,
                    child: Material(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() => _stage = (_stage + 1) % 3);
                          }
                        },
                        child: Center(
                          child: Text(
                            _stage == 2 ? 'Reset Password' : 'Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Remember your password?',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Back to Login',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
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
