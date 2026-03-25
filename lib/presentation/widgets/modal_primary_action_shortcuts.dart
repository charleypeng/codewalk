import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Adds Enter/NumpadEnter shortcuts to modal content with an explicit primary action.
class ModalPrimaryActionShortcuts extends StatelessWidget {
  const ModalPrimaryActionShortcuts({
    super.key,
    required this.child,
    required this.onPrimaryAction,
    this.enabled = true,
    this.autofocus = false,
  });

  final Widget child;
  final VoidCallback onPrimaryAction;
  final bool enabled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final wrappedChild = autofocus
        ? Focus(autofocus: true, canRequestFocus: true, child: child)
        : child;
    if (!enabled) {
      return wrappedChild;
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): onPrimaryAction,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): onPrimaryAction,
      },
      child: wrappedChild,
    );
  }
}
