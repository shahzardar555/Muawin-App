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
    final surface = Theme.of(context).colorScheme.surface;
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Headline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'How do you want to use Muawin?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 30, // text-3xl
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
              // Centered content area (flex-1 justify-center)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RoleCard(
                          icon: Icons.home_work_rounded,
                          title: 'I need household help',
                          description: 'Find verified professionals for cleaning, repairs, and daily tasks.',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const CustomerRegisterScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _RoleCard(
                          icon: Icons.build_circle_rounded,
                          title: 'I\'m a service professional',
                          description: 'Offer your skills and get connected with clients across Pakistan.',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
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
    );
  }
}

/// Interactive role card with squircle icon, hover and active states.
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

  static const double _padding = 32; // p-8
  static const double _radius = 24; // rounded-[24px]
  static const double _iconWrapperSize = 80; // w-20 h-20
  static const double _iconSize = 40; // w-10 h-10
  static const double _squircleRadius = 24; // rounded-3xl
  static const double _descPadding = 16; // px-4

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> with SingleTickerProviderStateMixin {
  bool _hovered = false;
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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) => _scaleController.reverse(),
        onTapCancel: () => _scaleController.reverse(),
        onTap: widget.onTap,
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
              color: _hovered ? primary.withValues(alpha: 0.05) : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(_RoleCard._radius),
              border: Border.all(
                color: _hovered ? primary.withValues(alpha: 0.3) : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Squircle icon wrapper (bg-primary/15, primary icon)
                Container(
                  width: _RoleCard._iconWrapperSize,
                  height: _RoleCard._iconWrapperSize,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(_RoleCard._squircleRadius),
                  ),
                  child: Icon(
                    widget.icon,
                    size: _RoleCard._iconSize,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 20),
                // Card title (text-xl font-bold)
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Description (text-sm text-muted-foreground, px-4)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _RoleCard._descPadding),
                  child: Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: muted,
                      height: 1.4,
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
