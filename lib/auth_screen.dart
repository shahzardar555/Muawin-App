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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive scaling factor based on screen width (360 is typical small phone)
    final scale = (screenWidth / 360).clamp(0.8, 1.2);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Auth image - capped at 40% of screen height for mobile fit
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: screenHeight * 0.55,
                        ),
                        child: Image.asset(
                          'imagess/Auth.png',
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Logo + Headlines row shifted downward
                      Transform.translate(
                        offset: const Offset(0, 40),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24 * scale,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'imagess/muawin_m_logo.svg',
                                height: 70 * scale,
                                width: 140 * scale,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(width: 12 * scale),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Get Trusted Household Help',
                                        style: GoogleFonts.poppins(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.4,
                                          color: Colors.black,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 42),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Anytime, Anywhere',
                                          style: GoogleFonts.poppins(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.4,
                                            color: Colors.black,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, 60),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                          child: Text(
                            'Find trusted, verified professionals for all your household needs',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: (15 * scale).clamp(13.0, 17.0),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.1,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Get Started button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24 * scale),
                        child: SizedBox(
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
                              padding: EdgeInsets.symmetric(
                                vertical: 16 * scale,
                              ),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              textStyle: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            child: const Text('Get Started'),
                          ),
                        ),
                      ),
                      SizedBox(height: 12 * scale),
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
                          padding: EdgeInsets.symmetric(
                            vertical: 12 * scale,
                          ),
                          textStyle: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        child: const Text('I already have an account'),
                      ),
                      SizedBox(height: 8 * scale),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}