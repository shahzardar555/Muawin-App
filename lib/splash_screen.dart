import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screen.dart';

/// Muawin Primary Teal - saturated color for brand authority
const Color _muawinPrimaryTeal = Color(0xFF047A62);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    // Entry fade-in animation: 500ms
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    // Dots bouncing animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    // Exactly 3000ms (3 seconds) before navigation
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeController,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(color: _muawinPrimaryTeal),
          child: Column(
            children: [
              // Upper two-thirds: centered identity anchor
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Container: 6rem x 6rem (96x96px) squircle
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(32), // 2rem radius
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/muawin_icon.png',
                            width: 56, // 3.5rem
                            height: 56,
                            color: _muawinPrimaryTeal,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Headline: "Muawin"
                      Text(
                        'Muawin',
                        style: GoogleFonts.poppins(
                          fontSize: 72, // 4.5rem
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1.08, // tracking-tighter
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Urdu Tagline: "گھر کے کام، اب آسان"
                      Text(
                        'گھر کے کام، اب آسان',
                        style: GoogleFonts.notoSansArabic(
                          fontSize: 24, // 1.5rem / text-2xl
                          color:
                              Colors.white.withValues(alpha: 0.95), // 95% white
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom third: footer with branding and progress indicator
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 64), // pb-16 (4rem)
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Brand micro-copy: "YOUR TRUSTED HOUSEHOLD HELPER"
                      Text(
                        'YOUR TRUSTED HOUSEHOLD HELPER',
                        style: GoogleFonts.poppins(
                          fontSize: 12, // text-xs (0.75rem)
                          fontWeight: FontWeight.bold,
                          color:
                              Colors.white.withValues(alpha: 0.6), // 60% white
                          letterSpacing: 3.2, // 0.2em (tracking-[0.2em])
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Activity indicator: three animated dots
                      _AnimatedDots(controller: _dotsController),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedDots extends AnimatedWidget {
  const _AnimatedDots({required Animation<double> controller})
      : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        // Staggered delays: -0.3s, -0.15s, 0s
        final stagger = index == 0 ? -0.3 : (index == 1 ? -0.15 : 0.0);
        final phase = (animation.value + stagger) % 1.0;

        // Bounce animation
        final bounceValue = (phase < 0.5)
            ? (phase * 2) // 0 to 1
            : 2 - (phase * 2); // 1 to 0
        final opacity = 0.4 + (bounceValue * 0.6);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Transform.translate(
            offset: Offset(0, -12 * bounceValue), // Bounce up/down
            child: Container(
              width: 10, // 0.625rem / w-2.5 h-2.5
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
