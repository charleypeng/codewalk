import 'package:flutter/material.dart';

import '../theme/app_animations.dart';

/// One-shot entrance animation: fade + 4% Y slide on initState.
/// After completion, build returns the raw [child] with zero overhead
/// to preserve downstream widget caches (e.g. ChatMessageWidget).
class MessageEntranceAnimation extends StatefulWidget {
  const MessageEntranceAnimation({
    super.key,
    required this.child,
    this.animate = true,
  });

  final Widget child;

  /// When false, the child is rendered immediately without any animation.
  final bool animate;

  @override
  State<MessageEntranceAnimation> createState() =>
      _MessageEntranceAnimationState();
}

class _MessageEntranceAnimationState extends State<MessageEntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;
  late final Animation<Offset> _slideAnimation;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _completed = true;
    }
    // Always create the controller (required by SingleTickerProviderStateMixin).
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );
    // Create derived animations once to avoid CurvedAnimation leak per build.
    _curved = _controller.drive(CurveTween(curve: AppAnimations.standardCurve));
    _slideAnimation = _controller.drive(
      Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).chain(CurveTween(curve: AppAnimations.standardCurve)),
    );
    if (!_completed) {
      _controller.addStatusListener(_onAnimationStatus);
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        _completed = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start the animation only once, after dependencies are available
    // so we can check accessibility settings.
    if (!_completed && _controller.value == 0) {
      if (!AppAnimations.enabled(context)) {
        setState(() {
          _completed = true;
        });
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _curved,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
