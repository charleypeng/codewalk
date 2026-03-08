part of '../chat_page.dart';

extension _ChatPageCommandQuery on _ChatPageState {
  Future<List<ChatComposerMentionSuggestion>> _queryMentionSuggestions(
    String query,
  ) async {
    final normalizedQuery = query.trim().toLowerCase();
    final projectProvider = context.read<ProjectProvider>();
    final chatProvider = context.read<ChatProvider>();
    final dio = di.sl<DioClient>().dio;

    try {
      final response = await dio.get(
        '/find/file',
        queryParameters: <String, String>{
          'query': normalizedQuery,
          if ((projectProvider.currentDirectory ?? '').isNotEmpty)
            'directory': projectProvider.currentDirectory!,
          'limit': '12',
        },
      );

      final fileData = response.data as List<dynamic>? ?? const <dynamic>[];
      final suggestions = <ChatComposerMentionSuggestion>[];

      for (final raw in fileData) {
        String? path;
        if (raw is String) {
          path = raw;
        } else if (raw is Map) {
          path =
              raw['path'] as String? ??
              raw['name'] as String? ??
              raw['file'] as String?;
        }
        if (path == null || path.trim().isEmpty) {
          continue;
        }
        suggestions.add(
          ChatComposerMentionSuggestion(
            value: path.trim(),
            type: ChatComposerSuggestionType.file,
            subtitle: 'file',
          ),
        );
      }

      for (final agent in chatProvider.agents) {
        final name = agent.name.trim();
        if (name.isEmpty || agent.hidden) {
          continue;
        }
        final normalizedName = name.toLowerCase();
        if (normalizedQuery.isNotEmpty &&
            !normalizedName.contains(normalizedQuery)) {
          continue;
        }
        suggestions.add(
          ChatComposerMentionSuggestion(
            value: name,
            type: ChatComposerSuggestionType.agent,
            subtitle: agent.mode.isEmpty ? 'agent' : agent.mode,
          ),
        );
      }

      return suggestions.take(20).toList(growable: false);
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Composer mention query failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const <ChatComposerMentionSuggestion>[];
    }
  }

  Future<List<ChatComposerSlashCommandSuggestion>> _querySlashSuggestions(
    String query,
  ) async {
    final normalizedQuery = query.trim().toLowerCase();
    final commands = <ChatComposerSlashCommandSuggestion>[
      ..._builtinSlashCommands(),
    ];
    final dio = di.sl<DioClient>().dio;

    try {
      final response = await dio.get('/command');
      final remoteData = response.data as List<dynamic>? ?? const <dynamic>[];
      for (final raw in remoteData) {
        if (raw is! Map) {
          continue;
        }
        final name = raw['name'] as String?;
        if (name == null || name.trim().isEmpty) {
          continue;
        }
        commands.add(
          ChatComposerSlashCommandSuggestion(
            name: name.trim(),
            source: raw['source'] as String? ?? 'command',
            description: raw['description'] as String?,
          ),
        );
      }
    } catch (error, stackTrace) {
      AppLogger.warn(
        'Composer slash query failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final deduped = <String, ChatComposerSlashCommandSuggestion>{};
    for (final command in commands) {
      deduped.putIfAbsent(command.name.toLowerCase(), () => command);
    }

    final filtered =
        deduped.values
            .where((command) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              final byName = command.name.toLowerCase().contains(
                normalizedQuery,
              );
              final bySource = command.source.toLowerCase().contains(
                normalizedQuery,
              );
              final byDescription = (command.description ?? '')
                  .toLowerCase()
                  .contains(normalizedQuery);
              return byName || bySource || byDescription;
            })
            .toList(growable: false)
          ..sort((a, b) {
            if (a.isBuiltin != b.isBuiltin) {
              return a.isBuiltin ? -1 : 1;
            }
            return a.name.compareTo(b.name);
          });

    return filtered.take(24).toList(growable: false);
  }

  Future<bool> _handleBuiltinSlashCommand({
    required String commandName,
    required ChatProvider chatProvider,
  }) async {
    final command = commandName.trim().toLowerCase();
    switch (command) {
      case 'new':
        await _createNewSession();
        return true;
      case 'models':
      case 'model':
        if (chatProvider.providers.isEmpty) {
          return true;
        }
        await _openModelSelector(chatProvider);
        return true;
      case 'sessions':
        await _openSessionsSurface();
        return true;
      case 'agent':
        if (!mounted || chatProvider.selectableAgents.isEmpty) {
          return true;
        }
        final anchorContext = _agentSelectorChipKey.currentContext;
        if (anchorContext != null) {
          await _openAgentQuickSelector(
            chatProvider,
            anchorContext: anchorContext,
          );
        }
        return true;
      case 'open':
        if (!mounted) {
          return true;
        }
        await _openQuickFileDialogFromCurrentContext();
        return true;
      case 'help':
        if (!mounted) {
          return true;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Use @ for mentions, ! for shell, / for commands'),
          ),
        );
        return true;
      case 'compact':
        if (!mounted) {
          return true;
        }
        await _compactCurrentSession(chatProvider);
        return true;
      case 'thinking':
        await _toggleThinkingBubbles();
        return true;
      case 'undo':
        await _triggerHistoryAction(
          chatProvider,
          action: _HistoryToolbarAction.undo,
        );
        return true;
      case 'redo':
        await _triggerHistoryAction(
          chatProvider,
          action: _HistoryToolbarAction.redo,
        );
        return true;
      default:
        return false;
    }
  }

  Future<void> _openSessionsSurface() async {
    if (!mounted) {
      return;
    }
    final settingsProvider = context.read<SettingsProvider>();
    final sizeClass = context.windowSizeClass;
    final conversationsVisible = settingsProvider.isDesktopPaneVisible(
      DesktopPane.conversations,
    );

    if (sizeClass.isCompact ||
        (sizeClass == WindowSizeClass.medium && !conversationsVisible)) {
      _scaffoldKey.currentState?.openDrawer();
      return;
    }

    if (sizeClass == WindowSizeClass.medium) {
      return;
    }

    if (!conversationsVisible) {
      await settingsProvider.setDesktopPaneVisible(
        DesktopPane.conversations,
        true,
      );
    }
  }

  Future<void> _toggleThinkingBubbles() async {
    if (!mounted) {
      return;
    }
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.setShowThinkingBubbles(
      !settingsProvider.showThinkingBubbles,
    );
  }

  Future<void> _triggerHistoryAction(
    ChatProvider chatProvider, {
    required _HistoryToolbarAction action,
  }) async {
    if (!mounted) {
      return;
    }

    final success = switch (action) {
      _HistoryToolbarAction.undo => await chatProvider.undoLastTurn(),
      _HistoryToolbarAction.redo => await chatProvider.redoLastTurn(),
    };
    if (success || !mounted) {
      return;
    }

    final message = switch (action) {
      _HistoryToolbarAction.undo => 'Nothing to undo in this session',
      _HistoryToolbarAction.redo => 'Nothing to redo in this session',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
