import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'service_provider_feed_screen.dart';
import 'vendor_home_screen.dart';
import 'customer_home_screen.dart';
import 'get_started_screen.dart';

/// Success celebration animation
class _SuccessAnimation extends StatefulWidget {
  const _SuccessAnimation();

  @override
  State<_SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<_SuccessAnimation>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Empty widget instead of animations
  }
}

/// Social login buttons component
class _SocialLoginButtons extends StatelessWidget {
  const _SocialLoginButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.withValues(alpha: 0.6),
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        // Google login button
        _SocialLoginButton(
          icon: Icons.g_mobiledata,
          label: 'Continue with Google',
          color: const Color(0xFF4285F4),
          onTap: () {
            // Frontend only - show placeholder
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Google login coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Apple login button
        _SocialLoginButton(
          icon: Icons.apple,
          label: 'Continue with Apple',
          color: Colors.black,
          onTap: () {
            // Frontend only - show placeholder
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Apple login coming soon!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Social login button component
class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced loading skeleton screen
class _LoadingSkeleton extends StatefulWidget {
  const _LoadingSkeleton();

  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Widget _buildSkeletonItem({
    required double width,
    required double height,
    double borderRadius = 8.0,
    Color? baseColor,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor ?? Colors.grey.withValues(alpha: 0.1),
                Colors.grey.withValues(alpha: 0.2),
                baseColor ?? Colors.grey.withValues(alpha: 0.1),
              ],
              stops: [
                0.0,
                (0.5 + _shimmerAnimation.value * 0.5).clamp(0.0, 1.0),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        // Logo skeleton
        _buildSkeletonItem(
          width: 96,
          height: 96,
          borderRadius: 40,
          baseColor: Colors.grey.withValues(alpha: 0.15),
        ),
        const SizedBox(height: 32),
        // Title skeleton
        _buildSkeletonItem(
          width: 200,
          height: 28,
          borderRadius: 4,
        ),
        const SizedBox(height: 8),
        // Subtitle skeleton
        _buildSkeletonItem(
          width: 160,
          height: 20,
          borderRadius: 4,
        ),
        const SizedBox(height: 40),
        // EMAIL label skeleton
        _buildSkeletonItem(
          width: 80,
          height: 12,
          borderRadius: 2,
        ),
        const SizedBox(height: 8),
        // Email field skeleton
        _buildSkeletonItem(
          width: double.infinity,
          height: 56,
          borderRadius: 16,
          baseColor: Colors.grey.withValues(alpha: 0.05),
        ),
        const SizedBox(height: 16),
        // PASSWORD label skeleton
        _buildSkeletonItem(
          width: 100,
          height: 12,
          borderRadius: 2,
        ),
        const SizedBox(height: 8),
        // Password field skeleton
        _buildSkeletonItem(
          width: double.infinity,
          height: 56,
          borderRadius: 16,
          baseColor: Colors.grey.withValues(alpha: 0.05),
        ),
        const SizedBox(height: 28),
        // Button skeleton
        _buildSkeletonItem(
          width: double.infinity,
          height: 56,
          borderRadius: 20,
          baseColor: const Color(0xFF047A62).withValues(alpha: 0.3),
        ),
        const SizedBox(height: 24),
        // Sign up text skeleton
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSkeletonItem(width: 120, height: 15, borderRadius: 2),
            const SizedBox(width: 8),
            _buildSkeletonItem(width: 60, height: 15, borderRadius: 2),
          ],
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

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

  bool _obscurePassword = true;
  bool _loading = false;
  bool _showSuccess = false;
  String? _errorMessage;

  bool get _isFormValid =>
      _emailController.text.isNotEmpty && _passwordController.text.isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Store navigator before async gap
    final navigator = Navigator.of(context);

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(seconds: 1)); // simulate login delay

    final email = _emailController.text.trim().toLowerCase();

    if (email == 'am@pro.com' ||
        email == 'am@vendor.com' ||
        email == 'am@c.com') {
      // Show success animation
      setState(() {
        _loading = false;
        _showSuccess = true;
      });

      // Wait for success animation to complete
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      // Navigate to appropriate screen
      if (email == 'am@pro.com') {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(
              builder: (_) => const ServiceProviderFeedScreen()),
          (route) => route.isFirst,
        );
      } else if (email == 'am@vendor.com') {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const VendorHomeScreen()),
          (route) => route.isFirst,
        );
      } else if (email == 'am@c.com') {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const CustomerHomeScreen()),
          (route) => route.isFirst,
        );
      }
    } else {
      setState(() {
        _loading = false;
        _errorMessage = 'Invalid email or password';
      });
      // Trigger shake animation
      _shakeButton();
    }
  }

  final GlobalKey<_LoginButtonState> _loginButtonKey = GlobalKey();

  void _shakeButton() {
    _loginButtonKey.currentState?._shake();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Main content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(_kScreenPadding),
                child: _loading
                    ? const _LoadingSkeleton()
                    : AutofillGroup(
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

                              // EMAIL LABEL
                              Text(
                                'EMAIL',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1 * 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _LoginInput(
                                controller: _emailController,
                                hint: 'you@example.com',
                                keyboardType: TextInputType.emailAddress,
                                obscureText: false,
                                autofillHints: const [AutofillHints.email],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Enter your email';
                                  }
                                  final emailRegex = RegExp(
                                      r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegex.hasMatch(v.trim())) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),

                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                          builder: (_) =>
                                              const _ForgotPasswordScreen(),
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
                                obscureText: _obscurePassword,
                                autofillHints: const [AutofillHints.password],
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Enter your password'
                                        : null,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),

                              const SizedBox(height: 28),
                              // Error message display
                              if (_errorMessage != null) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              _LoginButton(
                                key: _loginButtonKey,
                                onPressed: _isFormValid && !_loading
                                    ? _loginUser
                                    : null,
                                loading: _loading,
                              ),

                              const SizedBox(height: 24),

                              // Social login options
                              const _SocialLoginButtons(),

                              const SizedBox(height: 24),

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
                                      const TextSpan(
                                          text: "Don't have an account? "),
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
          ),
          // Success animation overlay
          if (_showSuccess)
            Container(
              color: Colors.white.withValues(alpha: 0.95),
              child: const _SuccessAnimation(),
            ),
        ],
      ),
    );
  }
}

