import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:convert';
import 'vendor_verify_phone_screen.dart';

/// Location data model for autocomplete
class Location {
  final String city;
  final String area;
  final String fullAddress;

  const Location({
    required this.city,
    required this.area,
    required this.fullAddress,
  });

  @override
  String toString() => fullAddress;
}

/// Service categories for provider registration with icons
const List<Map<String, dynamic>> kCategoriesWithIcons = [
  {'name': 'Maid', 'icon': Icons.cleaning_services_rounded},
  {'name': 'Driver', 'icon': Icons.drive_eta_rounded},
  {'name': 'Babysitter', 'icon': Icons.child_care_rounded},
  {'name': 'Security Guard', 'icon': Icons.security_rounded},
  {'name': 'Washerman', 'icon': Icons.local_laundry_service_rounded},
  {'name': 'Domestic Helper', 'icon': Icons.home_repair_service_rounded},
  {'name': 'Cook', 'icon': Icons.restaurant_rounded},
  {'name': 'Gardener', 'icon': Icons.yard_rounded},
  {'name': 'Tutor', 'icon': Icons.school_rounded},
];

/// Animated text field with focus animations
class _AnimatedTextField extends StatefulWidget {
  const _AnimatedTextField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.errorText,
    this.isValid = false,
    this.showValidationBorder = false,
    this.textInputAction,
    this.focusNode,
    this.nextFocusNode,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final String? errorText;
  final bool isValid;
  final bool showValidationBorder;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  @override
  State<_AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<_AnimatedTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _borderColorAnimation;
  late Animation<double> _borderWidthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _borderWidthAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Listen to focus changes
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _borderColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Theme.of(context).colorScheme.primary,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  void _onFocusChange() {
    if (widget.focusNode?.hasFocus ?? false) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    // Determine border color based on validation state
    Color borderColor = Colors.transparent;
    double borderWidth = 0;

    if (widget.showValidationBorder) {
      if (widget.errorText != null) {
        borderColor = Colors.red;
        borderWidth = 2;
      } else if (widget.isValid && widget.controller.text.isNotEmpty) {
        borderColor = Colors.green;
        borderWidth = 2;
      } else {
        borderColor = primary.withValues(alpha: 0.3);
        borderWidth = 1;
      }
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor != Colors.transparent
                  ? borderColor
                  : _borderColorAnimation.value ?? Colors.transparent,
              width:
                  borderWidth > 0 ? borderWidth : _borderWidthAnimation.value,
            ),
            boxShadow: widget.focusNode?.hasFocus ?? false
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            focusNode: widget.focusNode,
            obscureText: widget.obscureText,
            validator: widget.validator,
            onFieldSubmitted: (value) {
              if (widget.nextFocusNode != null) {
                FocusScope.of(context).requestFocus(widget.nextFocusNode);
              }
            },
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: onSurface,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: onSurface.withValues(alpha: 0.45),
                fontWeight: FontWeight.w400,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              errorText: widget.errorText,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: widget.showValidationBorder &&
                      widget.controller.text.isNotEmpty
                  ? Icon(
                      widget.errorText != null
                          ? Icons.error_outline
                          : widget.isValid
                              ? Icons.check_circle
                              : null,
                      color: widget.errorText != null
                          ? Colors.red
                          : widget.isValid
                              ? Colors.green
                              : null,
                      size: 20,
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}

/// Custom category selection grid
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final String? selectedCategory;
  final Function(String?) onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive grid columns
    int crossAxisCount = 3;
    if (screenWidth < 360) {
      crossAxisCount = 2; // Small phones
    } else if (screenWidth > 600) {
      crossAxisCount = 4; // Tablets and desktop
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: kCategoriesWithIcons.length,
      itemBuilder: (context, index) {
        final category = kCategoriesWithIcons[index];
        final isSelected = selectedCategory == category['name'];

        return _CategoryCard(
          category: category['name'] as String,
          icon: category['icon'] as IconData,
          isSelected: isSelected,
          onTap: () => onCategoryChanged(category['name'] as String),
        );
      },
    );
  }
}

