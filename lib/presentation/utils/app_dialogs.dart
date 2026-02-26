import 'package:flutter/material.dart';

import '../theme/app_animations.dart';

/// Shows a dialog with a scale (0.92 -> 1.0) + fade transition.
/// Drop-in replacement for [showDialog] for high-visibility dialogs.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel ??
        MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: AppAnimations.emphasized,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      if (!AppAnimations.enabled(context)) {
        return child;
      }
      // Use drive() instead of CurvedAnimation to avoid listener leaks.
      final fade = animation.drive(
        CurveTween(curve: AppAnimations.emphasizedCurve),
      );
      final scale = animation.drive(
        Tween<double>(begin: 0.92, end: 1.0).chain(
          CurveTween(curve: AppAnimations.emphasizedCurve),
        ),
      );
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: scale,
          child: child,
        ),
      );
    },
  );
}
