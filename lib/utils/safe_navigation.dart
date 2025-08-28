import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Utility class to safely handle navigation and ref access
class SafeNavigation {
  /// Safely navigate using pushReplacement, ensuring proper context handling
  static void pushReplacement(
    BuildContext context,
    Widget destination, {
    bool mounted = true,
  }) {
    if (!mounted) return;

    // Use a post-frame callback to ensure navigation happens after
    // any pending widget updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => destination));
      }
    });
  }

  /// Safely navigate using pushAndRemoveUntil
  static void pushAndRemoveUntil(
    BuildContext context,
    Widget destination, {
    bool mounted = true,
  }) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => destination),
          (route) => false,
        );
      }
    });
  }

  /// Safely access ref with proper error handling
  static T? safeReadRef<T>(WidgetRef? ref, ProviderListenable<T> provider) {
    try {
      return ref?.read(provider);
    } catch (e) {
      debugPrint('Error reading ref: $e');
      return null;
    }
  }
}

/// Extension to add context mounted check
extension BuildContextExtensions on BuildContext {
  /// Check if the widget is still mounted
  bool get isMounted {
    try {
      widget;
      return true;
    } catch (e) {
      return false;
    }
  }
}
