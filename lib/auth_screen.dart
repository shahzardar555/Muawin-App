import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'get_started_screen.dart';
import 'login_screen.dart';

/// Same green as splash background for Get Started button.
const Color _brandGreen = Color(0xFF047A62);

/// Authorization / onboarding screen shown after splash.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Muawin logo at the top
                    Image.asset(
                      'assets/muawin_logo.png',
                      height: 80,
                      width: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    // Bold headline: Get Trusted Household Help
                    Text(
                      'Get Trusted Household Help',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bold: Anytime, Anywhere
                    Text(
                      'Anytime, Anywhere',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Smaller non-bold body text
                    Text(
                      'Connecting you with verified professionals for all your home needs across Pakistan.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Feature cards row
                    _FeatureCard(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.3),
                      icon: Icons.verified_user_rounded,
                      title: 'Verified Pros',
                      description:
                          'Background-checked professionals you can trust.',
                    ),
                    const SizedBox(height: 16),
                    _FeatureCard(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      icon: Icons.flash_on_rounded,
                      title: 'Instant Matching',
                      description:
                          'Get matched with the right help in seconds.',
                    ),
                    const SizedBox(height: 32),
                    // Get Started button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const GetStartedScreen()),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _brandGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Get Started'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // I already have an account
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      child: const Text('I already have an account'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Single feature card: rounded container with icon circle + title/description.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.backgroundColor,
    required this.icon,
    required this.title,
    required this.description,
  });

  final Color backgroundColor;
  final IconData icon;
  final String title;
  final String description;

  static const double _radius = 16; // 1rem
  static const double _padding = 16; // p-4
  static const double _gap = 16; // gap-4
  static const double _iconSize = 48; // w-12 h-12 = 3rem

  @override
  Widget build(BuildContext context) {
    final mutedGray =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon wrapper: circle, white bg, no-shrink
          SizedBox(
            width: _iconSize,
            height: _iconSize,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, size: 24, color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: _gap),
          // Text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 12, // 0.75rem / text-xs
                    fontWeight: FontWeight.w400,
                    color: mutedGray,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
