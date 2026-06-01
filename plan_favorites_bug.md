# Plan: Fix Model Favorites Persistence Bug

## Problem

Model favorites are lost after switching projects within the same server. The bug also affects `_pinnedSessionIds`, `_modelUsageCounts`, and `_selectedVariantByModel` — any preference field that is cleared-then-reloaded in `_loadModelPreferenceState` and also included in `_SelectionPersistenceSnapshot`.

## Root Cause

Race condition between `initializeProviders()` (unawaited for project switches) and the Feature 7 late re-apply hook.

### Detailed Sequence

1. `_switchContext(reason: 'project')` calls `initializeProviders()` but does NOT await it
   - `chat_provider_session_ops.dart:118-131` — `unawaited(providersRefresh)` when `reason != 'server'`

2. `initializeProviders()` eventually calls `_loadModelPreferenceState()` which:
   - `chat_provider_preference_ops.dart:125` — **Clears `_favoriteModelKeys`** to `<String>[]`
   - `chat_provider_preference_ops.dart:140-143` — **Awaits** storage read to reload favorites
   - Between these two lines, `_favoriteModelKeys` is **EMPTY**

3. Meanwhile, `loadLastSession()` → `loadMessages()` → late re-apply hook
   - `chat_provider.dart:3672` — calls `_applySelectionPriorityForCurrentSession()`
   - This may call `_restoreSelectionFromMessages()`
   - `chat_provider_selection_helpers.dart:772` — `unawaited(_persistSelection(syncRemote: false))`

4. If the late re-apply fires during the empty window (step 2), `_restoreSelectionFromMessages()` calls `unawaited(_persistSelection(syncRemote: false))`

5. `_persistSelection` captures a snapshot with **EMPTY** `_favoriteModelKeys` and writes `[]` to `favorite_models::<serverId>`, **overwriting the correct favorites**

### Why It Only Happens on Project Switches

Server switches await `initializeProviders` (`chat_provider_session_ops.dart:129: await providersRefresh`), so the race doesn't occur. Project switches use `unawaited(providersRefresh)` (line 131).

### Same Issue Affects

- `_pinnedSessionIds` — cleared at `chat_provider_preference_ops.dart:126`, included in snapshot at `chat_provider.dart:2622-2624`
- `_modelUsageCounts` — cleared at `chat_provider_preference_ops.dart:127`, included in snapshot at `chat_provider.dart:2625`
- `_selectedVariantByModel` — cleared at `chat_provider_preference_ops.dart:128`, included in snapshot at `chat_provider.dart:2626`

## Key Code Locations

| File | Lines | What |
|------|-------|------|
| `chat_provider_session_ops.dart` | 118-131 | `initializeProviders()` unawaited for project switches |
| `chat_provider_preference_ops.dart` | 120-163 | `_loadModelPreferenceState` — clear-then-load pattern |
| `chat_provider_preference_ops.dart` | 236-269 | `_persistModelPreferenceState` — dedicated favorites persistence |
| `chat_provider.dart` | 2602-2631 | `_captureSelectionPersistenceSnapshot` — captures `_favoriteModelKeys` |
| `chat_provider.dart` | 2633-2700 | `_persistSelectionSnapshot` — writes favorites via snapshot |
| `chat_provider.dart` | 2771-2776 | `_persistSelection` — called from Feature 7 late re-apply |
| `chat_provider.dart` | 2714-2725 | `_scheduleSelectionPersistence` — deferred persistence |
| `chat_provider_selection_helpers.dart` | 692-776 | `_restoreSelectionFromMessages` — Feature 7 fallback |
| `chat_provider_selection_helpers.dart` | 772 | `unawaited(_persistSelection(syncRemote: false))` — the overwrite trigger |
| `chat_provider_context_state_ops.dart` | 85-163 | `_applySessionSelectionOverride` — Feature 7 override logic |
| `chat_provider.dart` | 3000-3015 | `toggleModelFavorite` — primary favorites persistence |
| `chat_provider.dart` | 3672 | Late re-apply hook in `loadMessages` |
| `chat_provider.dart` | 3278 | Late re-apply hook in `loadLastSession` |

## Persistence Paths for Favorites

### Path A (Primary — Correct)
`toggleModelFavorite` → `_persistModelPreferenceState` → `saveFavoriteModelsJson(serverId)`
- Immediate, correct
- `chat_provider.dart:3013`

### Path B (Secondary — Redundant and Dangerous)
`selectProvider/selectModel/selectAgent/selectVariant` → `_scheduleSelectionPersistence` → `_captureSelectionPersistenceSnapshot` → `_persistSelectionSnapshot` → `saveFavoriteModelsJson(serverId)`
- Deferred, captures current `_favoriteModelKeys`
- `chat_provider.dart:2821, 2841, 2897, 2928`

