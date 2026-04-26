import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'customer_home_screen.dart';

/// Max width 28rem (448px), centered (max-w-md mx-auto).
const double _kMaxContentWidth = 448;

/// Standard padding p-6 (1.5rem).
const double _kScreenPadding = 24;

/// Hero circle size for success state: 6rem (w-24 h-24).
const double _kSuccessHeroSize = 96;

/// Customer registration successful screen
/// Shows success animation and navigates to customer home screen
class CustomerRegistrationSuccessfulScreen extends StatefulWidget {
  const CustomerRegistrationSuccessfulScreen({super.key});

  @override
  State<CustomerRegistrationSuccessfulScreen> createState() =>
      _CustomerRegistrationSuccessfulScreenState();
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
    final random = math.Random();
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
        rotation: random.nextDouble() * math.pi * 2,
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

class _CustomerRegistrationSuccessfulScreenState
    extends State<CustomerRegistrationSuccessfulScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _progressController;
  late AnimationController _iconController;
  late AnimationController _titleController;
  late AnimationController _descriptionController;
  late AnimationController _buttonController;

  late Animation<double> _progressFade;
  late Animation<double> _iconScale;
  late Animation<double> _titleSlide;
  late Animation<double> _descriptionSlide;
  late Animation<double> _buttonSlide;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _titleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _descriptionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create animations
    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const ElasticOutCurve(0.8),
      ),
    );

    _titleSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );

    _descriptionSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _descriptionController, curve: Curves.easeOut),
    );

    _buttonSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _iconController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _titleController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _descriptionController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    _buttonController.forward();

    // Start bounce animation
    _bounceController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _progressController.dispose();
    _iconController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
            child: Padding(
              padding: const EdgeInsets.all(_kScreenPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Progress indicator
                  FadeTransition(
                    opacity: _progressFade,
                    child: Container(
                      width: double.infinity,
                      height: 4,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Success icon with bounce animation
                  AnimatedBuilder(
                    animation: _bounceController,
                    builder: (context, child) => Transform.scale(
                      scale: 1.0 + (_bounceController.value * 0.05),
                      child: child,
                    ),
                    child: ScaleTransition(
                      scale: _iconScale,
                      child: Container(
                        width: _kSuccessHeroSize,
                        height: _kSuccessHeroSize,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 60,
                          color: primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_titleSlide),
                    child: FadeTransition(
                      opacity: _titleSlide,
                      child: Text(
                        'Registration Successful!',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_descriptionSlide),
                    child: FadeTransition(
                      opacity: _descriptionSlide,
                      child: Text(
                        'Your account has been successfully created and verified. You\'re all set to start using our services!',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Go to Homepage button
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_buttonSlide),
                    child: FadeTransition(
                      opacity: _buttonSlide,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute<void>(
                                builder: (_) => const CustomerHomeScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 20),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Go to Homepage',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
