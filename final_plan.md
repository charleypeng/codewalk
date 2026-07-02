# Execution Plan — Issue #89: Files as a Micro File Manager

## Status

Ready.

## Problem

GitHub issue #89 requests evolving CodeWalk's current Files UI from a read-only file navigator into a small file manager. The current documented behavior in `BEHAVIOR.md` says the File Explorer is read-only and has no create/edit/delete operations. The user wants desktop right-click and mobile long-press actions for file management such as rename, create file, create folder, delete with confirmation, copy path, refresh, clear error handling, and no regression to the existing tap-to-open/tap-to-expand behavior.

The official local OpenCode docs currently document read/search/status file endpoints only (`GET /file`, `GET /file/content`, `GET /find`, `GET /find/file`, `GET /find/symbol`, `GET /file/status`). They also document `POST /session/:id/shell`, which runs shell commands in a session and returns chat-shaped message parts. There is no documented official file mutation API in the local docs snapshot.

## Objective

Implement a safe, capability-gated MVP file manager for the Files tree:

- Preserve all existing read-only navigation behavior.
- Add a context menu for file tree rows: desktop secondary click and mobile long press.
- Add file operations only when a shell capability probe succeeds for the active server/project directory.
- Support `New file`, `New folder`, `Rename`, `Delete`, `Copy path`, and `Refresh`.
- Keep unsupported environments read-only for mutating actions while still allowing `Copy path` and `Refresh`.
- Keep all file operations scoped to the active project directory.
- Refresh tree state and open file tabs correctly after successful mutations.
- Document the behavior change and ADR-023 exception/nuance.
- Add tests covering the exact feature behavior and failure fallbacks.

## Context and Constraints

### Project Facts

- Repository: `verseles/codewalk`.
- Workspace: `/home/ubuntu/MEGA/WORK/codewalk`.
- Project: CodeWalk, a Flutter mobile and desktop client for OpenCode.
- Project rules require mobile + desktop support, mobile UX consideration, `BEHAVIOR.md` before substantial planning, and ADR-023 alignment for behavior changes.
- OpenChamber is a secondary community reference only; it must not override official OpenCode docs/source.
- Do not run the destructive global ARB generator `dart tool/i18n/generate_arb.dart` unless all newer keys are synchronized. For this task, do not run it.
- For Flutter/Dart commands in non-interactive shells, prepend `export PATH="$HOME/flutter/bin:$PATH" && ...`.
- For CodeWalk validation, prefer focused tests while iterating, then `make check` at the final validation gate.

### Relevant Existing Files

- `BEHAVIOR.md`
  - Current Files behavior around lines 1231-1247 states the File Explorer is read-only.
- `ADR.md`
  - ADR-008 describes context-scoped file browsing/viewing with tree cache, tab state, ranked Quick Open, and diff-signature selective refresh.
  - ADR-023 requires official OpenCode contract-first behavior or an explicit ADR exception for intentional divergence.
- `CONTRACT_MATRIX.md`
  - Notes terminal/PTy runtime doc/source mismatch risk; do not broaden terminal assumptions without capability checks.
- `ai-docs/opencode_server.md`
  - Lines 613-627 document `POST /session/:id/shell`.
  - Lines 651-717 document read/search/status file endpoints only.
- `ai-docs/opencode_web.md`
  - Notes Windows users should run `opencode web` from WSL for filesystem/terminal integration.
- `lib/presentation/pages/chat_page.dart`
  - Imports DI, `DioClient`, `path_utils`, file entities, l10n, and all chat page parts.
- `lib/presentation/pages/chat_page_local_models_part.dart`
  - `_FileExplorerContextState` stores `directoryChildren`, `expandedDirectories`, `loadingDirectories`, `directoryErrors`, `tabsByPath`, `tabSelection`, `selectedLinesByPath`, `pendingScrollToLine`, and `treeError`.
- `lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart`
  - Builds desktop file pane, resolves context state, loads directory nodes, handles Quick Open and root panel controls.
  - Existing keys include `file_tree_list`, `file_tree_open_files_button`, `file_tree_quick_open_button`, `file_tree_refresh_button`, `hide_files_sidebar_button`, `file_tree_error_<key>`, and `file_tree_retry_<key>`.
- `lib/presentation/pages/chat_page/chat_page_file_runtime.dart`
  - Builds file tree rows with `InkWell` keyed `file_tree_item_<normalized path>`.
  - Existing `onTap` toggles directories or opens files in viewer.
  - Contains file root loading, diff reconciliation, list/read fallbacks, file path tap handling, tab activation/closing/reloading, and open-files dialog.
- `lib/presentation/pages/chat_page/chat_page_file_viewer.dart`
  - File viewer/tabs/content panel.
