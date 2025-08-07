import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'responsive_utils.dart';

class CompactTextStyles {
  // Compact header styles
  static TextStyle? getCompactHeader(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: ResponsiveUtils.getHeaderFontSize(context),
    );
  }

  static TextStyle? getCompactTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      fontSize: ResponsiveUtils.getTitleFontSize(context),
    );
  }

  static TextStyle? getCompactSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: ResponsiveUtils.getFontSize(context, small: 14, large: 16),
    );
  }

  // Compact body styles
  static TextStyle? getCompactBody(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: ResponsiveUtils.getFontSize(context),
    );
  }

  static TextStyle? getCompactBodySmall(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: ResponsiveUtils.getFontSize(context, small: 11, large: 12),
    );
  }

  static TextStyle? getCompactBodySecondary(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTheme.textSecondary,
      fontSize: ResponsiveUtils.getFontSize(context, small: 10, large: 12),
    );
  }

  // Compact label styles
  static TextStyle? getCompactLabel(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium?.copyWith(
      fontSize: ResponsiveUtils.getFontSize(context, small: 11, large: 12),
    );
  }

  static TextStyle? getCompactLabelSmall(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: ResponsiveUtils.getFontSize(context, small: 9, large: 10),
    );
  }

  // Compact button styles
  static TextStyle? getCompactButton(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: ResponsiveUtils.getFontSize(context, small: 11, large: 12),
    );
  }

  // Compact status styles
  static TextStyle? getCompactStatus(BuildContext context, Color color) {
    return Theme.of(context).textTheme.labelSmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
      fontSize: ResponsiveUtils.getFontSize(context, small: 9, large: 10),
    );
  }

  // Compact time styles
  static TextStyle? getCompactTime(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTheme.textLight,
      fontSize: ResponsiveUtils.getFontSize(context, small: 10, large: 12),
    );
  }

  // Compact stat styles
  static TextStyle? getCompactStatValue(BuildContext context, Color color) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: color,
      fontSize: ResponsiveUtils.getFontSize(context, small: 18, large: 20),
    );
  }

  static TextStyle? getCompactStatLabel(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTheme.textSecondary,
      fontSize: ResponsiveUtils.getFontSize(context, small: 10, large: 12),
    );
  }

  // Compact menu styles
  static TextStyle? getCompactMenuItem(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: ResponsiveUtils.getFontSize(context, small: 14, large: 16),
    );
  }

  static TextStyle? getCompactMenuItemSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTheme.textSecondary,
      fontSize: ResponsiveUtils.getFontSize(context, small: 11, large: 12),
    );
  }

  // Compact card styles
  static TextStyle? getCompactCardTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: ResponsiveUtils.getFontSize(context, small: 14, large: 16),
    );
  }

  static TextStyle? getCompactCardSubtitle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTheme.textSecondary,
      fontSize: ResponsiveUtils.getFontSize(context, small: 11, large: 12),
    );
  }

  // Compact chat styles
  static TextStyle? getCompactChatMessage(BuildContext context, bool isUser) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: isUser ? Colors.white : AppTheme.textPrimary,
      fontSize: ResponsiveUtils.getFontSize(context),
    );
  }

  static TextStyle? getCompactChatTime(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTheme.textLight,
      fontSize: ResponsiveUtils.getFontSize(context, small: 10, large: 12),
    );
  }

  // Compact AI styles
  static TextStyle? getCompactAIMessage(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppTheme.textPrimary,
      fontStyle: FontStyle.italic,
      fontSize: ResponsiveUtils.getFontSize(context),
    );
  }

  static TextStyle? getCompactAIThinking(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppTheme.textSecondary,
      fontSize: ResponsiveUtils.getFontSize(context, small: 10, large: 12),
    );
  }
} 