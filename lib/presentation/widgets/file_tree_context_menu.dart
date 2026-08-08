import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum FileTreeContextMenuActionType {
  newFile,
  newFolder,
  rename,
  duplicate,
  delete,
  copyPath,
  refresh,
}

class FileTreeContextMenuAction {
  const FileTreeContextMenuAction({
    required this.type,
    required this.label,
    required this.icon,
    this.destructive = false,
  });

  final FileTreeContextMenuActionType type;
  final String label;
  final IconData icon;
  final bool destructive;
}

class FileTreeContextMenuRegion extends StatelessWidget {
  const FileTreeContextMenuRegion({
    super.key,
    required this.child,
    required this.actions,
    required this.onSelected,
  });

  final Widget child;
  final List<FileTreeContextMenuAction> actions;
  final ValueChanged<FileTreeContextMenuActionType> onSelected;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapUp: (details) {
        _showMenu(context, details.globalPosition);
      },
      onLongPressStart: (details) {
        _showMenu(context, details.globalPosition);
      },
      child: child,
    );
  }

  Future<void> _showMenu(BuildContext context, Offset position) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) {
      return;
    }
    final selected = await showMenu<FileTreeContextMenuActionType>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: actions
          .map((action) {
            final color = action.destructive
                ? Theme.of(context).colorScheme.error
                : null;
            return PopupMenuItem<FileTreeContextMenuActionType>(
              key: ValueKey<String>(_menuKey(action.type)),
              value: action.type,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(action.icon, size: 18, color: color),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      action.label,
                      style: color == null ? null : TextStyle(color: color),
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  static String _menuKey(FileTreeContextMenuActionType type) {
    switch (type) {
      case FileTreeContextMenuActionType.newFile:
        return 'file_tree_menu_new_file';
      case FileTreeContextMenuActionType.newFolder:
        return 'file_tree_menu_new_folder';
      case FileTreeContextMenuActionType.rename:
        return 'file_tree_menu_rename';
      case FileTreeContextMenuActionType.duplicate:
        return 'file_tree_menu_duplicate';
      case FileTreeContextMenuActionType.delete:
        return 'file_tree_menu_delete';
      case FileTreeContextMenuActionType.copyPath:
        return 'file_tree_menu_copy_path';
      case FileTreeContextMenuActionType.refresh:
        return 'file_tree_menu_refresh';
    }
  }
}

IconData fileTreeActionIcon(FileTreeContextMenuActionType type) {
  switch (type) {
    case FileTreeContextMenuActionType.newFile:
      return Symbols.note_add;
    case FileTreeContextMenuActionType.newFolder:
      return Symbols.create_new_folder;
    case FileTreeContextMenuActionType.rename:
      return Symbols.drive_file_rename_outline;
    case FileTreeContextMenuActionType.duplicate:
      return Symbols.file_copy;
    case FileTreeContextMenuActionType.delete:
      return Symbols.delete;
    case FileTreeContextMenuActionType.copyPath:
      return Symbols.content_copy;
    case FileTreeContextMenuActionType.refresh:
      return Symbols.refresh_rounded;
  }
}
