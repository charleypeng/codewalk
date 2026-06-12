import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../core/logging/app_logger.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/get_chat_messages.dart';
import '../../domain/usecases/get_chat_sessions.dart';
import '../../domain/usecases/revert_chat_message.dart';
import '../../domain/usecases/send_chat_message.dart';
import '../providers/app_provider.dart';
import '../providers/project_provider.dart';

/// One session that can be a target of a forward action.
class ForwardSession {
  const ForwardSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.directory,
    this.providerId,
    this.modelId,
    this.lastMessagePreview,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final String? directory;
  final String? providerId;
  final String? modelId;
  final String? lastMessagePreview;
}

/// One project group containing the recent sessions the user can forward to.
class ForwardProjectGroup {
  const ForwardProjectGroup({required this.project, required this.sessions});

  final Project project;
  final List<ForwardSession> sessions;
}

/// One user-selected destination for a forward action.
class ForwardTarget {
  const ForwardTarget({
    required this.sessionId,
    required this.directory,
    this.providerId,
    this.modelId,
  });

  final String sessionId;
  final String? directory;
  final String? providerId;
  final String? modelId;
}

/// One successful forward entry — used to undo a previous forward.
class UndoForwardEntry {
  const UndoForwardEntry({
    required this.sessionId,
    required this.userMessageId,
    this.directory,
  });

  final String sessionId;
  final String userMessageId;
  final String? directory;
}

/// Result of a single forward action.
class ForwardResult {
  const ForwardResult({required this.successes, required this.failures});

  final List<UndoForwardEntry> successes;
  final List<({ForwardTarget target, Object error})> failures;

  bool get isFullSuccess => failures.isEmpty;
  int get totalCount => successes.length + failures.length;
}

/// Selects the provider/model/variant applied to a forwarded message when
/// the originating message does not specify one (e.g. user messages).
class ForwardSelection {
  const ForwardSelection({
    required this.providerId,
    required this.modelId,
    this.variant,
    this.mode,
  });

  final String providerId;
  final String modelId;
  final String? variant;
  final String? mode;
}

/// Read-only access to the providers the forward service depends on. Kept
/// as a thin contract so the service can be unit-tested without standing
/// up the full `AppProvider` / `ProjectProvider` ChangeNotifiers.
abstract class ForwardServiceContext {
  String? get activeServerId;
  ServerHealthStatus serverHealth(String serverId);
  List<Project> get openProjects;
  String get currentProjectId;
}

class _ProviderBackedContext implements ForwardServiceContext {
  _ProviderBackedContext({
    required this.appProvider,
    required this.projectProvider,
  });

  final AppProvider appProvider;
  final ProjectProvider projectProvider;

  @override
  String? get activeServerId => appProvider.activeServerId;

  @override
  ServerHealthStatus serverHealth(String serverId) =>
      appProvider.healthFor(serverId);

  @override
  List<Project> get openProjects => projectProvider.openProjects;

  @override
  String get currentProjectId => projectProvider.currentProjectId;
}

/// Coordinates loading recent sessions across the user's open projects and
/// sending a single chat message to one or more target sessions.
///
/// Scope (v1, ADR-023): targets are restricted to the **active server**.
/// Cross-server forwarding would require a transient swap of the global
/// `DioClient` base URL + auth, which conflicts with concurrent realtime
/// streams and is deferred to a follow-up.
class ForwardMessageService {
  ForwardMessageService({
    required GetChatSessions getChatSessions,
    required GetChatMessages getChatMessages,
    required SendChatMessage sendChatMessage,
    required RevertChatMessage revertChatMessage,
    required AppProvider appProvider,
    required ProjectProvider projectProvider,
  }) : _getChatSessions = getChatSessions,
       _getChatMessages = getChatMessages,
       _sendChatMessage = sendChatMessage,
       _revertChatMessage = revertChatMessage,
       _context = _ProviderBackedContext(
         appProvider: appProvider,
         projectProvider: projectProvider,
       );

  /// Test-friendly constructor that accepts the [ForwardServiceContext]
  /// directly. Allows unit tests to supply fakes without instantiating
  /// the full provider graph.
  @visibleForTesting
  ForwardMessageService.forTesting({
    required GetChatSessions getChatSessions,
    required GetChatMessages getChatMessages,
    required SendChatMessage sendChatMessage,
    required RevertChatMessage revertChatMessage,
    required ForwardServiceContext context,
  }) : _getChatSessions = getChatSessions,
       _getChatMessages = getChatMessages,
       _sendChatMessage = sendChatMessage,
       _revertChatMessage = revertChatMessage,
       _context = context;

