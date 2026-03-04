import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vendor_verify_phone_screen.dart';

/// Service categories for provider registration.
const List<String> kCategories = [
  'Maid',
  'Driver',
  'Babysitter',
  'Security Guard',
  'Washerman',
  'Domestic Helper',
  'Cook',
  'Gardener',
  'Tutor',
];

/// Max width 28rem (448px), centered.
const double _kMaxContentWidth = 448;

/// Standard padding p-6.
const double _kScreenPadding = 24;

/// Service provider registration screen.
class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  State<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _yearsController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  String? _selectedCategory;
  TimeOfDay _fromTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _yearsController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(BuildContext context, bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _fromTime : _toTime,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
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
                  // Headline
                  Text(
                    'Provider Account',
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sub-headline
                  Text(
                    'Join as a skilled professional',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Full Name
                  const _FieldLabel(text: 'FULL NAME'),
                  const SizedBox(height: 8),
                  _ProviderInput(
                    controller: _nameController,
                    hint: 'Enter your full name',
                    keyboardType: TextInputType.name,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Email
                  const _FieldLabel(text: 'EMAIL'),
                  const SizedBox(height: 8),
                  _ProviderInput(
                    controller: _emailController,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Phone
                  const _FieldLabel(text: 'PHONE'),
                  const SizedBox(height: 8),
                  _ProviderInput(
                    controller: _phoneController,
                    hint: '03XX XXXXXXX',
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Create New Password
                  const _FieldLabel(text: 'CREATE NEW PASSWORD'),
                  const SizedBox(height: 8),
                  _ProviderInput(
                    controller: _passwordController,
                    hint: 'Enter password',
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Confirm Password
                  const _FieldLabel(text: 'CONFIRM PASSWORD'),
                  const SizedBox(height: 8),
                  _ProviderInput(
                    controller: _confirmPasswordController,
                    hint: 'Confirm your password',
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
                  const SizedBox(height: 16),
                  // Service Category
                  const _FieldLabel(text: 'SERVICE CATEGORY'),
                  const SizedBox(height: 8),
                  _CategoryDropdown(
                    value: _selectedCategory,
                    items: kCategories,
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Years of Experience
                  const _FieldLabel(text: 'YEARS OF EXPERIENCE'),
                  const SizedBox(height: 8),
                  _ProviderInputWithIcon(
                    controller: _yearsController,
                    hint: 'e.g. 5',
                    icon: Icons.business_center_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Standard Working Hours
                  const _FieldLabel(text: 'STANDARD WORKING HOURS'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.15 * 10,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _TimeInput(
                              time: _fromTime,
                              onTap: () => _pickTime(context, true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.15 * 10,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _TimeInput(
                              time: _toTime,
                              onTap: () => _pickTime(context, false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // City & Area (50/50 grid)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel(text: 'CITY'),
                            const SizedBox(height: 8),
                            _ProviderInput(
                              controller: _cityController,
                              hint: 'City',
                              keyboardType: TextInputType.streetAddress,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel(text: 'AREA'),
                            const SizedBox(height: 8),
                            _ProviderInput(
                              controller: _areaController,
                              hint: 'Area',
                              keyboardType: TextInputType.streetAddress,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Register Now button
                  _RegisterNowButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (_formKey.currentState?.validate() ?? false) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => VendorVerifyPhoneScreen(
                              phoneNumber: _phoneController.text.trim(),
                              verificationType: VerificationType.provider,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  // Legal footer
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const _TermsOfServiceScreen(),
                        ),
                      );
                    },
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: muted,
                        ),
                        children: [
                          const TextSpan(
                              text: 'By registering, you agree to our '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
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
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.15 * 10,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

/// Standard input: h-12, rounded-xl, bg-surface, no border.
class _ProviderInput extends StatelessWidget {
  const _ProviderInput({
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

  static const double _height = 48;
  static const double _radius = 12;

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

/// Input with leading icon (Briefcase for Years of Experience).
class _ProviderInputWithIcon extends StatelessWidget {
  const _ProviderInputWithIcon({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  static const double _height = 48;
  static const double _radius = 12;
  static const double _iconLeft = 16;
  static const double _paddingLeft = 44;

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
            keyboardType: keyboardType,
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

/// Service Category dropdown.
class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.validator,
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
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
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      hint: Text(
        'Select category',
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: onSurface.withValues(alpha: 0.45),
          fontWeight: FontWeight.w400,
        ),
      ),
      isExpanded: true,
      validator: validator,
      items: items
          .map((e) => DropdownMenuItem<String>(
                value: e,
                child: Text(
                  e,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: onSurface,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// Time input tile (tappable to open picker).
class _TimeInput extends StatelessWidget {
  const _TimeInput({required this.time, required this.onTap});

  final TimeOfDay time;
  final VoidCallback onTap;

  static const double _height = 48;
  static const double _radius = 12;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(_radius),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          time.format(context),
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: onSurface,
          ),
        ),
      ),
    );
  }
}

/// Register Now button: h-14, rounded-2xl, shadow-primary/20.
class _RegisterNowButton extends StatefulWidget {
  const _RegisterNowButton({required this.onPressed});

  final VoidCallback onPressed;

  static const double _height = 56;
  static const double _radius = 16;

  @override
  State<_RegisterNowButton> createState() => _RegisterNowButtonState();
}

class _RegisterNowButtonState extends State<_RegisterNowButton>
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
          height: _RegisterNowButton._height,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(_RegisterNowButton._radius),
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
            'Register Now',
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

/// Terms of Service screen.
class _TermsOfServiceScreen extends StatelessWidget {
  const _TermsOfServiceScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

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
        title: Text(
          'Terms of Service',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Updated: March 3, 2026',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            const _TermsSection(
              title: '1. Acceptance of Terms',
              content:
                  'By using the Muawin platform, you agree to comply with these Terms of Service and all applicable laws and regulations. If you do not agree with any part of these terms, please do not use our service.',
            ),
            const SizedBox(height: 16),
            const _TermsSection(
              title: '2. User Responsibilities',
              content:
                  'As a service provider on Muawin, you agree to:\n• Provide accurate and truthful information\n• Maintain professional conduct\n• Comply with all local laws and regulations\n• Protect customer privacy and data\n• Report any issues promptly',
            ),
            const SizedBox(height: 16),
            const _TermsSection(
              title: '3. Service Quality',
              content:
                  'You commit to delivering high-quality professional services as described. Muawin reserves the right to take action against service providers who consistently receive poor ratings or customer complaints.',
            ),
            const SizedBox(height: 16),
            const _TermsSection(
              title: '4. Payment and Commissions',
              content:
                  'Muawin charges a commission on services rendered through the platform. By registering, you acknowledge and accept our current commission structure. Payment terms will be detailed in your service provider agreement.',
            ),
            const SizedBox(height: 16),
            const _TermsSection(
              title: '5. Code of Conduct',
              content:
                  'You agree to maintain professional behavior at all times. Any form of harassment, discrimination, or inappropriate conduct will result in immediate account suspension and potential legal action.',
            ),
            const SizedBox(height: 16),
            const _TermsSection(
              title: '6. Limitation of Liability',
              content:
                  'Muawin is provided "as is" without warranty. We are not liable for any indirect, incidental, special, or consequential damages arising from the use of our platform.',
            ),
            const SizedBox(height: 16),
            const _TermsSection(
              title: '7. Termination',
              content:
                  'Muawin reserves the right to suspend or terminate any account that violates these terms or engages in fraudulent activity.',
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
