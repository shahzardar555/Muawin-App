import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'customer_home_screen.dart';
import 'vendor_home_screen.dart';
import 'service_provider_feed_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _dotsController;
  late AnimationController _scaleController;
  late AnimationController _textController;

  // New animation controllers for enhanced sequence
  late AnimationController _urduFadeController;
  late AnimationController _logoFadeController;

  bool _isUserLoggedIn = false;
  String _userType = 'customer'; // 'customer', 'vendor', or 'service_provider'

  // Enhanced animation state
  bool _showFirstPart = false;
  bool _showSecondPart = false;
  bool _showLogoText = false;

  // Urdu text parts for ease-in animation
  static const String _firstPart = 'گھر کے کام';
  static const String _secondPart = 'اب آسان';

  // Animation controllers for Urdu text parts
  late AnimationController _firstPartController;
  late AnimationController _secondPartController;

  // Responsive sizing functions
  double getLogoSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 80;
    if (width < 400) return 100;
    return 120;
  }

  double getFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 40;
    if (width < 400) return 48;
    return 56;
  }

  double getIconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 40;
    if (width < 400) return 50;
    return 60;
  }

  double getUrduFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 32;
    if (width < 400) return 36;
    return 40;
  }

  @override
  void initState() {
    super.initState();

    // Preload fonts to prevent font switching during animation
    GoogleFonts.poppins(fontWeight: FontWeight.bold);
    GoogleFonts.notoSansArabic(fontWeight: FontWeight.w400);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // New animation controllers for enhanced sequence
    _urduFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _logoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Old controllers (kept for compatibility)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize Urdu text animation controllers
    _firstPartController = AnimationController(
      duration:
          const Duration(milliseconds: 800), // Ease-in duration for first part
      vsync: this,
    );

    _secondPartController = AnimationController(
      duration:
          const Duration(milliseconds: 600), // Ease-in duration for second part
      vsync: this,
    );

    // Start the fade controller to make the splash screen visible
    _fadeController.forward();

    // Start the enhanced animation sequence
    _startEnhancedAnimationSequence();
    _navigateAfterSplash();
  }

  void _startEnhancedAnimationSequence() {
    // Phase 1: Initial blank screen (400ms)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _showFirstPart = true;
        });
        // Start ease-in animation for first part
        _firstPartController.forward();
      }
    });

    // Phase 2: After first part animation (800ms + 1500ms display)
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) {
        setState(() {
          _showSecondPart = true;
        });
        // Start ease-in animation for second part
        _secondPartController.forward();
      }
    });

    // Phase 3: Fade out both parts after complete display (800ms after second part)
    Future.delayed(const Duration(milliseconds: 4100), () {
      if (mounted) {
        _urduFadeController.forward().then((_) {
          if (mounted) {
            setState(() {
              _showFirstPart = false;
              _showSecondPart = false;
            });
            // Phase 4: Transition pause (400ms)
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) {
                setState(() {
                  _showLogoText = true;
                });
                _logoFadeController.forward();
              }
            });
          }
        });
      }
    });
  }

  Future<void> _navigateAfterSplash() async {
    // Wait for 5.5 seconds total
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 5500)), // 5.5 seconds total
      _initializeApp(), // auth check, prefs load, etc.
    ]);

    // then navigate
    _navigateToNextScreen();
  }

  Future<void> _initializeApp() async {
    try {
      // Check SharedPreferences, validate token, load config
      final prefs = await SharedPreferences.getInstance();
      _isUserLoggedIn = prefs.getString('auth_token') != null;

      // Check user type if logged in
      if (_isUserLoggedIn) {
        _userType = prefs.getString('user_type') ?? 'customer';
      }

      // Simulate additional app initialization
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      // Handle initialization errors gracefully
    }
  }

  void _navigateToNextScreen() async {
    if (!mounted) return;

    await _fadeController.reverse();

    if (!mounted) return;

    // Check authentication status and route accordingly
    if (_isUserLoggedIn) {
      // User is logged in - navigate to appropriate home screen
      if (_userType == 'vendor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const VendorHomeScreen(),
          ),
        );
      } else if (_userType == 'service_provider') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ServiceProviderFeedScreen(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const CustomerHomeScreen(),
          ),
        );
      }
    } else {
      // User is not logged in - navigate to auth
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AuthScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dotsController.dispose();
    _scaleController.dispose();
    _textController.dispose();
    _urduFadeController.dispose();
    _logoFadeController.dispose();
    _firstPartController.dispose();
    _secondPartController.dispose();
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
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF047A62),
                  Color(0xFF036152),
                  Color(0xFF024842),
                ],
              ),
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
                        const SizedBox(
                            height:
                                40), // Added spacing above logo to move it down

                        const SizedBox(height: 8),

                        /// Urdu Text with Ease-in Animation - Shows during phase 1-2
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Second part: "اب آسان" with ease-in animation (appears on right for RTL)
                            if (_showSecondPart)
                              AnimatedBuilder(
                                animation: _secondPartController,
                                builder: (context, child) {
                                  return FadeTransition(
                                    opacity: _secondPartController,
                                    child: Text(
                                      _secondPart,
                                      style: TextStyle(
                                        fontFamily: 'AlFarsAban',
                                        fontSize: getUrduFontSize(context),
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white
                                            .withValues(alpha: 0.95),
                                        shadows: [
                                          Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            offset: const Offset(0, 2),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),

                            // Comma separator - shows when both parts are visible
                            if (_showFirstPart && _showSecondPart)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '،',
                                  style: TextStyle(
                                    fontFamily: 'AlFarsAban',
                                    fontSize: getUrduFontSize(context),
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    shadows: [
                                      Shadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                            // First part: "گھر کے کام" with ease-in animation (appears on left for RTL)
                            if (_showFirstPart)
                              AnimatedBuilder(
                                animation: _firstPartController,
                                builder: (context, child) {
                                  return FadeTransition(
                                    opacity: _firstPartController,
                                    child: Text(
                                      _firstPart,
                                      style: TextStyle(
                                        fontFamily: 'AlFarsAban',
                                        fontSize: getUrduFontSize(context),
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white
                                            .withValues(alpha: 0.95),
                                        shadows: [
                                          Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            offset: const Offset(0, 2),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),

                        /// App Logo/Icon - Shows during phase 4 with fade-in animation
                        if (_showLogoText)
                          AnimatedBuilder(
                            animation: _logoFadeController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _logoFadeController,
                                child: Column(
                                  children: [
                                    SvgPicture.asset(
                                      'imagess/muawin_m_logo.svg',
                                      width: getLogoSize(context),
                                      height: getLogoSize(context),
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 24),

                                    /// App Name - Enhanced with better shadow, responsive sizing
                                    Text(
                                      'Muawin',
                                      style: GoogleFonts.poppins(
                                        fontSize: getFontSize(context),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -1.08,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.4),
                                            offset: const Offset(0, 6),
                                            blurRadius: 30,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
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
                        const SizedBox(height: 20),

                        /// Loading animation
                        _AnimatedDots(controller: _dotsController),
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
