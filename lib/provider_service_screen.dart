import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'provider_register_screen.dart';
import 'vendor_register_screen.dart';

/// Max width 28rem (448px), centered.
const double _kMaxContentWidth = 448;

/// Standard padding p-6.
const double _kScreenPadding = 24;

/// Screen shown when tapping "I'm a service professional" — choose service category.
class ProviderServiceScreen extends StatelessWidget {
  const ProviderServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

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
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(_kScreenPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Typography block: headline + muted description
                        Text(
                          'Are you a?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 30, // 1.875rem / text-3xl
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tell us more about your business model',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: muted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 32), // space-y-8 = 2rem
                        // Selection cards
                        _ProviderRoleCard(
                          icon: Icons.person_rounded,
                          title: 'Service Provider',
                          description: 'Individual Professional (e.g Maid , Driver , Cook , Gardener)',
                          onTap: () => _onServiceSelected(context, 'Service Provider'),
                        ),
                        const SizedBox(height: 16),
                        _ProviderRoleCard(
                          icon: Icons.store_rounded,
                          title: 'Vendor',
                          description: 'Business or Shop (e.g SuperMarket , Milkshop , Meatshop , Water Plant)',
                          onTap: () => _onServiceSelected(context, 'Vendor'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Micro-typography footer
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Text(
                  'Choose the option that best describes your professional setup.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12, // 0.75rem / text-xs
                    fontWeight: FontWeight.w400,
                    color: muted,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onServiceSelected(BuildContext context, String service) {
    HapticFeedback.lightImpact();
    if (service == 'Service Provider') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ProviderRegisterScreen(),
        ),
      );
    } else if (service == 'Vendor') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const VendorRegisterScreen(),
        ),
      );
    }
  }
}

/// Interactive role card: rounded-[24px], p-8, squircle icon, hover + active:scale-95.
class _ProviderRoleCard extends StatefulWidget {
  const _ProviderRoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  static const double _padding = 32; // p-8 = 2rem
  static const double _radius = 24; // rounded-[24px] = 1.5rem
  static const double _iconSize = 80; // w-20 h-20 = 5rem
  static const double _squircleRadius = 24; // rounded-3xl = 1.5rem
  static const double _iconInnerSize = 40;

  @override
  State<_ProviderRoleCard> createState() => _ProviderRoleCardState();
}

class _ProviderRoleCardState extends State<_ProviderRoleCard>
    with SingleTickerProviderStateMixin {
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
          builder: (context, child) =>
              Transform.scale(scale: _scaleAnimation.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(_ProviderRoleCard._padding),
            decoration: BoxDecoration(
              color: _hovered
                  ? primary.withValues(alpha: 0.05)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(_ProviderRoleCard._radius),
              border: Border.all(
                color: _hovered
                    ? primary.withValues(alpha: 0.3)
                    : Colors.transparent,
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
                // Squircle icon: 5rem x 5rem, primary/15, radius 1.5rem
                Container(
                  width: _ProviderRoleCard._iconSize,
                  height: _ProviderRoleCard._iconSize,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(_ProviderRoleCard._squircleRadius),
                  ),
                  child: Icon(
                    widget.icon,
                    size: _ProviderRoleCard._iconInnerSize,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 20),
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
                Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: muted,
                    height: 1.4,
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
