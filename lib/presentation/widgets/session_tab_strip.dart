import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/i18n/l10n_context.dart';
import '../../core/utils/path_utils.dart';
import '../../domain/entities/chat_realtime.dart';
import '../../domain/entities/project.dart';
import '../providers/chat_provider.dart';
import 'project_icon.dart';

/// Height of the tab strip, also used by the integrated window chrome so the
/// title bar band and the strip stay aligned.
const double kSessionTabStripHeight = 54;
const double kSessionTabStripHeightCompact = 58;

/// Horizontal room each tab gives to its curved shoulders.
const double _kTabShoulder = 14;

/// Radius of the tab's top corners.
const double _kTabTopRadius = 10;

/// How long a tapped tab keeps its close button visible on touch devices.
const Duration _kTouchCloseReveal = Duration(seconds: 3);

/// Browser-style tab silhouette: the sides flare outwards at the bottom so the
/// tab reads as a tab instead of a rounded rectangle, and neighbours interlock.
class _ChromeTabBorder extends ShapeBorder {
  const _ChromeTabBorder();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const shoulder = _kTabShoulder;
    const r = _kTabTopRadius;
    // The shoulder curve stops short of the top edge so a proper rounded
    // corner can take over; going straight to the top made the corners read
    // as sharp next to the soft flare below them.
    return Path()
      ..moveTo(rect.left, rect.bottom)
      ..cubicTo(
        rect.left + shoulder * 0.55,
        rect.bottom,
        rect.left + shoulder * 0.42,
        rect.top + r,
        rect.left + shoulder,
        rect.top + r,
      )
      ..arcToPoint(
        Offset(rect.left + shoulder + r, rect.top),
        radius: const Radius.circular(r),
      )
      ..lineTo(rect.right - shoulder - r, rect.top)
      ..arcToPoint(
        Offset(rect.right - shoulder, rect.top + r),
        radius: const Radius.circular(r),
      )
      ..cubicTo(
        rect.right - shoulder * 0.42,
        rect.top + r,
        rect.right - shoulder * 0.55,
        rect.bottom,
        rect.right,
        rect.bottom,
      )
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

String sessionTabIdentityKey(SessionTabIdentity identity) {
  return '${identity.serverId}::${identity.directory}::${identity.sessionId}';
}

class SessionTabStrip extends StatefulWidget {
  const SessionTabStrip({
    super.key,
    required this.tabs,
    required this.projects,
    required this.openProjectIds,
    required this.isCompact,
    required this.onActivate,
    required this.onClose,
    this.fillWidth = true,
    this.transparentBackground = false,
  });

  final List<SessionTabRecord> tabs;
  final List<Project> projects;
  final Set<String> openProjectIds;
  final bool isCompact;

  /// When false the strip sizes itself to its tabs instead of expanding, so the
  /// integrated window chrome can use the leftover space as a drag region.
  final bool fillWidth;

  /// When true the strip paints no band of its own, so it blends into the
  /// surface behind it. The integrated window chrome already paints that band;
  /// standing alone under the app bar the strip still needs its own.
  final bool transparentBackground;
  final ValueChanged<SessionTabRecord> onActivate;
  final ValueChanged<SessionTabRecord> onClose;

  @override
  State<SessionTabStrip> createState() => _SessionTabStripState();
}

class _SessionTabStripState extends State<SessionTabStrip> {
  final ScrollController _scrollController = ScrollController();
  final Map<SessionTabIdentity, GlobalKey> _tabKeys =
      <SessionTabIdentity, GlobalKey>{};
  final Map<SessionTabIdentity, FocusNode> _tabFocusNodes =
      <SessionTabIdentity, FocusNode>{};
  SessionTabIdentity? _hoveredIdentity;
  SessionTabIdentity? _touchRevealedIdentity;
  Timer? _touchRevealTimer;
  SessionTabIdentity? _lastSelectedIdentity;
  double? _lastViewportWidth;
  bool _ensureVisibleScheduled = false;

