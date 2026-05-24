# Feature 9: Session Folders and Subfolders

**Phase**: 3 — Organization and Local Productivity
**Status**: [ ] Not started
**Priority**: P2
**CodeWalk Status**: Missing

## Why Here

Session pinning and project grouping exist, but long-term usage needs more organization.

## Target

- Client-local folder metadata scoped by `serverId::scopeId`.
- Folder CRUD, move session to folder, collapse/expand folder.
- Drag/reorder where platform UX supports it; provide non-drag actions on mobile.
- Keep pinning and archived filters working.

## Likely Files

- `lib/presentation/widgets/chat_session_list.dart`
- `lib/presentation/pages/chat_page/chat_page_scaffold.dart`
- `lib/presentation/providers/chat_provider.dart` or a focused local organization provider
- `lib/data/datasources/app_local_datasource.dart`
- New `lib/domain/entities/session_folder.dart`

## Validation

- Unit tests for folder persistence and scope isolation.
- Widget tests for nested display and move actions.
