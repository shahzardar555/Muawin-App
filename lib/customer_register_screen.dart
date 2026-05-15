import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'services/auth_service.dart';
import 'login_screen.dart';

/// Muawin Primary Teal
const Color _muawinPrimaryTeal = Color(0xFF047A62);

// Material 3 Design System Constants
const double _kMaxContentWidth = 448;

// 8px Grid Spacing System
const double _kSpacing2 = 8.0; // 2x grid
const double _kSpacing4 = 16.0; // 4x grid
const double _kSpacing6 = 24.0; // 6x grid
const double _kSpacing8 = 32.0; // 8x grid
const double _kSpacing12 = 48.0; // 12x grid

// Elevation System (Material 3)
const double _kElevationLevel1 = 1.0;
const double _kElevationLevel2 = 3.0;
const double _kElevationLevel3 = 6.0;

// Border Radius (Material 3)
const double _kRadiusMedium = 12.0;
const double _kRadiusLarge = 16.0;

// Screen Padding
const double _kScreenPadding = _kSpacing6;

// Touch Target Sizes (Material Design Guidelines)
const double _kMinTouchTarget = 48.0;
const double _kComfortableTouchTarget = 56.0;

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus nodes for smart field ordering
  FocusNode? _nameFocusNode;
  FocusNode? _emailFocusNode;
  FocusNode? _phoneFocusNode;
  FocusNode? _locationFocusNode;
  FocusNode? _passwordFocusNode;
  FocusNode? _confirmPasswordFocusNode;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _passwordStrength = '';
  bool _showAdvancedFields = false;

  // Progress indicator state
  int _currentStep = 1;
  final int _totalSteps = 3;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Focus scope node to prevent circular reference
  final _focusScopeNode = FocusScopeNode();

  // Flag to prevent initial focus from being set repeatedly
  bool _initialFocusSet = false;

  // Flag to prevent FocusNode usage after disposal
  bool _isDisposed = false;

  // Store listener functions to remove them properly
  VoidCallback? _nameListener;
  VoidCallback? _emailListener;
  VoidCallback? _phoneListener;
  VoidCallback? _locationListener;
  VoidCallback? _passwordListener;
  VoidCallback? _confirmPasswordListener;

  // Validation states for real-time feedback
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPhoneValid = false;
  bool _isLocationValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;

  // Calculate password strength
  String _calculatePasswordStrength(String password) {
    if (password.isEmpty) return '';

    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) strength++; // lowercase
    if (password.contains(RegExp(r'[A-Z]'))) strength++; // uppercase
    if (password.contains(RegExp(r'[0-9]'))) strength++; // numbers
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength++; // special chars
    }

    if (strength <= 2) return 'Weak';
    if (strength <= 4) return 'Medium';
    return 'Strong';
  }

  Color _getPasswordStrengthColor(String strength) {
    switch (strength) {
      case 'Weak':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize FocusNodes
    _nameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _locationFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _confirmPasswordFocusNode = FocusNode();

    // Initialize progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Start progress animation
    _progressController.forward();

    // Add listeners for real-time validation and progress tracking
    _nameListener = () {
      _validateName();
      _updateProgress();
    };
    _emailListener = () {
      _validateEmail();
      _updateProgress();
    };
    _phoneListener = () {
      _validatePhone();
      _updateProgress();
    };
    _locationListener = () {
      _validateLocation();
      _updateProgress();
    };
    _passwordListener = () {
      setState(() {
        _passwordStrength = _calculatePasswordStrength(
          _passwordController.text,
        );
      });
      _validatePassword();
      _updateProgress();
    };
    _confirmPasswordListener = () {
      _validateConfirmPassword();
      _updateProgress();
    };

    _nameController.addListener(_nameListener!);
    _emailController.addListener(_emailListener!);
    _phoneController.addListener(_phoneListener!);
    _locationController.addListener(_locationListener!);
    _passwordController.addListener(_passwordListener!);
    _confirmPasswordController.addListener(_confirmPasswordListener!);
  }

  // Real-time validation methods
  void _validateName() {
    if (_isDisposed) return;

    final name = _nameController.text.trim();
    setState(() {
      _isNameValid = name.isNotEmpty && name.length >= 2;
    });
  }

  void _validateEmail() {
    // Don't validate if widget is disposed
    if (_isDisposed) return;

    final email = _emailController.text.trim();
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
    final wasValid = _isEmailValid;
    final isValid = email.isNotEmpty && regex.hasMatch(email);

    // Only update state if validation status actually changes
    // This prevents unnecessary rebuilds during typing
    if (wasValid != isValid) {
      // Check if email field currently has focus to preserve it
      final emailHasFocus = !_isDisposed && _emailFocusNode?.hasFocus == true;

      setState(() {
        _isEmailValid = isValid;
      });

      // If email field had focus, restore it after setState
      if (emailHasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              !_isDisposed &&
              _emailFocusNode?.canRequestFocus == true) {
            _emailFocusNode?.requestFocus();
          }
        });
      }
    }
  }

  void _validatePhone() {
    if (_isDisposed) return;

    final phone = _phoneController.text.trim();
    // Phone is now mandatory - must have at least 10 digits
    final digitCount = phone.replaceAll(RegExp(r'\D'), '').length;
    final wasValid = _isPhoneValid;
    final isValid = digitCount >= 10;

    if (wasValid != isValid) {
      setState(() {
        _isPhoneValid = isValid;
      });
    }
  }

  void _validateLocation() {
    if (_isDisposed) return;

    final location = _locationController.text.trim();
    final wasValid = _isLocationValid;
    final isValid = location.isNotEmpty && location.length >= 2;

    if (wasValid != isValid) {
      setState(() {
        _isLocationValid = isValid;
      });
    }
  }

  void _validatePassword() {
    if (_isDisposed) return;

    final password = _passwordController.text.trim();
    final wasValid = _isPasswordValid;
    final isValid = password.isNotEmpty && password.length >= 8;

    if (wasValid != isValid) {
      setState(() {
        _isPasswordValid = isValid;
      });
    }
  }

  void _validateConfirmPassword() {
    if (_isDisposed) return;

    final confirmPassword = _confirmPasswordController.text.trim();
    final wasValid = _isConfirmPasswordValid;
    final isValid = confirmPassword.isNotEmpty &&
        confirmPassword == _passwordController.text;

    if (wasValid != isValid) {
      setState(() {
        _isConfirmPasswordValid = isValid;
      });
    }
  }

  // Step validation methods
  bool _isStep1Valid() {
    return _isNameValid && _isEmailValid && _isPhoneValid;
  }

  bool _isStep2Valid() {
    // Step 2 is always valid since phone and location are optional
    return true;
  }

  bool _isStep3Valid() {
    return _isPasswordValid && _isConfirmPasswordValid;
  }

  // Get form fields for current step
  List<Widget> _getStepFields() {
    switch (_currentStep) {
      case 1:
        return [
          _FloatingLabelInput(
            controller: _nameController,
            label: 'FULL NAME',
            hint: 'Enter your full name',
            keyboardType: TextInputType.name,
            inputFormatters: [_SmartCapitalizationTextInputFormatter()],
            focusNode: _nameFocusNode,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
            textCapitalization: TextCapitalization.words,
            autofillHint: AutofillHints.name,
            isValid: _isNameValid,
            showValidation: true,
            icon: Icons.person_outline,
            onFieldSubmitted: (value) =>
                _onFieldSubmitted(value, _nameFocusNode),
          ),
          const SizedBox(height: 16),
          _FloatingLabelInput(
            controller: _emailController,
            label: 'EMAIL',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'\s')), // Deny spaces
              FilteringTextInputFormatter.deny(
                RegExp(r'[!#$%^&*(),":{}|<>]'),
              ), // Deny special chars but allow dot
            ],
            focusNode: _emailFocusNode,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Required';
              }
              final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
              if (!regex.hasMatch(v.trim())) {
                return 'Enter valid email';
              }
              return null;
            },
            autofillHint: AutofillHints.email,
            isValid: _isEmailValid,
            showValidation: true,
            icon: Icons.email_outlined,
            onFieldSubmitted: (value) =>
                _onFieldSubmitted(value, _emailFocusNode),
          ),
          const SizedBox(height: 16),
          _FloatingLabelInput(
            controller: _phoneController,
            label: 'PHONE NUMBER',
            hint: '0300-1234567',
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            focusNode: _phoneFocusNode,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Required';
              }
              final digitCount = v.replaceAll(RegExp(r'\D'), '').length;
              if (digitCount < 10) {
                return 'Enter valid phone number';
              }
              return null;
            },
            autofillHint: AutofillHints.telephoneNumber,
            isValid: _isPhoneValid,
            showValidation: true,
            icon: Icons.phone_outlined,
            onFieldSubmitted: (value) =>
                _onFieldSubmitted(value, _phoneFocusNode),
          ),
        ];
      case 2:
        return [
          // Progressive Disclosure Toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _showAdvancedFields = !_showAdvancedFields;
              });
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Information',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add location (optional)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showAdvancedFields
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showAdvancedFields
                ? Column(
                    key: const ValueKey('advanced_fields'),
                    children: [
                      TextField(
                        controller: _locationController,
                        keyboardType: TextInputType.streetAddress,
                        focusNode: _locationFocusNode,
                        onChanged: (value) {
                          // Validate location on change
                          final wasValid = _isLocationValid;
                          final isValid = value.isEmpty || value.length >= 2;
                          if (wasValid != isValid) {
                            setState(() {
                              _isLocationValid = isValid;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          labelText: 'Location',
                          hintText: 'Enter your location',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          errorText: _locationController.text.isNotEmpty &&
                                  _locationController.text.length < 2
                              ? 'Enter valid location'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _FloatingLabelInput(
                        controller: _locationController,
                        label: 'LOCATION (Optional)',
                        hint: 'City or area',
                        keyboardType: TextInputType.text,
                        focusNode: _locationFocusNode,
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            if (v.trim().length < 2) {
                              return 'Minimum 2 characters';
                            }
                          }
                          return null;
                        },
                        autofillHint: AutofillHints.addressCity,
                        isValid: _isLocationValid,
                        showValidation: true,
                        icon: Icons.location_on_outlined,
                        onFieldSubmitted: (value) =>
                            _onFieldSubmitted(value, _locationFocusNode),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ];
      case 3:
        return [
          Row(
            children: [
              Expanded(
                child: _FloatingLabelInput(
                  controller: _passwordController,
                  label: 'CREATE NEW PASSWORD',
                  hint: '••••••••',
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: _obscurePassword,
                  focusNode: _passwordFocusNode,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Required';
                    }
                    if (v.trim().length < 8) {
                      return 'Minimum 8 characters';
                    }
                    return null;
                  },
                  autofillHint: AutofillHints.newPassword,
                  isValid: _isPasswordValid,
                  showValidation: true,
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _passwordStrength = _calculatePasswordStrength(value);
                    });
                  },
                ),
              ),
            ],
          ),
          if (_passwordStrength.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PasswordStrengthIndicator(
              strength: _passwordStrength,
              color: _getPasswordStrengthColor(_passwordStrength),
            ),
          ],
          const SizedBox(height: 16),
          _FloatingLabelInput(
            controller: _confirmPasswordController,
            label: 'CONFIRM NEW PASSWORD',
            hint: '••••••••',
            keyboardType: TextInputType.visiblePassword,
            obscureText: _obscureConfirmPassword,
            focusNode: _confirmPasswordFocusNode,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Required';
              }
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            autofillHint: AutofillHints.newPassword,
            isValid: _isConfirmPasswordValid,
            showValidation: true,
            icon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
          ),
        ];
      default:
        return [];
    }
  }

  // Helper methods for step-based UI
  Widget _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return Text(
          'Basic Information',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.2,
          ),
        );
      case 2:
        return Text(
          'Additional Information',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.2,
          ),
        );
      case 3:
        return Text(
          'Security',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            height: 1.2,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _getStepDescription() {
    switch (_currentStep) {
      case 1:
        return Text(
          'Let\'s start with your name, email and phone number',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        );
      case 2:
        return Text(
          'Add your location (optional)',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        );
      case 3:
        return Text(
          'Create a secure password for your account',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _getStepNavigationButtons() {
    switch (_currentStep) {
      case 1:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kRadiusMedium),
                  ),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _goToNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _muawinPrimaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kRadiusMedium),
                  ),
                  elevation: _kElevationLevel2,
                ),
                child: Text(
                  'Next',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      case 2:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kRadiusMedium),
                  ),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _goToNextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _muawinPrimaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kRadiusMedium),
                  ),
                  elevation: _kElevationLevel2,
                ),
                child: Text(
                  'Next',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goToPreviousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_kRadiusMedium),
                      ),
                    ),
                    child: Text(
                      'Back',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _LoadingSkeleton(
                    isLoading: _isLoading,
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        if (_formKey.currentState?.validate() ?? false) {
                          // Store context before async gap
                          final navigator = Navigator.of(context);
                          setState(() => _isLoading = true);

                          try {
                            // Sanitize email
                            String cleanEmail = _emailController.text
                                .trim()
                                .toLowerCase()
                                .replaceAll('[', '')
                                .replaceAll(']', '')
                                .replaceAll(' ', '');

                            // Validate email
                            if (!cleanEmail.contains('@') ||
                                !cleanEmail.contains('.')) {
                              throw Exception(
                                  'Please enter a valid email address');
                            }

                            final authService = AuthService();
                            await authService.signUp(
                              email: cleanEmail,
                              password: _passwordController.text.trim(),
                              fullName: _nameController.text.trim(),
                              phoneNumber: _phoneController.text.trim(),
                              role: 'customer',
                            );

                            if (!mounted) return;

                            // Show success message and navigate to login
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Registration successful! Please login.',
                                ),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 3),
                              ),
                            );

                            navigator.pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setState(() => _isLoading = false);

                            // Show readable error message
                            final errorMessage = _getReadableErrorMessage(
                              e.toString(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMessage),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _muawinPrimaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kRadiusMedium),
                        ),
                        elevation: _kElevationLevel2,
                      ),
                      child: Text(
                        'Register',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Progress tracking method
  void _updateProgress() {
    // Update current step based on manual navigation
    setState(() {
      _currentStep = _currentStep;
    });
  }

  // Smart field navigation and auto-advance
  void _advanceToNextField(FocusNode? currentFocus) {
    if (_isDisposed) return;

    final fieldOrder = [
      _nameFocusNode,
      _emailFocusNode,
      _phoneFocusNode,
      _locationFocusNode,
      _passwordFocusNode,
      _confirmPasswordFocusNode,
    ];

    if (currentFocus == null) return;

    final currentIndex = fieldOrder.indexOf(currentFocus);
    if (currentIndex == -1 || currentIndex >= fieldOrder.length - 1) return;

    final nextFocus = fieldOrder[currentIndex + 1];

    // Skip optional fields if advanced fields are not shown
    if (!_showAdvancedFields &&
        (nextFocus == _phoneFocusNode || nextFocus == _locationFocusNode)) {
      _advanceToNextField(nextFocus);
      return;
    }

    if (nextFocus != null) {
      nextFocus.requestFocus();
    }
  }

  void _onFieldSubmitted(String value, FocusNode? currentFocus) {
    // Auto-advance to next field on submission
    _advanceToNextField(currentFocus);
  }

  void _setInitialFocus() {
    // Set initial focus to name field when screen loads (only once)
    if (!_initialFocusSet && !_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_initialFocusSet &&
            !_isDisposed &&
            _nameFocusNode != null) {
          _nameFocusNode?.requestFocus();
          _initialFocusSet = true;
        }
      });
    }
  }

  // Step navigation methods
  void _goToNextStep() {
    if (_currentStep < _totalSteps) {
      // Validate current step before proceeding
      bool isCurrentStepValid = false;
      switch (_currentStep) {
        case 1:
          isCurrentStepValid = _isStep1Valid();
          break;
        case 2:
          isCurrentStepValid = _isStep2Valid();
          break;
        case 3:
          isCurrentStepValid = _isStep3Valid();
          break;
      }

      if (isCurrentStepValid) {
        // Enhanced haptic feedback for step navigation
        HapticFeedback.mediumImpact();

        setState(() {
          _currentStep++;
        });

        // Focus on first field of next step
        _focusOnFirstFieldOfCurrentStep();

        // Additional haptic feedback for successful navigation
        HapticFeedback.selectionClick();
      } else {
        // Show validation feedback
        HapticFeedback.heavyImpact();
        _focusOnFirstInvalidField();
      }
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 1) {
      // Enhanced haptic feedback for step navigation
      HapticFeedback.mediumImpact();

      setState(() {
        _currentStep--;
      });

      // Focus on first field of current step
      _focusOnFirstFieldOfCurrentStep();

      // Additional haptic feedback for successful navigation
      HapticFeedback.selectionClick();
    } else {
      // Can't navigate back further - provide feedback
      HapticFeedback.heavyImpact();
    }
  }

  void _focusOnFirstFieldOfCurrentStep() {
    if (_isDisposed) return;

    switch (_currentStep) {
      case 1:
        _nameFocusNode?.requestFocus();
        break;
      case 2:
        if (_showAdvancedFields) {
          _phoneFocusNode?.requestFocus();
        }
        break;
      case 3:
        _passwordFocusNode?.requestFocus();
        break;
    }
  }

  void _focusOnFirstInvalidField() {
    if (_isDisposed) return;

    switch (_currentStep) {
      case 1:
        if (!_isNameValid) {
          _nameFocusNode?.requestFocus();
        } else if (!_isEmailValid) {
          _emailFocusNode?.requestFocus();
        }
        break;
      case 3:
        if (!_isPasswordValid) {
          _passwordFocusNode?.requestFocus();
        } else if (!_isConfirmPasswordValid) {
          _confirmPasswordFocusNode?.requestFocus();
        }
        break;
    }
  }

  // Swipe navigation methods (for gesture support)
  void _navigateToNextStep() {
    _goToNextStep();
  }

  void _navigateToPreviousStep() {
    _goToPreviousStep();
  }

  String _getReadableErrorMessage(String error) {
    if (error.contains('User already registered')) {
      return 'An account with this email already exists';
    }
    if (error.contains('Invalid email')) {
      return 'Please enter a valid email address';
    }
    if (error.contains('Password')) {
      return 'Password must be at least 8 characters';
    }
    if (error.contains('weak')) {
      return 'Password is too weak';
    }
    return error;
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(_kRadiusLarge),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar with animation
              Container(
                margin: const EdgeInsets.only(top: _kSpacing2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: _kSpacing4),
              // Title with Material 3 styling
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _kScreenPadding,
                ),
                child: Text(
                  'Additional Options',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: _kSpacing2),
              // Divider
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _kScreenPadding,
                ),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: _kSpacing2),
              // Enhanced Options with Material 3 styling
              _BottomSheetOption(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get assistance with your account',
                color: _muawinPrimaryTeal,
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  _showComingSoonDialog('Help & Support');
                },
              ),
              _BottomSheetOption(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Learn how we protect your data',
                color: _muawinPrimaryTeal,
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  _showComingSoonDialog('Privacy Policy');
                },
              ),
              _BottomSheetOption(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                subtitle: 'Review our terms and conditions',
                color: _muawinPrimaryTeal,
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  _showComingSoonDialog('Terms of Service');
                },
              ),
              const SizedBox(height: _kSpacing2),
              // Divider before destructive action
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _kScreenPadding,
                ),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: _kSpacing2),
              // Clear Form with destructive styling
              _BottomSheetOption(
                icon: Icons.clear_all_outlined,
                title: 'Clear Form',
                subtitle: 'Reset all form fields',
                color: Colors.red,
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _showClearFormConfirmation();
                },
              ),
              const SizedBox(height: _kSpacing4),
              // Safe area padding for bottom navigation
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Coming Soon',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          '$feature feature will be available in the next update. We\'re working hard to bring you the best experience!',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _muawinPrimaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearFormConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Form',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to clear all form fields? This action cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _locationController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _currentStep = 1;
      _showAdvancedFields = false;
      _passwordStrength = '';
    });
    // Only request focus if not disposed
    if (!_isDisposed && _nameFocusNode != null) {
      _nameFocusNode?.requestFocus();
    }
  }

  @override
  void dispose() {
    // Set disposal flag first to prevent FocusNode usage
    _isDisposed = true;

    // Remove listeners first to prevent FocusNode usage after disposal
    if (_nameListener != null) {
      _nameController.removeListener(_nameListener!);
    }
    if (_emailListener != null) {
      _emailController.removeListener(_emailListener!);
    }
    if (_phoneListener != null) {
      _phoneController.removeListener(_phoneListener!);
    }
    if (_locationListener != null) {
      _locationController.removeListener(_locationListener!);
    }
    if (_passwordListener != null) {
      _passwordController.removeListener(_passwordListener!);
    }
    if (_confirmPasswordListener != null) {
      _confirmPasswordController.removeListener(_confirmPasswordListener!);
    }

    // Dispose controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    // Dispose FocusNodes safely
    _nameFocusNode?.dispose();
    _emailFocusNode?.dispose();
    _phoneFocusNode?.dispose();
    _locationFocusNode?.dispose();
    _passwordFocusNode?.dispose();
    _confirmPasswordFocusNode?.dispose();

    // Null FocusNodes
    _nameFocusNode = null;
    _emailFocusNode = null;
    _phoneFocusNode = null;
    _locationFocusNode = null;
    _passwordFocusNode = null;
    _confirmPasswordFocusNode = null;

    _focusScopeNode.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set initial focus when widget builds
    _setInitialFocus();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: FocusScope(
        node: _focusScopeNode,
        autofocus: true,
        child: GestureDetector(
          // Enhanced swipe gesture detection for step navigation
          onPanEnd: (details) {
            final velocity = details.velocity.pixelsPerSecond.dx;
            const threshold = 300.0;

            if (velocity > threshold) {
              // Swipe right - previous step
              _navigateToPreviousStep();
            } else if (velocity < -threshold) {
              // Swipe left - next step
              _navigateToNextStep();
            }
          },
          child: Container(
            decoration: const _BackgroundGradient(),
            child: CustomScrollView(
              cacheExtent: 1000,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  floating: true,
                  pinned: false,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(_kRadiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: _kElevationLevel2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: _kMinTouchTarget,
                      height: _kMinTouchTarget,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.black87,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _kScreenPadding,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _kMaxContentWidth,
                      ),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: _kSpacing2),
                              // Progress Indicator
                              _ProgressIndicator(
                                currentStep: _currentStep,
                                totalSteps: _totalSteps,
                                progressAnimation: _progressAnimation,
                              ),
                              const SizedBox(height: _kSpacing6),
                              Text(
                                'Create your account',
                                style: GoogleFonts.poppins(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: _kSpacing2),
                              Text(
                                'Sign up to find verified professionals for your home.',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: _kSpacing6),
                              // Social Login Section
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    _kRadiusLarge,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: _kElevationLevel3,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: _kElevationLevel1,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(_kSpacing6),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Or continue with',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: _kSpacing4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _SocialLoginButton(
                                              text: 'Google',
                                              icon: Icons.g_mobiledata,
                                              color: const Color(0xFF4285F4),
                                              onPressed: () {
                                                // TODO: Implement Google login
                                                HapticFeedback.lightImpact();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: _kSpacing4),
                                          Expanded(
                                            child: _SocialLoginButton(
                                              text: 'Facebook',
                                              icon: Icons.facebook,
                                              color: const Color(0xFF1877F2),
                                              onPressed: () {
                                                // TODO: Implement Facebook login
                                                HapticFeedback.lightImpact();
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: _kSpacing4),
                                      _SocialLoginButton(
                                        text: 'Apple',
                                        icon: Icons.apple,
                                        color: Colors.black,
                                        onPressed: () {
                                          // TODO: Implement Apple login
                                          HapticFeedback.lightImpact();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: _kSpacing4),
                              const SizedBox(height: _kSpacing4),
                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: _kSpacing4,
                                    ),
                                    child: Text(
                                      'OR',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.grey.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: _kSpacing8),
                              // Step-based form fields
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Column(
                                  key: ValueKey('step_$_currentStep'),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Step title
                                    _getStepTitle(),
                                    const SizedBox(height: _kSpacing4),
                                    _getStepDescription(),
                                    const SizedBox(height: _kSpacing6),
                                    // Form fields for current step
                                    ..._getStepFields(),
                                    const SizedBox(height: _kSpacing6),
                                    // Navigation buttons
                                    _getStepNavigationButtons(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: _kSpacing8),
                              // Additional Options Button
                              SizedBox(
                                width: double.infinity,
                                height: _kComfortableTouchTarget,
                                child: OutlinedButton.icon(
                                  onPressed: _showBottomSheet,
                                  icon: const Icon(Icons.more_horiz, size: 20),
                                  label: Text(
                                    'More Options',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _muawinPrimaryTeal,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: _muawinPrimaryTeal.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        _kRadiusMedium,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: _kSpacing12),
                            ],
                          ),
                        ),
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

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.progressAnimation,
  });

  final int currentStep;
  final int totalSteps;
  final Animation<double> progressAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progressAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(_kSpacing4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: _kElevationLevel2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Step indicator text
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step $currentStep of $totalSteps',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _muawinPrimaryTeal,
                    ),
                  ),
                  Text(
                    '${(currentStep / totalSteps * 100).round()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _kSpacing4),
              // Progress bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor:
                      progressAnimation.value * (currentStep / totalSteps),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _muawinPrimaryTeal,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _kSpacing2),
              // Step descriptions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(totalSteps, (index) {
                  final stepNumber = index + 1;
                  final isCompleted = stepNumber < currentStep;
                  final isCurrent = stepNumber == currentStep;

                  return Expanded(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? _muawinPrimaryTeal
                                : isCurrent
                                    ? _muawinPrimaryTeal.withValues(alpha: 0.2)
                                    : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                            border: isCurrent
                                ? Border.all(
                                    color: _muawinPrimaryTeal,
                                    width: 2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : Text(
                                    '$stepNumber',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isCurrent
                                          ? _muawinPrimaryTeal
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: _kSpacing2),
                        Text(
                          _getStepDescription(stepNumber),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight:
                                isCurrent ? FontWeight.w600 : FontWeight.w400,
                            color: isCurrent
                                ? _muawinPrimaryTeal
                                : Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 1:
        return 'Basic Info';
      case 2:
        return 'Details';
      case 3:
        return 'Password';
      default:
        return '';
    }
  }
}

class _RegisterButton extends StatefulWidget {
  const _RegisterButton({
    required this.onPressed,
    required this.isLoading,
    required this.primaryColor,
  });

  final VoidCallback onPressed;
  final bool isLoading;
  final Color primaryColor;

  static const double _height = 56;
  static const double _radius = 16;

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shimmerController;
  late Animation<double> _scale;
  late Animation<double> _shimmerAnimation;
  final bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Start shimmer when loading
    if (widget.isLoading) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_RegisterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (!widget.isLoading && _shimmerController.isAnimating) {
      _shimmerController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scale, _shimmerController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              height: _RegisterButton._height,
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: BorderRadius.circular(_RegisterButton._radius),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: widget.isLoading
                  ? AnimatedBuilder(
                      animation: _shimmerAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              _RegisterButton._radius,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment(
                                -1.0 + _shimmerAnimation.value,
                                0.0,
                              ),
                              end: Alignment(
                                1.0 + _shimmerAnimation.value,
                                0.0,
                              ),
                              colors: [
                                widget.primaryColor.withValues(alpha: 0.8),
                                widget.primaryColor.withValues(alpha: 1.0),
                                widget.primaryColor.withValues(alpha: 0.8),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: const Center(
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _showSuccess
                              ? const Icon(
                                  Icons.check_circle,
                                  key: ValueKey('success'),
                                  color: Colors.white,
                                  size: 20,
                                )
                              : const SizedBox.shrink(key: ValueKey('empty')),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Register',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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

class _SkipButton extends StatefulWidget {
  const _SkipButton({required this.onPressed, required this.text});

  final VoidCallback onPressed;
  final String text;

  @override
  State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _borderOpacity;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _borderOpacity = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              height: _kMinTouchTarget,
              decoration: BoxDecoration(
                color: _isPressed ? Colors.grey.shade50 : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade400.withValues(
                    alpha: _borderOpacity.value,
                  ),
                  width: 1,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      transform: Matrix4.identity()
                        ..scaleByDouble(
                          _isPressed ? 1.2 : 1.0,
                          _isPressed ? 1.2 : 1.0,
                          1.0,
                          1.0,
                        ),
                      child: Icon(
                        Icons.skip_next,
                        size: 16,
                        color: _isPressed
                            ? Colors.grey.shade800
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.text,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isPressed
                            ? Colors.grey.shade800
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SocialLoginButton extends StatefulWidget {
  const _SocialLoginButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  State<_SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<_SocialLoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _elevation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _elevation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _isPressed ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.color.withValues(alpha: _isPressed ? 0.5 : 0.3),
                  width: _isPressed ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: _elevation.value,
                    offset: Offset(0, _elevation.value / 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    transform: Matrix4.identity()
                      ..scaleByDouble(
                        _isPressed ? 1.1 : 1.0,
                        _isPressed ? 1.1 : 1.0,
                        1.0,
                        1.0,
                      ),
                    child: Icon(widget.icon, size: 20, color: widget.color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isPressed ? widget.color : Colors.black87,
                    ),
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

class _LoadingSkeleton extends StatefulWidget {
  const _LoadingSkeleton({required this.child, required this.isLoading});

  final Widget child;
  final bool isLoading;

  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_LoadingSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isLoading && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _shimmerAnimation.value, 0.0),
              end: Alignment(1.0 + _shimmerAnimation.value, 0.0),
              colors: [
                Colors.grey.withValues(alpha: 0.2),
                Colors.grey.withValues(alpha: 0.3),
                Colors.grey.withValues(alpha: 0.2),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.9),
            ),
            child: const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({
    required this.strength,
    required this.color,
  });

  final String strength;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.security, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          'Password strength: $strength',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        const Spacer(),
        ...List.generate(3, (index) {
          final isActive = index <
              (strength == 'Weak'
                  ? 1
                  : strength == 'Medium'
                      ? 2
                      : 3);
          return Container(
            margin: const EdgeInsets.only(left: 4),
            width: 8,
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? color : Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ],
    );
  }
}

class _FloatingLabelInput extends StatefulWidget {
  const _FloatingLabelInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHint,
    this.isValid = false,
    this.showValidation = false,
    this.icon,
    this.onChanged,
    this.focusNode,
    this.onFieldSubmitted,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;
  final String? autofillHint;
  final bool isValid;
  final bool showValidation;
  final IconData? icon;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<_FloatingLabelInput> createState() => _FloatingLabelInputState();
}

class _FloatingLabelInputState extends State<_FloatingLabelInput>
    with TickerProviderStateMixin {
  bool _isFocused = false;
  bool _hasError = false;
  String? _errorMessage;
  late FocusNode _focusNode;
  late AnimationController _errorAnimationController;
  late Animation<double> _errorAnimation;
  late AnimationController _borderAnimationController;
  late Animation<double> _borderAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();

    // Error animation
    _errorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _errorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _errorAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // Border animation for focus effects
    _borderAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _borderAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    // Remove listener before disposing
    _focusNode.removeListener(_onFocusChanged);

    // Only dispose FocusNode if we created it (not provided by widget)
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    _errorAnimationController.dispose();
    _borderAnimationController.dispose();
    super.dispose();
  }

  bool _hasText() {
    return widget.controller.text.isNotEmpty;
  }

  void _onFocusChanged() {
    if (mounted) {
      final newFocusState = _focusNode.hasFocus;
      if (_isFocused != newFocusState) {
        setState(() {
          _isFocused = newFocusState;
        });

        // Animate border changes
        if (newFocusState) {
          _borderAnimationController.forward();
        } else {
          _borderAnimationController.reverse();
        }
      }
    }
  }

  void _validateField() {
    if (widget.validator != null) {
      final result = widget.validator!(widget.controller.text);
      final previousError = _errorMessage;

      setState(() {
        _hasError = result != null;
        _errorMessage = _getProgressiveErrorMessage(result);
      });

      // Enhanced feedback with haptic responses
      if (_hasError) {
        _errorAnimationController.forward(from: 0.0);
        // Different haptic feedback for different error types
        if (_errorMessage?.contains('Required') == true) {
          HapticFeedback.heavyImpact(); // Strong feedback for required fields
        } else if (_errorMessage?.contains('Invalid') == true) {
          HapticFeedback
              .mediumImpact(); // Medium feedback for validation errors
        } else {
          HapticFeedback.lightImpact(); // Light feedback for suggestions
        }
      } else {
        _errorAnimationController.reverse();
        // Success feedback with progressive acknowledgment
        if (widget.controller.text.isNotEmpty) {
          if (widget.isValid) {
            HapticFeedback.selectionClick(); // Success feedback
          } else {
            // Subtle feedback for partial completion
            if (previousError != null && _errorMessage == null) {
              HapticFeedback.lightImpact();
            }
          }
        }
      }
    }
  }

  String? _getProgressiveErrorMessage(String? originalError) {
    if (originalError == null) return null;

    final text = widget.controller.text;

    // Progressive validation messages based on field type and content
    if (widget.label.contains('EMAIL')) {
      if (text.isEmpty) {
        return 'Email address is required';
      } else if (!text.contains('@')) {
        return 'Add @ to complete email address';
      } else if (!text.contains('.')) {
        return 'Add domain extension (.com, .org, etc.)';
      } else if (text.length < 5) {
        return 'Email seems too short';
      }
      return originalError;
    }

    if (widget.label.contains('PASSWORD')) {
      if (text.isEmpty) {
        return 'Password is required for security';
      } else if (text.length < 8) {
        return 'Use 8+ characters for better security';
      } else if (!RegExp(r'[A-Z]').hasMatch(text)) {
        return 'Add uppercase letter (A-Z)';
      } else if (!RegExp(r'[0-9]').hasMatch(text)) {
        return 'Add number (0-9)';
      }
      // Special character check temporarily disabled
      /* else if (!text.contains('!') && !text.contains('@') && !text.contains('#') && !text.contains('$') && !text.contains('%')) {
        return 'Add special character (!@#$%)';
      } */
      return originalError;
    }

    if (widget.label.contains('PHONE')) {
      if (text.isEmpty) {
        return 'Phone number helps us contact you';
      } else if (!RegExp(r'^03\d{2}').hasMatch(text)) {
        return 'Format: 03XX XXXXXXX';
      } else {
        // Count digits only (ignore space)
        final digitCount = text.replaceAll(RegExp(r'\D'), '').length;
        if (digitCount < 11) {
          return 'Complete phone number';
        }
      }
      return originalError;
    }

    if (widget.label.contains('NAME')) {
      if (text.isEmpty) {
        return 'Your name helps us personalize your experience';
      } else if (text.length < 2) {
        return 'Name seems too short';
      } else if (RegExp(r'[0-9]').hasMatch(text)) {
        return 'Name should only contain letters';
      }
      return originalError;
    }

    return originalError;
  }

  void _onFieldChanged(String value) {
    _validateField();
    if (widget.onChanged != null) {
      widget.onChanged!(value);
    }
  }

  String _getSemanticLabel() {
    var label = widget.label;
    if (widget.obscureText) {
      label += ', password field';
    }
    if (_hasError) {
      label += ', error: $_errorMessage';
    }
    return label;
  }

  String _getSemanticHint() {
    if (widget.obscureText) {
      return 'Enter your password. This field is private and will be hidden.';
    }

    if (widget.keyboardType == TextInputType.emailAddress) {
      return 'Enter your email address in format: example@domain.com';
    }

    if (widget.keyboardType == TextInputType.phone) {
      return 'Enter your phone number in format: 03XX XXXXXXX';
    }

    if (widget.label.contains('NAME')) {
      return 'Enter your full name using letters only';
    }

    return widget.hint;
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    const primary = _muawinPrimaryTeal;

    // High contrast mode support
    final isHighContrast = MediaQuery.of(context).highContrast;
    final highContrastPrimary = isHighContrast ? Colors.black : primary;
    final highContrastOnSurface = isHighContrast ? Colors.black : onSurface;

    final labelColor = _isFocused
        ? highContrastPrimary
        : highContrastOnSurface.withValues(alpha: isHighContrast ? 1.0 : 0.7);
    final labelFontSize = _isFocused || _hasText() ? 12.0 : 14.0;
    final labelOffset = _isFocused || _hasText() ? -40.0 : 0.0;

    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          // Floating Label
          Positioned(
            left: widget.icon != null ? 44 : 16,
            top: 18 + labelOffset,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Text(
                widget.label,
                style: GoogleFonts.poppins(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
            ),
          ),
          // Input Field
          Semantics(
            label: _getSemanticLabel(),
            hint: _getSemanticHint(),
            textField: true,
            child: AnimatedBuilder(
              animation: _borderAnimation,
              builder: (context, child) {
                return TextFormField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  keyboardType: widget.keyboardType,
                  obscureText: widget.obscureText,
                  validator: widget.validator,
                  autofillHints: widget.autofillHint != null
                      ? [widget.autofillHint!]
                      : null,
                  inputFormatters: widget.inputFormatters ?? [],
                  onChanged: _onFieldChanged,
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
                    filled: true,
                    fillColor: _hasError
                        ? Colors.red.withValues(alpha: 0.05)
                        : surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _hasError
                            ? Colors.red.withValues(alpha: 0.7)
                            : primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red.withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.red.withValues(alpha: 0.7),
                        width: 2,
                      ),
                    ),
                    contentPadding: EdgeInsets.only(
                      left: widget.icon != null ? 44 : 16,
                      right: 16,
                      top: 14,
                      bottom: _hasError ? 8 : 14, // Adjust for error message
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.showValidation &&
                            widget.controller.text.isNotEmpty)
                          AnimatedBuilder(
                            animation: _errorAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 0.8 + (_errorAnimation.value * 0.2),
                                child: Icon(
                                  widget.isValid
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 20,
                                  color: widget.isValid
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              );
                            },
                          ),
                        if (widget.suffixIcon != null) widget.suffixIcon!,
                      ],
                    ),
                    prefixIcon: widget.icon != null
                        ? Padding(
                            padding: const EdgeInsets.only(left: 16, right: 12),
                            child: AnimatedBuilder(
                              animation: _errorAnimation,
                              builder: (context, child) {
                                return Icon(
                                  widget.icon,
                                  size: 20,
                                  color: _hasError
                                      ? Colors.red.withValues(alpha: 0.7)
                                      : primary.withValues(alpha: 0.7),
                                );
                              },
                            ),
                          )
                        : null,
                    errorText: _hasError ? _errorMessage : null,
                    errorStyle: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.red.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartCapitalizationTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Smart capitalization for names
    List<String> words = newValue.text.split(' ');
    List<String> capitalizedWords = [];

    for (String word in words) {
      if (word.isNotEmpty) {
        String capitalized =
            word[0].toUpperCase() + word.substring(1).toLowerCase();
        capitalizedWords.add(capitalized);
      } else {
        capitalizedWords.add(word);
      }
    }

    String formatted = capitalizedWords.join(' ');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _PageTransitionWidget extends StatefulWidget {
  const _PageTransitionWidget({required this.child, required this.isVisible});

  final Widget child;
  final bool isVisible;

  @override
  State<_PageTransitionWidget> createState() => _PageTransitionWidgetState();
}

class _PageTransitionWidgetState extends State<_PageTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_PageTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double slideOffset = _slideAnimation.value * 50;

        return Transform.translate(
          offset: Offset(slideOffset, 0),
          child: Opacity(opacity: _fadeAnimation.value, child: widget.child),
        );
      },
    );
  }
}

enum PageTransitionType { slideRight, slideLeft, slideUp, slideDown }

class _ShakeAnimationWidget extends StatefulWidget {
  const _ShakeAnimationWidget({required this.child});

  final Widget child;

  @override
  State<_ShakeAnimationWidget> createState() => _ShakeAnimationWidgetState();
}

class _ShakeAnimationWidgetState extends State<_ShakeAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  void shake() {
    _controller.forward(from: 0.0).then((_) {
      _controller.reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value *
                10.0 *
                (sin(_shakeAnimation.value * pi * 3 * 2)),
            0,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _StaggeredAnimationWidget extends StatefulWidget {
  const _StaggeredAnimationWidget({required this.children});

  final List<Widget> children;

  @override
  State<_StaggeredAnimationWidget> createState() =>
      _StaggeredAnimationWidgetState();
}

class _StaggeredAnimationWidgetState extends State<_StaggeredAnimationWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.children.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
    }).toList();

    // Start animations with staggered delay
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(const Duration(milliseconds: 100) * i, () {
        if (mounted) {
          _controllers[i].forward();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _animations[index].value)),
              child: Opacity(opacity: _animations[index].value, child: child),
            );
          },
          child: child,
        );
      }).toList(),
    );
  }
}

class _CelebrationAnimationWidget extends StatefulWidget {
  const _CelebrationAnimationWidget({
    required this.child,
    required this.isCompleted,
  });

  final Widget child;
  final bool isCompleted;

  @override
  State<_CelebrationAnimationWidget> createState() =>
      _CelebrationAnimationWidgetState();
}

class _CelebrationAnimationWidgetState
    extends State<_CelebrationAnimationWidget> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _opacityController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _opacityController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _opacityController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(_CelebrationAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _startCelebration();
    }
  }

  void _startCelebration() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    _rotationController.repeat(reverse: true);

    _opacityController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _opacityController.reverse();
        }
      });
    });

    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _opacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _rotationAnimation,
        _opacityAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: widget.isCompleted
                    ? [
                        BoxShadow(
                          color: Colors.green.withValues(
                            alpha: _opacityAnimation.value * 0.4,
                          ),
                          blurRadius: 20 * _opacityAnimation.value,
                          spreadRadius: 5 * _opacityAnimation.value,
                        ),
                        BoxShadow(
                          color: _muawinPrimaryTeal.withValues(
                            alpha: _opacityAnimation.value * 0.3,
                          ),
                          blurRadius: 15 * _opacityAnimation.value,
                          spreadRadius: 3 * _opacityAnimation.value,
                        ),
                      ]
                    : null,
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  double velocityX;
  double velocityY;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;
  double opacity;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
  });

  void update(double deltaTime) {
    x += velocityX * deltaTime;
    y += velocityY * deltaTime;
    velocityY += 300 * deltaTime; // Gravity
    rotation += rotationSpeed * deltaTime;
    opacity = max(0, opacity - deltaTime * 0.5);
  }
}

