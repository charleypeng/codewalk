import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/i18n/l10n_context.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/chat_session.dart';
import '../utils/session_title_formatter.dart';
import 'modal_primary_action_shortcuts.dart';

const String sessionMenuPin = 'pin';
const String sessionMenuRename = 'rename';
const String sessionMenuShare = 'share';
const String sessionMenuCopyLink = 'copy-link';
const String sessionMenuArchive = 'archive';
const String sessionMenuFork = 'fork';
const String sessionMenuDelete = 'delete';

class SessionContextMenuActions {
  const SessionContextMenuActions({
    this.onSessionDeleted,
    this.onSessionRenamed,
    this.onSessionShareToggled,
    this.onSessionArchiveToggled,
    this.onSessionPinToggled,
    this.onSessionForked,
    this.pinnedSessionIds = const <String>{},
  });

  final Future<void> Function(ChatSession session)? onSessionDeleted;
  final Future<bool> Function(ChatSession session, String title)?
  onSessionRenamed;
  final Future<bool> Function(ChatSession session)? onSessionShareToggled;
  final Future<bool> Function(ChatSession session, bool archived)?
  onSessionArchiveToggled;
  final Future<void> Function(ChatSession session)? onSessionPinToggled;
  final Future<void> Function(ChatSession session)? onSessionForked;
  final Set<String> pinnedSessionIds;

  bool isPinned(ChatSession session) => pinnedSessionIds.contains(session.id);
}

class SessionContextMenuButton extends StatelessWidget {
  const SessionContextMenuButton({
    super.key,
    required this.session,
    required this.actions,
    required this.surface,
    this.iconColor,
  });

  final ChatSession session;
  final SessionContextMenuActions actions;
  final String surface;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Symbols.more_vert, color: iconColor),
      onOpened: () =>
          logSessionContextMenuOpen(surface: surface, sessionId: session.id),
      onSelected: (value) => unawaited(
        handleSessionContextMenuSelection(
          context,
          session: session,
          value: value,
          actions: actions,
        ),
      ),
      itemBuilder: (context) => buildSessionContextMenuEntries(
        context,
        session: session,
        isPinned: actions.isPinned(session),
      ),
    );
  }
}

class SessionContextMenuRegion extends StatelessWidget {
  const SessionContextMenuRegion({
    super.key,
    required this.session,
    required this.actions,
    required this.surface,
    required this.child,
  });

  final ChatSession session;
  final SessionContextMenuActions actions;
  final String surface;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapUp: (details) => unawaited(
        showSessionContextMenu(
          context,
          session: session,
          actions: actions,
          surface: surface,
          globalPosition: details.globalPosition,
        ),
      ),
      onLongPressStart: (details) => unawaited(
        showSessionContextMenu(
          context,
          session: session,
          actions: actions,
          surface: surface,
          globalPosition: details.globalPosition,
          haptic: true,
        ),
      ),
      child: child,
    );
  }
}

List<PopupMenuEntry<String>> buildSessionContextMenuEntries(
  BuildContext context, {
  required ChatSession session,
  required bool isPinned,
}) {
  return [
    PopupMenuItem(
      value: sessionMenuPin,
      child: Row(
        children: [
          const Icon(Symbols.push_pin),
          const SizedBox(width: 8),
          Text(isPinned ? context.l10n.sessionUnpin : context.l10n.sessionPin),
        ],
      ),
    ),
    PopupMenuItem(
      value: sessionMenuRename,
      child: Row(
        children: [
          const Icon(Symbols.edit),
          const SizedBox(width: 8),
          Text(context.l10n.sessionRename),
        ],
      ),
    ),
    PopupMenuItem(
      value: sessionMenuShare,
      child: Row(
        children: [
          Icon(session.shared ? Symbols.link_off : Symbols.link),
          const SizedBox(width: 8),
          Text(
            session.shared
                ? context.l10n.sessionUnshareAction
                : context.l10n.sessionShareAction,
          ),
        ],
      ),
    ),
    if (session.shareUrl != null && session.shareUrl!.isNotEmpty)
      PopupMenuItem(
        value: sessionMenuCopyLink,
        child: Row(
          children: [
            const Icon(Symbols.content_copy),
            const SizedBox(width: 8),
            Text(context.l10n.sessionCopyLink),
          ],
        ),
      ),
    PopupMenuItem(
      value: sessionMenuArchive,
      child: Row(
        children: [
          Icon(session.archived ? Symbols.unarchive : Symbols.archive),
          const SizedBox(width: 8),
          Text(
            session.archived
                ? context.l10n.sessionUnarchive
                : context.l10n.sessionArchive,
          ),
        ],
      ),
    ),
    PopupMenuItem(
      value: sessionMenuFork,
      child: Row(
        children: [
          const Icon(Symbols.call_split),
          const SizedBox(width: 8),
          Text(context.l10n.sessionFork),
        ],
      ),
    ),
    PopupMenuItem(
      value: sessionMenuDelete,
      child: Row(
        children: [
          const Icon(Symbols.delete, color: Colors.red),
          const SizedBox(width: 8),
          Text(
            context.l10n.sessionDelete,
            style: const TextStyle(color: Colors.red),
          ),
        ],
      ),
    ),
  ];
}

