import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/register_provider.dart';
import 'smart_form_features.dart';
import 'success_screen.dart';

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

/// Responsive design utilities
class ResponsiveSpacing {
  static double getPadding(double screenWidth) {
    if (screenWidth < 360) return 16;
    if (screenWidth < 600) return 24;
    return 32;
  }

  static double getContentWidth(double screenWidth) {
    if (screenWidth < 600) return screenWidth;
    if (screenWidth < 900) return 600;
    if (screenWidth < 1200) return 800;
    return 1000;
  }

  static double getFontSize(
      double screenWidth, double mobile, double tablet, double desktop) {
    if (screenWidth < 600) return mobile;
    if (screenWidth < 900) return tablet;
    return desktop;
  }

  static double getButtonHeight(double screenWidth) {
    return getFontSize(screenWidth, 48, 52, 56);
  }
}

/// Animated text field with focus animations
class AnimatedTextField extends StatefulWidget {
  const AnimatedTextField({
    super.key,
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
    this.onChanged,
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
  final Function(String)? onChanged;

  @override
  State<AnimatedTextField> createState() => _AnimatedTextFieldState();
}

class _AnimatedTextFieldState extends State<AnimatedTextField> {
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

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
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
        onChanged: widget.onChanged,
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
          suffixIcon:
              widget.showValidationBorder && widget.controller.text.isNotEmpty
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
  }
}

/// Custom category selection grid
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
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