  final GetChatSessions _getChatSessions;
  final GetChatMessages _getChatMessages;
  final SendChatMessage _sendChatMessage;
  final RevertChatMessage _revertChatMessage;
  final ForwardServiceContext _context;

  /// Load the recent sessions of the user's open projects on the active
  /// server, grouped by project and ordered by last activity.
  ///
  /// Projects without sessions are still returned (with an empty list) so
  /// the dialog can show "no recent sessions" for them. Server health is
  /// surfaced via [serverReachable] so the dialog can disable items.
  Future<ForwardSessionsBundle> loadTargetSessions({
    int perProjectLimit = 20,
    bool rootsOnly = true,
  }) async {
    final serverReachable = _serverReachable();
    final openProjects = _context.openProjects;
    final groups = <ForwardProjectGroup>[];

    for (final project in openProjects) {
      if (!serverReachable) {
        groups.add(ForwardProjectGroup(project: project, sessions: const <ForwardSession>[]));
        continue;
      }
      final sessionsResult = await _getChatSessions(
        GetChatSessionsParams(
          directory: project.path,
          rootsOnly: rootsOnly ? true : null,
          limit: perProjectLimit,
        ),
      );
      final sessions = sessionsResult.fold(
        (_) => <ChatSession>[],
        (value) => value,
      );
      final mapped = <ForwardSession>[];
      for (final session in sessions) {
        final preview = await _loadLastMessagePreview(
          projectId: project.id,
          sessionId: session.id,
          directory: project.path,
        );
        mapped.add(
          ForwardSession(
            id: session.id,
            title: session.title?.trim().isNotEmpty == true
                ? session.title!.trim()
                : 'Untitled',
            updatedAt: session.time,
            directory: project.path,
            providerId: null,
            modelId: null,
            lastMessagePreview: preview,
          ),
        );
      }
      mapped.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      groups.add(ForwardProjectGroup(project: project, sessions: mapped));
    }

    return ForwardSessionsBundle(
      groups: groups,
      serverReachable: serverReachable,
    );
  }

  /// Send [text] (prepended with [provenanceLine]) to every [target] and
  /// return per-target outcomes. The stream from each target is consumed
  /// until the first assistant message is observed; the most recent user
  /// message in the session is then captured for undo.
  Future<ForwardResult> forwardToSessions({
    required String text,
    required String provenanceLine,
    required List<ForwardTarget> targets,
    required ForwardSelection selection,
    String? clientMessageIdPrefix,
  }) async {
    if (targets.isEmpty) {
      return const ForwardResult(successes: [], failures: []);
    }

    final composedText = _composeForwardedText(
      text: text,
      provenanceLine: provenanceLine,
    );

    final successes = <UndoForwardEntry>[];
    final failures = <({ForwardTarget target, Object error})>[];

    for (final target in targets) {
      try {
        final undoEntry = await _forwardToSingleTarget(
          target: target,
          text: composedText,
          selection: selection,
          clientMessageIdPrefix: clientMessageIdPrefix,
        );
        if (undoEntry != null) {
          successes.add(undoEntry);
        } else {
          failures.add((
            target: target,
            error: StateError('Forwarded message but could not resolve undo target'),
          ));
        }
      } catch (error, stackTrace) {
        AppLogger.warn(
          'Forward to session=${target.sessionId} failed',
          error: error,
          stackTrace: stackTrace,
        );
        failures.add((target: target, error: error));
      }
    }

    return ForwardResult(successes: successes, failures: failures);
  }

  /// Revert each entry in [entries] via the official `/revert` endpoint.
  /// Returns the entries that failed to revert.
  Future<List<UndoForwardEntry>> undoForward(
    List<UndoForwardEntry> entries,
  ) async {
    final failed = <UndoForwardEntry>[];
    for (final entry in entries) {
      final result = await _revertChatMessage(
        RevertChatMessageParams(
          projectId: _context.currentProjectId,
          sessionId: entry.sessionId,
          messageId: entry.userMessageId,
          directory: entry.directory,
        ),
      );
      result.fold((_) => failed.add(entry), (_) {});
    }
    return failed;
  }