Future<void> showSessionContextMenu(
  BuildContext context, {
  required ChatSession session,
  required SessionContextMenuActions actions,
  required String surface,
  required Offset globalPosition,
  bool haptic = false,
}) async {
  if (haptic) {
    unawaited(HapticFeedback.mediumImpact());
  }
  logSessionContextMenuOpen(surface: surface, sessionId: session.id);

  final overlay = Overlay.of(context).context.findRenderObject();
  if (overlay is! RenderBox) {
    return;
  }
  final selected = await showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
      Offset.zero & overlay.size,
    ),
    items: buildSessionContextMenuEntries(
      context,
      session: session,
      isPinned: actions.isPinned(session),
    ),
  );
  if (!context.mounted || selected == null) {
    return;
  }
  await handleSessionContextMenuSelection(
    context,
    session: session,
    value: selected,
    actions: actions,
  );
}

Future<void> handleSessionContextMenuSelection(
  BuildContext context, {
  required ChatSession session,
  required String value,
  required SessionContextMenuActions actions,
}) async {
  switch (value) {
    case sessionMenuRename:
      _showRenameDialog(context, session, actions);
      return;
    case sessionMenuShare:
      await _toggleShare(context, session, actions);
      return;
    case sessionMenuCopyLink:
      await _copyShareLink(context, session);
      return;
    case sessionMenuArchive:
      await _toggleArchive(context, session, actions);
      return;
    case sessionMenuPin:
      await _togglePinned(context, session, actions);
      return;
    case sessionMenuFork:
      await _forkSession(session, actions);
      return;
    case sessionMenuDelete:
      _showDeleteDialog(context, session, actions);
      return;
  }
}

void logSessionContextMenuOpen({
  required String surface,
  required String sessionId,
}) {
  AppLogger.debug('session_context_menu_open surface=$surface id=$sessionId');
}

void _showRenameDialog(
  BuildContext context,
  ChatSession session,
  SessionContextMenuActions actions,
) {
  final callback = actions.onSessionRenamed;
  if (callback == null) {
    return;
  }

  final controller = TextEditingController(text: session.title);

  Future<void> submitRename(BuildContext dialogContext) async {
    final newTitle = controller.text.trim();
    if (newTitle.isEmpty) {
      return;
    }
    Navigator.of(dialogContext).pop();
    final ok = await callback(session, newTitle);
    if (!context.mounted) {
      return;
    }
    if (!ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.sessionFailedRename)));
    }
  }

  showDialog<void>(
    context: context,
    builder: (dialogContext) => ModalPrimaryActionShortcuts(
      onPrimaryAction: () {
        unawaited(submitRename(dialogContext));
      },
      child: AlertDialog(
        title: Text(context.l10n.sessionRenameTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.sessionRenameHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              unawaited(submitRename(dialogContext));
            },
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
    ),
  );
}

Future<void> _toggleShare(
  BuildContext context,
  ChatSession session,
  SessionContextMenuActions actions,
) async {
  final callback = actions.onSessionShareToggled;
  if (callback == null) {
    return;
  }

  final ok = await callback(session);
  if (!context.mounted) {
    return;
  }
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.sessionFailedUpdateSharing)),
    );
    return;
  }

  final nextAction = session.shared ? 'unshared' : 'shared';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.chatSessionConversationNextAction(nextAction)),
    ),
  );
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
  ).showSnackBar(SnackBar(content: Text(context.l10n.sessionShareLinkCopied)));
}

Future<void> _toggleArchive(
  BuildContext context,
  ChatSession session,
  SessionContextMenuActions actions,
) async {
  final callback = actions.onSessionArchiveToggled;
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
      SnackBar(content: Text(context.l10n.sessionFailedUpdateArchive)),
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

Future<void> _togglePinned(
  BuildContext context,
  ChatSession session,
  SessionContextMenuActions actions,
) async {
  final callback = actions.onSessionPinToggled;
  if (callback == null) {
    return;
  }

  final wasPinned = actions.isPinned(session);
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

Future<void> _forkSession(
  ChatSession session,
  SessionContextMenuActions actions,
) async {
  final callback = actions.onSessionForked;
  if (callback == null) {
    return;
  }
  await callback(session);
}

void _showDeleteDialog(
  BuildContext context,
  ChatSession session,
  SessionContextMenuActions actions,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.sessionDeleteTitle),
      content: Text(
        'Are you sure you want to delete the conversation "${SessionTitleFormatter.displayTitle(time: session.time, title: session.title)}"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(context.l10n.commonCancel),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            final callback = actions.onSessionDeleted;
            if (callback != null) {
              unawaited(callback(session));
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(context.l10n.sessionDelete),
        ),
      ],
    ),
  );
}
