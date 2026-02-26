import 'package:flutter/material.dart';

import '../theme/app_animations.dart';

/// Custom page route with combined fade + subtle vertical slide transition.
/// Drop-in replacement for [MaterialPageRoute]. Respects accessibility
/// settings via [AppAnimations.enabled].
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          transitionDuration: AppAnimations.pageTransition,
          reverseTransitionDuration: AppAnimations.pageTransition,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
              child: SlideTransition(
                position: slide,
                child: child,
              ),
            );
          },
        );
}
