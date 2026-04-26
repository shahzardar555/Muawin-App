import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'provider_document_verification_screen.dart';

/// Max width 28rem (448px), centered (max-w-md mx-auto).
const double _kMaxContentWidth = 448;

/// Standard padding p-6 (1.5rem).
const double _kScreenPadding = 24;

/// Phone Verified success screen after provider phone verification.
/// Final step - navigates to service provider feed screen.
class ProviderPhoneVerifiedScreen extends StatefulWidget {
  /// The verified phone number to display
  final String phoneNumber;

  const ProviderPhoneVerifiedScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<ProviderPhoneVerifiedScreen> createState() =>
      _ProviderPhoneVerifiedScreenState();
}

/// Confetti particle data class
class _ConfettiParticle {
  final double x;
  final double y;
  final double velocityX;
  final double velocityY;
  final Color color;
  final double size;
  final double rotation;
  final double rotationSpeed;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.color,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
  });

  _ConfettiParticle copyWith({
    double? x,
    double? y,
    double? velocityX,
    double? velocityY,
    Color? color,
    double? size,
    double? rotation,
    double? rotationSpeed,
  }) {
    return _ConfettiParticle(
      x: x ?? this.x,
      y: y ?? this.y,
      velocityX: velocityX ?? this.velocityX,
      velocityY: velocityY ?? this.velocityY,
      color: color ?? this.color,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      rotationSpeed: rotationSpeed ?? this.rotationSpeed,
    );
  }
}

/// Custom painter for confetti animation
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final Animation<double> animation;

  _ConfettiPainter({
    required this.particles,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      final animatedParticle = _updateParticle(particle, animation.value, size);

      paint.color = animatedParticle.color;
      canvas.save();
      canvas.translate(animatedParticle.x, animatedParticle.y);
      canvas.rotate(animatedParticle.rotation);

      // Draw confetti rectangle
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: animatedParticle.size,
            height: animatedParticle.size * 0.6,
          ),
          Radius.circular(animatedParticle.size * 0.1),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  _ConfettiParticle _updateParticle(
      _ConfettiParticle particle, double progress, Size size) {
    const gravity = 500.0;
    final time = progress * 3.0;

    final newY = particle.y +
        (particle.velocityY * time) +
        (0.5 * gravity * time * time);
    final newX = particle.x + (particle.velocityX * time);
    final newRotation = particle.rotation + (particle.rotationSpeed * time);

    return particle.copyWith(
      x: newX,
      y: newY,
      rotation: newRotation,
    );
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}

/// Confetti widget for celebration effect
class _ConfettiWidget extends StatefulWidget {
  const _ConfettiWidget();

  @override
  State<_ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<_ConfettiWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _particles = _generateConfetti();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_ConfettiParticle> _generateConfetti() {
    final random = Random();
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];

    return List.generate(50, (index) {
      return _ConfettiParticle(
        x: random.nextDouble() * 400,
        y: -50 - random.nextDouble() * 100,
        velocityX: (random.nextDouble() - 0.5) * 100,
        velocityY: random.nextDouble() * 100 + 50,
        color: colors[random.nextInt(colors.length)],
        size: random.nextDouble() * 8 + 4,
        rotation: random.nextDouble() * pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 10,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ConfettiPainter(
              particles: _particles,
              animation: _controller,
            ),
          );
        },
      ),
    );
  }
}

class _ProviderPhoneVerifiedScreenState
    extends State<ProviderPhoneVerifiedScreen> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _iconController;
  late AnimationController _titleController;
  late AnimationController _phoneController;
  late AnimationController _descriptionController;
  late AnimationController _buttonController;

  late Animation<double> _iconScale;
  late Animation<double> _titleSlide;
  late Animation<double> _phoneSlide;
  late Animation<double> _descriptionFade;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();

    // Initialize all animation controllers
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _phoneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _descriptionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Original bounce animation for success icon
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Create animations
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _titleSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );

    _phoneSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _phoneController, curve: Curves.easeOut),
    );

    _descriptionFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _descriptionController, curve: Curves.easeInOut),
    );

    _buttonScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );

    // Start staggered animations
    _startStaggeredAnimations();
  }

  void _startStaggeredAnimations() {
    // Success icon appears first
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _iconController.forward();
        _bounceController.forward();
      }
    });

    // Title appears third
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _titleController.forward();
    });

    // Phone number appears fourth
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _phoneController.forward();
    });

    // Description appears fifth
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) _descriptionController.forward();
    });

    // Button appears last
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _buttonController.dispose();
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
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verification Complete',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti celebration effect
            const _ConfettiWidget(),
            // Main content
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.all(_kScreenPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Success State: Enhanced success indicator with gradient and shadows
                      AnimatedBuilder(
                        animation: _iconScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _iconScale.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary,
                                primary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: primary.withValues(alpha: 0.1),
                                blurRadius: 40,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Subtle pulse ring
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.3),
                                      width: 3,
                                    ),
                                  ),
                                ),
                              ),
                              // Success icon with better visual
                              const Center(
                                child: Icon(
                                  Icons.verified_rounded,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Headline: "Phone Verified!"
                      AnimatedBuilder(
                        animation: _titleSlide,
                        builder: (context, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _titleSlide,
                              curve: Curves.easeOut,
                            )),
                            child: FadeTransition(
                              opacity: _titleSlide,
                              child: Semantics(
                                label: 'Phone verification successful',
                                child: Text(
                                  'Phone Verified!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      // Personalized phone number
                      AnimatedBuilder(
                        animation: _phoneSlide,
                        builder: (context, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _phoneSlide,
                              curve: Curves.easeOut,
                            )),
                            child: FadeTransition(
                              opacity: _phoneSlide,
                              child: Semantics(
                                label:
                                    'Phone number ${widget.phoneNumber} has been verified',
                                child: Text(
                                  '',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: primary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Body text
                      AnimatedBuilder(
                        animation: _descriptionFade,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _descriptionFade,
                            child: Semantics(
                              label:
                                  'Your account is now more secure. Next step is to upload your professional documents to complete verification.',
                              child: Text(
                                "Your account is now more secure. Next step: upload your professional documents to complete verification.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: muted,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      // Final CTA: "Continue to Verification"
                      AnimatedBuilder(
                        animation: _buttonScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _buttonScale.value,
                            child: child,
                          );
                        },
                        child: Semantics(
                          label: 'Continue to document verification',
                          hint: 'Double tap to proceed to the next step',
                          button: true,
                          child: _ContinueToVerificationButton(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // End of main content
          ],
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
  bool _isLoading = false;

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

  Future<void> _navigateToVerification() async {
    try {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);

      // Simulate navigation delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const ProviderDocumentVerificationScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Unable to navigate. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                setState(() => _isLoading = false);
                _navigateToVerification();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () async {
        await _navigateToVerification();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primary,
                primary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: primary.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading...',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue to Verification',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