- `lib/presentation/pages/chat_page/chat_page_chrome.dart`
  - `_openMobileFilesDialog` uses the same file explorer panel in fullscreen mobile UI.
- `lib/presentation/utils/file_explorer_logic.dart`
  - Pure file-tab and Quick Open helpers.
- `lib/domain/repositories/project_repository.dart`
  - Current file API is read/search only: `listFiles`, `findFiles`, `searchFileContents`, `findSymbols`, `readFileContent`.
- `lib/data/datasources/project_remote_datasource.dart`
  - Calls official read/search file endpoints only.
- `lib/presentation/providers/project_provider.dart`
  - Exposes current project/directory context and read/search file methods.
- `lib/data/datasources/chat_remote_datasource_helpers.dart`
  - `_sendShellCommand` posts to `/session/$sessionId/shell` with optional `directory` query parameter.
- `lib/data/datasources/quota_remote_datasource.dart`
  - Existing example of ephemeral session + shell command + sentinel JSON extraction + delete session.
- `lib/presentation/widgets/session_context_menu.dart`
  - Existing right-click/long-press context menu pattern using `GestureDetector`, `onSecondaryTapUp`, `onLongPressStart`, and `showMenu`.
- `test/widget/chat_session_list_test.dart`
  - Existing test pattern for secondary-click and long-press menus.
- `test/widget/chat_page_test.dart`
  - Existing file-tree, Quick Open, file viewer, binary/error preview, and file-tab coverage.
- `test/support/fakes.dart`
  - `FakeProjectRepository` currently fakes read/search APIs only.
- `lib/l10n/app_en.arb`
  - Existing `files*` keys around lines 2053-2111 cover read-only Files strings.
- `lib/l10n/generated/`
  - Generated l10n classes are checked in and must be updated after ARB changes.

## Decisions (Resolved)

1. **Do not query live `/doc` in the MVP flow.** Use the current local docs as the contract baseline: file endpoints are read-only and there is no documented file-mutation API.
2. **Use `POST /session/:id/shell` only behind a cached capability probe.** Mutating actions must not be shown as enabled until the active server/directory proves it can run the required POSIX-style sentinel command.
3. **Use an ephemeral session for shell file operations.** Do not run file manager operations through the currently visible chat session.
4. **Do not use PTY/terminal endpoints for file operations.** PTY has a known docs/source mismatch risk and is unnecessary for non-interactive file operations.
5. **Do not use local `dart:io` against the client filesystem.** The Files tree represents the OpenCode server/project filesystem, not necessarily the device running CodeWalk.
6. **Do not add file mutation methods to `ProjectRepository`.** Keep official read/search project APIs separate from shell-backed file operations by creating a dedicated file operations service/datasource.
7. **Implement a POSIX/WSL MVP.** If the shell probe does not confirm POSIX-compatible behavior, the UI remains read-only for mutating actions.
8. **Use sentinel JSON only.** The client must parse only lines beginning with `CW_FILE_OP_JSON:` and must treat missing or malformed sentinel output as failure. Do not parse free-form stderr as the primary success/error contract.
9. **Implement same-directory rename only.** Rename changes the leaf name within the same parent directory; moving files/folders to another directory is out of scope.
10. **Implement single-level create file/folder.** New file/folder names are leaf names under the selected directory or root; nested path creation such as `foo/bar/baz.txt` is out of scope.
11. **Implement recursive folder delete only after explicit confirmation.** Delete must never target the project root; confirmation copy must state that folders and their contents will be deleted permanently.
12. **Do not implement `Reveal in folder` in this MVP.** It has no reliable cross-platform mobile/desktop behavior and remains out of scope for this issue implementation.
13. **Update ADR.md.** Because shell-backed file mutations intentionally use an endpoint outside the documented Files read API, add an ADR-023 exception/nuance documenting rationale, risks, feature gate, rollback behavior, and tests.

## Why This Plan

This plan delivers the issue's micro file manager behavior without pretending that OpenCode has a structured file-mutation API. It limits risk by gating mutating UI behind a shell capability probe, isolating operations in ephemeral sessions, using a sentinel response contract, keeping operations scoped to the project root, and preserving read-only behavior when the environment is incompatible. It also addresses planner-raised risks around ADR-023, shell output fragility, platform variance, cache invalidation, open tabs, tests, and l10n/documentation.

## Overview

Add a dedicated shell-backed file operations service, guarded by a cached capability probe for the active server/directory. Add desktop and mobile context menus to file tree rows and a root-level “New” menu in the Files panel. Implement mutating actions with strict client-side validation, server-side shell validation, sentinel JSON parsing, targeted tree refresh, and open-tab reconciliation. Update documentation, ADR, l10n, and tests.

## Steps

### 1. Add a dedicated file operations service and result model

