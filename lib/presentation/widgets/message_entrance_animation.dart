import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import '../theme/app_animations.dart';

/// One-shot entrance animation with role-specific motion profiles.
///
/// User role: 130ms, easeOut, Y slide (-6px→0) + scale (0.98→1.0) + fade.
/// Feels launched from the composer.
///
/// Assistant/tool/null: 180ms, easeOutCubic, Y slide (-8px→0) + fade only.
/// Calm and readable entrance.
///
/// After completion, build returns the raw [child] with zero overhead
/// to preserve downstream widget caches (e.g. ChatMessageWidget).
class MessageEntranceAnimation extends StatefulWidget {
  const MessageEntranceAnimation({
    super.key,
    required this.child,
    this.animate = true,
    this.role,
  });

  final Widget child;

  /// When false, the child is rendered immediately without any animation.
  final bool animate;

  /// Determines which motion profile to apply.
  /// - [MessageRole.user]: fast, with subtle scale (composer-launch feel).
  /// - Other / null: slower, no scale (calm assistant entrance).
  final MessageRole? role;

  @override
  State<MessageEntranceAnimation> createState() =>
      _MessageEntranceAnimationState();
}

class _MessageEntranceAnimationState extends State<MessageEntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double>? _scaleAnimation;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _completed = true;
    }
    final isUser = widget.role == MessageRole.user;
    final duration =
        isUser ? AppAnimations.userBubble : AppAnimations.assistantBubble;
    final curve =
        isUser ? AppAnimations.decelerateCurve : AppAnimations.standardCurve;
    // User: -6px upward; assistant/tool: -8px upward (fractional offset).
    // SlideTransition uses a fraction of widget size, so approximate with
    // a fixed small Offset that works well across typical bubble heights.
    final slideBegin = isUser ? const Offset(0, -0.035) : const Offset(0, 0.04);

    // Always create the controller (required by SingleTickerProviderStateMixin).
    _controller = AnimationController(vsync: this, duration: duration);
    _curved = _controller.drive(CurveTween(curve: curve));
    _slideAnimation = _controller.drive(
      Tween<Offset>(begin: slideBegin, end: Offset.zero).chain(
        CurveTween(curve: curve),
      ),
    );
    // Scale only for user bubbles (0.98 → 1.0).
    _scaleAnimation = isUser
        ? _controller.drive(
            Tween<double>(begin: 0.98, end: 1.0).chain(
              CurveTween(curve: curve),
            ),
          )
        : null;
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

    Widget animated = FadeTransition(
      opacity: _curved,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );

    // Wrap with scale only for user role.
    if (_scaleAnimation != null) {
      animated = ScaleTransition(scale: _scaleAnimation!, child: animated);
    }

    return animated;
  }
}