  @override
  void didUpdateWidget(covariant SessionTabStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final identities = widget.tabs.map((tab) => tab.identity).toSet();
    // A closed tab never gets a pointer-exit, so drop reveal state that points
    // at a tab which no longer exists.
    if (_hoveredIdentity != null && !identities.contains(_hoveredIdentity)) {
      _hoveredIdentity = null;
    }
    if (_touchRevealedIdentity != null &&
        !identities.contains(_touchRevealedIdentity)) {
      _touchRevealTimer?.cancel();
      _touchRevealedIdentity = null;
    }
    _tabKeys.removeWhere((identity, _) => !identities.contains(identity));
    final removedFocusNodes = _tabFocusNodes.entries
        .where((entry) => !identities.contains(entry.key))
        .toList(growable: false);
    for (final entry in removedFocusNodes) {
      _tabFocusNodes.remove(entry.key);
      entry.value.dispose();
    }
  }

  @override
  void dispose() {
    _touchRevealTimer?.cancel();
    _scrollController.dispose();
    for (final focusNode in _tabFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectedIdentity = _selectedIdentity();
        if (selectedIdentity != _lastSelectedIdentity ||
            constraints.maxWidth != _lastViewportWidth) {
          _lastSelectedIdentity = selectedIdentity;
          _lastViewportWidth = constraints.maxWidth;
          _scheduleEnsureSelectedVisible(selectedIdentity);
        }

        return Container(
          key: const ValueKey<String>('session_tab_strip'),
          height: widget.isCompact
              ? kSessionTabStripHeightCompact
              : kSessionTabStripHeight,
          width: widget.fillWidth ? double.infinity : null,
          // No bottom border: the selected tab reaches the strip edge and
          // merges with the content panel below, like a browser tab.
          decoration: BoxDecoration(
            color: widget.transparentBackground
                ? Colors.transparent
                : colorScheme.surfaceContainerHigh,
          ),
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: !widget.isCompact,
              interactive: !widget.isCompact,
              child: SingleChildScrollView(
                key: const ValueKey<String>('session_tab_strip_scroll_view'),
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsetsDirectional.fromSTEB(
                  widget.isCompact ? 6 : 8,
                  4,
                  widget.isCompact ? 6 : 8,
                  0,
                ),
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < widget.tabs.length;
                      index++
                    ) ...[
                      if (index > 0) const SizedBox(width: 2),
                      _buildTab(context, widget.tabs[index]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _setHovered(SessionTabIdentity? identity) {
    if (!mounted || _hoveredIdentity == identity) {
      return;
    }
    setState(() => _hoveredIdentity = identity);
  }

  /// Touch devices have no hover, so tapping a tab reveals its close button
  /// for a short while instead of showing it permanently.
  void _revealCloseForTouch(SessionTabIdentity identity) {
    _touchRevealTimer?.cancel();
    if (mounted) {
      setState(() => _touchRevealedIdentity = identity);
    }
    _touchRevealTimer = Timer(_kTouchCloseReveal, () {
      if (mounted) {
        setState(() => _touchRevealedIdentity = null);
      }
    });
  }

  Widget _buildTab(BuildContext context, SessionTabRecord tab) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = tab.title.trim().isEmpty
        ? context.l10n.sessionExportUntitled
        : tab.title.trim();
    final key = sessionTabIdentityKey(tab.identity);
    final selected = tab.isSelected;
    final project = _projectForTab(tab);
    const radius = BorderRadius.vertical(top: Radius.circular(10));
    final foreground = selected
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;
    final hovered = _hoveredIdentity == tab.identity;
    // Pointer devices reveal the close button on hover; touch devices reveal it
    // for a few seconds after the tab is tapped. Either way the title keeps the
    // extra width the rest of the time.
    final showClose = widget.isCompact
        ? _touchRevealedIdentity == tab.identity
        : hovered;

    return MouseRegion(
      onEnter: (_) => _setHovered(tab.identity),
      onExit: (_) => _setHovered(null),
      child: SizedBox(
        key: _tabKeys.putIfAbsent(tab.identity, GlobalKey.new),
        width: widget.isCompact ? 214 : 244,
        child: Material(
          key: ValueKey<String>('session_tab_$key'),
          // The selected tab shares the content surface colour, which is what
          // creates the visual continuity with the chat panel underneath. No
          // border on any side: a bottom stroke would draw a hairline between
          // the tab and the content it is supposed to be joined to.
          color: selected
              ? colorScheme.surface
              : hovered
              ? colorScheme.surface.withValues(alpha: 0.45)
              : Colors.transparent,
          shape: const _ChromeTabBorder(),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: selected,
                        label: _semanticLabel(context, tab, title),
                        onTap: () => widget.onActivate(tab),
                        child: Tooltip(
                          message: title,
                          excludeFromSemantics: true,
                          child: ExcludeSemantics(
                            child: InkWell(
                              key: ValueKey<String>(
                                'session_tab_activate_$key',
                              ),
                              focusNode: _tabFocusNodes.putIfAbsent(
                                tab.identity,
                                () => FocusNode(debugLabel: 'Session tab $key'),
                              ),
                              borderRadius: radius,
                              overlayColor:
                                  WidgetStateProperty.resolveWith<Color?>((
                                    states,
                                  ) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return colorScheme.primary.withValues(
                                        alpha: 0.18,
                                      );
                                    }
                                    if (states.contains(WidgetState.focused)) {
                                      return colorScheme.primary.withValues(
                                        alpha: 0.14,
                                      );
                                    }
                                    if (states.contains(WidgetState.hovered)) {
                                      return colorScheme.primary.withValues(
                                        alpha: 0.09,
                                      );
                                    }
                                    return null;
                                  }),
                              onTap: () {
                                if (widget.isCompact) {
                                  _revealCloseForTouch(tab.identity);
                                }
                                widget.onActivate(tab);
                              },
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: Center(
                                          child: _buildLeading(
                                            context,
                                            tab,
                                            project,
                                            title,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          title,
                                          key: ValueKey<String>(
                                            'session_tab_title_$key',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: foreground,
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      if (tab.isBusy) ...[
                                        const SizedBox(width: 6),
                                        Icon(
                                          Symbols.sync_rounded,
                                          key: ValueKey<String>(
                                            'session_tab_busy_${tab.status.name}_$key',
                                          ),
                                          size: 17,
                                          color:
                                              tab.status ==
                                                  SessionStatusType.retry
                                              ? colorScheme.tertiary
                                              : colorScheme.primary,
                                        ),
                                      ],
                                      const SizedBox(width: 2),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!showClose)
                      const SizedBox(width: _kTabShoulder)
                    else
                      Semantics(
                        button: true,
                        label: context.l10n.chatClose,
                        onTap: () => _handleClose(tab),
                        child: ExcludeSemantics(
                          child: IconButton(
                            key: ValueKey<String>('session_tab_close_$key'),
                            tooltip: context.l10n.chatClose,
                            // A full 48px splash swamped the tab and clashed
                            // with its curved shoulders; the tap target stays
                            // comfortable on touch, tighter with a pointer.
                            constraints: BoxConstraints.tightFor(
                              width: widget.isCompact ? 40 : 26,
                              height: widget.isCompact ? 40 : 26,
                            ),
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            color: foreground,
                            icon: const Icon(Symbols.close_rounded),
                            onPressed: () => _handleClose(tab),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(
    BuildContext context,
    SessionTabRecord tab,
    Project? project,
    String title,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final key = sessionTabIdentityKey(tab.identity);
    if (tab.hasUnseenError) {
      return _attentionIcon(
        key: ValueKey<String>('session_tab_leading_error_$key'),
        icon: Symbols.error,
        background: colorScheme.errorContainer,
        foreground: colorScheme.onErrorContainer,
      );
    }
    if (tab.hasUnseenQuestion) {
      return _attentionIcon(
        key: ValueKey<String>('session_tab_leading_question_$key'),
        icon: Symbols.help,
        background: colorScheme.tertiaryContainer,
        foreground: colorScheme.onTertiaryContainer,
      );
    }
    if (tab.hasUnseenCompletion) {
      return _attentionIcon(
        key: ValueKey<String>('session_tab_leading_completion_$key'),
        icon: Symbols.notifications_active,
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      );
    }

    final resolvedProject = project ?? _fallbackProject(tab);
    final projectLabel = resolvedProject.name.trim().isEmpty
        ? fileBasename(tab.identity.directory)
        : resolvedProject.name.trim();
    return Tooltip(
      message: projectLabel,
      child: ProjectIcon(
        key: ValueKey<String>('session_tab_project_icon_$key'),
        project: resolvedProject,
        size: 20,
        color: tab.isSelected
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
        autoDiscover:
            project != null && widget.openProjectIds.contains(project.id),
      ),
    );
  }

  Widget _attentionIcon({
    required Key key,
    required IconData icon,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      key: key,
      width: 26,
      height: 26,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: foreground),
    );
  }

  String _semanticLabel(
    BuildContext context,
    SessionTabRecord tab,
    String title,
  ) {
    final base = switch ((
      tab.hasUnseenError,
      tab.hasUnseenQuestion,
      tab.hasUnseenCompletion,
    )) {
      (true, _, _) => context.l10n.sessionHasError(title),
      (false, true, _) => context.l10n.sessionNeedsInput(title),
      (false, false, true) => context.l10n.sessionHasNewReply(title),
      _ => context.l10n.chatSessionChatSessionSession(title),
    };
    if (tab.status == SessionStatusType.retry) {
      return '$base ${context.l10n.chatStatusRetry}';
    }
    if (tab.status == SessionStatusType.busy) {
      return '$base ${context.l10n.chatStatusBusy}';
    }
    return base;
  }

  Project? _projectForTab(SessionTabRecord tab) {
    for (final project in widget.projects) {
      if (areEquivalentFilePaths(project.path, tab.identity.directory)) {
        return project;
      }
    }
    final projectId = tab.projectId?.trim();
    if (projectId == null || projectId.isEmpty) {
      return null;
    }
    for (final project in widget.projects) {
      if (project.id == projectId) {
        return project;
      }
    }
    return null;
  }

  Project _fallbackProject(SessionTabRecord tab) {
    final directoryLabel = fileBasename(tab.identity.directory);
    return Project(
      id: tab.projectId?.trim().isNotEmpty ?? false
          ? tab.projectId!.trim()
          : tab.identity.directory,
      name: directoryLabel,
      path: tab.identity.directory,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  SessionTabIdentity? _selectedIdentity() {
    for (final tab in widget.tabs) {
      if (tab.isSelected) {
        return tab.identity;
      }
    }
    return null;
  }

  void _handleClose(SessionTabRecord tab) {
    final fallback = sessionTabCloseFallback(widget.tabs, tab.identity);
    widget.onClose(tab);
    if (fallback == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _tabFocusNodes[fallback.identity]?.requestFocus();
    });
  }

  void _scheduleEnsureSelectedVisible(SessionTabIdentity? identity) {
    if (identity == null || _ensureVisibleScheduled) {
      return;
    }
    _ensureVisibleScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureVisibleScheduled = false;
      if (!mounted) {
        return;
      }
      final tabContext = _tabKeys[identity]?.currentContext;
      if (tabContext == null) {
        return;
      }
      Scrollable.ensureVisible(
        tabContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scrollController.hasClients) {
      return;
    }
    final delta = event.scrollDelta.dy.abs() >= event.scrollDelta.dx.abs()
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    if (delta == 0) {
      return;
    }
    final position = _scrollController.position;
    final next = (_scrollController.offset + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.jumpTo(next.toDouble());
  }
}
