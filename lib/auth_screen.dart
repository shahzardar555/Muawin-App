import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'get_started_screen.dart';
import 'login_screen.dart';

const Color _brandGreen = Color(0xFF047A62);

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Muawin logo
              SvgPicture.asset(
                'imagess/muawin_m_logo.svg',
                height: 120, // Reduced from 240 to 120
                width: 300, // Reduced from 600 to 300
                fit: BoxFit.contain,
              ),
              // Headlines // No spacing - logo and text directly connected
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
              // Feature cards
              _FeatureCard(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .secondary
                    .withValues(alpha: 0.3),
                icon: Icons.verified_user_rounded,
                title: 'Verified Pros',
                description: 'Background-checked professionals you can trust.',
              ),
              const SizedBox(height: 16),
              _FeatureCard(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                icon: Icons.flash_on_rounded,
                title: 'Instant Matching',
                description: 'Get matched with the right help in seconds.',
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
      ),
    );
  }
}

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

  static const double _radius = 16;
  static const double _padding = 16;
  static const double _gap = 16;
  static const double _iconSize = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedGray = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.all(_padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                    fontSize: 12,
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
