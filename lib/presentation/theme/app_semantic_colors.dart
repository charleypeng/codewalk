import 'package:flutter/material.dart';

/// Centralized semantic status colors for shared success treatments.
class AppSemanticColors {
  AppSemanticColors._();

  static Color success(BuildContext context) {
    return successForBrightness(Theme.of(context).brightness);
  }

  static Color successContainer(BuildContext context) {
    return successContainerForBrightness(Theme.of(context).brightness);
  }

  static Color successForBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade700;
  }

  static Color successContainerForBrightness(Brightness brightness) {
    return brightness == Brightness.dark
        ? Colors.green.shade800.withValues(alpha: 0.45)
        : Colors.green.shade100;
  }
}