        return CategoryCard(
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
class CategoryCard extends StatefulWidget {
  const CategoryCard({
    super.key,
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
  State<CategoryCard> createState() => CategoryCardState();
}

class CategoryCardState extends State<CategoryCard>
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
  void didUpdateWidget(CategoryCard oldWidget) {
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

/// Field label widget
class FieldLabel extends StatelessWidget {
  const FieldLabel({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.15 * 10,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// Progress indicator widget for form steps
class ProgressIndicator extends StatelessWidget {
  const ProgressIndicator({
    super.key,
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

/// Main provider registration screen with Provider state management
class ProviderRegisterScreenProvider extends StatelessWidget {
  const ProviderRegisterScreenProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterProvider(),
      child: const _ProviderRegisterScreenProvider(),
    );
  }
}

class _ProviderRegisterScreenProvider extends StatefulWidget {
  const _ProviderRegisterScreenProvider();

  @override
  State<_ProviderRegisterScreenProvider> createState() =>
      _ProviderRegisterScreenProviderState();
}

class _ProviderRegisterScreenProviderState
    extends State<_ProviderRegisterScreenProvider> {
  @override
  void initState() {
    super.initState();
    // Check for draft and show restoration dialog if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowDraftDialog();
    });
  }

  void _checkAndShowDraftDialog() {
    final provider = Provider.of<RegisterProvider>(context, listen: false);
    if (provider.hasDraft) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const DraftRestoreDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final responsivePadding = ResponsiveSpacing.getPadding(screenWidth);
    final buttonHeight = ResponsiveSpacing.getButtonHeight(screenWidth);
    final primary = Theme.of(context).colorScheme.primary;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
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
                    screenHeight - kToolbarHeight - responsivePadding * 2,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveSpacing.getContentWidth(screenWidth),
                  ),
                  child: Consumer<RegisterProvider>(
                    builder: (context, provider, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          // Responsive Headline
                          Text(
                            'Provider Account',
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

                          // Smart Form Toolbar
                          const SmartFormToolbar(),
                          const SizedBox(height: 16),

                          // Form Progress Indicator
                          const FormProgressIndicator(),
                          SizedBox(
                              height: ResponsiveSpacing.getFontSize(
                                  screenWidth, 16, 20, 24)),

                          // Responsive Progress Indicator
                          ProgressIndicator(
                            currentStep: provider.currentStep,
                            totalSteps: provider.totalSteps,
                          ),
                          SizedBox(
                              height: ResponsiveSpacing.getFontSize(
                                  screenWidth, 24, 28, 32)),

                          // Step Content
                          _buildCurrentStep(context, provider),

                          SizedBox(
                              height: ResponsiveSpacing.getFontSize(
                                  screenWidth, 24, 28, 32)),

                          // Error message
                          if (provider.errors['general'] != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      provider.errors['general']!,
                                      style: GoogleFonts.poppins(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Responsive Navigation Buttons
                          _buildNavigationButtons(
                              context, provider, primary, buttonHeight),

                          // Keyboard avoidance padding
                          SizedBox(
                            height: MediaQuery.of(context).viewInsets.bottom > 0
                                ? MediaQuery.of(context).viewInsets.bottom + 20
                                : 0,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, RegisterProvider provider) {
    switch (provider.currentStep) {
      case 1:
        return _Step1PersonalInfo(provider: provider);
      case 2:
        return _Step2ProfessionalInfo(provider: provider);
      case 3:
        return _Step3Availability(provider: provider);
      case 4:
        return _Step4Password(provider: provider);
      default:
        return Container();
    }
  }

  Widget _buildNavigationButtons(BuildContext context,
      RegisterProvider provider, Color primary, double buttonHeight) {
    return Row(
      children: [
        // Previous Button
        if (provider.canGoPrevious)
          Expanded(
            child: Container(
              height: buttonHeight,
              margin: const EdgeInsets.only(right: 12),
              child: ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.goToPreviousStep(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: primary,
                  side: BorderSide(color: primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      )
                    : Text(
                        'Previous',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),

        // Next/Submit Button
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: ElevatedButton(
              onPressed: (provider.isLoading || !provider.canGoNext)
                  ? null
                  : provider.currentStep == provider.totalSteps
                      ? () => _submitForm(context, provider)
                      : () => provider.goToNextStep(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: primary.withValues(alpha: 0.2),
              ),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      provider.currentStep == provider.totalSteps
                          ? 'Register Now'
                          : 'Next',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm(
      BuildContext context, RegisterProvider provider) async {
    final success = await provider.registerProvider();

    if (success && context.mounted) {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SuccessScreen(),
          ),
        );
      }
    }
  }
}

/// Step 1: Personal Information
class _Step1PersonalInfo extends StatelessWidget {
  const _Step1PersonalInfo({required this.provider});

  final RegisterProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        // Full Name
        const FieldLabel(text: 'FULL NAME'),
        const SizedBox(height: 8),
        AnimatedTextField(
          controller: TextEditingController(text: provider.name),
          hint: 'Enter your full name',
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          focusNode: provider.focusNodes['name'],
          nextFocusNode: provider.focusNodes['email'],
          errorText: provider.errors['name'],
          isValid: provider.isNameValid,
          showValidationBorder: true,
          onChanged: (value) => provider.updateName(value),
        ),
        const SizedBox(height: 16),
        // Email
        const FieldLabel(text: 'EMAIL'),
        const SizedBox(height: 8),
        AnimatedTextField(
          controller: TextEditingController(text: provider.email),
          hint: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          focusNode: provider.focusNodes['email'],
          nextFocusNode: provider.focusNodes['phone'],
          errorText: provider.errors['email'],
          isValid: provider.isEmailValid,
          showValidationBorder: true,
          onChanged: (value) => provider.updateEmail(value),
        ),
        const SizedBox(height: 16),
        // Phone
        const FieldLabel(text: 'PHONE'),
        const SizedBox(height: 8),
        AnimatedTextField(
          controller: TextEditingController(text: provider.phone),
          hint: '03XX XXXXXXX',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          focusNode: provider.focusNodes['phone'],
          errorText: provider.errors['phone'],
          isValid: provider.isPhoneValid,
          showValidationBorder: true,
          onChanged: (value) => provider.updatePhone(value),
        ),
      ],
    );
  }
}

/// Step 2: Professional Information
class _Step2ProfessionalInfo extends StatelessWidget {
  const _Step2ProfessionalInfo({required this.provider});

  final RegisterProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        // Service Category
        const FieldLabel(text: 'SERVICE CATEGORY'),
        const SizedBox(height: 8),
        CategoryGrid(
          selectedCategory: provider.selectedCategory,
          onCategoryChanged: (category) => provider.updateCategory(category),
        ),
        if (provider.errors['category'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              provider.errors['category']!,
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 24),
        // Years of Experience
        const FieldLabel(text: 'YEARS OF EXPERIENCE'),
        const SizedBox(height: 8),
        AnimatedTextField(
          controller: TextEditingController(text: provider.years),
          hint: 'e.g. 5',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          focusNode: provider.focusNodes['years'],
          errorText: provider.errors['years'],
          isValid: provider.isYearsValid,
          showValidationBorder: true,
          onChanged: (value) => provider.updateYears(value),
        ),
      ],
    );
  }
}

/// Step 3: Availability
class _Step3Availability extends StatelessWidget {
  const _Step3Availability({required this.provider});

  final RegisterProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        // City
        const FieldLabel(text: 'CITY'),
        const SizedBox(height: 8),
        AnimatedTextField(
          controller: TextEditingController(text: provider.city),
          hint: 'Enter your city',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.next,
          focusNode: provider.focusNodes['city'],
          nextFocusNode: provider.focusNodes['area'],
          errorText: provider.errors['city'],
          isValid: provider.isCityValid,
          showValidationBorder: true,
          onChanged: (value) => provider.updateCity(value),
        ),
        const SizedBox(height: 16),
        // Area
        const FieldLabel(text: 'AREA'),
        const SizedBox(height: 8),
        AnimatedTextField(
          controller: TextEditingController(text: provider.area),
          hint: 'Enter your area',
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          focusNode: provider.focusNodes['area'],
          errorText: provider.errors['area'],
          isValid: provider.isAreaValid,
          showValidationBorder: true,
          onChanged: (value) => provider.updateArea(value),
        ),
      ],
    );
  }
}

/// Step 4: Password
class _Step4Password extends StatelessWidget {
  const _Step4Password({required this.provider});

  final RegisterProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        // Create New Password
        const FieldLabel(text: 'CREATE NEW PASSWORD'),
        const SizedBox(height: 8),
        AnimatedTextField(
          controller: TextEditingController(text: provider.password),
          hint: 'Enter password',
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.next,
          focusNode: provider.focusNodes['password'],
          nextFocusNode: provider.focusNodes['confirmPassword'],
          obscureText: true,
          errorText: provider.errors['password'],
          isValid: provider.isPasswordValid,
          showValidationBorder: true,
          onChanged: (value) => provider.updatePassword(value),
        ),
        const SizedBox(height: 16),
        // Confirm Password
        const FieldLabel(text: 'CONFIRM PASSWORD'),
        const SizedBox(height: 8),
        AnimatedTextField(
          controller: TextEditingController(text: provider.confirmPassword),
          hint: 'Confirm your password',
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          focusNode: provider.focusNodes['confirmPassword'],
          obscureText: true,
          errorText: provider.errors['confirmPassword'],
          isValid: provider.isConfirmPasswordValid,
          showValidationBorder: true,
          onChanged: (value) => provider.updateConfirmPassword(value),
        ),
        const SizedBox(height: 16),
        // Password requirements
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password Requirements:',
                style: GoogleFonts.poppins(
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
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          requirement,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
