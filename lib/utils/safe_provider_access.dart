import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Safe wrapper for accessing Riverpod providers to prevent type casting errors
class SafeProviderAccess {
  /// Safely access a provider with error handling
  static T? safeRead<T>(WidgetRef? ref, ProviderListenable<T> provider) {
    try {
      if (ref == null) {
        debugPrint('SafeProviderAccess: ref is null');
        return null;
      }
      return ref.read(provider);
    } catch (e, stackTrace) {
      debugPrint('SafeProviderAccess: Error reading provider: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Safely watch a provider with error handling
  static T? safeWatch<T>(WidgetRef? ref, ProviderListenable<T> provider) {
    try {
      if (ref == null) {
        debugPrint('SafeProviderAccess: ref is null');
        return null;
      }
      return ref.watch(provider);
    } catch (e, stackTrace) {
      debugPrint('SafeProviderAccess: Error watching provider: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Check if a context is properly mounted and can access providers
  static bool canAccessProviders(BuildContext context) {
    try {
      // Try to find the nearest ProviderScope
      ProviderScope.containerOf(context, listen: false);
      return true;
    } catch (e) {
      debugPrint('SafeProviderAccess: Cannot access providers: $e');
      return false;
    }
  }
}

/// Extension to add safe provider access to ConsumerState
extension SafeConsumerState<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Safely read a provider with mounted check
  R? safeRead<R>(ProviderListenable<R> provider) {
    if (!mounted) {
      debugPrint('SafeConsumerState: Widget not mounted');
      return null;
    }

    try {
      return ref.read(provider);
    } catch (e, stackTrace) {
      debugPrint('SafeConsumerState: Error reading provider: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Safely watch a provider with mounted check
  R? safeWatch<R>(ProviderListenable<R> provider) {
    if (!mounted) {
      debugPrint('SafeConsumerState: Widget not mounted');
      return null;
    }

    try {
      return ref.watch(provider);
    } catch (e, stackTrace) {
      debugPrint('SafeConsumerState: Error watching provider: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
}

/// Mixin to add safe navigation capabilities
mixin SafeNavigationMixin<T extends StatefulWidget> on State<T> {
  /// Safely navigate with mounted check
  void safeNavigate(VoidCallback navigation) {
    if (!mounted) {
      debugPrint(
        'SafeNavigationMixin: Widget not mounted, skipping navigation',
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        navigation();
      }
    });
  }

  /// Safely show dialog with mounted check
  void safeShowDialog(WidgetBuilder builder) {
    if (!mounted) {
      debugPrint('SafeNavigationMixin: Widget not mounted, skipping dialog');
      return;
    }

    showDialog(context: context, builder: builder);
  }

  /// Safely show snackbar with mounted check
  void safeShowSnackBar(SnackBar snackBar) {
    if (!mounted) {
      debugPrint('SafeNavigationMixin: Widget not mounted, skipping snackbar');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