/// Animated category card
class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.category,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String category;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(_CategoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isSelected ? primary : surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected
                      ? primary
                      : primary.withValues(alpha: 0.2),
                  width: widget.isSelected ? 2.0 : 1.0,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 32,
                    color: widget.isSelected ? Colors.white : primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.category,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Service categories for provider registration (legacy support)
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

/// Common Pakistani cities and areas for autocomplete
const List<Location> kLocations = [
  // Karachi
  Location(city: 'Karachi', area: 'DHA', fullAddress: 'Karachi, DHA'),
  Location(city: 'Karachi', area: 'Clifton', fullAddress: 'Karachi, Clifton'),
  Location(
      city: 'Karachi',
      area: 'Gulshan-e-Iqbal',
      fullAddress: 'Karachi, Gulshan-e-Iqbal'),
  Location(
      city: 'Karachi',
      area: 'North Nazimabad',
      fullAddress: 'Karachi, North Nazimabad'),
  Location(
      city: 'Karachi',
      area: 'Bahadurabad',
      fullAddress: 'Karachi, Bahadurabad'),
  Location(city: 'Karachi', area: 'PECHS', fullAddress: 'Karachi, PECHS'),
  Location(
      city: 'Karachi', area: 'Tariq Road', fullAddress: 'Karachi, Tariq Road'),

  // Lahore
  Location(city: 'Lahore', area: 'DHA', fullAddress: 'Lahore, DHA'),
  Location(city: 'Lahore', area: 'Gulberg', fullAddress: 'Lahore, Gulberg'),
  Location(
      city: 'Lahore', area: 'Model Town', fullAddress: 'Lahore, Model Town'),
  Location(
      city: 'Lahore', area: 'Johar Town', fullAddress: 'Lahore, Johar Town'),
  Location(
      city: 'Lahore', area: 'Cantonment', fullAddress: 'Lahore, Cantonment'),
  Location(
      city: 'Lahore',
      area: 'Allama Iqbal Town',
      fullAddress: 'Lahore, Allama Iqbal Town'),

  // Islamabad
  Location(city: 'Islamabad', area: 'F-6', fullAddress: 'Islamabad, F-6'),
  Location(city: 'Islamabad', area: 'F-7', fullAddress: 'Islamabad, F-7'),
  Location(city: 'Islamabad', area: 'F-8', fullAddress: 'Islamabad, F-8'),
  Location(city: 'Islamabad', area: 'F-10', fullAddress: 'Islamabad, F-10'),
  Location(city: 'Islamabad', area: 'G-6', fullAddress: 'Islamabad, G-6'),
  Location(city: 'Islamabad', area: 'G-9', fullAddress: 'Islamabad, G-9'),
  Location(city: 'Islamabad', area: 'E-11', fullAddress: 'Islamabad, E-11'),

  // Rawalpindi
  Location(
      city: 'Rawalpindi', area: 'Saddar', fullAddress: 'Rawalpindi, Saddar'),
  Location(
      city: 'Rawalpindi',
      area: 'Cantonment',
      fullAddress: 'Rawalpindi, Cantonment'),
  Location(
      city: 'Rawalpindi',
      area: 'Bahria Town',
      fullAddress: 'Rawalpindi, Bahria Town'),
  Location(
      city: 'Rawalpindi',
      area: 'Westridge',
      fullAddress: 'Rawalpindi, Westridge'),

  // Faisalabad
  Location(
      city: 'Faisalabad', area: 'Gulberg', fullAddress: 'Faisalabad, Gulberg'),
  Location(
      city: 'Faisalabad',
      area: 'Madina Town',
      fullAddress: 'Faisalabad, Madina Town'),
  Location(
      city: 'Faisalabad',
      area: 'People\'s Colony',
      fullAddress: 'Faisalabad, People\'s Colony'),

  // Multan
  Location(
      city: 'Multan', area: 'Cantonment', fullAddress: 'Multan, Cantonment'),
  Location(
      city: 'Multan',
      area: 'Gulshan-e-Iqbal',
      fullAddress: 'Multan, Gulshan-e-Iqbal'),
  Location(
      city: 'Multan',
      area: 'Shah Rukn-e-Alam',
      fullAddress: 'Multan, Shah Rukn-e-Alam'),

  // Peshawar
  Location(
      city: 'Peshawar',
      area: 'Cantonment',
      fullAddress: 'Peshawar, Cantonment'),
  Location(
      city: 'Peshawar',
      area: 'University Town',
      fullAddress: 'Peshawar, University Town'),
  Location(
      city: 'Peshawar', area: 'Hayatabad', fullAddress: 'Peshawar, Hayatabad'),

  // Quetta
  Location(
      city: 'Quetta', area: 'Cantonment', fullAddress: 'Quetta, Cantonment'),
  Location(
      city: 'Quetta',
      area: 'Brewery Road',
      fullAddress: 'Quetta, Brewery Road'),
  Location(
      city: 'Quetta', area: 'Jinnah Road', fullAddress: 'Quetta, Jinnah Road'),
];

/// Common working hour presets
class WorkingHoursPreset {
  final String label;
  final TimeOfDay fromTime;
  final TimeOfDay toTime;
  final String description;

  const WorkingHoursPreset({
    required this.label,
    required this.fromTime,
    required this.toTime,
    required this.description,
  });
}

const List<WorkingHoursPreset> kWorkingHoursPresets = [
  WorkingHoursPreset(
    label: '9 AM - 5 PM',
    fromTime: TimeOfDay(hour: 9, minute: 0),
    toTime: TimeOfDay(hour: 17, minute: 0),
    description: 'Standard business hours',
  ),
  WorkingHoursPreset(
    label: '8 AM - 4 PM',
    fromTime: TimeOfDay(hour: 8, minute: 0),
    toTime: TimeOfDay(hour: 16, minute: 0),
    description: 'Early shift',
  ),
  WorkingHoursPreset(
    label: '10 AM - 6 PM',
    fromTime: TimeOfDay(hour: 10, minute: 0),
    toTime: TimeOfDay(hour: 18, minute: 0),
    description: 'Late shift',
  ),
  WorkingHoursPreset(
    label: 'Flexible',
    fromTime: TimeOfDay(hour: 6, minute: 0),
    toTime: TimeOfDay(hour: 22, minute: 0),
    description: 'Available most of the day',
  ),
  WorkingHoursPreset(
    label: 'Weekends Only',
    fromTime: TimeOfDay(hour: 10, minute: 0),
    toTime: TimeOfDay(hour: 18, minute: 0),
    description: 'Saturday and Sunday',
  ),
  WorkingHoursPreset(
    label: 'Evenings Only',
    fromTime: TimeOfDay(hour: 17, minute: 0),
    toTime: TimeOfDay(hour: 21, minute: 0),
    description: 'After work hours',
  ),
];

/// Responsive design breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
}

