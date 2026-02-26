import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Centralized animation constants aligned with MD3 motion guidelines.
/// See: https://m3.material.io/styles/motion/overview
class AppAnimations {
  AppAnimations._();

  // -- Durations --
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 300);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration fabScale = Duration(milliseconds: 180);
  // Per-role message entrance durations (WS4 bubble motion).
  static const Duration userBubble = Duration(milliseconds: 130);
  static const Duration assistantBubble = Duration(milliseconds: 180);

  // -- Stagger --
  static const Duration staggerDelay = Duration(milliseconds: 35);
  static const int maxStaggerItems = 8;

  // -- Curves --
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Easing.emphasizedDecelerate;
  static const Curve decelerateCurve = Curves.easeOut;
  static const Curve accelerateCurve = Curves.easeIn;
  static const Curve fabCurve = Curves.easeOutBack;

  /// Whether animations should play in the current context.
  /// Returns false when the platform or user has requested reduced motion.
  static bool enabled(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq != null && mq.disableAnimations) {
      return false;
    }
    return !ui.PlatformDispatcher.instance.accessibilityFeatures
        .disableAnimations;
  }
}
