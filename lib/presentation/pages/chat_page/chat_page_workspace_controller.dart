part of '../chat_page.dart';

extension _ChatPageWorkspaceController on _ChatPageState {
  Future<void> _switchProjectContext(String projectId) async {
    final projectProvider = context.read<ProjectProvider>();
    final chatProvider = context.read<ChatProvider>();
    final changed = await projectProvider.switchProject(projectId);
    if (!changed) {
      return;
    }
    await chatProvider.onProjectScopeChanged();
  }

  Future<void> _closeProjectContext(String projectId) async {
    final projectProvider = context.read<ProjectProvider>();
    final chatProvider = context.read<ChatProvider>();
    final changed = await projectProvider.closeProject(projectId);
    if (!changed) {
      return;
    }
    await chatProvider.onProjectScopeChanged();
  }

  Future<void> _reopenProjectContext(String projectId) async {
    final projectProvider = context.read<ProjectProvider>();
    final chatProvider = context.read<ChatProvider>();
    final changed = await projectProvider.reopenProject(
      projectId,
      makeActive: true,
    );
    if (!changed) {
      return;
    }
    await chatProvider.onProjectScopeChanged();
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
    final chatProvider = context.read<ChatProvider>();
    final appProvider = context.read<AppProvider>();
    final defaultDirectory =
        projectProvider.currentDirectory ??
        appProvider.appInfo?.path.data ??
        '/';
    final nameController = TextEditingController();
    final baseDirectoryController = TextEditingController(
      text: defaultDirectory,
    );
    final createdInput = await showDialog<(String, String?)>(
      context: context,
      builder: (dialogContext) {
        var validatingDirectory = false;
        String? validationMessage;
        bool? gitDirectory;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Create Workspace'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const ValueKey<String>('workspace_name_input'),
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Workspace name',
                        hintText: 'ex: feature-branch',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey<String>(
                        'workspace_base_directory_input',
                      ),
                      controller: baseDirectoryController,
                      decoration: InputDecoration(
                        labelText: 'Base directory',
                        hintText: '/repo/my-project',
                        helperText:
                            'Browse folders to pick where the workspace is created',
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
                            setDialogState(() {
                              validationMessage = null;
                              gitDirectory = null;
                            });
                          },
                          icon: const Icon(Symbols.folder_open),
                        ),
                      ),
                    ),
                    if (validationMessage != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            gitDirectory == true
                                ? Symbols.check_circle_outline
                                : Symbols.warning_amber_rounded,
                            size: 16,
                            color: gitDirectory == true
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              validationMessage!,
                              key: const ValueKey<String>(
                                'workspace_directory_validation_message',
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: gitDirectory == true
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: validatingDirectory
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            setDialogState(() {
                              validationMessage =
                                  'Workspace name cannot be empty.';
                              gitDirectory = false;
                            });
                            return;
                          }

                          final baseDirectory = baseDirectoryController.text
                              .trim();
                          if (baseDirectory.isNotEmpty) {
                            setDialogState(() {
                              validatingDirectory = true;
                              validationMessage = null;
                              gitDirectory = null;
                            });
                            final isGit = await projectProvider.isGitDirectory(
                              baseDirectory,
                            );
                            if (!dialogContext.mounted) {
                              return;
                            }
                            if (isGit == null) {
                              setDialogState(() {
                                validatingDirectory = false;
                                validationMessage =
                                    projectProvider.error ??
                                    'Failed to validate directory.';
                                gitDirectory = false;
                              });
                              return;
                            }
                            if (!isGit) {
                              setDialogState(() {
                                validatingDirectory = false;
                                validationMessage =
                                    'Selected directory is not a Git repository.';
                                gitDirectory = false;
                              });
                              return;
                            }
                            setDialogState(() {
                              validatingDirectory = false;
                              validationMessage = 'Git repository detected.';
                              gitDirectory = true;
                            });
                          }

                          if (!dialogContext.mounted) {
                            return;
                          }
                          Navigator.of(dialogContext).pop((
                            name,
                            baseDirectory.isEmpty ? null : baseDirectory,
                          ));
                        },
                  child: validatingDirectory
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted || createdInput == null || createdInput.$1.trim().isEmpty) {
      return;
    }

    final created = await projectProvider.createWorktree(
      createdInput.$1,
      switchToCreated: true,
      directory: createdInput.$2,
    );
    if (!mounted) {
      return;
    }
    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(projectProvider.error ?? 'Failed to create workspace'),
        ),
      );
      return;
    }
    await projectProvider.switchToDirectoryContext(created.directory);
    await chatProvider.onProjectScopeChanged();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          createdInput.$2 == null
              ? 'Workspace created: ${created.name}'
              : 'Workspace created in ${createdInput.$2}: ${created.name}',
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

  Future<void> _resetWorkspace(String worktreeId) async {
    final projectProvider = context.read<ProjectProvider>();
    final ok = await projectProvider.resetWorktree(worktreeId);
    if (!mounted) {
      return;
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(projectProvider.error ?? 'Failed to reset workspace'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Workspace reset')));
  }

  Future<void> _deleteWorkspace(String worktreeId) async {
    final projectProvider = context.read<ProjectProvider>();
    final chatProvider = context.read<ChatProvider>();
    final ok = await projectProvider.deleteWorktree(worktreeId);
    if (!mounted) {
      return;
    }
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(projectProvider.error ?? 'Failed to delete workspace'),
        ),
      );
      return;
    }
    await chatProvider.onProjectScopeChanged();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Workspace deleted')));
  }
}