- **Files**:
  - Create `lib/presentation/services/workspace_file_operations_service.dart`.
  - Update `lib/core/di/injection_container.dart`.
  - Update `lib/presentation/pages/chat_page.dart` imports if needed.
- **Details**:
  - Define these immutable classes/enums in `workspace_file_operations_service.dart`:

```dart
enum WorkspaceFileOperationCode {
  ok,
  unavailable,
  invalidName,
  outsideRoot,
  rootDeleteBlocked,
  missing,
  alreadyExists,
  permissionDenied,
  notDirectory,
  failed,
  malformedResponse,
}

class WorkspaceFileOperationResult {
  const WorkspaceFileOperationResult({
    required this.ok,
    required this.code,
    required this.message,
    this.path,
    this.newPath,
  });

  final bool ok;
  final WorkspaceFileOperationCode code;
  final String message;
  final String? path;
  final String? newPath;
}

class WorkspaceFileOperationsCapabilities {
  const WorkspaceFileOperationsCapabilities({
    required this.shellFileOpsSupported,
    required this.message,
  });

  final bool shellFileOpsSupported;
  final String message;
}
```

  - Define `WorkspaceFileOperationsService` with methods:

```dart
abstract class WorkspaceFileOperationsService {
  Future<WorkspaceFileOperationsCapabilities> getCapabilities({
    required String serverScopeKey,
    required String directory,
  });

  Future<void> invalidateCapabilities({
    required String serverScopeKey,
    required String directory,
  });

  Future<WorkspaceFileOperationResult> createFile({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  });

  Future<WorkspaceFileOperationResult> createFolder({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  });

  Future<WorkspaceFileOperationResult> rename({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String oldName,
    required String newName,
  });

  Future<WorkspaceFileOperationResult> delete({
    required String serverScopeKey,
    required String rootDirectory,
    required String parentDirectory,
    required String name,
  });
}
```

  - Implement `WorkspaceFileOperationsServiceImpl` in the same file using `DioClient().dio` injected from DI.
  - Register it in `lib/core/di/injection_container.dart`:

```dart
sl.registerLazySingleton<WorkspaceFileOperationsService>(
  () => WorkspaceFileOperationsServiceImpl(dio: sl<DioClient>().dio),
);
```

  - Use `ChatTitleGenerator.ephemeralSessionTitle` and `ChatTitleGenerator.ephemeralSessionIds` the same way as `QuotaRemoteDataSource` so ephemeral shell sessions do not remain visible in normal session lists.
- **Risk**: Medium. This introduces a new shell-backed service path. Mitigate by isolating it from `ProjectRepository`, gating capabilities, and adding focused tests.
- **Validation**: `export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/presentation/services/workspace_file_operations_service.dart lib/core/di/injection_container.dart`.

### 2. Implement ephemeral shell execution with sentinel JSON parsing

- **Files**:
  - `lib/presentation/services/workspace_file_operations_service.dart`.
- **Details**:
  - Implement private helpers:
    - `_createEphemeralSession()` using `POST /session` with `{'title': ChatTitleGenerator.ephemeralSessionTitle}`.
    - `_deleteEphemeralSession(String sessionId)` using `DELETE /session/$sessionId` in `finally`.
    - `_runShellOperation({required String directory, required String command})` using `POST /session/$sessionId/shell`, data `{'agent': 'build', 'command': command}`, query parameter `{'directory': directory}`.
    - `_extractSentinel(Map<String, dynamic> envelope)` that scans `parts` and nested `state` string fields for a line beginning with `CW_FILE_OP_JSON:`.
    - `_parseSentinelJson(String raw)` that decodes JSON and maps `ok/code/message/path/newPath` to `WorkspaceFileOperationResult`.
  - Treat these as `WorkspaceFileOperationCode.unavailable`:
    - `POST /session` fails.
    - `/session/:id/shell` returns 404.
    - sentinel output is absent in capability probe.
  - Treat malformed JSON or unknown codes as `WorkspaceFileOperationCode.malformedResponse`.
  - Never infer success from HTTP 200 alone. Success requires sentinel JSON with `ok: true`.
- **Risk**: High. `/session/:id/shell` returns chat-shaped data, not a typed file API. Mitigate by accepting sentinel JSON only and failing closed.
- **Validation**: Add unit tests for sentinel extraction/parsing before wiring UI.

### 3. Add cached capability probe

- **Files**:
  - `lib/presentation/services/workspace_file_operations_service.dart`.
  - `test/unit/services/workspace_file_operations_service_test.dart` or nearest existing service-test location.
- **Details**:
  - Cache capabilities by this key:

```dart
'$serverScopeKey::$directory'
```

  - The probe command must be POSIX-compatible and must output exactly one sentinel line:

