import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'customer_register_screen.dart';
import 'provider_service_screen.dart';

/// Max width for the narrow centered column (max-w-md).
const double _kMaxContentWidth = 448;

/// Screen shown after tapping "Get Started" on the auth screen.
class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
            child: Column(
              children: [
                const SizedBox(height: 24),

                /// Headline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'How do you want to use Muawin?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                      height: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// Centered content area
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _RoleCard(
                            icon: Icons.home_work_rounded,
                            title: 'I need household help',
                            description:
                                'Find verified professionals for cleaning, repairs, and daily tasks.',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CustomerRegisterScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _RoleCard(
                            icon: Icons.build_circle_rounded,
                            title: 'I\'m a service professional',
                            description:
                                'Offer your skills and get connected with clients across Pakistan.',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProviderServiceScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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

/// Interactive role card with squircle icon and press animation.
class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  static const double _padding = 32;
  static const double _radius = 24;
  static const double _iconWrapperSize = 80;
  static const double _iconSize = 40;
  static const double _squircleRadius = 24;
  static const double _descPadding = 16;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return InkWell(
      borderRadius: BorderRadius.circular(_RoleCard._radius),
      onTap: widget.onTap,
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(scale: _scaleAnimation.value, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(_RoleCard._padding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(_RoleCard._radius),
            border: Border.all(
              color: primary.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Icon container
              Container(
                width: _RoleCard._iconWrapperSize,
                height: _RoleCard._iconWrapperSize,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius:
                      BorderRadius.circular(_RoleCard._squircleRadius),
                ),
                child: Icon(
                  widget.icon,
                  size: _RoleCard._iconSize,
                  color: primary,
                ),
              ),

              const SizedBox(height: 20),

              /// Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              /// Description
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _RoleCard._descPadding),
                child: Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: muted,
                    height: 1.4,
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
