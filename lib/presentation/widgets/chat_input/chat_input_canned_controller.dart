part of '../chat_input_widget.dart';

extension _ChatInputCannedController on _ChatInputWidgetState {
  List<CannedAnswer> get _visibleCannedAnswers {
    final merged = <CannedAnswer>[
      ..._projectCannedAnswers,
      ..._globalCannedAnswers,
    ];
    merged.sort((a, b) => b.updatedAtEpochMs.compareTo(a.updatedAtEpochMs));
    return merged;
  }

  String get _normalizedCannedServerId {
    final value = widget.cannedAnswersServerId?.trim() ?? '';
    return value;
  }

  String get _normalizedCannedScopeId {
    final value = widget.cannedAnswersScopeId?.trim() ?? '';
    return value;
  }

  Future<void> _loadCannedAnswers() async {
    final localDataSource = widget.cannedAnswersDataSource;
    if (localDataSource == null) {
      if (!mounted) {
        return;
      }
      _setState(() {
        _globalCannedAnswers = <CannedAnswer>[];
        _projectCannedAnswers = <CannedAnswer>[];
      });
      return;
    }
    final globalRaw = await localDataSource.getCannedAnswersJson();
    final hasScopedContext =
        _normalizedCannedServerId.isNotEmpty &&
        _normalizedCannedScopeId.isNotEmpty;
    final scopedRaw = hasScopedContext
        ? await localDataSource.getCannedAnswersJson(
            serverId: _normalizedCannedServerId,
            scopeId: _normalizedCannedScopeId,
          )
        : null;
    if (!mounted) {
      return;
    }
    _setState(() {
      _globalCannedAnswers = _decodeCannedAnswers(globalRaw);
      _projectCannedAnswers = _decodeCannedAnswers(scopedRaw);
      if (_popoverType == ChatComposerPopoverType.canned &&
          _activeSuggestionIndex >= _visibleCannedAnswers.length) {
        _activeSuggestionIndex = _visibleCannedAnswers.isEmpty
            ? 0
            : _visibleCannedAnswers.length - 1;
      }
    });
  }