```sh
printf '%s\n' 'CW_FILE_OP_JSON:{"ok":true,"code":"ok","message":"shell file operations available"}'
```

  - `getCapabilities(...)` returns cached success/failure until invalidated or until the app/server context changes naturally by key.
  - Do not query live `/doc` in this MVP.
  - If a later operation returns `unavailable` or `malformedResponse`, call `invalidateCapabilities(...)` for that key and show the operation error.
- **Risk**: Medium. Some servers may support shell but not POSIX shell syntax. Mitigate by keeping mutating actions disabled when the probe fails.
- **Validation**: Unit-test cache hit, cache invalidation, probe success, probe 404, and malformed probe output.

### 4. Add strict name/path validation before command construction

- **Files**:
  - `lib/presentation/services/workspace_file_operations_service.dart`.
  - Consider adding pure helpers to `lib/presentation/utils/file_explorer_logic.dart` only if tests benefit from pure extraction.
- **Details**:
  - Implement `_validateLeafName(String name)` with these rules:
    - trim surrounding whitespace;
    - reject empty names;
    - reject `.` and `..`;
    - reject names containing `/`, `\\`, or NUL (`\x00`);
    - return the trimmed name for command use.
  - Implement `_parentPath(String path)` in the UI/service layer using `normalizeFilePath` and last slash splitting.
  - Implement `_isPathUnderRoot(String rootDirectory, String candidate)` using normalized forward-slash paths:
    - `candidate == root` is allowed for root checks but not delete;
    - `candidate.startsWith('$root/')` is allowed;
    - everything else is `outsideRoot`.
  - Pass only `rootDirectory`, `parentDirectory`, and leaf names into the shell script. Do not pass arbitrary user-entered paths.
  - Validate on the client before running shell and validate again in shell.
- **Risk**: High. Bad validation can cause data loss. Mitigate with duplicate client + shell checks and tests for traversal and root delete.
- **Validation**: Unit-test invalid names, traversal attempts, root delete blocking, and parent/root prefix handling.

### 5. Implement POSIX shell scripts for create file/folder, rename, and delete

- **Files**:
  - `lib/presentation/services/workspace_file_operations_service.dart`.
- **Details**:
  - Implement a POSIX single-quote helper:

```dart
String _shQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";
```

  - Each operation must generate a script that:
    - uses `set -u`;
    - assigns quoted variables `CW_ROOT_INPUT`, `CW_PARENT_INPUT`, `CW_NAME`, and for rename `CW_NEW_NAME`;
    - canonicalizes root and parent with `cd -- "$path" && pwd -P`;
    - validates parent is root or under root;
    - blocks root delete;
    - checks existence/non-existence before mutation;
    - prints a sentinel JSON line for every expected outcome;
    - prints `failed` for unexpected command failure.
  - Use these shell operation semantics:
    - `createFile`: fail if target exists; create with `: > "$target"`.
    - `createFolder`: fail if target exists; create with `mkdir -- "$target"`.
    - `rename`: fail if source missing; fail if destination exists; execute `mv -- "$source" "$destination"`.
    - `delete`: fail if target missing; fail if target equals root; execute `rm -r -- "$target"` for directories and `rm -- "$target"` for non-directories.
  - Use these sentinel codes exactly:

```json
{"ok":true,"code":"ok","message":"ok"}
{"ok":false,"code":"invalidName","message":"Invalid name."}
{"ok":false,"code":"outsideRoot","message":"Path is outside the project root."}
{"ok":false,"code":"rootDeleteBlocked","message":"The project root cannot be deleted."}
{"ok":false,"code":"missing","message":"Path does not exist."}
{"ok":false,"code":"alreadyExists","message":"A file or folder with that name already exists."}
{"ok":false,"code":"permissionDenied","message":"Permission denied."}
{"ok":false,"code":"notDirectory","message":"Parent is not a directory."}
{"ok":false,"code":"failed","message":"File operation failed."}
```

  - Detect permission errors with a best-effort precheck: before mutating, test `[ -w "$parent" ]`; if false, emit `permissionDenied`. Still handle command failure as `failed` because POSIX permission checks can be imperfect.
  - Include `path` and `newPath` in success sentinel for rename. Do not include raw stderr in sentinel JSON.
- **Risk**: High. Shell operations are destructive and platform-sensitive. Mitigate by POSIX capability probe, strict quoting, and fail-closed parsing.
- **Validation**: Unit-test command generation for spaces, unicode, and single quotes in paths/names; unit-test parser behavior for every sentinel code.

### 6. Add Files context menu UI without breaking tap behavior

- **Files**:
  - Create `lib/presentation/widgets/file_tree_context_menu.dart`.
  - Update `lib/presentation/pages/chat_page.dart` imports.
  - Update `lib/presentation/pages/chat_page/chat_page_file_runtime.dart`.