class _ConfettiWidget extends StatefulWidget {
  const _ConfettiWidget({required this.child, required this.isActive});

  final Widget child;
  final bool isActive;

  @override
  State<_ConfettiWidget> createState() => _ConfettiWidgetState();
}

class _ConfettiWidgetState extends State<_ConfettiWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(_ConfettiWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startConfetti();
    }
  }

  void _startConfetti() {
    _particles.clear();

    for (int i = 0; i < 50; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble() * 400,
          y: -20,
          velocityX: (_random.nextDouble() - 0.5) * 200,
          velocityY: _random.nextDouble() * 200 + 100,
          size: _random.nextDouble() * 8 + 4,
          color: [
            Colors.green,
            _muawinPrimaryTeal,
            Colors.blue,
            Colors.orange,
            Colors.purple,
          ][_random.nextInt(5)],
          rotation: _random.nextDouble() * pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 10,
          opacity: 1.0,
        ),
      );
    }

    _controller.forward(from: 0.0);
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isActive)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              const deltaTime = 0.016; // 60 FPS

              for (final particle in _particles) {
                particle.update(deltaTime);
              }

              _particles.removeWhere(
                (particle) => particle.opacity <= 0 || particle.y > 600,
              );

              return CustomPaint(
                painter: _ConfettiPainter(_particles),
                size: Size.infinite,
              );
            },
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);

      // Draw confetti as small rectangles
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size * 2,
          height: particle.size,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SkeletonWidget extends StatefulWidget {
  const _SkeletonWidget({required this.child, required this.isLoading});

  final Widget child;
  final bool isLoading;

  @override
  State<_SkeletonWidget> createState() => _SkeletonWidgetState();
}

