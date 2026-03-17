import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/entities/chat_session.dart';
import '../providers/chat_provider.dart';
import '../utils/session_title_formatter.dart';

/// Chat session list widget
class ChatSessionList extends StatefulWidget {
  const ChatSessionList({
    super.key,
    required this.sessions,
    this.currentSession,
    this.isSessionActive,
    this.sessionAttentionFor,
    this.isMobileLayout = false,
    this.onSessionSelected,
    this.onSessionDeleted,
    this.onSessionRenamed,
    this.onSessionShareToggled,
    this.onSessionArchiveToggled,
    this.onSessionPinToggled,
    this.onSessionForked,
    this.pinnedSessionIds = const <String>{},
    this.shrinkWrap = false,
    this.physics,
    this.padding = const EdgeInsets.fromLTRB(8, 0, 8, 8),
    this.verticalTilePadding = 3,
  });

  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final bool Function(String sessionId)? isSessionActive;
  final SessionAttentionState Function(String sessionId)? sessionAttentionFor;
  final bool isMobileLayout;
  final Future<void> Function(ChatSession session)? onSessionSelected;
  final Future<void> Function(ChatSession session)? onSessionDeleted;
  final Future<bool> Function(ChatSession session, String title)?
  onSessionRenamed;
  final Future<bool> Function(ChatSession session)? onSessionShareToggled;
  final Future<bool> Function(ChatSession session, bool archived)?
  onSessionArchiveToggled;
  final Future<void> Function(ChatSession session)? onSessionPinToggled;
  final Future<void> Function(ChatSession session)? onSessionForked;
  final Set<String> pinnedSessionIds;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry padding;
  final double verticalTilePadding;

  @override
  State<ChatSessionList> createState() => _ChatSessionListState();
}

class _ChatSessionListState extends State<ChatSessionList> {
  static final RegExp _pseudoSummaryPattern = RegExp(
    r'^\s*(additions|deletions)\s*:\s*\d+(\s*,\s*(additions|deletions)\s*:\s*\d+)*\s*$',
    caseSensitive: false,
  );

  final Set<String> _expandedParentIds = <String>{};
  String? _cachedTreeSignature;
  List<_SessionTreeRow> _cachedVisibleRows = const <_SessionTreeRow>[];
  bool _isSessionSelectionInFlight = false;
  String? _activeSessionSelectionId;
  ChatSession? _pendingSessionSelection;

  @override
  void initState() {
    super.initState();
    final sessionById = <String, ChatSession>{
      for (final session in widget.sessions) session.id: session,
    };
    _expandCurrentSessionAncestors(sessionById);
  }

  @override
  void didUpdateWidget(covariant ChatSessionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sessionIds = widget.sessions.map((session) => session.id).toSet();
    _expandedParentIds.removeWhere((id) => !sessionIds.contains(id));
    final sessionById = <String, ChatSession>{
      for (final session in widget.sessions) session.id: session,
    };
    _expandCurrentSessionAncestors(sessionById);
    _invalidateTreeCache();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new conversation to start chatting',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final sessionById = <String, ChatSession>{
      for (final session in widget.sessions) session.id: session,
    };
    final childrenByParent = <String, List<ChatSession>>{};
    final roots = <ChatSession>[];

    for (final session in widget.sessions) {
      final parentId = session.parentId;
      if (parentId == null ||
          parentId.isEmpty ||
          !sessionById.containsKey(parentId) ||
          parentId == session.id) {
        roots.add(session);
        continue;
      }
      childrenByParent
          .putIfAbsent(parentId, () => <ChatSession>[])
          .add(session);
    }

    final signature = _createTreeSignature(
      sessions: widget.sessions,
      roots: roots,
      expandedParentIds: _expandedParentIds,
      pinnedSessionIds: widget.pinnedSessionIds,
    );
    if (_cachedTreeSignature != signature) {
      _cachedTreeSignature = signature;
      final visited = <String>{};
      final rows = <_SessionTreeRow>[];
      for (final root in roots) {
        rows.addAll(
          _buildSessionRows(
            session: root,
            childrenByParent: childrenByParent,
            depth: 0,
            visited: visited,
          ),
        );
      }
      _cachedVisibleRows = rows;
    }