### Path C (Feature 7 — The Trigger)
`_restoreSelectionFromMessages` / `_applySessionSelectionOverride` → `_persistSelection` → `_captureSelectionPersistenceSnapshot` → `_persistSelectionSnapshot` → `saveFavoriteModelsJson(serverId)`
- Called from late re-apply hooks
- `chat_provider_selection_helpers.dart:772`, `chat_provider_selection_helpers.dart:277`
- `chat_provider_message_state_ops.dart:459`

### Path D (initializeProviders — Correct)
`initializeProviders` → `_persistModelPreferenceState` → `saveFavoriteModelsJson(serverId)`
- `chat_provider_core.dart:364`

All four paths write to the same key: `favorite_models::<encodedServerId>`. Path A and D are correct. Path B and C are redundant and dangerous because they can capture stale/empty state.

## Nuances

1. **Favorites are server-scoped, not project-scoped**: `saveFavoriteModelsJson` and `getFavoriteModelsJson` intentionally omit `scopeId`. This is correct by design (ADR-001). The bug is not a scoping issue.

2. **Legacy migration is one-time**: `_loadModelPreferenceState` lines 144-162 migrate from project-scoped legacy keys to server-scoped keys. Once migrated, legacy keys are deleted. This is correct and not the bug.

3. **`_switchContext` does NOT clear `_favoriteModelKeys`**: Line 87 only clears `_recentModelKeys`. The clear happens later inside `_loadModelPreferenceState` (line 125). This means during the initial part of the race, `_favoriteModelKeys` still holds old values (which are correct for same-server switches). The empty window only opens when `_loadModelPreferenceState` starts executing.

4. **Dart event loop ordering**: `initializeProviders()` is called at line 118. Even though it's unawaited, it starts executing synchronously up to its first `await` at `_resolveServerScopeId()` (chat_provider_core.dart:141). The clear at line 125 of preference_ops happens AFTER several `await` calls (getProviders, _refreshAgents), so it occurs later in the event loop.

5. **`_persistSelection` is `unawaited`** in Feature 7 paths (line 772, line 459). This means the persistence runs asynchronously on the event loop. It could complete before or after `_persistModelPreferenceState` in `initializeProviders`. If it completes after, it overwrites the correct data.

6. **`_ChatContextSnapshot` intentionally excludes `_favoriteModelKeys`**: The context snapshot (used for fast project transitions) doesn't save/restore favorites. This is correct — favorites are server-scoped and shouldn't vary by project.

7. **The `_scheduleSelectionPersistence` flush loop** (chat_provider.dart:2727-2743) uses a `while(true)` loop that re-captures snapshots until `_selectionPersistenceDirty` is false. This means if a selection change happens during the empty window, the loop will capture and persist empty favorites.

## Fix Plan

### Fix 1: Atomic Field Swap in `_loadModelPreferenceState`

Refactor `_loadModelPreferenceState` to load all data into local variables first, then swap all fields at the end. No field is cleared until its replacement value is ready.

**Before (vulnerable)**:
```dart
_favoriteModelKeys = <String>[];  // EMPTY WINDOW STARTS
final favoritesJson = await localDataSource.getFavoriteModelsJson(serverId: serverId);
_favoriteModelKeys = _decodeStoredModelKeys(favoritesJson);  // EMPTY WINDOW ENDS
```

**After (safe)**:
```dart
final favoritesJson = await localDataSource.getFavoriteModelsJson(serverId: serverId);
final loadedFavorites = _decodeStoredModelKeys(favoritesJson);
// ... load all other fields into locals ...
_favoriteModelKeys = loadedFavorites;  // ATOMIC SWAP — no empty window
```

Apply the same pattern to: `_recentModelKeys`, `_pinnedSessionIds`, `_modelUsageCounts`, `_selectedVariantByModel`, `_agentSelectionMemoryByAgent`.

**File**: `lib/presentation/providers/chat_provider/chat_provider_preference_ops.dart`

### Fix 2: Remove Redundant Fields from `_SelectionPersistenceSnapshot`

Remove `favoriteModelsJson` and `pinnedSessionsJson` from the snapshot class, its capture, and its persistence. These fields have their own dedicated persistence path (`_persistModelPreferenceState`) and should not be redundantly written by the snapshot path.

This is defense-in-depth: even if a similar race is introduced later, the snapshot won't overwrite favorites or pinned sessions.

**Files**:
- `lib/presentation/providers/chat_provider.dart` — `_SelectionPersistenceSnapshot` class, `_captureSelectionPersistenceSnapshot`, `_persistSelectionSnapshot`

### Validation

- `make check` passes
- Existing `chat_provider` tests pass
- Manual test: toggle favorites, switch projects, verify favorites persist

## Constraints

- ADR-023 compliance: no regression in session/message handling
- Favorites remain server-scoped (no scopeId in storage key)
- Legacy migration path preserved
- Feature 7 late re-apply hooks continue to work correctly
