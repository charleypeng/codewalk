import 'package:flutter/material.dart';

class SidebarSelectionIndicator extends StatelessWidget {
  const SidebarSelectionIndicator({
    super.key,
    required this.selected,
    required this.child,
    this.padding = const EdgeInsetsDirectional.only(start: 8),
    this.top = 8,
    this.bottom = 8,
    this.width = 3,
  });

  final bool selected;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double top;
  final double bottom;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Padding(padding: padding, child: child),
        if (selected)
          PositionedDirectional(
            start: 0,
            top: top,
            bottom: bottom,
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}