- **Details**:
  - Create a `FileTreeContextMenuRegion` widget modeled after `SessionContextMenuRegion` but file-specific and generic enough to avoid session coupling.
  - Required API:

```dart
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
}
```

  - Use `GestureDetector(behavior: HitTestBehavior.translucent, onSecondaryTapUp, onLongPressStart)` and `showMenu<FileTreeContextMenuActionType>` at pointer/global position.
  - Define action types: `newFile`, `newFolder`, `rename`, `delete`, `copyPath`, `refresh`.
  - Add menu item keys:
    - `file_tree_menu_new_file`
    - `file_tree_menu_new_folder`
    - `file_tree_menu_rename`
    - `file_tree_menu_delete`
    - `file_tree_menu_copy_path`
    - `file_tree_menu_refresh`
  - Wrap the existing `InkWell` row in `_buildFileTreeChildren` with `FileTreeContextMenuRegion` while preserving the existing `InkWell.onTap` exactly.
  - For directories with shell capability: show `New file`, `New folder`, `Rename`, `Delete`, `Copy path`, `Refresh`.
  - For files with shell capability: show `Rename`, `Delete`, `Copy path`, `Refresh`.
  - Without shell capability: show only `Copy path` and `Refresh`; do not show disabled destructive items.
- **Risk**: Medium. Gesture wrapping can accidentally trigger tap and menu together. Mitigate with tests for secondary-click and long-press not opening/toggling items.
- **Validation**: Widget tests: right-click on a file opens menu and does not open the file; long-press on a directory opens menu and does not expand/collapse it.

### 7. Add root-level New menu in the Files panel header

- **Files**:
  - `lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart`.
  - `lib/presentation/widgets/file_tree_context_menu.dart` if reusing menu widgets.
- **Details**:
  - Add a small `IconButton` or `PopupMenuButton` near the existing Quick Open and Refresh buttons in `_buildFileExplorerPanel`.
  - Key: `file_tree_new_button`.
  - Tooltip/l10n: `filesNew`.
  - The root New menu contains `New file` and `New folder` only when shell capability is available for the current root directory.
  - If shell capability is unavailable, do not render the root New button.
  - Root New actions create items under the current root directory.
- **Risk**: Low. Adds discoverability for root creation. Mitigate by hiding when unsupported.
- **Validation**: Widget test that root New button appears only when fake capabilities report shell support.

### 8. Add dialogs and handlers for create, rename, delete, copy path, and refresh

- **Files**:
  - `lib/presentation/pages/chat_page/chat_page_file_runtime.dart`.
  - `lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart` for root New handlers.
  - `lib/presentation/widgets/file_tree_context_menu.dart` if action routing helpers are placed there.
- **Details**:
  - Add private ChatPage methods:
    - `_handleFileTreeAction(...)`.
    - `_showCreateFileDialog(...)`.
    - `_showCreateFolderDialog(...)`.
    - `_showRenameFileNodeDialog(...)`.
    - `_confirmDeleteFileNode(...)`.
    - `_runFileOperationWithFeedback(...)`.
    - `_refreshAfterFileMutation(...)`.
    - `_copyFilePathToClipboard(String path)`.
  - Use `showDialog` with `TextField`, `ModalPrimaryActionShortcuts`, `commonCancel`, and clear primary action labels.
  - Delete confirmation must include the item name and this exact meaning: deletion is permanent and folders include their contents.
  - Display errors with `ScaffoldMessenger.of(context).showSnackBar(...)` using l10n messages mapped from `WorkspaceFileOperationCode`.
  - During an operation, prevent duplicate submission by disabling the dialog primary action or using an in-flight flag in the dialog state.
  - Copy path uses `Clipboard.setData(ClipboardData(text: path))` and snackbar confirmation.
  - Refresh calls `_loadDirectoryNodes(...)` for the selected directory if it is a directory, otherwise its parent.
- **Risk**: Medium. Dialogs can be hard to test in the large ChatPage widget. Mitigate by keeping dialog logic small and adding targeted widget tests.
- **Validation**: Widget tests for each dialog's happy path and cancel path.

### 9. Reconcile tree cache and open tabs after successful mutations

- **Files**:
  - `lib/presentation/pages/chat_page/chat_page_file_runtime.dart`.
  - `lib/presentation/utils/file_explorer_logic.dart` if pure helper extraction is useful.
  - `test/unit/utils/file_explorer_logic_test.dart` if pure helpers are added.
