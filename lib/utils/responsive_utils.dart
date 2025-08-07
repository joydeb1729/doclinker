import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isSmallScreen(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return screenHeight < 700 || screenWidth < 360;
  }

  static bool isMediumScreen(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenHeight >= 700 && screenHeight < 900) || 
           (screenWidth >= 360 && screenWidth < 600);
  }

  static bool isLargeScreen(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return screenHeight >= 900 || screenWidth >= 600;
  }

  // Responsive padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    final isSmall = isSmallScreen(context);
    return EdgeInsets.all(isSmall ? 16 : 20);
  }

  static EdgeInsets getCardPadding(BuildContext context) {
    final isSmall = isSmallScreen(context);
    return EdgeInsets.all(isSmall ? 12 : 16);
  }

  static EdgeInsets getButtonPadding(BuildContext context) {
    final isSmall = isSmallScreen(context);
    return EdgeInsets.symmetric(
      horizontal: isSmall ? 12 : 16,
      vertical: isSmall ? 6 : 8,
    );
  }

  // Responsive spacing
  static double getSpacing(BuildContext context, {double small = 8, double large = 12}) {
    final isSmall = isSmallScreen(context);
    return isSmall ? small : large;
  }

  static double getLargeSpacing(BuildContext context, {double small = 16, double large = 24}) {
    final isSmall = isSmallScreen(context);
    return isSmall ? small : large;
  }

  // Responsive font sizes
  static double getFontSize(BuildContext context, {
    double small = 12,
    double medium = 14,
    double large = 16,
  }) {
    if (isSmallScreen(context)) return small;
    if (isMediumScreen(context)) return medium;
    return large;
  }

  static double getTitleFontSize(BuildContext context, {
    double small = 16,
    double medium = 18,
    double large = 20,
  }) {
    if (isSmallScreen(context)) return small;
    if (isMediumScreen(context)) return medium;
    return large;
  }

  static double getHeaderFontSize(BuildContext context, {
    double small = 20,
    double medium = 22,
    double large = 24,
  }) {
    if (isSmallScreen(context)) return small;
    if (isMediumScreen(context)) return medium;
    return large;
  }

  // Responsive icon sizes
  static double getIconSize(BuildContext context, {
    double small = 16,
    double medium = 20,
    double large = 24,
  }) {
    if (isSmallScreen(context)) return small;
    if (isMediumScreen(context)) return medium;
    return large;
  }

  static double getAvatarSize(BuildContext context, {
    double small = 32,
    double medium = 40,
    double large = 48,
  }) {
    if (isSmallScreen(context)) return small;
    if (isMediumScreen(context)) return medium;
    return large;
  }

  // Responsive container sizes
  static double getContainerHeight(BuildContext context, {
    double small = 40,
    double medium = 48,
    double large = 56,
  }) {
    if (isSmallScreen(context)) return small;
    if (isMediumScreen(context)) return medium;
    return large;
  }

  // Text overflow handling
  static Text getResponsiveText(
    BuildContext context,
    String text, {
    TextStyle? style,
    int maxLines = 1,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextAlign textAlign = TextAlign.start,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  // Responsive SizedBox
  static SizedBox getVerticalSpacing(BuildContext context, {
    double small = 8,
    double large = 12,
  }) {
    return SizedBox(height: getSpacing(context, small: small, large: large));
  }

  static SizedBox getHorizontalSpacing(BuildContext context, {
    double small = 8,
    double large = 12,
  }) {
    return SizedBox(width: getSpacing(context, small: small, large: large));
  }
} 