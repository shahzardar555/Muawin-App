/// Profile screen constants extracted from service_provider_profile_screen.dart
/// Contains all UI constants for better maintainability and consistency

library profile_constants;

import 'package:flutter/material.dart';

/// Spacing Constants
class ProfileSpacing {
  // Main spacing values
  static const double majorSectionSpacing = 32.0;
  static const double subSectionSpacing = 24.0;
  static const double relatedItemSpacing = 16.0;
  static const double tightSpacing = 12.0;
  static const double compactSpacing = 8.0;
  static const double microSpacing = 4.0;

  // Responsive spacing
  static double responsiveSubSpacing(BuildContext context) =>
      MediaQuery.of(context).size.width < 600
          ? compactSpacing
          : subSectionSpacing;
  static double responsiveCompactSpacing(BuildContext context) =>
      MediaQuery.of(context).size.width < 600 ? microSpacing : tightSpacing;
}

/// UI Dimensions
class ProfileDimensions {
  // Avatar and image dimensions
  static const double avatarSize = 90.0;
  static const double avatarBorderRadius = 24.0;
  static const double avatarClipRadius = 21.0;
  static const double avatarBorderWidth = 3.0;

  // Card dimensions
  static const double cardBorderRadiusMobile = 12.0;
  static const double cardBorderRadiusDesktop = 16.0;
  static const double cardElevationMobile = 2.0;
  static const double cardElevationDesktop = 4.0;

  // Dialog dimensions
  static const double dialogWidth = 400.0;
  static const double dialogHeight = 600.0;
  static const double dialogMobileWidth = 350.0;
  static const double dialogMobileHeight = 500.0;

  // Button dimensions
  static const double buttonHeight = 48.0;
  static const double buttonBorderRadius = 12.0;
  static const double iconButtonSize = 24.0;

  // Input field dimensions
  static const double inputFieldHeight = 56.0;
  static const double inputFieldBorderRadius = 8.0;

  // Skeleton loading dimensions
  static const double skeletonAvatarWidth = 90.0;
  static const double skeletonAvatarHeight = 90.0;
  static const double skeletonNameWidth = 150.0;
  static const double skeletonNameHeight = 20.0;
  static const double skeletonStatusWidth = 100.0;
  static const double skeletonStatusHeight = 16.0;
  static const double skeletonHeaderWidth = 120.0;
  static const double skeletonHeaderHeight = 12.0;
  static const double skeletonIconSize = 48.0;
  static const double skeletonIconSizeMobile = 64.0;
}

/// Color Constants
class ProfileColors {
  // Status colors
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;

  // Gradient colors
  static const Color primaryGradient = Color(0xFF047A62);
  static const Color primaryGradientLight = Color(0xFF047A62);

  // Rating and review colors
  static const Color starColor = Color(0xFFFBBF24);
  static const Color ratingBackground = Color(0xFFF3F4F6);

  // Background colors
  static const Color cardBackground = Colors.white;
  static const Color skeletonBackground = Colors.grey;
  static const Color surfaceBackground = Color(0xFFF9FAFB);

  // Border colors
  static const Color borderColor = Colors.grey;
  static const Color borderLight = Color(0xFFE5E7EB);

  // Text colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.grey;
  static const Color textTertiary = Colors.grey;
  static const Color textWhite = Colors.white;

  // Alpha transparency values
  static double primaryAlpha(double alpha) => alpha;
  static double shadowAlpha(double alpha) => alpha;
  static double backgroundAlpha(double alpha) => alpha;
}

/// Typography Constants
class ProfileTypography {
  // Font sizes
  static const double titleSizeMobile = 22.0;
  static const double titleSizeDesktop = 24.0;
  static const double subtitleSize = 16.0;
  static const double bodySize = 14.0;
  static const double captionSize = 12.0;
  static const double smallSize = 11.0;
  static const double tinySize = 10.0;

  // Font weights
  static const FontWeight boldWeight = FontWeight.w700;
  static const FontWeight semiBoldWeight = FontWeight.w600;
  static const FontWeight mediumWeight = FontWeight.w500;
  static const FontWeight regularWeight = FontWeight.w400;

  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 18.0;
  static const double iconSizeLarge = 24.0;
  static const double iconSizeXLarge = 48.0;
  static const double iconSizeXXLarge = 64.0;

  // Responsive icon sizes
  static double responsiveIconSize(
          BuildContext context, double mobileSize, double desktopSize) =>
      MediaQuery.of(context).size.width < 600 ? mobileSize : desktopSize;
}

/// Animation Constants
class ProfileAnimations {
  // Durations
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration successAnimationDuration = Duration(milliseconds: 800);
  static const Duration dialogTransitionDuration = Duration(milliseconds: 300);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 200);

  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve dialogCurve = Curves.easeOutCubic;
  static const Curve buttonCurve = Curves.elasticOut;

  // Values
  static const double shimmerBaseOpacity = 0.3;
  static const double shimmerHighlightOpacity = 0.1;
  static const double successAnimationScale = 1.1;
}

/// Touch Target Constants
class ProfileTouchTargets {
  // Minimum touch sizes
  static const double minTouchTargetMobile = 44.0;
  static const double minTouchTargetDesktop = 40.0;

  // Gesture sensitivity
  static const double panSensitivity = 100.0;
  static const double sliderStepSize = 10.0;

  // Responsive getters
  static double minTouchTarget(BuildContext context) =>
      MediaQuery.of(context).size.width < 600
          ? minTouchTargetMobile
          : minTouchTargetDesktop;
}

/// Responsive Breakpoints
class ProfileBreakpoints {
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1440.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;
}

/// Utility getters for commonly used responsive values
class ProfileUtils {
  static double cardBorderRadius(BuildContext context) =>
      ProfileBreakpoints.isMobile(context)
          ? ProfileDimensions.cardBorderRadiusMobile
          : ProfileDimensions.cardBorderRadiusDesktop;

  static double cardElevation(BuildContext context) =>
      ProfileBreakpoints.isMobile(context)
          ? ProfileDimensions.cardElevationMobile
          : ProfileDimensions.cardElevationDesktop;

  static double titleFontSize(BuildContext context) =>
      ProfileBreakpoints.isMobile(context)
          ? ProfileTypography.titleSizeMobile
          : ProfileTypography.titleSizeDesktop;

  static EdgeInsets responsivePadding(BuildContext context) {
    if (ProfileBreakpoints.isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }

  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    if (ProfileBreakpoints.isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    }
  }
}
