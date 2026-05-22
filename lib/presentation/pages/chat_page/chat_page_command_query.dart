part of '../chat_page.dart';

extension _ChatPageCommandQuery on _ChatPageState {
  Future<List<ChatComposerMentionSuggestion>> _queryMentionSuggestions(
    String query,
  ) async {
    final normalizedQuery = query.trim().toLowerCase();
    final projectProvider = context.read<ProjectProvider>();
    final chatProvider = context.read<ChatProvider>();

    try {
      final filesFuture = projectProvider.findFiles(
        query: normalizedQuery,
        limit: 12,
        updateProviderError: false,
      );
      final symbolsFuture = projectProvider.findSymbols(
        query: normalizedQuery,
        limit: 8,
      );
      final foundFiles = await filesFuture;
      final foundSymbols = await symbolsFuture;

      final suggestions = <ChatComposerMentionSuggestion>[];

      for (final file in foundFiles ?? const <FileNode>[]) {
        final path = file.path.trim();
        if (path.isEmpty) {
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

      for (final symbol in foundSymbols ?? const <WorkspaceSymbol>[]) {
        final name = symbol.name.trim();
        if (name.isEmpty) {
          continue;
        }
        suggestions.add(
          ChatComposerMentionSuggestion(
            value: name,
            type: ChatComposerSuggestionType.symbol,
            subtitle: symbol.path.isEmpty
                ? symbol.kind ?? 'symbol'
                : symbol.path,
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
    final projectProvider = context.read<ProjectProvider>();
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

    final localProjectCommands = await _loadProjectLocalSlashCommands(
      projectDirectory: projectProvider.currentDirectory,
      dio: dio,
    );
    commands.addAll(localProjectCommands);

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

  Future<List<ChatComposerSlashCommandSuggestion>>
  _loadProjectLocalSlashCommands({
    required String? projectDirectory,
    required dynamic dio,
  }) async {
    final normalizedDirectory = projectDirectory?.trim();
    if (normalizedDirectory == null || normalizedDirectory.isEmpty) {
      return const <ChatComposerSlashCommandSuggestion>[];
    }

    try {
      final response = await dio.get(
        '/file',
        queryParameters: <String, dynamic>{
          'directory': normalizedDirectory,
          'path': '.opencode/commands',
        },
      );
      final data = response.data as List<dynamic>? ?? const <dynamic>[];
      final suggestions = <ChatComposerSlashCommandSuggestion>[];
      for (final raw in data) {
        if (raw is! Map) {
          continue;
        }
        final type = (raw['type'] as String?)?.trim().toLowerCase();
        if (type != 'file') {
          continue;
        }
        final name = (raw['name'] as String?)?.trim() ?? '';
        if (!name.toLowerCase().endsWith('.md')) {
          continue;
        }
        final commandName = name.substring(0, name.length - 3).trim();
        if (commandName.isEmpty) {
          continue;
        }
        suggestions.add(
          ChatComposerSlashCommandSuggestion(
            name: commandName,
            source: 'project',
            description: 'Project command',
          ),
        );
      }
      return suggestions;
    } catch (error, stackTrace) {
      AppLogger.debug(
        'Project local slash commands unavailable',
        error: error,
        stackTrace: stackTrace,
      );
      return const <ChatComposerSlashCommandSuggestion>[];
    }
  }

  _SlashCommandInvocation? _parseSlashCommandInvocation(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('/')) {
      return null;
    }

    final body = trimmed.substring(1).trimLeft();
    if (body.isEmpty) {
      return null;
    }

    final separatorMatch = RegExp(r'\s').firstMatch(body);
    final commandName =
        (separatorMatch == null
                ? body
                : body.substring(0, separatorMatch.start))
            .trim()
            .toLowerCase();
    if (commandName.isEmpty) {
      return null;
    }

    final arguments = separatorMatch == null
        ? ''
        : body.substring(separatorMatch.start).trimLeft();
    return _SlashCommandInvocation(name: commandName, arguments: arguments);
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
        _showChatPageMessageSnackBar(
          'Use @ for mentions, ! for shell, / for commands',
          hideCurrent: false,
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

    final providerMessage = chatProvider.errorMessage?.trim();
    final message = providerMessage != null && providerMessage.isNotEmpty
        ? providerMessage
        : switch (action) {
            _HistoryToolbarAction.undo => 'Nothing to undo in this session',
            _HistoryToolbarAction.redo => 'Nothing to redo in this session',
          };
    _showChatPageMessageSnackBar(message, hideCurrent: false);
  }
}

class _SlashCommandInvocation {
  const _SlashCommandInvocation({required this.name, required this.arguments});

  final String name;
  final String arguments;
}