- **Details**:
  - Add `_refreshAfterFileMutation` behavior:
    - Always reload the mutation parent directory using `_loadDirectoryNodes` with `cacheKey` equal to the parent path or `_rootTreeCacheKey` for root.
    - For create folder: keep parent expanded and reload parent.
    - For create file: reload parent; do not automatically open the new file.
    - For rename file: reload parent; if `tabsByPath` contains old path, move that tab entry to the new path and update `tabSelection.activePath` if needed.
    - For rename folder: reload parent; for every open tab whose path equals old folder path or starts with `oldFolderPath/`, update the key/path prefix to the new folder path.
    - For delete file: close the tab for the deleted path if open; clear `selectedLinesByPath[path]` and `pendingScrollToLine[path]`.
    - For delete folder: close all open tabs whose path equals the folder path or starts with `folderPath/`; clear selected-line and pending-scroll entries for those paths; remove stale `directoryChildren`, `directoryErrors`, `loadingDirectories`, and `expandedDirectories` entries for the deleted subtree.
  - Ensure stale async directory loads do not resurrect deleted cache entries. If an existing request finishes after delete/rename, its parent reload should win. Use the existing request/load guards if present; otherwise add a mutation generation integer to `_FileExplorerContextState` and verify it before applying delayed results.
- **Risk**: High. Incorrect reconciliation can leave broken tabs or stale tree rows. Mitigate with unit tests for pure path updates and widget tests for open tab behavior.
- **Validation**: Widget tests: open a file, rename it, verify tab path/name updates; open nested file, delete parent folder, verify tab closes.

### 10. Add l10n keys safely

- **Files**:
  - `lib/l10n/app_en.arb`.
  - All existing `lib/l10n/app_*.arb` locale files.
  - `lib/l10n/generated/app_localizations*.dart`.
- **Details**:
  - Add these keys to `app_en.arb` near the existing `files*` block:

```json
"filesNew": "New",
"filesNewFile": "New file",
"filesNewFolder": "New folder",
"filesRename": "Rename",
"filesRenameTitle": "Rename {name}",
"filesCreateFileTitle": "Create file",
"filesCreateFolderTitle": "Create folder",
"filesNameHint": "Name",
"filesDelete": "Delete",
"filesDeleteTitle": "Delete {name}",
"filesDeleteConfirm": "Delete {name}? This cannot be undone. Folders and their contents will be deleted.",
"filesCopyPath": "Copy path",
"filesPathCopied": "Path copied.",
"filesOperationUnavailable": "File operations are not available for this server.",
"filesInvalidName": "Enter a valid name without path separators.",
"filesAlreadyExists": "A file or folder with that name already exists.",
"filesPermissionDenied": "Permission denied.",
"filesPathMissing": "Path does not exist.",
"filesOutsideRoot": "The path is outside the project root.",
"filesRootDeleteBlocked": "The project root cannot be deleted.",
"filesOperationFailed": "File operation failed.",
"filesFileCreated": "File created.",
"filesFolderCreated": "Folder created.",
"filesRenamed": "Renamed.",
"filesDeleted": "Deleted."
```

  - Add metadata entries for placeholder keys (`name`) using the existing ARB metadata style.
  - Add the same keys to all locale ARB files. Use English fallback strings if the safe translation workflow is not being run in this implementation session.
  - Run Flutter's l10n generator, not the destructive custom ARB generator:

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n
```

- **Risk**: Medium. Generated localization files can be large and easy to desynchronize. Mitigate by using `flutter gen-l10n` and checking generated getters compile.
- **Validation**: `export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/l10n/generated lib/presentation/pages/chat_page.dart`.

### 11. Add tests and fakes for file operations

- **Files**:
  - `test/support/fakes.dart` or create `test/support/fake_workspace_file_operations_service.dart`.
  - `test/unit/services/workspace_file_operations_service_test.dart`.
  - `test/widget/chat_page_test.dart`.
- **Details**:
  - Prefer creating a fake `WorkspaceFileOperationsService` with:
    - configurable capabilities;
    - recorded calls;
    - in-memory result queue per operation;
    - optional mutation of `FakeProjectRepository.filesByPath` for widget tests.
  - Update `_testApp(...)` in `chat_page_test.dart` to accept `WorkspaceFileOperationsService? fileOperationsService`; register it in `di.sl` before pumping `ChatPage`.
  - Add unit tests for:
    - sentinel extraction/parsing;
    - capability cache success/failure/invalidation;
    - name validation;
    - command quoting for spaces, unicode, and single quotes;
    - mapping sentinel codes to result codes.
  - Add widget tests for:
    - secondary-click on `file_tree_item_/repo/a/lib/main.dart` opens file menu and does not open the file;
    - long-press on `file_tree_item_/repo/a/lib` opens file menu and does not toggle expansion;
    - unsupported capabilities hide `New file`, `New folder`, `Rename`, and `Delete`, but keep `Copy path` and `Refresh`;
    - root `file_tree_new_button` appears only when capabilities are supported;
    - create file under directory refreshes the parent and shows new row;
    - create folder under directory refreshes the parent and shows new row;
    - rename file updates the visible row and an open tab;
    - delete file shows confirmation, calls service, refreshes parent, and closes any open tab;
    - service error `alreadyExists` shows the already-exists message and does not mutate UI state.
- **Risk**: Medium. `chat_page_test.dart` is large and can be slow. Mitigate by keeping focused tests near existing Files tests and using existing helper setup.
- **Validation**:

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/services/workspace_file_operations_service_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "file tree"
```

