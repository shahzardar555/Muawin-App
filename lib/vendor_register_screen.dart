import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'vendor_verify_phone_screen.dart';

/// Vendor categories for vendor registration.
const List<String> kVendorCategories = [
  'Supermarket',
  'Meatshop',
  'Milkshop',
  'Water Plant',
  'Gas Cylinder Shop',
  'Fruits and Vegetables Market',
  'Bakery',
];

/// Max width 28rem (448px), centered. Mobile-optimized (max-w-md mx-auto).
const double _kMaxContentWidth = 448;

/// Standard padding p-6 (1.5rem).
const double _kScreenPadding = 24;

/// Vertical gap between header and form (space-y-8 = 2rem).
const double _kHeaderFormGap = 32;

/// Vendor registration screen — Register your business or shop.
class VendorRegisterScreen extends StatefulWidget {
  const VendorRegisterScreen({super.key});

  @override
  State<VendorRegisterScreen> createState() => _VendorRegisterScreenState();
}

class _VendorRegisterScreenState extends State<VendorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _yearsController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _yearsController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    super.dispose();
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
                  // Primary Headline: "Vendor Account" — 1.875rem / text-3xl, bold Poppins
                  Text(
                    'Vendor Account',
                    style: GoogleFonts.poppins(
                      fontSize: 30, // 1.875rem
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sub-headline: "Register your business or shop" — medium weight gray
                  Text(
                    'Register your business or shop',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: _kHeaderFormGap),
                  // Business Name — User icon, placeholder "Super Grocery Store"
                  const _VendorFieldLabel(text: 'BUSINESS NAME'),
                  const SizedBox(height: 8),
                  _VendorInputWithIcon(
                    controller: _businessNameController,
                    hint: 'Super Grocery Store',
                    icon: Icons.person_rounded,
                    keyboardType: TextInputType.name,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Email
                  const _VendorFieldLabel(text: 'EMAIL'),
                  const SizedBox(height: 8),
                  _VendorInput(
                    controller: _emailController,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Phone Number
                  const _VendorFieldLabel(text: 'PHONE NUMBER'),
                  const SizedBox(height: 8),
                  _VendorInput(
                    controller: _phoneController,
                    hint: '03XX XXXXXXX',
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Vendor Category — custom Select dropdown
                  const _VendorFieldLabel(text: 'VENDOR CATEGORY'),
                  const SizedBox(height: 8),
                  _VendorCategoryDropdown(
                    value: _selectedCategory,
                    items: kVendorCategories,
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // Years in Business — Briefcase icon, "e.g. 5"
                  const _VendorFieldLabel(text: 'YEARS IN BUSINESS'),
                  const SizedBox(height: 8),
                  _VendorInputWithIcon(
                    controller: _yearsController,
                    hint: 'e.g. 5',
                    icon: Icons.business_center_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  // City & Area — 50/50 horizontal grid
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _VendorFieldLabel(text: 'CITY'),
                            const SizedBox(height: 8),
                            _VendorInput(
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
                            const _VendorFieldLabel(text: 'AREA'),
                            const SizedBox(height: 8),
                            _VendorInput(
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
                  const SizedBox(height: _kHeaderFormGap),
                  // Register Now — full-width, h-14, rounded-2xl, shadow, scale on tap
                  _VendorRegisterNowButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (_formKey.currentState?.validate() ?? false) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => VendorVerifyPhoneScreen(
                              phoneNumber: _phoneController.text.trim(),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  // Legal footer: "By registering, you agree to our Terms of Service"
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

/// Micro-typography label: 0.625rem (text-[10px]), bold, uppercase, letter-spacing 0.15em.
class _VendorFieldLabel extends StatelessWidget {
  const _VendorFieldLabel({required this.text});

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

/// High-profile field: h-12 (3rem), rounded-xl (0.75rem), bg-surface, no border.
class _VendorInput extends StatelessWidget {
  const _VendorInput({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

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

/// Input with leading icon (User for Business Name, Briefcase for Years).
class _VendorInputWithIcon extends StatelessWidget {
  const _VendorInputWithIcon({
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

/// Vendor Category dropdown.
class _VendorCategoryDropdown extends StatelessWidget {
  const _VendorCategoryDropdown({
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

/// Register Now button: h-14 (3.5rem), rounded-2xl (1rem), shadow-primary/20, active:scale-95.
class _VendorRegisterNowButton extends StatefulWidget {
  const _VendorRegisterNowButton({required this.onPressed});

  final VoidCallback onPressed;

  static const double _height = 56;
  static const double _radius = 16;

  @override
  State<_VendorRegisterNowButton> createState() =>
      _VendorRegisterNowButtonState();
}

class _VendorRegisterNowButtonState extends State<_VendorRegisterNowButton>
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
          height: _VendorRegisterNowButton._height,
          decoration: BoxDecoration(
            color: primary,
            borderRadius:
                BorderRadius.circular(_VendorRegisterNowButton._radius),
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
              title: '2. Vendor Responsibilities',
              content:
                  'As a vendor partner with Muawin, you agree to:\n• Provide accurate business information\n• Maintain professional standards\n• Comply with all local regulations\n• Honor pricing and availability commitments\n• Respond promptly to customer inquiries',
            ),
            const SizedBox(height: 16),
            const _TermsSection(
              title: '3. Service Quality',
              content:
                  'You commit to delivering high-quality products and services as listed. Muawin reserves the right to delist vendors who consistently fail to meet quality standards.',
            ),
            const SizedBox(height: 16),
            const _TermsSection(
              title: '4. Commission Structure',
              content:
                  'Muawin charges a commission on transactions. By registering, you acknowledge and accept our commission rates. Commission details will be provided in your vendor agreement.',
            ),
            const SizedBox(height: 16),
            const _TermsSection(
              title: '5. Professional Conduct',
              content:
                  'You agree to maintain professional conduct at all times. Harassment, discrimination, or unethical behavior will result in immediate delisting and potential legal action.',
            ),
            const SizedBox(height: 16),
            const _TermsSection(
              title: '6. Limitation of Liability',
              content:
                  'Muawin is provided "as is" without warranty. We are not liable for any indirect, incidental, special, or consequential damages from platform use.',
            ),
            const SizedBox(height: 16),
            const _TermsSection(
              title: '7. Account Termination',
              content:
                  'Muawin reserves the right to suspend or terminate any vendor account that violates these terms or engages in fraudulent activity.',
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