  Future<UndoForwardEntry?> _forwardToSingleTarget({
    required ForwardTarget target,
    required String text,
    required ForwardSelection selection,
    String? clientMessageIdPrefix,
  }) async {
    final messageId = _buildClientMessageId(
      prefix: clientMessageIdPrefix,
      sessionId: target.sessionId,
    );
    final input = ChatInput(
      messageId: messageId,
      providerId: selection.providerId,
      modelId: selection.modelId,
      variant: selection.variant,
      mode: selection.mode,
      parts: [TextInputPart(text: text)],
    );
    final stream = _sendChatMessage(
      SendChatMessageParams(
        projectId: _context.currentProjectId,
        sessionId: target.sessionId,
        input: input,
        directory: target.directory,
      ),
    );
    var firstYielded = false;
    await for (final result in stream) {
      result.fold((_) => null, (_) => null);
      if (!firstYielded) {
        firstYielded = true;
      }
    }
    final undoEntry = await _resolveForwardedUserMessageId(
      sessionId: target.sessionId,
      directory: target.directory,
      clientMessageId: messageId,
    );
    return undoEntry;
  }

  /// Find the user message that was just created by the forward action.
  ///
  /// Strategy: list the last few messages of the target session, find the
  /// most recent user message. If the client-provided message id matches
  /// one of the returned ids, prefer that exact match.
  Future<UndoForwardEntry?> _resolveForwardedUserMessageId({
    required String sessionId,
    required String? directory,
    String? clientMessageId,
  }) async {
    final result = await _getChatMessages(
      GetChatMessagesParams(
        projectId: _context.currentProjectId,
        sessionId: sessionId,
        directory: directory,
        limit: 3,
      ),
    );
    final messages = result.fold(
      (_) => <ChatMessage>[],
      (value) => value,
    );
    for (final message in messages) {
      if (message is! UserMessage) continue;
      if (clientMessageId != null &&
          clientMessageId.isNotEmpty &&
          message.id == clientMessageId) {
        return UndoForwardEntry(
          sessionId: sessionId,
          userMessageId: message.id,
          directory: directory,
        );
      }
    }
    for (final message in messages) {
      if (message is UserMessage) {
        return UndoForwardEntry(
          sessionId: sessionId,
          userMessageId: message.id,
          directory: directory,
        );
      }
    }
    return null;
  }

  Future<String?> _loadLastMessagePreview({
    required String projectId,
    required String sessionId,
    required String? directory,
  }) async {
    final result = await _getChatMessages(
      GetChatMessagesParams(
        projectId: projectId,
        sessionId: sessionId,
        directory: directory,
        limit: 1,
      ),
    );
    return result.fold<String?>(
      (_) => null,
      (messages) {
      if (messages.isEmpty) return null;
      final last = messages.last;
      for (final part in last.parts) {
        if (part is TextPart && part.text.trim().isNotEmpty) {
          return _truncate(part.text.trim(), 140);
        }
      }
      return null;
      },
    );
  }

  bool _serverReachable() {
    final serverId = _context.activeServerId;
    if (serverId == null || serverId.isEmpty) return false;
    final status = _context.serverHealth(serverId);
    return status == ServerHealthStatus.healthy;
  }

  String _composeForwardedText({required String text, required String provenanceLine}) {
    final buffer = StringBuffer();
    if (provenanceLine.trim().isNotEmpty) {
      buffer.writeln(provenanceLine.trim());
    }
    buffer.write(text);
    return buffer.toString();
  }

  String _buildClientMessageId({String? prefix, required String sessionId}) {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = sessionId.hashCode.toRadixString(36);
    final base = (prefix == null || prefix.isEmpty) ? 'fwd' : prefix;
    return '$base-$now-$salt';
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 1).trimRight()}…';
  }
}

/// Bundle of load results — convenient to consume from the dialog.
class ForwardSessionsBundle {
  const ForwardSessionsBundle({
    required this.groups,
    required this.serverReachable,
  });

  final List<ForwardProjectGroup> groups;
  final bool serverReachable;

  /// Total session count across all groups (used for the empty state).
  int get totalSessions =>
      groups.fold<int>(0, (sum, group) => sum + group.sessions.length);
}