### 12. Update behavior, code map, and ADR documentation

- **Files**:
  - `BEHAVIOR.md`.
  - `CODEBASE.md`.
  - `ADR.md`.
- **Details**:
  - Update `BEHAVIOR.md` Files section to state:
    - Files remains read-only when server shell file operations are unavailable.
    - When capability probe succeeds, Files offers context-menu file operations.
    - Mutating operations are scoped to the current project root.
    - Delete requires confirmation.
    - Unsupported environments show read-only behavior with `Copy path` and `Refresh`.
  - Update `CODEBASE.md` to include the new file operations service, context menu widget, and test locations.
  - Update `ADR.md` with an ADR-023 exception/nuance:
    - Decision: shell-backed file operations are allowed only behind a capability gate.
    - Rationale: official Files API is read-only and issue #89 requires file management before upstream typed mutation endpoints exist.
    - Risks: shell output shape, platform variance, command quoting, destructive operations, future migration to official APIs.
    - Mitigations: ephemeral session, POSIX probe, sentinel JSON only, root/name validation, fail-closed UI, tests.
    - Rollback: disable/hide mutating actions by failing the capability probe or unregistering the service; Files remains read-only.
  - Use `adrkeeper`/ADR flow and `codemapper`/CODEBASE flow if executing within the normal OpenCode agent workflow.
- **Risk**: Medium. ADR/documentation must match actual implementation. Mitigate by updating docs after code behavior is stable.
- **Validation**: Review docs diff manually and ensure no ranking/planning artifact is added to docs.

### 13. Run validation gates