class _SkeletonWidgetState extends State<_SkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_SkeletonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [0.0, 0.5 + _animation.value * 0.5, 1.0],
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _ParallaxBackgroundWidget extends StatefulWidget {
  const _ParallaxBackgroundWidget({required this.child});

  final Widget child;

  @override
  State<_ParallaxBackgroundWidget> createState() =>
      _ParallaxBackgroundWidgetState();
}

class _ParallaxBackgroundWidgetState extends State<_ParallaxBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  late ScrollController _internalScrollController;

  @override
  void initState() {
    super.initState();

    _internalScrollController = ScrollController();
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeOutCubic,
      ),
    );

    _internalScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (mounted) {
      final offset = _internalScrollController.offset;
      final maxOffset = _internalScrollController.position.maxScrollExtent;

      if (maxOffset > 0) {
        final scrollPercentage = (offset / maxOffset).clamp(0.0, 1.0);
        _backgroundController.value = scrollPercentage;
      }
    }
  }

  @override
  void dispose() {
    _internalScrollController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Background layers with parallax effect
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF0F9FF),
                      Color(0xFFE0F2FE),
                      Color(0xFFBAE6FD),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            // Parallax layer 1 - Slow moving
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, -_backgroundAnimation.value * 100),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.7),
                        Colors.white.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Parallax layer 2 - Medium moving
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, -_backgroundAnimation.value * 50),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topLeft,
                      radius: 1.5,
                      colors: [
                        _muawinPrimaryTeal.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Parallax layer 3 - Fast moving decorative elements
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(
                  _backgroundAnimation.value * 30,
                  -_backgroundAnimation.value * 150,
                ),
                child: CustomPaint(
                  painter: _ParallaxPatternPainter(_backgroundAnimation.value),
                  size: Size.infinite,
                ),
              ),
            ),
            // Content
            widget.child,
          ],
        );
      },
    );
  }
}