  List<CannedAnswer> _decodeCannedAnswers(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <CannedAnswer>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <CannedAnswer>[];
      }
      final parsed = <CannedAnswer>[];
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        final answer = CannedAnswer.fromJson(item);
        if (answer != null) {
          parsed.add(answer);
        }
      }
      return parsed;
    } catch (_) {
      return <CannedAnswer>[];
    }
  }

  Future<void> _persistCannedAnswers({
    required CannedAnswerScopeMode scope,
  }) async {
    final localDataSource = widget.cannedAnswersDataSource;
    if (localDataSource == null) {
      return;
    }
    final answers = scope == CannedAnswerScopeMode.global
        ? _globalCannedAnswers
        : _projectCannedAnswers;
    final payload = jsonEncode(
      answers.map((answer) => answer.toJson()).toList(growable: false),
    );
    if (scope == CannedAnswerScopeMode.global) {
      await localDataSource.saveCannedAnswersJson(payload);
      return;
    }
    if (_normalizedCannedServerId.isEmpty || _normalizedCannedScopeId.isEmpty) {
      return;
    }
    await localDataSource.saveCannedAnswersJson(
      payload,
      serverId: _normalizedCannedServerId,
      scopeId: _normalizedCannedScopeId,
    );
  }

  void _toggleExtrasPopover() {
    _setState(() {
      if (_popoverType == ChatComposerPopoverType.canned) {
        _popoverType = ChatComposerPopoverType.none;
        _activeSuggestionIndex = 0;
        return;
      }
      _popoverType = ChatComposerPopoverType.canned;
      _activeSuggestionIndex = 0;
    });
    _ensureInputFocus();
  }

  Future<void> _openQuickReplyCreatorFromExtras() async {
    _closePopover();
    await _promptCreateCannedAnswer();
  }

  void _openAttachmentOptionsFromExtras() {
    if (!_canOpenAttachmentOptions) {
      return;
    }
    _closePopover();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showAttachmentOptions();
    });
  }

  Future<void> _applyCannedAnswer(CannedAnswer answer) async {
    final trimmedText = answer.text.trimRight();
    if (trimmedText.isEmpty) {
      return;
    }
    if (answer.insertMode == CannedAnswerInsertMode.replace) {
      _controller.value = TextEditingValue(
        text: trimmedText,
        selection: TextSelection.collapsed(offset: trimmedText.length),
      );
    } else {
      final parts = splitComposerTextAtSelection(_controller.value);
      _controller.value = composeComposerValueWithSuffix(
        leadingText: '${parts.leadingText}$trimmedText',
        trailingText: parts.trailingText,
      );
    }
    _setState(() {
      _isComposing = _controller.text.trim().isNotEmpty;
      _popoverType = ChatComposerPopoverType.none;
      _activeSuggestionIndex = 0;
    });
    _ensureInputFocus();
  }

  Future<void> _promptCreateCannedAnswer() async {
    final created = await _showCannedAnswerDialog();
    if (created == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    _setState(() {
      if (created.scopeMode == CannedAnswerScopeMode.global) {
        _globalCannedAnswers = <CannedAnswer>[created, ..._globalCannedAnswers];
      } else {
        _projectCannedAnswers = <CannedAnswer>[
          created,
          ..._projectCannedAnswers,
        ];
      }
    });
    await _persistCannedAnswers(scope: created.scopeMode);
    _ensureInputFocus();
  }

  Future<void> _promptEditOrDeleteCannedAnswer(CannedAnswer answer) async {
    if (!mounted) {
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Symbols.edit_rounded),
                title: const Text('Edit'),
                onTap: () => Navigator.of(context).pop('edit'),
              ),
              ListTile(
                leading: const Icon(Symbols.delete_rounded),
                title: const Text('Delete'),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) {
      return;
    }
    if (action == 'delete') {
      _setState(() {
        if (answer.scopeMode == CannedAnswerScopeMode.global) {
          _globalCannedAnswers = _globalCannedAnswers
              .where((item) => item.id != answer.id)
              .toList(growable: false);
        } else {
          _projectCannedAnswers = _projectCannedAnswers
              .where((item) => item.id != answer.id)
              .toList(growable: false);
        }
      });
      await _persistCannedAnswers(scope: answer.scopeMode);
      _ensureInputFocus();
      return;
    }
    final edited = await _showCannedAnswerDialog(initial: answer);
    if (!mounted || edited == null) {
      _ensureInputFocus();
      return;
    }
    _setState(() {
      _globalCannedAnswers = _globalCannedAnswers
          .where((item) => item.id != answer.id)
          .toList(growable: false);
      _projectCannedAnswers = _projectCannedAnswers
          .where((item) => item.id != answer.id)
          .toList(growable: false);
      if (edited.scopeMode == CannedAnswerScopeMode.global) {
        _globalCannedAnswers = <CannedAnswer>[edited, ..._globalCannedAnswers];
      } else {
        _projectCannedAnswers = <CannedAnswer>[
          edited,
          ..._projectCannedAnswers,
        ];
      }
    });
    await _persistCannedAnswers(scope: CannedAnswerScopeMode.global);
    await _persistCannedAnswers(scope: CannedAnswerScopeMode.projectOnly);
    _ensureInputFocus();
  }

  Future<CannedAnswer?> _showCannedAnswerDialog({CannedAnswer? initial}) async {
    final labelController = TextEditingController(
      text: initial?.normalizedLabel,
    );
    final textController = TextEditingController(text: initial?.text ?? '');
    var insertMode = initial?.insertMode ?? CannedAnswerInsertMode.append;
    var scopeMode = initial?.scopeMode ?? CannedAnswerScopeMode.global;
    final isProjectScopeAvailable =
        _normalizedCannedServerId.isNotEmpty &&
        _normalizedCannedScopeId.isNotEmpty;
    if (!isProjectScopeAvailable &&
        scopeMode == CannedAnswerScopeMode.projectOnly) {
      scopeMode = CannedAnswerScopeMode.global;
    }
    final result = await showDialog<CannedAnswer>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                initial == null ? 'Add canned answer' : 'Edit canned answer',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      minLines: 2,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Text'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Append at cursor'),
                      subtitle: const Text(
                        'Off means replace current composer text',
                      ),
                      value: insertMode == CannedAnswerInsertMode.append,
                      onChanged: (enabled) {
                        setDialogState(() {
                          insertMode = enabled
                              ? CannedAnswerInsertMode.append
                              : CannedAnswerInsertMode.replace;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Global'),
                      subtitle: Text(
                        isProjectScopeAvailable
                            ? 'Disable for project-only item'
                            : 'Project-only unavailable in current context',
                      ),
                      value: scopeMode == CannedAnswerScopeMode.global,
                      onChanged: isProjectScopeAvailable
                          ? (enabled) {
                              setDialogState(() {
                                scopeMode = enabled
                                    ? CannedAnswerScopeMode.global
                                    : CannedAnswerScopeMode.projectOnly;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final text = textController.text.trim();
                    if (text.isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop(
                      CannedAnswer(
                        id: initial?.id ?? _nextCannedAnswerId(),
                        label: labelController.text.trim().isEmpty
                            ? null
                            : labelController.text.trim(),
                        text: text,
                        insertMode: insertMode,
                        scopeMode: scopeMode,
                        updatedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    labelController.dispose();
    textController.dispose();
    return result;
  }

  String _nextCannedAnswerId() {
    return 'canned_${DateTime.now().microsecondsSinceEpoch}';
  }

  Widget _buildExtrasActionChip({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onPressed,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget? _buildCannedAnswerMetadata(CannedAnswer item) {
    final metadataText = item.normalizedLabel.isEmpty ? null : item.text;
    if (metadataText == null &&
        item.scopeMode != CannedAnswerScopeMode.global) {
      return null;
    }
    return Row(
      children: [
        if (item.scopeMode == CannedAnswerScopeMode.global) ...[
          const Icon(Symbols.public_rounded, size: 14),
          if (metadataText != null) const SizedBox(width: 6),
        ],
        if (metadataText != null)
          Expanded(
            child: Text(
              metadataText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildExtrasPopover({
    required ColorScheme colorScheme,
    required double maxHeight,
  }) {
    final items = _visibleCannedAnswers;
    return Material(
      key: const ValueKey<String>('composer_popover_panel_extras'),
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView(
          key: const ValueKey<String>('composer_popover_extras_replies'),
          padding: EdgeInsets.zero,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildExtrasActionChip(
                    icon: Symbols.edit_note_rounded,
                    label: 'New quick reply',
                    onPressed: () =>
                        unawaited(_openQuickReplyCreatorFromExtras()),
                  ),
                  _buildExtrasActionChip(
                    icon: Symbols.attach_file_rounded,
                    label: 'Attach files',
                    onPressed: _canOpenAttachmentOptions
                        ? _openAttachmentOptionsFromExtras
                        : null,
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Text('No quick replies yet.'),
              )
            else
              for (var index = 0; index < items.length; index++)
                Builder(
                  builder: (context) {
                    final item = items[index];
                    final selected = index == _activeSuggestionIndex;
                    return ListTile(
                      selected: selected,
                      title: Text(
                        item.normalizedLabel.isEmpty
                            ? item.text
                            : item.normalizedLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: _buildCannedAnswerMetadata(item),
                      onTap: () {
                        _setState(() {
                          _activeSuggestionIndex = index;
                        });
                        unawaited(_applyCannedAnswer(item));
                      },
                      onLongPress: () =>
                          unawaited(_promptEditOrDeleteCannedAnswer(item)),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