- **Files**: No edits; command-only validation.
- **Details**:
  - Run focused validation first:

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/presentation/services/workspace_file_operations_service.dart lib/presentation/widgets/file_tree_context_menu.dart lib/presentation/pages/chat_page.dart test/unit/services/workspace_file_operations_service_test.dart test/widget/chat_page_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/services/workspace_file_operations_service_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "file tree"
```

  - Run final validation gate:

```bash
make check
```

- **Risk**: Medium. Full `make check` can expose unrelated existing failures. Mitigate by recording exact failures and separating unrelated pre-existing issues from this change.
- **Validation**: All targeted tests and `make check` pass, or any failure is explicitly triaged before completion.

## Risks & Mitigations

### Critical

- **Risk: Destructive shell command can delete or rename the wrong path.**
  - **Mitigation**: Pass only root, parent, and leaf names; reject path separators and traversal; validate root prefix client-side and shell-side; block root delete; quote all shell values; use tests for dangerous names.

### High

- **Risk: `/session/:id/shell` is not a structured file API.**
  - **Mitigation**: Use capability probe; parse sentinel JSON only; fail closed on missing/malformed sentinel; document ADR-023 exception.
- **Risk: Platform differences break shell operations.**
  - **Mitigation**: POSIX probe gates mutating UI; unsupported shells remain read-only.
- **Risk: Tree cache and tabs desynchronize after rename/delete.**
  - **Mitigation**: Explicit parent reload; migrate/close affected tabs; clear subtree cache entries; add widget tests for open-tab reconciliation.

### Medium

- **Risk: Context menu gestures conflict with tap-to-open/tap-to-expand.**
  - **Mitigation**: Wrap row without changing existing `InkWell.onTap`; test secondary-click and long-press do not trigger tap behavior.
- **Risk: L10n generated files desynchronize.**
  - **Mitigation**: Add keys to all ARBs and run `flutter gen-l10n`; do not run the destructive custom ARB generator.
- **Risk: Ephemeral sessions leak into session list.**
  - **Mitigation**: Reuse `ChatTitleGenerator.ephemeralSessionTitle` and `ephemeralSessionIds`; always delete ephemeral sessions in `finally`.

### Low

- **Risk: Users expect unsupported `Reveal in folder`.**
  - **Mitigation**: Keep it out of scope and do not show it in UI.

## Assumptions to Validate

1. **Assumption: `POST /session/:id/shell` exists on the active server.**
   - **Verify**: Capability probe creates an ephemeral session and receives sentinel output.
   - **Fallback**: Hide mutating file actions; keep Files read-only with `Copy path` and `Refresh`.
2. **Assumption: the active server shell is POSIX-compatible or WSL-compatible.**
   - **Verify**: Probe command using POSIX `printf` succeeds.
   - **Fallback**: Hide mutating file actions.
3. **Assumption: current project directory paths returned by `/file` correspond to shell-visible paths under `ProjectProvider.currentDirectory`.**
   - **Verify**: Shell script can canonicalize root and parent with `cd -- "$path" && pwd -P`.
   - **Fallback**: Return `outsideRoot`, `notDirectory`, or `unavailable`; show read-only behavior for mutating actions if probe fails.
4. **Assumption: Flutter l10n generation works from ARB files.**
   - **Verify**: `export PATH="$HOME/flutter/bin:$PATH" && flutter gen-l10n` succeeds.
   - **Fallback**: Fix ARB metadata/placeholders; do not hand-edit generated classes as the primary workflow.

## Decisions and Nuances

- The shell backend is a controlled bridge, not a general-purpose file API.
- Mutating actions are hidden when unsupported, not shown disabled except during in-flight operations.
- File operation success is recognized only by sentinel JSON with `ok: true`.
- Rename does not move files between folders.
- Create file/folder accepts only a single leaf name.
- Delete is recursive for folders after explicit confirmation.
- The root directory can be refreshed and used as a creation parent, but cannot be renamed or deleted.
- Existing tap behavior remains authoritative: tap directory toggles expansion; tap file opens preview.
- `Copy path` and `Refresh` remain available regardless of shell capability.
- `Reveal in folder` is intentionally excluded from the MVP.
- The implementation must be ready to migrate later to official file-mutation endpoints by keeping shell operations isolated in `WorkspaceFileOperationsService`.

## Blockers and Open Questions

None.

## Testing Strategy

Create or update the following tests:

1. `test/unit/services/workspace_file_operations_service_test.dart`
   - Sentinel extraction from `parts` text.
   - Sentinel extraction from nested `state` strings if the server returns output there.
   - Malformed sentinel maps to `malformedResponse`.
   - Capability cache hit and invalidation.
   - Name validation rejects empty, `.`, `..`, slash, backslash, and NUL.
   - POSIX quoting handles spaces, unicode, and single quotes.
   - Result code mapping covers every `WorkspaceFileOperationCode` used by the UI.

2. `test/widget/chat_page_test.dart`
   - Right-click on a file row opens menu and does not open the file.
   - Long-press on a directory row opens menu and does not expand/collapse.
   - Unsupported capabilities hide mutating actions and root New button.
   - Supported capabilities show mutating context actions.
   - Create file refreshes parent and shows new row.
   - Create folder refreshes parent and shows new row.
   - Rename file updates row and open tab.
   - Delete file confirms, refreshes parent, and closes open tab.
   - Delete folder closes nested open tabs and removes subtree cache.
   - Operation error shows correct snackbar and leaves UI state unchanged.

Run these commands:

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/services/workspace_file_operations_service_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "file tree"
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/presentation/services/workspace_file_operations_service.dart lib/presentation/widgets/file_tree_context_menu.dart lib/presentation/pages/chat_page.dart test/unit/services/workspace_file_operations_service_test.dart test/widget/chat_page_test.dart
make check
```

## Execution Handoff

Start here:

1. Open `lib/presentation/services/workspace_file_operations_service.dart` as a new file and implement the model/service/capability/shell execution layer first.
2. Register the service in `lib/core/di/injection_container.dart`.
3. Add unit tests for the service before touching ChatPage UI.
4. Create `lib/presentation/widgets/file_tree_context_menu.dart`.
5. Wire context menus into `_buildFileTreeChildren` in `lib/presentation/pages/chat_page/chat_page_file_runtime.dart` while preserving existing `InkWell.onTap` behavior.
6. Add root New menu in `lib/presentation/pages/chat_page/chat_page_file_explorer_controller.dart`.
7. Add dialogs/handlers and state reconciliation methods in `chat_page_file_runtime.dart`.
8. Add l10n keys and regenerate localization with `flutter gen-l10n`.
9. Add widget tests.
10. Update `BEHAVIOR.md`, `ADR.md`, and `CODEBASE.md` after code behavior is stable.
11. Run focused tests and final `make check`.

Strict sequencing constraint: do not expose mutating UI before `WorkspaceFileOperationsService.getCapabilities(...)` can report shell support and tests cover unsupported read-only fallback.

## Out of Scope

- Editing file contents.
- Moving files/folders between directories.
- Copying/duplicating files/folders.
- Drag and drop.
- Multi-select operations.
- Trash/recycle-bin integration.
- `Reveal in folder` / OS file manager integration.
- Windows PowerShell-native file operations.
- Live `/doc` probing for official mutation endpoints.
- Adding upstream OpenCode file-mutation endpoints.