class _ParallaxPatternPainter extends CustomPainter {
  final double scrollProgress;

  _ParallaxPatternPainter(this.scrollProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _muawinPrimaryTeal.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    // Draw floating circles with parallax effect
    final circles = [
      Offset(size.width * 0.1, size.height * 0.2 + scrollProgress * 50),
      Offset(size.width * 0.8, size.height * 0.1 + scrollProgress * 30),
      Offset(size.width * 0.7, size.height * 0.6 + scrollProgress * 70),
      Offset(size.width * 0.2, size.height * 0.8 + scrollProgress * 40),
      Offset(size.width * 0.9, size.height * 0.4 + scrollProgress * 60),
    ];

    for (int i = 0; i < circles.length; i++) {
      final circle = circles[i];
      final radius = 20.0 + (i * 10) + (scrollProgress * 10);

      canvas.drawCircle(circle, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _CustomRippleButton extends StatefulWidget {
  const _CustomRippleButton({required this.child, required this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  State<_CustomRippleButton> createState() => _CustomRippleButtonState();
}

class _CustomRippleButtonState extends State<_CustomRippleButton>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _scaleController;
  late Animation<double> _rippleAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOutCubic),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    _startRippleAnimation(details.localPosition);
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  void _startRippleAnimation(Offset position) {
    _rippleController.forward(from: 0.0).then((_) {
      _rippleController.reverse();
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _rippleAnimation,
        _opacityAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: _muawinPrimaryTeal.withValues(alpha: 0.3),
                  blurRadius: 8 * _scaleAnimation.value,
                  offset: Offset(0, 4 * _scaleAnimation.value),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12.0),
              child: InkWell(
                onTap: widget.onPressed,
                onTapDown: _handleTapDown,
                onTapUp: _handleTapUp,
                onTapCancel: _handleTapCancel,
                borderRadius: BorderRadius.circular(12.0),
                splashColor: Colors.white.withValues(alpha: 0.3),
                highlightColor: Colors.white.withValues(alpha: 0.1),
                child: Stack(
                  children: [
                    // Custom ripple effect
                    if (_rippleAnimation.value > 0)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RipplePainter(
                            center: Offset.zero, // Will be updated on tap
                            radius: 100 * _rippleAnimation.value,
                            color: Colors.white.withValues(
                              alpha: _opacityAnimation.value,
                            ),
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    // Button content
                    Center(child: widget.child),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;

  _RipplePainter({
    required this.center,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AnimatedProgressBar extends StatefulWidget {
  const _AnimatedProgressBar({required this.progress});

  final double progress; // 0.0 to 1.0

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late Animation<double> _shimmerAnimation;
  late AnimationController _shimmerController;

  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation =
        Tween<double>(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeOutCubic,
      ),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _progressController.forward();
    _shimmerController.repeat();
  }

  @override
  void didUpdateWidget(_AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.progress != oldWidget.progress) {
      _previousProgress = oldWidget.progress;
      _progressAnimation =
          Tween<double>(begin: _previousProgress, end: widget.progress).animate(
        CurvedAnimation(
          parent: _progressController,
          curve: Curves.easeOutCubic,
        ),
      );

      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _shimmerAnimation]),
      builder: (context, child) {
        return Container(
          height: 8.0,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Stack(
            children: [
              // Progress fill
              FractionallySizedBox(
                widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _muawinPrimaryTeal,
                        _muawinPrimaryTeal.withValues(alpha: 0.8),
                        _muawinPrimaryTeal,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                    boxShadow: [
                      BoxShadow(
                        color: _muawinPrimaryTeal.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Shimmer effect
              if (_progressAnimation.value > 0.1)
                FractionallySizedBox(
                  widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                          stops: [
                            0.0,
                            0.5 + _shimmerAnimation.value * 0.5,
                            1.0,
                          ],
                          tileMode: TileMode.clamp,
                        ).createShader(bounds);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),
                ),
              // Progress indicator dots
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final dotProgress = (_progressAnimation.value * 5) - index;
                    return Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotProgress > 0 && dotProgress <= 1
                            ? Colors.white.withValues(
                                alpha: dotProgress.clamp(0.0, 1.0),
                              )
                            : Colors.transparent,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LongPressOptionsWidget extends StatefulWidget {
  const _LongPressOptionsWidget({required this.child, required this.options});

  final Widget child;
  final List<String> options;

  @override
  State<_LongPressOptionsWidget> createState() =>
      _LongPressOptionsWidgetState();
}

class _LongPressOptionsWidgetState extends State<_LongPressOptionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _menuController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  OverlayEntry? _overlayEntry;
  bool _isMenuVisible = false;

  @override
  void initState() {
    super.initState();

    _menuController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _menuController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _menuController, curve: Curves.easeOut));
  }

  void _showMenu(BuildContext context, Offset position) {
    HapticFeedback.mediumImpact();

    _overlayEntry = OverlayEntry(
      builder: (context) => _ContextMenuOverlay(
        position: position,
        options: widget.options,
        onOptionSelected: (option) {
          _hideMenu();
        },
        onClose: _hideMenu,
        scaleAnimation: _scaleAnimation,
        opacityAnimation: _opacityAnimation,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _menuController.forward();
    _isMenuVisible = true;
  }

  void _hideMenu() {
    if (_isMenuVisible && _overlayEntry != null) {
      _menuController.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _isMenuVisible = false;
      });
    }
  }

  @override
  void dispose() {
    _menuController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        _showMenu(context, details.globalPosition);
      },
      child: widget.child,
    );
  }
}

class _ContextMenuOverlay extends StatelessWidget {
  const _ContextMenuOverlay({
    required this.position,
    required this.options,
    required this.onOptionSelected,
    required this.onClose,
    required this.scaleAnimation,
    required this.opacityAnimation,
  });

  final Offset position;
  final List<String> options;
  final Function(String) onOptionSelected;
  final VoidCallback onClose;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Material(
        color: Colors.black.withValues(alpha: 0.3),
        child: AnimatedBuilder(
          animation: Listenable.merge([scaleAnimation, opacityAnimation]),
          builder: (context, child) {
            return Positioned(
              left: position.dx,
              top: position.dy,
              child: Transform.scale(
                scale: scaleAnimation.value,
                child: Opacity(
                  opacity: opacityAnimation.value,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: options.map((option) {
                        return InkWell(
                          onTap: () => onOptionSelected(option),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getOptionIcon(option),
                                  size: 20,
                                  color: _muawinPrimaryTeal,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getOptionIcon(String option) {
    switch (option.toLowerCase()) {
      case 'edit':
        return Icons.edit;
      case 'copy':
        return Icons.copy;
      case 'delete':
        return Icons.delete;
      case 'share':
        return Icons.share;
      case 'info':
        return Icons.info;
      case 'settings':
        return Icons.settings;
      default:
        return Icons.more_vert;
    }
  }
}

class _PinchToZoomWidget extends StatefulWidget {
  const _PinchToZoomWidget({required this.child});

  final Widget child;

  @override
  State<_PinchToZoomWidget> createState() => _PinchToZoomWidgetState();
}

class _PinchToZoomWidgetState extends State<_PinchToZoomWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  double _currentScale = 1.0;
  double _previousScale = 1.0;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _previousScale = _currentScale;
    HapticFeedback.lightImpact();
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final newScale = (_previousScale * details.scale).clamp(0.8, 2.0);

    if (newScale != _currentScale) {
      setState(() {
        _currentScale = newScale;
      });

      _scaleAnimation = Tween<double>(
        begin: _scaleAnimation.value,
        end: _currentScale,
      ).animate(
        CurvedAnimation(
          parent: _scaleController,
          curve: Curves.easeOutCubic,
        ),
      );

      _scaleController.forward(from: 0.0);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Snap back to reasonable scale if too extreme
    final targetScale = _currentScale.clamp(0.9, 1.5);

    if (targetScale != _currentScale) {
      _scaleAnimation =
          Tween<double>(begin: _currentScale, end: targetScale).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
      );

      _scaleController.forward().then((_) {
        setState(() {
          _currentScale = targetScale;
        });
      });
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          alignment: Alignment.center,
          child: GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _DragToReorderWidget extends StatefulWidget {
  const _DragToReorderWidget({required this.children, required this.onReorder});

  final List<Widget> children;
  final Function(int oldIndex, int newIndex) onReorder;

  @override
  State<_DragToReorderWidget> createState() => _DragToReorderWidgetState();
}

class _DragToReorderWidgetState extends State<_DragToReorderWidget>
    with TickerProviderStateMixin {
  late List<Widget> _items;
  int? _draggingIndex;
  int? _hoveringIndex;
  late AnimationController _dragController;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.children);

    _dragController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  void _handleDragStart(int index) {
    setState(() {
      _draggingIndex = index;
    });
    _dragController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleDragUpdate(int index, DragUpdateDetails details) {
    if (_draggingIndex == null) return;

    // Calculate new position based on drag offset
    const itemHeight = 80.0; // Approximate item height
    final dragOffset = details.primaryDelta ?? 0;
    final currentPosition = index * itemHeight;
    final newPosition = currentPosition + dragOffset;
    final newHoveringIndex = (newPosition / itemHeight).round().clamp(
          0,
          _items.length - 1,
        );

    if (newHoveringIndex != _hoveringIndex &&
        newHoveringIndex != _draggingIndex) {
      setState(() {
        _hoveringIndex = newHoveringIndex;
      });

      // Swap items visually
      if (_draggingIndex != null && _hoveringIndex != null) {
        final draggingItem = _items[_draggingIndex!];
        _items[_draggingIndex!] = _items[_hoveringIndex!];
        _items[_hoveringIndex!] = draggingItem;

        setState(() {
          _draggingIndex = _hoveringIndex;
        });
      }
    }
  }

  void _handleDragEnd(int index) {
    if (_draggingIndex != null && _draggingIndex != index) {
      widget.onReorder(index, _draggingIndex!);
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _draggingIndex = null;
      _hoveringIndex = null;
    });

    _dragController.reverse();
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isDragging = _draggingIndex == index;
        final isHovering = _hoveringIndex == index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translateByDouble(
              0.0,
              isDragging ? -5.0 : (isHovering ? 5.0 : 0.0),
              0.0,
              1.0,
            ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDragging
                  ? _muawinPrimaryTeal.withValues(alpha: 0.1)
                  : Colors.white,
              border: isDragging
                  ? Border.all(color: _muawinPrimaryTeal, width: 2)
                  : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              boxShadow: isDragging
                  ? [
                      BoxShadow(
                        color: _muawinPrimaryTeal.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Drag handle
                GestureDetector(
                  onPanStart: (_) => _handleDragStart(index),
                  onPanUpdate: (details) => _handleDragUpdate(index, details),
                  onPanEnd: (_) => _handleDragEnd(index),
                  child: SizedBox(
                    width: 40,
                    height: 60,
                    child: Icon(Icons.drag_handle, color: Colors.grey[600]),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: item,
                  ),
                ),
                // Reorder indicator
                if (isDragging)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Icon(
                      Icons.reorder,
                      color: _muawinPrimaryTeal,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SwipeToDeleteWidget extends StatefulWidget {
  const _SwipeToDeleteWidget({required this.child, required this.onDelete});

  final Widget child;
  final VoidCallback onDelete;

  @override
  State<_SwipeToDeleteWidget> createState() => _SwipeToDeleteWidgetState();
}

class _SwipeToDeleteWidgetState extends State<_SwipeToDeleteWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _deleteController;
  late Animation<double> _slideAnimation;
  late Animation<double> _deleteAnimation;
  double _dragOffset = 0.0;
  bool _isDeleteMode = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _deleteController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _deleteAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _deleteController, curve: Curves.easeInOut),
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isDeleteMode) return;

    setState(() {
      _dragOffset += details.delta.dx;
      _dragOffset = _dragOffset.clamp(-100.0, 0.0);
    });

    _slideAnimation =
        Tween<double>(begin: 0.0, end: _dragOffset / 100.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward(from: 0.0);
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isDeleteMode) return;

    if (_dragOffset.abs() >= 100.0 * 0.7) {
      // Trigger delete
      _confirmDelete();
    } else {
      // Snap back
      _resetPosition();
    }
  }

  void _confirmDelete() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isDeleteMode = true;
    });

    _deleteController.forward().then((_) {
      widget.onDelete();
    });
  }

  void _resetPosition() {
    setState(() {
      _dragOffset = 0.0;
    });

    _slideAnimation =
        Tween<double>(begin: _slideAnimation.value, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _slideController.forward(from: 0.0);
  }

  void _cancelDelete() {
    if (_isDeleteMode) {
      _deleteController.reverse().then((_) {
        setState(() {
          _isDeleteMode = false;
        });
        _resetPosition();
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _deleteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _deleteAnimation]),
      builder: (context, child) {
        return Stack(
          children: [
            // Delete background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, color: Colors.white, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Transform.translate(
              offset: Offset(_slideAnimation.value * 100.0, 0),
              child: Transform.scale(
                scale: _isDeleteMode ? _deleteAnimation.value : 1.0,
                child: GestureDetector(
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      border: Border.all(
                        color: _dragOffset.abs() > 100.0 * 0.5
                            ? Colors.red
                            : Colors.grey.withValues(alpha: 0.3),
                        width: _dragOffset.abs() > 100.0 * 0.5 ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: _isDeleteMode ? 8 : 2,
                          offset: Offset(0, _isDeleteMode ? 4 : 1),
                        ),
                      ],
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
            // Cancel button
            if (_isDeleteMode)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _cancelDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.red),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PullToRefreshWidget extends StatefulWidget {
  const _PullToRefreshWidget({required this.child, required this.onRefresh});

  final Widget child;
  final Future<void> Function() onRefresh;

  @override
  State<_PullToRefreshWidget> createState() => _PullToRefreshWidgetState();
}

class _PullToRefreshWidgetState extends State<_PullToRefreshWidget>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late AnimationController _indicatorController;
  late Animation<double> _pullAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  double _pullOffset = 0.0;
  bool _isRefreshing = false;
  bool _isPulling = false;

  @override
  void initState() {
    super.initState();

    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pullAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeOutCubic),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.linear),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _indicatorController, curve: Curves.easeIn),
    );
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isRefreshing) return;

    setState(() {
      _pullOffset += details.primaryDelta ?? 0;
      _pullOffset = _pullOffset.clamp(0.0, 80.0 * 1.5);
      _isPulling = _pullOffset > 10.0;
    });

    final progress = (_pullOffset / 80.0).clamp(0.0, 1.0);
    _refreshController.value = progress;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isRefreshing) return;

    if (_pullOffset >= 80.0) {
      _startRefresh();
    } else {
      _resetPull();
    }
  }

  void _startRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isRefreshing = true;
    });

    _indicatorController.repeat();

    try {
      await widget.onRefresh();
    } finally {
      _stopRefresh();
    }
  }

  void _stopRefresh() {
    _indicatorController.stop();
    _indicatorController.reverse().then((_) {
      setState(() {
        _isRefreshing = false;
      });
      _resetPull();
    });
  }

  void _resetPull() {
    _refreshController.reverse().then((_) {
      setState(() {
        _pullOffset = 0.0;
        _isPulling = false;
      });
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        Transform.translate(
          offset: Offset(0, _pullOffset),
          child: GestureDetector(
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: widget.child,
          ),
        ),
        // Refresh indicator
        if (_isPulling || _isRefreshing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60.0,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _pullAnimation,
                _rotateAnimation,
                _scaleAnimation,
                _opacityAnimation,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _muawinPrimaryTeal.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(child: _buildRefreshIndicator()),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRefreshIndicator() {
    if (_isRefreshing) {
      return Transform.rotate(
        angle: _rotateAnimation.value * 2 * 3.14159,
        child: const Icon(Icons.refresh, color: _muawinPrimaryTeal, size: 24),
      );
    } else {
      final progress = _pullAnimation.value;
      return Transform.rotate(
        angle: progress * 3.14159,
        child: Icon(
          progress >= 1.0 ? Icons.arrow_downward : Icons.keyboard_arrow_down,
          color: _muawinPrimaryTeal,
          size: 24,
        ),
      );
    }
  }
}

class _InfiniteScrollWidget extends StatefulWidget {
  const _InfiniteScrollWidget({required this.child, required this.onLoadMore});

  final Widget child;
  final Future<void> Function() onLoadMore;

  @override
  State<_InfiniteScrollWidget> createState() => _InfiniteScrollWidgetState();
}

class _InfiniteScrollWidgetState extends State<_InfiniteScrollWidget> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= 200.0) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    HapticFeedback.lightImpact();

    try {
      await widget.onLoadMore();
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          _onScroll();
        }
        return false;
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: widget.child,
            ),
          ),
          // Loading indicator
          if (_isLoadingMore)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _muawinPrimaryTeal,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading more...',
                    style: TextStyle(
                      color: _muawinPrimaryTeal,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

class _GestureShortcutsWidget extends StatefulWidget {
  const _GestureShortcutsWidget({required this.child});

  final Widget child;

  @override
  State<_GestureShortcutsWidget> createState() =>
      _GestureShortcutsWidgetState();
}

class _GestureShortcutsWidgetState extends State<_GestureShortcutsWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
      },
      child: widget.child,
    );
  }
}

class _AnimatedOpacityWidget extends StatefulWidget {
  const _AnimatedOpacityWidget({required this.child});

  final Widget child;

  @override
  State<_AnimatedOpacityWidget> createState() => _AnimatedOpacityWidgetState();
}

class _AnimatedOpacityWidgetState extends State<_AnimatedOpacityWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  double _previousOpacity = 1.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: _previousOpacity,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start animation if opacity is different from initial
    if (1.0 != 1.0) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedOpacityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.child != widget.child) {
      _previousOpacity = 1.0;

      _opacityAnimation = Tween<double>(
        begin: _previousOpacity,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

      _controller.duration = const Duration(milliseconds: 300);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(opacity: _opacityAnimation.value, child: widget.child);
      },
    );
  }
}

class _TransformAnimationWidget extends StatefulWidget {
  const _TransformAnimationWidget({required this.child});

  final Widget child;

  @override
  State<_TransformAnimationWidget> createState() =>
      _TransformAnimationWidgetState();
}

class _TransformAnimationWidgetState extends State<_TransformAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  final Offset _previousOffset = Offset.zero;
  final double _previousScale = 1.0;
  final double _previousRotation = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _setupAnimations();
  }

  void _setupAnimations() {
    _offsetAnimation = Tween<Offset>(
      begin: _previousOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(
      begin: _previousScale,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: _previousRotation,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _offsetAnimation,
        _scaleAnimation,
        _rotationAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: _offsetAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _PhysicsAnimationWidget extends StatefulWidget {
  const _PhysicsAnimationWidget({required this.child});

  final Widget child;

  @override
  State<_PhysicsAnimationWidget> createState() =>
      _PhysicsAnimationWidgetState();
}

class _PhysicsAnimationWidgetState extends State<_PhysicsAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _physicsAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _setupPhysicsAnimation();
    _controller.repeat();
  }

  void _setupPhysicsAnimation() {
    _physicsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const _PhysicsCurve(
          springConfig: _SpringConfig(
            mass: 1.0,
            stiffness: 100.0,
            damping: 10.0,
          ),
          frictionConfig: _FrictionConfig(coefficient: 0.1),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _physicsAnimation,
      builder: (context, child) {
        final value = _physicsAnimation.value;
        final physicsValue = _calculatePhysics(value);

        return Transform.translate(offset: physicsValue, child: widget.child);
      },
    );
  }

  Offset _calculatePhysics(double t) {
    // Spring physics simulation
    const spring = _SpringConfig(mass: 1.0, stiffness: 100.0, damping: 10.0);
    final displacement = sin(t * 2 * pi) * 20.0;
    final damping = exp(-spring.damping * t);
    return Offset(displacement * damping, 0);
  }
}

class _SpringConfig {
  const _SpringConfig({
    required this.mass,
    required this.stiffness,
    required this.damping,
  });

  final double mass;
  final double stiffness;
  final double damping;
}

class _FrictionConfig {
  const _FrictionConfig({required this.coefficient});

  final double coefficient;
}

class _PhysicsCurve extends Curve {
  const _PhysicsCurve({this.springConfig, this.frictionConfig});

  final _SpringConfig? springConfig;
  final _FrictionConfig? frictionConfig;

  @override
  double transform(double t) {
    if (springConfig != null) {
      // Spring physics: oscillation with damping
      final spring = springConfig!;
      final omega = sqrt(spring.stiffness / spring.mass);
      final damping = spring.damping / (2 * spring.mass);
      final oscillation = exp(-damping * t) * cos(omega * t);
      return (oscillation + 1.0) / 2.0;
    }

    if (frictionConfig != null) {
      // Friction physics: deceleration
      final friction = frictionConfig!;
      return 1.0 - exp(-friction.coefficient * t * 5);
    }

    return t;
  }
}

class _GPUAcceleratedAnimationWidget extends StatefulWidget {
  _GPUAcceleratedAnimationWidget({
    required this.child,
    Matrix4? transform,
    this.opacity = 1.0,
    this.duration = const Duration(milliseconds: 16), // 60fps = 16.67ms
  }) : transform = transform ?? Matrix4.identity();

  final Widget child;
  final Matrix4 transform;
  final double opacity;
  final Duration duration;

  @override
  State<_GPUAcceleratedAnimationWidget> createState() =>
      _GPUAcceleratedAnimationWidgetState();
}

class _GPUAcceleratedAnimationWidgetState
    extends State<_GPUAcceleratedAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _transformAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: widget.duration, vsync: this);

    _transformAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: widget.opacity,
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_transformAnimation, _opacityAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_transformAnimation.value * 0.1),
            alignment: Alignment.center,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

class _AnimationPreloader extends StatefulWidget {
  const _AnimationPreloader({required this.child, required this.animations});

  final Widget child;
  final List<AnimationController> animations;

  @override
  State<_AnimationPreloader> createState() => _AnimationPreloaderState();
}

class _AnimationPreloaderState extends State<_AnimationPreloader> {
  bool _isPreloaded = false;

  @override
  void initState() {
    super.initState();
    _preloadAnimations();
  }

  Future<void> _preloadAnimations() async {
    // Preload all animations to ensure instant responses
    for (final controller in widget.animations) {
      controller.forward();
      await controller.forward();
      controller.reverse();
      await controller.reverse();
    }

    if (mounted) {
      setState(() {
        _isPreloaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPreloaded) {
      return const SizedBox.shrink();
    }

    return widget.child;
  }
}

class _ReducedMotionWidget extends StatefulWidget {
  const _ReducedMotionWidget({
    required this.child,
    required this.animationChild,
  });

  final Widget child;
  final Widget animationChild;

  @override
  State<_ReducedMotionWidget> createState() => _ReducedMotionWidgetState();
}

class _ReducedMotionWidgetState extends State<_ReducedMotionWidget> {
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _checkReducedMotion();
  }

  void _checkReducedMotion() async {
    final mediaQuery = MediaQuery.of(context);
    _reducedMotion = mediaQuery.accessibleNavigation ||
        mediaQuery.disableAnimations ||
        mediaQuery.highContrast;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reducedMotion) {
      // Show child without animation for accessibility
      return widget.child;
    }

    // Show animated version
    return widget.animationChild;
  }
}

class _PerformanceOptimizedAnimation extends StatefulWidget {
  const _PerformanceOptimizedAnimation({required this.child});

  final Widget child;

  @override
  State<_PerformanceOptimizedAnimation> createState() =>
      _PerformanceOptimizedAnimationState();
}

class _PerformanceOptimizedAnimationState
    extends State<_PerformanceOptimizedAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _performanceTimer;
  double _lastFrameTime = 0.0;

  @override
  void initState() {
    super.initState();

    const frameDuration = 1000.0 / 60.0; // 60fps
    _controller = AnimationController(
      duration: Duration(milliseconds: frameDuration.round()),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _startPerformanceMonitoring();
    _controller.repeat();
  }

  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(
      const Duration(milliseconds: 1000),
      _monitorPerformance,
    );
  }

  void _monitorPerformance(Timer timer) {
    final currentTime = DateTime.now().millisecondsSinceEpoch.toDouble();
    if (_lastFrameTime > 0) {
      final deltaTime = currentTime - _lastFrameTime;
      final currentFPS = 1000.0 / deltaTime;

      // Adjust animation quality based on performance
      if (currentFPS < 60.0 * 0.8) {
        // Reduce animation quality if performance is low
        _controller.stop();
        _controller.duration = Duration(
          milliseconds: (1000.0 / (60.0 * 0.6)).round(),
        );
        _controller.repeat();
      }
    }
    _lastFrameTime = currentTime;
  }

  @override
  void dispose() {
    _performanceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animatedChild = AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (_animation.value * 0.05),
          child: Opacity(
            opacity: 0.8 + (_animation.value * 0.2),
            child: widget.child,
          ),
        );
      },
    );

    return RepaintBoundary(
      child: _GPUAcceleratedAnimationWidget(
        transform: Matrix4.identity(),
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: animatedChild,
      ),
    );
  }
}

class _BackgroundGradient extends BoxDecoration {
  const _BackgroundGradient()
      : super(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFAFAFA), Color(0xFFF5F5F5)],
            stops: [0.0, 0.6, 1.0],
          ),
        );
}

class _BottomSheetOption extends StatelessWidget {
  const _BottomSheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_kRadiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _kScreenPadding,
              vertical: 12,
            ),
            child: Row(
              children: [
                // Icon container with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? color.withValues(alpha: 0.1)
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(_kRadiusMedium),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: _kSpacing4),
                // Text content
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
                          color: isDestructive
                              ? color
                              : Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
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