/// Logo hero: primary squircle + gradient + title text.
class _LogoHero extends StatelessWidget {
  const _LogoHero({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SVG logo
        Transform.translate(
          offset: const Offset(0, -20), // Move logo up
          child: Center(
            child: SvgPicture.asset(
              'imagess/muawin_m_logo.svg',
              width: 96,
              height: 96,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 32), // Spacing between icon and text

        // Attractive title text
        Column(
          children: [
            Text(
              'Login to your',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black87.withValues(alpha: 0.8),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Muawin Account',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF047A62),
                height: 1.2,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: 60,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF047A62).withValues(alpha: 0.3),
                    const Color(0xFF047A62),
                    const Color(0xFF047A62).withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tall input field: h-14, rounded-2xl, bg-surface, no border.
class _LoginInput extends StatefulWidget {
  const _LoginInput({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.obscureText,
    this.validator,
    this.autofillHints,
    this.suffixIcon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final List<String>? autofillHints;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;

  static const double _height = 56;
  static const double _radius = 16;

  @override
  State<_LoginInput> createState() => _LoginInputState();
}

class _LoginInputState extends State<_LoginInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _containerOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _containerOpacityAnimation = Tween<double>(begin: 0.05, end: 0.1).animate(
      CurvedAnimation(parent: _focusController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);

    _borderColorAnimation = ColorTween(
      begin: Colors.grey.withValues(alpha: 0.3),
      end: theme.colorScheme.primary,
    ).animate(_focusController);
  }

  @override
  void dispose() {
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AnimatedBuilder(
      animation: _focusController,
      builder: (context, child) {
        return Container(
          height: _LoginInput._height,
          decoration: BoxDecoration(
            color: surface.withValues(alpha: _containerOpacityAnimation.value),
            border: Border.all(
              color: _borderColorAnimation.value ??
                  Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(_LoginInput._radius),
          ),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            validator: widget.validator,
            onChanged: widget.onChanged,
            autofillHints: widget.autofillHints,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: onSurface,
              fontWeight: FontWeight.w500,
            ),
            onTap: () => _focusController.forward(),
            onTapOutside: (_) => _focusController.reverse(),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              suffixIcon: widget.suffixIcon,
            ),
          ),
        );
      },
    );
  }
}

/// Full-width login button with loading spinner.
class _LoginButton extends StatefulWidget {
  const _LoginButton(
      {super.key, required this.onPressed, this.loading = false});

  final VoidCallback? onPressed;
  final bool loading;

  static const double _height = 56;
  static const double _radius = 20;

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shakeController;
  late Animation<double> _scale;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = Tween<double>(begin: 1, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeController.forward().then((_) => _shakeController.reset());
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    const splashColor =
        Color(0xFF047A62); // Muawin Primary Teal from splash screen

    return AnimatedBuilder(
      animation: Listenable.merge([_scale, _shakeAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value * 10 * sin(_shakeAnimation.value * pi * 4),
            0,
          ),
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: disabled ? null : widget.onPressed,
        child: Container(
          height: _LoginButton._height,
          decoration: BoxDecoration(
            color: disabled ? splashColor.withValues(alpha: 0.5) : splashColor,
            borderRadius: BorderRadius.circular(_LoginButton._radius),
            boxShadow: [
              BoxShadow(
                color: splashColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
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
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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

                  if (!_emailSent) ...[
                    // Email input form
                    Text(
                      'Reset Password',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // EMAIL LABEL
                    Text(
                      'EMAIL',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1 * 12,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LoginInput(
                      controller: _emailController,
                      hint: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      obscureText: false,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter your email';
                        }
                        final emailRegex =
                            RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _LoginButton(
                      onPressed: _isLoading ? null : _sendResetEmail,
                      loading: _isLoading,
                    ),
                  ] else ...[
                    // Success state
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_read_rounded,
                              size: 40,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Check your email',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We\'ve sent a password reset link to\n${_emailController.text}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _LoginButton(
                            onPressed: () => Navigator.of(context).pop(),
                            loading: false,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Back to login link
                  if (!_emailSent)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Center(
                        child: Text(
                          'Back to Login',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primary,
                          ),
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

  void _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _emailSent = true;
    });

    // Show success feedback
    HapticFeedback.mediumImpact();
  }
}
