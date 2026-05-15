import 'package:flutter/material.dart';
import 'auth_screen.dart';

/// Muawin Primary Teal - saturated color for brand authority
const Color _muawinPrimaryTeal = Color(0xFF047A62);

class LogoutSplashScreen extends StatefulWidget {
  const LogoutSplashScreen({super.key});

  @override
  State<LogoutSplashScreen> createState() => _LogoutSplashScreenState();
}

class _LogoutSplashScreenState extends State<LogoutSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _logoController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _navigateAfterLogout();
  }

  Future<void> _navigateAfterLogout() async {
    await Future.delayed(const Duration(seconds: 4));

    await _fadeController.reverse();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _logoController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: _muawinPrimaryTeal,
            ),
            child: Column(
              children: [
                /// Top Section
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// Animated Urdu text
                        AnimatedBuilder(
                          animation: _scaleController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_scaleController.value * 0.05),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _waveController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _waveController.value * 0.3,
                                        child: Text(
                                          '👋',
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width <
                                                    400
                                                ? 48
                                                : 64,
                                            color: Colors.white
                                                .withValues(alpha: 0.95),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.85,
                                    ),
                                    child: Text(
                                      'ہمیں معاونت کا موقع دینے کا شکریہ',
                                      style: TextStyle(
                                        fontFamily: 'AlFarsAban',
                                        fontSize:
                                            MediaQuery.of(context).size.width <
                                                    400
                                                ? 32
                                                : 42,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white
                                            .withValues(alpha: 0.95),
                                        height:
                                            1.3, // Better line spacing for Urdu
                                        shadows: [
                                          Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            offset: const Offset(0, 4),
                                            blurRadius: 20,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines:
                                          2, // Allow text to wrap if needed
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                /// Bottom Section
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 64),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox(height: 32),

                        /// Loading animation
                        _AnimatedLogoutDots(controller: _logoController),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedLogoutDots extends AnimatedWidget {
  const _AnimatedLogoutDots({required Animation<double> controller})
      : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final stagger = index == 0 ? -0.3 : (index == 1 ? -0.15 : 0.0);
        final phase = (animation.value + stagger) % 1.0;

        final bounceValue = (phase < 0.5) ? (phase * 2) : 2 - (phase * 2);
        final opacity = 0.4 + (bounceValue * 0.6);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Transform.translate(
            offset: Offset(0, -12 * bounceValue),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
