import 'package:flutter/material.dart';

import '../theme/app_animations.dart';

/// Custom page route with combined fade + subtle vertical slide transition.
/// Extends [MaterialPageRoute] to preserve platform back-gesture behavior
/// (iOS swipe-back, Android predictive back) while applying a custom animation.
class AppPageRoute<T> extends MaterialPageRoute<T> {
  AppPageRoute({
    required super.builder,
    super.settings,
    super.fullscreenDialog,
  });

  @override
  Duration get transitionDuration => AppAnimations.pageTransition;

  @override
  Duration get reverseTransitionDuration => AppAnimations.pageTransition;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!AppAnimations.enabled(context)) {
      return child;
    }
    // Use drive() instead of CurvedAnimation to avoid listener leaks.
    final fade = animation.drive(
      CurveTween(curve: AppAnimations.emphasizedCurve),
    );
    final slide = animation.drive(
      Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).chain(CurveTween(curve: AppAnimations.emphasizedCurve)),
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
