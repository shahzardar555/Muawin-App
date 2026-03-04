import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'customer_home_screen.dart';

/// Max width 28rem (448px), centered.
const double _kMaxContentWidth = 448;

/// Standard padding p-6.
const double _kScreenPadding = 24;

/// Customer registration screen shown when tapping "I need household help".
class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_kScreenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // Primary headline (text-3xl font-bold)
                  Text(
                    'Create your account',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sub-headline (text-muted-foreground font-medium)
                  Text(
                    'Sign up to find verified professionals for your home.',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32), // space-y-8 = 2rem
                  // Field labels: 0.625rem bold uppercase letter-spacing 0.15em
                  const _FieldLabel(text: 'FULL NAME'),
                  const SizedBox(height: 8),
                  _RegisterInput(
                    controller: _nameController,
                    hint: 'Enter your full name',
                    keyboardType: TextInputType.name,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel(text: 'EMAIL'),
                  const SizedBox(height: 8),
                  _RegisterInput(
                    controller: _emailController,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel(text: 'PHONE'),
                  const SizedBox(height: 8),
                  _RegisterInput(
                    controller: _phoneController,
                    hint: '03XX XXXXXXX',
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel(text: 'LOCATION'),
                  const SizedBox(height: 8),
                  _RegisterInputWithIcon(
                    controller: _locationController,
                    hint: 'City or area',
                    icon: Icons.location_on_outlined,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel(text: 'CREATE NEW PASSWORD'),
                  const SizedBox(height: 8),
                  _RegisterInput(
                    controller: _passwordController,
                    hint: '••••••••',
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel(text: 'CONFIRM NEW PASSWORD'),
                  const SizedBox(height: 8),
                  _RegisterInput(
                    controller: _confirmPasswordController,
                    hint: '••••••••',
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  _RegisterButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (_formKey.currentState?.validate() ?? false) {
                        // pretend registration succeeded and move to home
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => CustomerHomeScreen(
                                userName: _nameController.text.trim()),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Micro-typography label: 0.625rem bold uppercase letter-spacing 0.15em.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 10, // 0.625rem
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15 * 10, // 0.15em
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

/// High-profile input: h-12, rounded-xl, bg-surface, no border.
class _RegisterInput extends StatelessWidget {
  const _RegisterInput({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.validator,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;

  static const double _height = 48; // h-12 = 3rem
  static const double _radius = 12; // rounded-xl = 0.75rem

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SizedBox(
      height: _height,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: GoogleFonts.poppins(
            fontSize: 15, color: onSurface, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: onSurface.withValues(alpha: 0.45),
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: BorderSide(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

/// Input with leading icon (absolute left-4, pl-11).
class _RegisterInputWithIcon extends StatelessWidget {
  const _RegisterInputWithIcon({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  static const double _height = 48;
  static const double _radius = 12;
  static const double _iconLeft = 16; // left-4
  static const double _paddingLeft = 44; // pl-11

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: _height,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: _iconLeft,
            child: Icon(icon, size: 20, color: primary.withValues(alpha: 0.7)),
          ),
          TextFormField(
            controller: controller,
            validator: validator,
            style: GoogleFonts.poppins(
                fontSize: 15, color: onSurface, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: BorderSide(
                  color: primary.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              contentPadding: const EdgeInsets.only(
                  left: _paddingLeft, right: 16, top: 14, bottom: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Register button: full-width h-14, rounded-2xl, shadow-primary/20, active:scale-95.
class _RegisterButton extends StatefulWidget {
  const _RegisterButton({required this.onPressed});

  final VoidCallback onPressed;

  static const double _height = 56; // h-14
  static const double _radius = 16; // rounded-2xl = 1rem

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          height: _RegisterButton._height,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(_RegisterButton._radius),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'Register',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
