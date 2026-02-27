part of '../chat_page.dart';

extension _ChatPageWorkspaceController on _ChatPageState {
  Future<void> _runProjectScopeTransition(
    Future<void> Function() operation,
  ) async {
    while (true) {
      final inFlight = _projectScopeTransitionTask;
      if (inFlight == null) {
        break;
      }
      await inFlight;
    }
    if (!mounted) {
      return;
    }

    final completion = Completer<void>();
    _projectScopeTransitionTask = completion.future;

    Object? pendingError;
    StackTrace? pendingStackTrace;

    _setState(() {
      _isProjectScopeTransitioning = true;
    });

    try {
      await operation();
    } catch (error, stackTrace) {
      pendingError = error;
      pendingStackTrace = stackTrace;
    } finally {
      if (mounted) {
        _setState(() {
          _isProjectScopeTransitioning = false;
        });
      }
      if (!completion.isCompleted) {
        completion.complete();
      }
      if (identical(_projectScopeTransitionTask, completion.future)) {
        _projectScopeTransitionTask = null;
      }
    }

    if (pendingError != null && pendingStackTrace != null) {
      Error.throwWithStackTrace(pendingError, pendingStackTrace);
    }
  }

  Future<void> _switchProjectContext(String projectId) async {
    final projectProvider = context.read<ProjectProvider>();
    if (projectProvider.currentProject?.id == projectId) {
      return;
    }
    final chatProvider = context.read<ChatProvider>();
    await _runProjectScopeTransition(() async {
      final changed = await projectProvider.switchProject(projectId);
      if (!changed) {
        return;
      }
      await chatProvider.onProjectScopeChanged(waitForRevalidation: false);
    });
  }

  Future<void> _switchDirectoryContext(String directory) async {
    final projectProvider = context.read<ProjectProvider>();
    final normalized = directory.trim();
    if (normalized.isEmpty || projectProvider.currentDirectory == normalized) {
      return;
    }
    final chatProvider = context.read<ChatProvider>();
    await _runProjectScopeTransition(() async {
      final switched = await projectProvider.switchToDirectoryContext(
        normalized,
      );
      if (!switched) {
        return;
      }
      await chatProvider.onProjectScopeChanged(waitForRevalidation: false);
    });
  }

  Future<void> _closeProjectContext(String projectId) async {
    await _runProjectScopeTransition(() async {
      final projectProvider = context.read<ProjectProvider>();
      final wasActiveProject = projectProvider.currentProject?.id == projectId;
      final changed = await projectProvider.closeProject(projectId);
      if (!changed || !wasActiveProject) {
        return;
      }
      await context.read<ChatProvider>().onProjectScopeChanged(
        waitForRevalidation: false,
      );
    });
  }

  Future<void> _reopenProjectContext(String projectId) async {
    final projectProvider = context.read<ProjectProvider>();
    final chatProvider = context.read<ChatProvider>();
    await _runProjectScopeTransition(() async {
      final changed = await projectProvider.reopenProject(
        projectId,
        makeActive: true,
      );
      if (!changed) {
        return;
      }
      await chatProvider.onProjectScopeChanged(waitForRevalidation: false);
    });
  }

  Future<void> _archiveClosedProjectContext(String projectId) async {
    final projectProvider = context.read<ProjectProvider>();
    final ok = await projectProvider.archiveClosedProject(projectId);
    if (!mounted) {
      return;
    }
    if (!ok) {
      final error = projectProvider.error;
      if (error != null && error.trim().isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Project archived from closed list')),
    );
  }

  Future<void> _createWorkspace() async {
    final projectProvider = context.read<ProjectProvider>();
    final appProvider = context.read<AppProvider>();
    final defaultDirectory =
        projectProvider.currentDirectory ??
        appProvider.appInfo?.path.data ??
        '/';
    final baseDirectoryController = TextEditingController(
      text: defaultDirectory,
    );
    final selectedDirectory = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Open project folder'),
              content: SizedBox(
                width: 420,
                child: TextField(
                  key: const ValueKey<String>('workspace_base_directory_input'),
                  controller: baseDirectoryController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Project directory',
                    hintText: '/repo/my-project',
                    helperText: 'Choose any folder to open as project context.',
                    suffixIcon: IconButton(
                      key: const ValueKey<String>(
                        'workspace_open_directory_picker_button',
                      ),
                      tooltip: 'Browse directories',
                      onPressed: () async {
                        final picked = await _openDirectoryPicker(
                          initialDirectory:
                              baseDirectoryController.text.trim().isEmpty
                              ? defaultDirectory
                              : baseDirectoryController.text.trim(),
                        );
                        if (!dialogContext.mounted || picked == null) {
                          return;
                        }
                        baseDirectoryController.text = picked;
                        setDialogState(() {});
                      },
                      icon: const Icon(Symbols.folder_open),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final baseDirectory = baseDirectoryController.text.trim();
                    if (!dialogContext.mounted) {
                      return;
                    }
                    Navigator.of(
                      dialogContext,
                    ).pop(baseDirectory.isEmpty ? null : baseDirectory);
                  },
                  child: const Text('Open folder'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted || selectedDirectory == null) {
      return;
    }

    final requestedDirectory = selectedDirectory.trim();
    if (requestedDirectory.isEmpty) {
      return;
    }

    await _switchDirectoryContext(requestedDirectory);
    if (!mounted) {
      return;
    }
    final openedDirectory = projectProvider.currentDirectory;
    if (openedDirectory == requestedDirectory) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project context opened: $requestedDirectory')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          projectProvider.error ??
              'Failed to open project context: $requestedDirectory',
        ),
      ),
    );
  }

  Future<String?> _openDirectoryPicker({
    required String initialDirectory,
  }) async {
    final appProvider = context.read<AppProvider>();
    final startDirectory = initialDirectory.trim().isNotEmpty
        ? initialDirectory.trim()
        : (appProvider.appInfo?.path.data.trim().isNotEmpty ?? false)
        ? appProvider.appInfo!.path.data.trim()
        : '/';

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DirectoryPickerSheet(initialDirectory: startDirectory),
    );
  }
}