    return ListView.builder(
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemCount: _cachedVisibleRows.length,
      itemBuilder: (context, index) {
        final row = _cachedVisibleRows[index];
        return _buildSessionTile(
          context,
          session: row.session,
          depth: row.depth,
          hasChildren: row.hasChildren,
          childCount: row.childCount,
          expanded: row.expanded,
        );
      },
    );
  }

  bool _expandCurrentSessionAncestors(Map<String, ChatSession> sessionById) {
    final current = widget.currentSession;
    if (current == null) {
      return false;
    }
    var changed = false;
    var parentId = current.parentId;
    while (parentId != null && parentId.isNotEmpty) {
      final inserted = _expandedParentIds.add(parentId);
      changed = changed || inserted;
      final parent = sessionById[parentId];
      if (parent == null || parent.parentId == parentId) {
        break;
      }
      parentId = parent.parentId;
    }
    return changed;
  }

  List<_SessionTreeRow> _buildSessionRows({
    required ChatSession session,
    required Map<String, List<ChatSession>> childrenByParent,
    required int depth,
    required Set<String> visited,
  }) {
    if (!visited.add(session.id)) {
      return const <_SessionTreeRow>[];
    }

    final children = childrenByParent[session.id] ?? const <ChatSession>[];
    final hasChildren = children.isNotEmpty;
    final expanded = hasChildren && _expandedParentIds.contains(session.id);
    final rows = <_SessionTreeRow>[
      _SessionTreeRow(
        session: session,
        depth: depth,
        hasChildren: hasChildren,
        childCount: children.length,
        expanded: expanded,
      ),
    ];

    if (!expanded) {
      return rows;
    }

    for (final child in children) {
      rows.addAll(
        _buildSessionRows(
          session: child,
          childrenByParent: childrenByParent,
          depth: depth + 1,
          visited: visited,
        ),
      );
    }

    return rows;
  }

  String _createTreeSignature({
    required List<ChatSession> sessions,
    required List<ChatSession> roots,
    required Set<String> expandedParentIds,
    required Set<String> pinnedSessionIds,
  }) {
    final expanded = expandedParentIds.toList(growable: false)..sort();
    final buffer = StringBuffer()
      ..write('sessions:${sessions.length};')
      ..write('roots:${roots.map((session) => session.id).join(',')};')
      ..write('expanded:${expanded.join(',')};')
      ..write('current:${widget.currentSession?.id ?? ''};');
    for (final session in sessions) {
      final attention = widget.sessionAttentionFor?.call(session.id);
      buffer
        ..write(session.id)
        ..write(':')
        ..write(session.parentId ?? '')
        ..write(':')
        ..write(session.time.millisecondsSinceEpoch)
        ..write(':')
        ..write(session.archived)
        ..write(':')
        ..write(session.shared)
        ..write(':')
        ..write(attention?.unreadCompletionAt?.millisecondsSinceEpoch ?? 0)
        ..write(':')
        ..write(pinnedSessionIds.contains(session.id))
        ..write(';');
    }
    return buffer.toString();
  }

  String? _sidebarSummary(String? summary) {
    final trimmed = summary?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    if (_pseudoSummaryPattern.hasMatch(trimmed)) {
      return null;
    }
    return trimmed;
  }

  Widget _buildCompactMetaRow(
    BuildContext context, {
    required ChatSession session,
    required bool isSelected,
    required bool hasChildren,
    required String childLabel,
    required bool isPinned,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final metaColor = isSelected
        ? colorScheme.onSecondaryContainer.withValues(alpha: 0.7)
        : colorScheme.onSurfaceVariant;
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: metaColor);

    return Wrap(
      spacing: 8,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        Text(_formatTime(session.time), style: textStyle, maxLines: 1),
        if (hasChildren) Text(childLabel, style: textStyle, maxLines: 1),
        if (session.shared) Icon(Symbols.share, size: 12, color: metaColor),
        if (isPinned) Icon(Symbols.push_pin, size: 12, color: metaColor),
        if (session.archived) Icon(Symbols.archive, size: 12, color: metaColor),
      ],
    );
  }

  void _invalidateTreeCache() {
    _cachedTreeSignature = null;
    _cachedVisibleRows = const <_SessionTreeRow>[];
  }

  Future<void> _handleSessionSelected(ChatSession session) async {
    final callback = widget.onSessionSelected;
    if (callback == null) {
      return;
    }
    if (_isSessionSelectionInFlight) {
      final pendingSessionId = _pendingSessionSelection?.id;
      if (pendingSessionId == session.id) {
        return;
      }
      if (_activeSessionSelectionId == session.id) {
        _pendingSessionSelection = null;
        return;
      }
      _pendingSessionSelection = session;
      return;
    }

    _pendingSessionSelection = session;
    _isSessionSelectionInFlight = true;
    try {
      while (true) {
        final pendingSession = _pendingSessionSelection;
        _pendingSessionSelection = null;
        if (pendingSession == null) {
          return;
        }
        _activeSessionSelectionId = pendingSession.id;
        await callback(pendingSession);
      }
    } finally {
      _activeSessionSelectionId = null;
      _isSessionSelectionInFlight = false;
    }
  }

  Widget _buildSessionTile(
    BuildContext context, {
    required ChatSession session,
    required int depth,
    required bool hasChildren,
    required int childCount,
    required bool expanded,
  }) {
    final isSelected = widget.currentSession?.id == session.id;
    final isSessionActive = widget.isSessionActive?.call(session.id) ?? false;
    final sessionAttention =
        widget.sessionAttentionFor?.call(session.id) ??
        SessionAttentionState(isActive: isSessionActive);
    final floatingBadgeKind = _resolveFloatingBadgeKind(
      attention: sessionAttention,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final isPinned = widget.pinnedSessionIds.contains(session.id);
    final childLabel = childCount == 1
        ? '1 sub-conversation'
        : '$childCount sub-conversations';
    final hasRecentUnreadHighlight =
        sessionAttention.hasRecentUnreadCompletion &&
        (session.parentId == null || session.parentId!.trim().isEmpty);
    final subtitleText = _sidebarSummary(session.summary);
    final tileColor = isSelected
        ? colorScheme.secondaryContainer
        : (hasRecentUnreadHighlight
              ? Color.alphaBlend(
                  colorScheme.primary.withValues(alpha: 0.08),
                  colorScheme.surfaceContainerLow,
                )
              : colorScheme.surfaceContainerLow);
    final outlineColor = hasRecentUnreadHighlight && !isSelected
        ? colorScheme.primary.withValues(alpha: 0.4)
        : Colors.transparent;
    final compactMeta = _buildCompactMetaRow(
      context,
      session: session,
      isSelected: isSelected,
      hasChildren: hasChildren,
      childLabel: childLabel,
      isPinned: isPinned,
    );

    return Padding(
      key: ValueKey<String>('chat_session_tile_${session.id}'),
      padding: EdgeInsets.symmetric(vertical: widget.verticalTilePadding),
      child: Semantics(
        label: 'Chat session: ${session.title}',
        selected: isSelected,
        child: Material(
          color: tileColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: outlineColor),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ListTile(
                mouseCursor: SystemMouseCursors.click,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                contentPadding: EdgeInsets.fromLTRB(
                  10 + (depth * 16.0),
                  0,
                  4,
                  0,
                ),
                dense: true,
                visualDensity: const VisualDensity(vertical: -2),
                minVerticalPadding: 0,
                title: Row(
                  children: [
                    if (hasChildren)
                      InkWell(
                        key: ValueKey<String>(
                          'chat_session_toggle_${session.id}',
                        ),
                        onTap: () {
                          setState(() {
                            if (expanded) {
                              _expandedParentIds.remove(session.id);
                            } else {
                              _expandedParentIds.add(session.id);
                            }
                            _invalidateTreeCache();
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            expanded
                                ? Symbols.expand_more
                                : Symbols.chevron_right,
                            size: 18,
                            color: isSelected
                                ? colorScheme.onSecondaryContainer.withValues(
                                    alpha: 0.9,
                                  )
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else if (depth > 0)
                      const SizedBox(width: 22),
                    Expanded(
                      child: Text(
                        SessionTitleFormatter.displayTitle(
                          time: session.time,
                          title: session.title,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? colorScheme.onSecondaryContainer
                              : null,
                          decoration: session.archived
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitleText != null) ...[
                      Text(
                        subtitleText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? colorScheme.onSecondaryContainer.withValues(
                                  alpha: 0.8,
                                )
                              : colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    compactMeta,
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: Icon(
                    Symbols.more_vert,
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'rename':
                        _showRenameDialog(context, session);
                        break;
                      case 'share':
                        _toggleShare(context, session);
                        break;
                      case 'copy-link':
                        _copyShareLink(context, session);
                        break;
                      case 'archive':
                        _toggleArchive(context, session);
                        break;
                      case 'pin':
                        _togglePinned(context, session);
                        break;
                      case 'fork':
                        _forkSession(context, session);
                        break;
                      case 'delete':
                        _showDeleteDialog(context, session);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          const Icon(Symbols.push_pin),
                          const SizedBox(width: 8),
                          Text(isPinned ? 'Unpin' : 'Pin'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Symbols.edit),
                          SizedBox(width: 8),
                          Text('Rename'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(
                            session.shared ? Symbols.link_off : Symbols.link,
                          ),
                          const SizedBox(width: 8),
                          Text(session.shared ? 'Unshare' : 'Share'),
                        ],
                      ),
                    ),
                    if (session.shareUrl != null &&
                        session.shareUrl!.isNotEmpty)
                      const PopupMenuItem(
                        value: 'copy-link',
                        child: Row(
                          children: [
                            Icon(Symbols.content_copy),
                            SizedBox(width: 8),
                            Text('Copy Link'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(
                            session.archived
                                ? Symbols.unarchive
                                : Symbols.archive,
                          ),
                          const SizedBox(width: 8),
                          Text(session.archived ? 'Unarchive' : 'Archive'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'fork',
                      child: Row(
                        children: [
                          Icon(Symbols.call_split),
                          SizedBox(width: 8),
                          Text('Fork'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Symbols.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () async {
                  await _handleSessionSelected(session);
                },
              ),
              if (floatingBadgeKind != SessionAttentionKind.none)
                Positioned(
                  top: 8,
                  right: 46,
                  child: _buildFloatingAttentionBadge(
                    context,
                    sessionId: session.id,
                    kind: floatingBadgeKind,
                    isSelected: isSelected,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  SessionAttentionKind _resolveFloatingBadgeKind({
    required SessionAttentionState attention,
  }) {
    final primaryKind = attention.primaryKind;
    if (primaryKind == SessionAttentionKind.none) {
      return SessionAttentionKind.none;
    }
    return primaryKind;
  }

  Widget _buildFloatingAttentionBadge(
    BuildContext context, {
    required String sessionId,
    required SessionAttentionKind kind,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = _attentionBadgeColor(
      colorScheme: colorScheme,
      kind: kind,
      isSelected: isSelected,
    );
    final badgeKey = ValueKey<String>(
      'chat_session_attention_badge_${kind.name}_$sessionId',
    );

    if (kind == SessionAttentionKind.unreadCompletion) {
      return Container(
        key: badgeKey,
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
      );
    }

    final badgeIcon = switch (kind) {
      SessionAttentionKind.active => Symbols.sync_rounded,
      SessionAttentionKind.pendingInteraction => Symbols.help,
      SessionAttentionKind.error => Symbols.error,
      SessionAttentionKind.none => Symbols.circle,
      SessionAttentionKind.unreadCompletion => Symbols.circle,
    };
    final iconColor = switch (kind) {
      SessionAttentionKind.error => colorScheme.onError,
      SessionAttentionKind.pendingInteraction => colorScheme.onTertiary,
      SessionAttentionKind.active => colorScheme.onPrimary,
      SessionAttentionKind.none => colorScheme.onSurface,
      SessionAttentionKind.unreadCompletion => colorScheme.onSurface,
    };

    return AnimatedContainer(
      key: badgeKey,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(badgeIcon, size: 11, color: iconColor),
    );
  }

  Color _attentionBadgeColor({
    required ColorScheme colorScheme,
    required SessionAttentionKind kind,
    required bool isSelected,
  }) {
    return switch (kind) {
      SessionAttentionKind.error => colorScheme.error,
      SessionAttentionKind.pendingInteraction => colorScheme.tertiary,
      SessionAttentionKind.unreadCompletion =>
        isSelected ? colorScheme.onSecondaryContainer : colorScheme.primary,
      SessionAttentionKind.active => colorScheme.primary,
      SessionAttentionKind.none => colorScheme.onSurface,
    };
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${time.month}/${time.day}';
    }
  }

  void _showRenameDialog(BuildContext context, ChatSession session) {
    final callback = widget.onSessionRenamed;
    if (callback == null) {
      return;
    }

    final controller = TextEditingController(text: session.title);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter new conversation name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newTitle = controller.text.trim();
              if (newTitle.isEmpty) {
                return;
              }
              Navigator.of(context).pop();
              final ok = await callback(session, newTitle);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to rename conversation'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleShare(BuildContext context, ChatSession session) async {
    final callback = widget.onSessionShareToggled;
    if (callback == null) {
      return;
    }

    final ok = await callback(session);
    if (!context.mounted) {
      return;
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update sharing state')),
      );
      return;
    }

    final nextAction = session.shared ? 'unshared' : 'shared';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Conversation $nextAction')));
  }

  Future<void> _copyShareLink(BuildContext context, ChatSession session) async {
    final link = session.shareUrl;
    if (link == null || link.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share link copied')));
  }

  Future<void> _toggleArchive(BuildContext context, ChatSession session) async {
    final callback = widget.onSessionArchiveToggled;
    if (callback == null) {
      return;
    }

    final archive = !session.archived;
    final ok = await callback(session, archive);
    if (!context.mounted) {
      return;
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update archive state')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          archive ? 'Conversation archived' : 'Conversation unarchived',
        ),
      ),
    );
  }

  Future<void> _togglePinned(BuildContext context, ChatSession session) async {
    final callback = widget.onSessionPinToggled;
    if (callback == null) {
      return;
    }

    final wasPinned = widget.pinnedSessionIds.contains(session.id);
    await callback(session);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasPinned ? 'Conversation unpinned' : 'Conversation pinned',
        ),
      ),
    );
  }

  Future<void> _forkSession(BuildContext context, ChatSession session) async {
    final callback = widget.onSessionForked;
    if (callback == null) {
      return;
    }
    await callback(session);
  }

  void _showDeleteDialog(BuildContext context, ChatSession session) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete the conversation "${SessionTitleFormatter.displayTitle(time: session.time, title: session.title)}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final callback = widget.onSessionDeleted;
              if (callback != null) {
                callback(session);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SessionTreeRow {
  const _SessionTreeRow({
    required this.session,
    required this.depth,
    required this.hasChildren,
    required this.childCount,
    required this.expanded,
  });

  final ChatSession session;
  final int depth;
  final bool hasChildren;
  final int childCount;
  final bool expanded;
}
