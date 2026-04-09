import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domain/entities/quota.dart';

class PaceLabel extends StatelessWidget {
  const PaceLabel({super.key, required this.paceInfo});

  final PaceInfo paceInfo;

  static const String explanation =
      'Pace predicts total usage by the end of the current limit window based on the current rate.';

  @override
  Widget build(BuildContext context) {
    final isTouchLike =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            MediaQuery.sizeOf(context).width < 600);
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: paceInfo.predictedFinalPercent > 100
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final child = Text(
      'Pace ${paceInfo.predictedFinalPercent.round()}%',
      style: textStyle,
    );

    if (isTouchLike) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showExplanation(context),
        onLongPress: () => _showExplanation(context),
        child: child,
      );
    }

    return Tooltip(message: explanation, child: child);
  }

  void _showExplanation(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text(explanation)));
  }
}
