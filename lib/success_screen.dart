import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'providers/register_provider.dart';

/// Success celebration screen with confetti animation
class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _checkController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _textAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Create animations
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    ));

    // Start animations with delays
    _startAnimations();
  }

  void _startAnimations() {
    // Start confetti immediately
    _confettiController.forward();

    // Start scale animation after 200ms
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scaleController.forward();
    });

    // Start check animation after 400ms
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _checkController.forward();
    });

    // Start fade animation after 600ms
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primary.withValues(alpha: 0.1),
                  Colors.white,
                  primary.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),

          // Confetti animation
          _buildConfettiAnimation(),

          // Success content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Top spacer
                  SizedBox(height: screenHeight * 0.15),

                  // Success icon with animation
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                              width: 3,
                            ),
                          ),
                          child: AnimatedBuilder(
                            animation: _checkAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _checkAnimation.value,
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  size: 80,
                                  color: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Success title with animation
                  AnimatedBuilder(
                    animation: _textAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _textAnimation,
                            curve: Curves.easeOut,
                          )),
                          child: Text(
                            'Registration Successful!',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Success message with animation
                  AnimatedBuilder(
                    animation: _textAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _textAnimation,
                            curve: Curves.easeOut,
                          )),
                          child: Text(
                            'Welcome to the Muawin family!\nYour provider account has been created successfully.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Registration insights
                  AnimatedBuilder(
                    animation: _textAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textAnimation,
                        child: Consumer<RegisterProvider>(
                          builder: (context, provider, child) {
                            return _buildRegistrationInsights(provider);
                          },
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Continue button with animation
                  AnimatedBuilder(
                    animation: _buttonAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _buttonAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _buttonAnimation,
                            curve: Curves.easeOut,
                          )),
                          child: _buildContinueButton(context),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfettiAnimation() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ConfettiPainter(_confettiController),
      ),
    );
  }

  Widget _buildRegistrationInsights(RegisterProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Registration Summary',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            'Service Category',
            provider.selectedCategory ?? 'Not specified',
            Icons.business_center_rounded,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            'Experience',
            '${provider.years.isNotEmpty ? provider.years : '0'} years',
            Icons.work_outline_rounded,
          ),
          const SizedBox(height: 12),
          _buildInsightRow(
            'Location',
            '${provider.city.isNotEmpty ? provider.city : 'Not specified'}, ${provider.area.isNotEmpty ? provider.area : ''}',
            Icons.location_on_rounded,
          ),
          if (provider.formCompletionTime != null) ...[
            const SizedBox(height: 12),
            _buildInsightRow(
              'Completion Time',
              _formatDuration(provider.formCompletionTime!),
              Icons.access_time_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              Text(
                value,
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
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _navigateToDashboard,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue to Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(DateTime completionTime) {
    final duration = completionTime.difference(completionTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _navigateToDashboard() {
    // Navigate to dashboard (placeholder for now)
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }
}

/// Custom confetti painter
class ConfettiPainter extends CustomPainter {
  final Animation<double> animation;

  ConfettiPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random();

    // Generate confetti particles
    for (int i = 0; i < 50; i++) {
      final x = (random.nextDouble() * size.width);
      final y =
          (random.nextDouble() * size.height) - (animation.value * size.height);
      final color = _getRandomColor(i);
      final particleSize = random.nextDouble() * 4 + 2;

      paint.color = color;
      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }

    // Add some rectangular confetti
    for (int i = 0; i < 30; i++) {
      final x = (random.nextDouble() * size.width);
      final y =
          (random.nextDouble() * size.height) - (animation.value * size.height);
      final color = _getRandomColor(i + 50);
      final width = random.nextDouble() * 6 + 3;
      final height = random.nextDouble() * 3 + 2;

      paint.color = color;
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, y),
          width: width,
          height: height,
        ),
        paint,
      );
    }
  }

  Color _getRandomColor(int seed) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
    ];

    return colors[seed % colors.length];
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}

/// Enhanced success screen with more sophisticated animations
class EnhancedSuccessScreen extends StatefulWidget {
  const EnhancedSuccessScreen({super.key});

  @override
  State<EnhancedSuccessScreen> createState() => _EnhancedSuccessScreenState();
}

class _EnhancedSuccessScreenState extends State<EnhancedSuccessScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _particleControllers;
  late AnimationController _mainController;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Create multiple particle controllers for layered effects
    _particleControllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 2000 + index * 500),
        vsync: this,
      );
    });

    // Start animations
    _mainController.forward();
    for (final controller in _particleControllers) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    for (final controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Multiple confetti layers
          ..._particleControllers.map((controller) {
            return Positioned.fill(
              child: CustomPaint(
                painter: ConfettiPainter(controller),
              ),
            );
          }),

          // Main success content
          const SuccessScreen(),
        ],
      ),
    );
  }
}
