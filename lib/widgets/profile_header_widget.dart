/// Profile header widget extracted from service_provider_profile_screen.dart
/// Contains profile avatar, name, verification status, and rating display

library profile_header_widget;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/profile_constants.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String providerName;
  final String? profileImagePath;
  final Uint8List? profileImageBytes;
  final String? coverPhotoPath;
  final bool isCNICVerified;
  final double rating;
  final int reviewCount;
  final bool showProfileSuccessAnimation;
  final bool isMobile;
  final VoidCallback onPickProfileImage;
  final VoidCallback onEditName;
  final Widget Function() buildProfileImageWidget;

  const ProfileHeaderWidget({
    super.key,
    required this.providerName,
    this.profileImagePath,
    this.profileImageBytes,
    this.coverPhotoPath,
    required this.isCNICVerified,
    required this.rating,
    required this.reviewCount,
    required this.showProfileSuccessAnimation,
    required this.isMobile,
    required this.onPickProfileImage,
    required this.onEditName,
    required this.buildProfileImageWidget,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        // Main Header Container
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 20,
            bottom: 40,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Interactive Avatar Squircle
                GestureDetector(
                  onTap: onPickProfileImage,
                  child: Container(
                    width: ProfileDimensions.avatarSize,
                    height: ProfileDimensions.avatarSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                          ProfileDimensions.avatarBorderRadius),
                      border: Border.all(
                          color: Colors.white,
                          width: ProfileDimensions.avatarBorderWidth),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          ProfileDimensions.avatarClipRadius),
                      child: buildProfileImageWidget(),
                    ),
                  ),
                ),

                SizedBox(height: ProfileSpacing.responsiveSubSpacing(context)),

                // Editable Provider Name with Verification Status
                GestureDetector(
                  onTap: onEditName,
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            providerName,
                            style: GoogleFonts.poppins(
                              fontSize: ProfileUtils.titleFontSize(context),
                              fontWeight: ProfileTypography.boldWeight,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit,
                            color: Colors.white.withValues(alpha: 0.7),
                            size: ProfileTypography.iconSizeMedium,
                          ),
                        ],
                      ),

                      const SizedBox(height: ProfileSpacing.compactSpacing),

                      // Verification Status Badge (Priority Info)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              ProfileSpacing.responsiveCompactSpacing(context),
                          vertical: ProfileSpacing.microSpacing,
                        ),
                        decoration: BoxDecoration(
                          color: isCNICVerified
                              ? ProfileColors.successColor
                                  .withValues(alpha: 0.9)
                              : ProfileColors.warningColor
                                  .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCNICVerified
                                  ? Icons.verified_user
                                  : Icons.pending_actions,
                              size: ProfileTypography.responsiveIconSize(
                                  context, 14, 16),
                              color: Colors.white,
                            ),
                            const SizedBox(width: ProfileSpacing.microSpacing),
                            Text(
                              isCNICVerified ? 'Verified' : 'Pending',
                              style: GoogleFonts.poppins(
                                fontSize: ProfileTypography.responsiveIconSize(
                                    context, 11, 12),
                                fontWeight: ProfileTypography.semiBoldWeight,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: ProfileColors.starColor),
                      const SizedBox(width: 4),
                      Text(
                        '$rating ($reviewCount reviews)',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: ProfileTypography.semiBoldWeight,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
