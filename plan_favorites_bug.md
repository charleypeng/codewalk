# Model Favorites Persistence Bug

**Status**: Resolved
**Last reviewed**: 2026-06-15

This file is retained as a short postmortem. It is not an active implementation plan.

## Problem

Model favorites could be lost after switching projects within the same server. The race also applied to nearby preference fields such as pinned sessions, model usage counts, and selected model variants.

## Root Cause

`_loadModelPreferenceState` previously cleared preference fields before awaiting storage reads. During that empty window, late selection re-apply paths could persist an empty `_SelectionPersistenceSnapshot` and overwrite correct stored data.

The bug was project-switch specific because same-server project switches refresh providers asynchronously, while server switches wait for provider initialization.

## Implemented Fix

- `lib/presentation/providers/chat_provider/chat_provider_preference_ops.dart` now loads model preference fields into local variables first and swaps instance fields only after all awaited reads complete.
- `_SelectionPersistenceSnapshot` no longer owns the server-scoped favorites/pinned-session write path; those preferences are persisted through their dedicated model/session preference paths.
- Favorites remain server-scoped by design, not project-scoped.

## Regression Coverage

Relevant coverage lives in `test/unit/providers/chat_provider_project_test.dart` and related chat-provider preference/session tests:

- favorites persist and reload across provider instances
- legacy scoped favorites migrate to server-scoped storage
- favorite models stay shared across projects on the same server
- pinned sessions remain isolated by project scope