/// Responsive spacing utilities
class ResponsiveSpacing {
  static double getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 16; // Small phones
    if (width < 600) return 20; // Large phones
    if (width < 900) return 24; // Tablets
    return 32; // Desktop
  }

  static double getContentWidth(double screenWidth) {
    if (screenWidth < 600) {
      return screenWidth - 32; // Mobile: full width minus padding
    } else if (screenWidth < 900) {
      return 600; // Tablet: max 600px
    } else if (screenWidth < 1200) {
      return 800; // Small desktop: max 800px
    } else {
      return 1000; // Large desktop: max 1000px
    }
  }

  static double getButtonHeight(double screenWidth) {
    if (screenWidth < 360) return 44; // Small phones
    if (screenWidth < 600) return 48; // Large phones
    return 56; // Tablet and desktop
  }

  static double getFontSize(double screenWidth, double mobileSize,
      double tabletSize, double desktopSize) {
    if (screenWidth < 600) return mobileSize;
    if (screenWidth < 900) return tabletSize;
    return desktopSize;
  }
}

/// Service provider registration screen.
class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({super.key});

  @override
  State<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _yearsController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();

  // Focus nodes for keyboard navigation
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _yearsFocusNode = FocusNode();
  final _cityFocusNode = FocusNode();
  final _areaFocusNode = FocusNode();

  String? _selectedCategory;
  TimeOfDay _fromTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 17, minute: 0);

  // Step tracking for progressive disclosure
  int _currentStep = 1;
  static const int _totalSteps = 4;

  // Form step keys for validation
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();
  final _step4Key = GlobalKey<FormState>();

  // Real-time validation state
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _experienceError;
  String? _cityError;
  String? _areaError;

  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPhoneValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _isExperienceValid = false;
  bool _isCityValid = false;
  bool _isAreaValid = false;

  // Save provider registration data securely
  Future<void> _saveProviderData() async {
    try {
      // Use secure storage instead of SharedPreferences
      const storage = FlutterSecureStorage();

      // Hash the password securely
      final hashedPassword =
          BCrypt.hashpw(_passwordController.text, BCrypt.gensalt());

      // Extract city from full address for proper data storage
      String cityName = _cityController.text.trim();
      String areaName = _areaController.text.trim();

      // Try to extract city name from full address if it contains comma
      if (cityName.contains(',')) {
        cityName = cityName.split(',').first.trim();
      }

      // Create provider data map (without plain text password)
      final providerData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'category': _selectedCategory,
        'experience': _yearsController.text.trim(),
        'city': cityName,
        'area': areaName,
        'fullAddress':
            _cityController.text.trim(), // Store full address for display
        'fromTime': '${_fromTime.hour}:${_fromTime.minute}',
        'toTime': '${_toTime.hour}:${_toTime.minute}',
        'registeredAt': DateTime.now().toIso8601String(),
        'isVerified': false,
        'serviceRates': {}, // Initialize empty service rates
      };

      // Save hashed password separately in secure storage
      await storage.write(
        key: 'provider_password_${_phoneController.text.trim()}',
        value: hashedPassword,
      );

      // Save provider data in regular storage (without password)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'provider_data_${_phoneController.text.trim()}',
        jsonEncode(providerData),
      );

      debugPrint(
          'Provider data saved securely for category: $_selectedCategory');
    } catch (e) {
      debugPrint('Error saving provider data: $e');
      // In a real app, you'd want to show this error to the user
      rethrow; // Re-throw to handle in UI
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _yearsController.dispose();
    _cityController.dispose();
    _areaController.dispose();

    // Dispose focus nodes
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _yearsFocusNode.dispose();
    _cityFocusNode.dispose();
    _areaFocusNode.dispose();

    super.dispose();
  }

  // Enhanced validation methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Enter valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (!RegExp(r'^03[0-9]{2}[0-9]{7}$').hasMatch(value.trim())) {
      return 'Enter valid Pakistani phone number (03XX XXXXXXX)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Include uppercase letter';
    if (!value.contains(RegExp(r'[a-z]'))) return 'Include lowercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Include number';
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Include special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  String? _validateExperience(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final years = int.tryParse(value.trim());
    if (years == null) return 'Enter valid number';
    if (years < 0) return 'Experience cannot be negative';
    if (years > 50) return 'Please enter reasonable years of experience';
    return null;
  }

  // Real-time validation methods
  void _validateNameRealtime(String value) {
    setState(() {
      _nameError = _validateName(value);
      _isNameValid = _nameError == null && value.trim().isNotEmpty;
    });
  }

  void _validateEmailRealtime(String value) {
    setState(() {
      _emailError = _validateEmail(value);
      _isEmailValid = _emailError == null && value.trim().isNotEmpty;
    });
  }

  void _validatePhoneRealtime(String value) {
    setState(() {
      _phoneError = _validatePhone(value);
      _isPhoneValid = _phoneError == null && value.trim().isNotEmpty;
    });
  }

  void _validatePasswordRealtime(String value) {
    setState(() {
      _passwordError = _validatePassword(value);
      _isPasswordValid = _passwordError == null && value.trim().isNotEmpty;
      // Re-validate confirm password when password changes
      if (_confirmPasswordController.text.isNotEmpty) {
        _confirmPasswordError =
            _validateConfirmPassword(_confirmPasswordController.text);
        _isConfirmPasswordValid = _confirmPasswordError == null;
      }
    });
  }

  void _validateConfirmPasswordRealtime(String value) {
    setState(() {
      _confirmPasswordError = _validateConfirmPassword(value);
      _isConfirmPasswordValid =
          _confirmPasswordError == null && value.trim().isNotEmpty;
    });
  }

  void _validateExperienceRealtime(String value) {
    setState(() {
      _experienceError = _validateExperience(value);
      _isExperienceValid = _experienceError == null && value.trim().isNotEmpty;
    });
  }

  void _validateCityRealtime(String value) {
    setState(() {
      _cityError = value.trim().isEmpty ? 'Required' : null;
      _isCityValid = _cityError == null && value.trim().isNotEmpty;
    });
  }

  void _validateAreaRealtime(String value) {
    setState(() {
      _areaError = value.trim().isEmpty ? 'Required' : null;
      _isAreaValid = _areaError == null && value.trim().isNotEmpty;
    });
  }

  // Smart defaults and autocomplete methods
  List<Location> _getLocationSuggestions(String query) {
    if (query.isEmpty) return kLocations.take(5).toList();

    final lowerQuery = query.toLowerCase();
    return kLocations
        .where((location) {
          return location.city.toLowerCase().contains(lowerQuery) ||
              location.area.toLowerCase().contains(lowerQuery) ||
              location.fullAddress.toLowerCase().contains(lowerQuery);
        })
        .take(10)
        .toList();
  }

  void _onLocationSelected(Location location) {
    setState(() {
      _cityController.text = location.fullAddress;
      _areaController.text = location.area;
      _validateCityRealtime(location.city);
      _validateAreaRealtime(location.area);
    });
  }

  void _setWorkingHoursPreset(WorkingHoursPreset preset) {
    setState(() {
      _fromTime = preset.fromTime;
      _toTime = preset.toTime;
    });
  }

  @override
  void initState() {
    super.initState();
    // Set up real-time validation listeners
    _nameController
        .addListener(() => _validateNameRealtime(_nameController.text));
    _emailController
        .addListener(() => _validateEmailRealtime(_emailController.text));
    _phoneController
        .addListener(() => _validatePhoneRealtime(_phoneController.text));
    _passwordController
        .addListener(() => _validatePasswordRealtime(_passwordController.text));
    _confirmPasswordController.addListener(() =>
        _validateConfirmPasswordRealtime(_confirmPasswordController.text));
    _yearsController
        .addListener(() => _validateExperienceRealtime(_yearsController.text));
    _cityController
        .addListener(() => _validateCityRealtime(_cityController.text));
    _areaController
        .addListener(() => _validateAreaRealtime(_areaController.text));
  }

  // Step navigation methods
  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _canGoNext() {
    switch (_currentStep) {
      case 1:
        return _step1Key.currentState?.validate() ?? false;
      case 2:
        return _step2Key.currentState?.validate() ?? false;
      case 3:
        return _step3Key.currentState?.validate() ?? false;
      case 4:
        return _step4Key.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  Future<void> _submitForm() async {
    if (_canGoNext()) {
      try {
        await _saveProviderData();
        // Navigate to phone verification first
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VendorVerifyPhoneScreen(
                phoneNumber: _phoneController.text.trim(),
                verificationType: VerificationType.provider,
              ),
            ),
          );
        }
      } catch (e) {
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final responsivePadding = ResponsiveSpacing.getPadding(context);
    final buttonHeight = ResponsiveSpacing.getButtonHeight(screenWidth);

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(responsivePadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    (screenHeight - kToolbarHeight - responsivePadding * 2) -
                        4.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveSpacing.getContentWidth(screenWidth),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      // Responsive Headline
                      Text(
                        'Service Provider Account',
                        style: GoogleFonts.poppins(
                          fontSize: ResponsiveSpacing.getFontSize(
                              screenWidth, 24, 28, 32),
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Responsive Sub-headline
                      Text(
                        'Join as a skilled professional',
                        style: GoogleFonts.poppins(
                          fontSize: ResponsiveSpacing.getFontSize(
                              screenWidth, 14, 15, 16),
                          fontWeight: FontWeight.w500,
                          color: muted,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                          height: ResponsiveSpacing.getFontSize(
                              screenWidth, 24, 28, 32)),

                      // Responsive Progress Indicator
                      _ProgressIndicator(
                        currentStep: _currentStep,
                        totalSteps: _totalSteps,
                      ),
                      SizedBox(
                          height: ResponsiveSpacing.getFontSize(
                              screenWidth, 24, 28, 32)),

                      // Step Content
                      _buildCurrentStep(),

                      SizedBox(
                          height: ResponsiveSpacing.getFontSize(
                              screenWidth, 24, 28, 32)),

                      // Responsive Navigation Buttons
                      _buildNavigationButtons(primary, buttonHeight),

                      // Keyboard avoidance padding
                      SizedBox(
                        height: MediaQuery.of(context).viewInsets.bottom > 0
                            ? MediaQuery.of(context).viewInsets.bottom + 20
                            : 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _Step1PersonalInfo(
          nameController: _nameController,
          emailController: _emailController,
          phoneController: _phoneController,
          validateName: _validateName,
          validateEmail: _validateEmail,
          validatePhone: _validatePhone,
          formKey: _step1Key,
          nameError: _nameError,
          emailError: _emailError,
          phoneError: _phoneError,
          isNameValid: _isNameValid,
          isEmailValid: _isEmailValid,
          isPhoneValid: _isPhoneValid,
          nameFocusNode: _nameFocusNode,
          emailFocusNode: _emailFocusNode,
          phoneFocusNode: _phoneFocusNode,
        );
      case 2:
        return _Step2ProfessionalInfo(
          selectedCategory: _selectedCategory,
          yearsController: _yearsController,
          onCategoryChanged: (value) =>
              setState(() => _selectedCategory = value),
          validateExperience: _validateExperience,
          formKey: _step2Key,
          experienceError: _experienceError,
          isExperienceValid: _isExperienceValid,
          yearsFocusNode: _yearsFocusNode,
        );
      case 3:
        return _Step3Availability(
          cityController: _cityController,
          areaController: _areaController,
          fromTime: _fromTime,
          toTime: _toTime,
          onPickTime: _pickTime,
          formKey: _step3Key,
          cityError: _cityError,
          areaError: _areaError,
          isCityValid: _isCityValid,
          isAreaValid: _isAreaValid,
          onLocationSelected: _onLocationSelected,
          setWorkingHoursPreset: _setWorkingHoursPreset,
          getLocationSuggestions: _getLocationSuggestions,
        );
      case 4:
        return _Step4Password(
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          validatePassword: _validatePassword,
          validateConfirmPassword: _validateConfirmPassword,
          formKey: _step4Key,
          passwordError: _passwordError,
          confirmPasswordError: _confirmPasswordError,
          isPasswordValid: _isPasswordValid,
          isConfirmPasswordValid: _isConfirmPasswordValid,
          passwordFocusNode: _passwordFocusNode,
          confirmPasswordFocusNode: _confirmPasswordFocusNode,
        );
      default:
        return Container();
    }
  }

  Widget _buildNavigationButtons(Color primary, double buttonHeight) {
    return Row(
      children: [
        // Previous Button
        if (_currentStep > 1)
          Expanded(
            child: Container(
              height: buttonHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: primary,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveSpacing.getFontSize(
                        MediaQuery.of(context).size.width, 14, 15, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        if (_currentStep > 1) const SizedBox(width: 16),
        // Next/Submit Button
        Expanded(
          child: Container(
            height: buttonHeight,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _canGoNext()
                  ? (_currentStep < _totalSteps ? _nextStep : _submitForm)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep < _totalSteps ? 'Next Step' : 'Register Now',
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveSpacing.getFontSize(
                      MediaQuery.of(context).size.width, 14, 15, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
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

/// Input with leading icon (Briefcase for Years of Experience).
class _ProviderInputWithIcon extends StatelessWidget {
  const _ProviderInputWithIcon({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    this.validator,
    this.errorText,
    this.isValid = false,
    this.showValidationBorder = false,
    this.textInputAction,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool isValid;
  final bool showValidationBorder;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  static const double _height = 48;
  static const double _radius = 12;
  static const double _iconLeft = 16;
  static const double _paddingLeft = 44;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    // Determine border color based on validation state
    Color borderColor = Colors.transparent;
    double borderWidth = 0;

    if (showValidationBorder) {
      if (errorText != null) {
        borderColor = Colors.red;
        borderWidth = 2;
      } else if (isValid && controller.text.isNotEmpty) {
        borderColor = Colors.green;
        borderWidth = 2;
      } else {
        borderColor = primary.withValues(alpha: 0.3);
        borderWidth = 1;
      }
    }

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
            textInputAction: textInputAction,
            focusNode: focusNode,
            validator: validator,
            onFieldSubmitted: (value) {
              // For icon inputs, typically no next field navigation needed
              // Keyboard will hide automatically with TextInputAction.done
            },
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
                borderSide: BorderSide(color: borderColor, width: borderWidth),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: BorderSide(color: borderColor, width: borderWidth),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: BorderSide(
                  color: primary.withValues(alpha: 0.5),
                  width: showValidationBorder ? borderWidth : 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_radius),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              errorText: errorText,
              contentPadding: const EdgeInsets.only(
                  left: _paddingLeft, right: 16, top: 14, bottom: 14),
              // Add validation indicator icon
              suffixIcon: showValidationBorder && controller.text.isNotEmpty
                  ? Icon(
                      errorText != null
                          ? Icons.error_outline
                          : isValid
                              ? Icons.check_circle
                              : null,
                      color: errorText != null
                          ? Colors.red
                          : isValid
                              ? Colors.green
                              : null,
                      size: 20,
                    )
                  : null,
            ),
          ),
        ],
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

/// Progress indicator widget for form steps
class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    final screenWidth = MediaQuery.of(context).size.width;

    final circleSize = ResponsiveSpacing.getFontSize(screenWidth, 28, 32, 36);
    final iconSize = ResponsiveSpacing.getFontSize(screenWidth, 14, 16, 18);
    final fontSize = ResponsiveSpacing.getFontSize(screenWidth, 12, 14, 16);
    final connectorHeight = ResponsiveSpacing.getFontSize(screenWidth, 2, 2, 3);

    return Row(
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final isActive = currentStep >= stepNumber;
        final isCompleted = currentStep > stepNumber;

        return Expanded(
          child: Row(
            children: [
              // Step circle
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  color: isActive ? primary : muted.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: isActive && !isCompleted
                      ? Border.all(color: primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          size: iconSize,
                          color: Colors.white,
                        )
                      : Text(
                          '$stepNumber',
                          style: GoogleFonts.poppins(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : muted,
                          ),
                        ),
                ),
              ),
              // Connector line (except for last step)
              if (index < totalSteps - 1)
                Expanded(
                  child: Container(
                    height: connectorHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isActive ? primary : muted.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

/// Time picker button widget
class _TimePickerButton extends StatelessWidget {
  const _TimePickerButton({
    required this.time,
    required this.onTap,
    required this.label,
  });

  final TimeOfDay time;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: primary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Text(
                  time.format(context),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: primary.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Step 1: Personal Information
class _Step1PersonalInfo extends StatelessWidget {
  const _Step1PersonalInfo({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.validateName,
    required this.validateEmail,
    required this.validatePhone,
    required this.formKey,
    required this.nameError,
    required this.emailError,
    required this.phoneError,
    required this.isNameValid,
    required this.isEmailValid,
    required this.isPhoneValid,
    required this.nameFocusNode,
    required this.emailFocusNode,
    required this.phoneFocusNode,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final String? Function(String?) validateName;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePhone;
  final GlobalKey<FormState> formKey;
  final String? nameError;
  final String? emailError;
  final String? phoneError;
  final bool isNameValid;
  final bool isEmailValid;
  final bool isPhoneValid;
  final FocusNode nameFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode phoneFocusNode;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          // Full Name
          const _FieldLabel(text: 'FULL NAME'),
          const SizedBox(height: 8),
          _AnimatedTextField(
            controller: nameController,
            hint: 'Enter your full name',
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            focusNode: nameFocusNode,
            nextFocusNode: emailFocusNode,
            validator: validateName,
            errorText: nameError,
            isValid: isNameValid,
            showValidationBorder: true,
          ),
          const SizedBox(height: 16),
          // Email
          const _FieldLabel(text: 'EMAIL'),
          const SizedBox(height: 8),
          _AnimatedTextField(
            controller: emailController,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            focusNode: emailFocusNode,
            nextFocusNode: phoneFocusNode,
            validator: validateEmail,
            errorText: emailError,
            isValid: isEmailValid,
            showValidationBorder: true,
          ),
          const SizedBox(height: 16),
          // Phone
          const _FieldLabel(text: 'PHONE'),
          const SizedBox(height: 8),
          _AnimatedTextField(
            controller: phoneController,
            hint: '03XX XXXXXXX',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            focusNode: phoneFocusNode,
            validator: validatePhone,
            errorText: phoneError,
            isValid: isPhoneValid,
            showValidationBorder: true,
          ),
        ],
      ),
    );
  }
}

/// Step 2: Professional Information
class _Step2ProfessionalInfo extends StatelessWidget {
  const _Step2ProfessionalInfo({
    required this.selectedCategory,
    required this.yearsController,
    required this.onCategoryChanged,
    required this.validateExperience,
    required this.formKey,
    required this.experienceError,
    required this.isExperienceValid,
    required this.yearsFocusNode,
  });

  final String? selectedCategory;
  final TextEditingController yearsController;
  final Function(String?) onCategoryChanged;
  final String? Function(String?) validateExperience;
  final GlobalKey<FormState> formKey;
  final String? experienceError;
  final bool isExperienceValid;
  final FocusNode yearsFocusNode;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          // Service Category
          const _FieldLabel(text: 'SERVICE CATEGORY'),
          const SizedBox(height: 8),
          _CategoryGrid(
            selectedCategory: selectedCategory,
            onCategoryChanged: onCategoryChanged,
          ),
          const SizedBox(height: 24),
          // Years of Experience
          const _FieldLabel(text: 'YEARS OF EXPERIENCE'),
          const SizedBox(height: 8),
          _ProviderInputWithIcon(
            controller: yearsController,
            hint: 'e.g. 5',
            icon: Icons.business_center_rounded,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            focusNode: yearsFocusNode,
            validator: validateExperience,
            errorText: experienceError,
            isValid: isExperienceValid,
            showValidationBorder: true,
          ),
        ],
      ),
    );
  }
}

/// Step 3: Availability
class _Step3Availability extends StatelessWidget {
  const _Step3Availability({
    required this.cityController,
    required this.areaController,
    required this.fromTime,
    required this.toTime,
    required this.onPickTime,
    required this.formKey,
    required this.cityError,
    required this.areaError,
    required this.isCityValid,
    required this.isAreaValid,
    required this.onLocationSelected,
    required this.setWorkingHoursPreset,
    required this.getLocationSuggestions,
  });

  final TextEditingController cityController;
  final TextEditingController areaController;
  final TimeOfDay fromTime;
  final TimeOfDay toTime;
  final Function(BuildContext, bool) onPickTime;
  final GlobalKey<FormState> formKey;
  final String? cityError;
  final String? areaError;
  final bool isCityValid;
  final bool isAreaValid;
  final Function(Location) onLocationSelected;
  final Function(WorkingHoursPreset) setWorkingHoursPreset;
  final List<Location> Function(String) getLocationSuggestions;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          // Location Autocomplete
          const _FieldLabel(text: 'LOCATION'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: cityError != null
                    ? Colors.red
                    : isCityValid
                        ? Colors.green
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                width: cityError != null || isCityValid ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Autocomplete<Location>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                return getLocationSuggestions(textEditingValue.text);
              },
              onSelected: onLocationSelected,
              displayStringForOption: (Location option) => option.fullAddress,
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
                return TextFormField(
                  controller: cityController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search city or area...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    suffixIcon: Icon(
                      Icons.location_on,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                );
              },
            ),
          ),
          if (cityError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                cityError!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Working Hours Presets
          const _FieldLabel(text: 'QUICK TIME SELECTION'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select common working hours:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: kWorkingHoursPresets.map((preset) {
                    final isSelected = fromTime.hour == preset.fromTime.hour &&
                        toTime.hour == preset.toTime.hour;
                    return _TimeChip(
                      label: preset.label,
                      isSelected: isSelected,
                      onTap: () => setWorkingHoursPreset(preset),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Custom Time Selection
          const _FieldLabel(text: 'CUSTOM WORKING HOURS'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimePickerButton(
                  time: fromTime,
                  onTap: () => onPickTime(context, true),
                  label: 'From',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TimePickerButton(
                  time: toTime,
                  onTap: () => onPickTime(context, false),
                  label: 'To',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Current: ${fromTime.format(context)} - ${toTime.format(context)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Time chip widget for quick selection
class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primary : primary.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : primary,
          ),
        ),
      ),
    );
  }
}

/// Step 4: Password
class _Step4Password extends StatelessWidget {
  const _Step4Password({
    required this.passwordController,
    required this.confirmPasswordController,
    required this.validatePassword,
    required this.validateConfirmPassword,
    required this.formKey,
    required this.passwordError,
    required this.confirmPasswordError,
    required this.isPasswordValid,
    required this.isConfirmPasswordValid,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateConfirmPassword;
  final GlobalKey<FormState> formKey;
  final String? passwordError;
  final String? confirmPasswordError;
  final bool isPasswordValid;
  final bool isConfirmPasswordValid;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          // Create New Password
          const _FieldLabel(text: 'CREATE NEW PASSWORD'),
          const SizedBox(height: 8),
          _AnimatedTextField(
            controller: passwordController,
            hint: 'Enter password',
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
            focusNode: passwordFocusNode,
            nextFocusNode: confirmPasswordFocusNode,
            obscureText: true,
            validator: validatePassword,
            errorText: passwordError,
            isValid: isPasswordValid,
            showValidationBorder: true,
          ),
          const SizedBox(height: 16),
          // Confirm Password
          const _FieldLabel(text: 'CONFIRM PASSWORD'),
          const SizedBox(height: 8),
          _AnimatedTextField(
            controller: confirmPasswordController,
            hint: 'Confirm your password',
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            focusNode: confirmPasswordFocusNode,
            obscureText: true,
            validator: validateConfirmPassword,
            errorText: confirmPasswordError,
            isValid: isConfirmPasswordValid,
            showValidationBorder: true,
          ),
          const SizedBox(height: 16),
          // Password requirements
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Requirements:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  'At least 8 characters',
                  'One uppercase letter',
                  'One lowercase letter',
                  'One number',
                  'One special character',
                ].map((requirement) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            requirement,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
