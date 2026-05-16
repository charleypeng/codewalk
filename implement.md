# CodeWalk Upstream Alignment Plan (OpenCode v1.14.x - v1.15.0)

> **Generated:** May 15, 2026
> **Objective:** Align CodeWalk with the last 30 days of upstream changes in OpenCode (official contract) and OpenChamber (secondary UX reference), strictly adhering to ADR-023 (Contract-First Compatibility).

## ⚠️ CRUCIAL NUANCES & INVARIANTS (DO NOT IGNORE)

When implementing this plan later, you must preserve these existing invariants. Several AI planners hallucinated that these were broken, but they are load-bearing and correct:

1. **DO NOT migrate `/global/event` to `/event`**: Both endpoints coexist in the official OpenCode spec. `/event` is session-scoped, `/global/event` is global. CodeWalk uses both correctly. Migrating would break cross-project event delivery.
2. **DO NOT "fix" `prompt_async` by falling back to sync `/message`**: The `prompt_async` endpoint correctly returns `204 No Content` and relies on SSE + fallback polling. The existing `local_user_*` optimistic IDs and the omission of `messageId` in the payload are **critical** for SSE reconciliation (ADR-023 Pitfall P-001).
3. **DO NOT centralize `PATCH /config` beyond existing guards**: CodeWalk already has ADR-019 deferred config guards (`shouldDeferConfigMutations`). Do not rewrite this into a new centralized mutation guard; just ensure it handles the new HTTP 409 errors.
4. **DO NOT blindly merge Questions into Permissions**: Verify against the live `/doc` endpoint first. If the server does not explicitly document a session-scoped question endpoint, keep questions on their top-level routes.

---

## 🛠 EXECUTION STEPS

### Step 1: Update Contract Test Harness (Safety First)
Before touching production code, update the test harness to prevent regressions on load-bearing components.
*   **Files**: `test/support/mock_opencode_server.dart`, `test/contract/opencode_contract_test.dart`
*   **Actions**:
    *   Add mock support for session-scoped permissions: `POST /session/:id/permissions/:permissionID`.
    *   Add mock responses for structured error payloads (e.g., 400/422 validation arrays).
    *   Add mock responses for HTTP 409 Conflict (busy session).
    *   Assert that `prompt_async` still returns `204 No Content` and that `messageId` is still omitted from the payload.

### Step 2: Migrate Permission Responses to Session-Scoped Route
The official server spec lists `POST /session/:id/permissions/:permissionID` as the canonical reply route. Top-level routes are legacy.
*   **Files**: `lib/data/datasources/chat_remote_datasource.dart`, `lib/domain/usecases/reply_permission.dart`, `lib/presentation/widgets/permission_request_card.dart`
*   **Actions**:
    *   Plumb the active `sessionId` to the permission reply call.
    *   Use the new route: `POST /session/:sessionID/permissions/:permissionID`.
    *   Update the payload to match the official spec: `{ "response": "once"|"always"|"reject" }` (note: it's `response`, not CodeWalk's legacy `reply`).
    *   **CRITICAL FALLBACK**: Implement a `try/catch` that falls back to the legacy `POST /permission/:requestID/reply` if the new endpoint returns a 404/405. This ensures compatibility with older servers.

### Step 3: Handle HTTP 409 Busy Errors & 400/422 Validation
OpenCode now returns proper HTTP 409 errors when a session is busy, and structured 400/422 errors for invalid IDs.
*   **Files**: `lib/data/datasources/chat_remote_datasource.dart`, `lib/core/errors/exceptions.dart`
*   **Actions**:
    *   Create a `ConflictException` (or similar) mapped to HTTP 409.
    *   In `_fallbackServerMessageForStatus`, map 409 to a user-friendly message: "Session is busy processing another request."
    *   When 409 is received (e.g., during `prompt_async`), transition the session to a busy status or trigger the fallback polling, rather than throwing a hard generic `ServerException`.
    *   Update `_extractServerMessage` to parse nested validation error arrays (`errors: [{field, message}]`) into a single readable string.

### Step 4: Ignore `server.heartbeat` Events
The upstream migration to the Effect runtime introduced a `server.heartbeat` SSE event emitted every 10 seconds.
*   **Files**: `lib/presentation/providers/chat_provider/chat_provider_event_reducer_ops.dart`
*   **Actions**:
    *   Add `case 'server.heartbeat': break;` to the `_applyChatEvent` switch statement.
    *   **Reason**: If unrecognized, it falls through to `_tryApplyGlobalEventIncremental`, returns false, and triggers `_scheduleGlobalFallbackReconcile`. This causes false "activity" signals, unnecessary UI re-renders, and breaks scroll-lock.

### Step 5: Support Workspace Query Parameter
OpenCode v1.14.50+ expects workspace context for v2 model/provider discovery.
*   **Files**: `lib/data/datasources/app_remote_datasource.dart`
*   **Actions**:
    *   In `getProviders()`, `getAgents()`, and `getConfig()`, add `workspace: directory` to the `queryParameters` map whenever the `directory` variable is provided.
    *   Keep global settings paths untouched.

### Step 6: Preserve Typed OpenCode Error Details
*   **Files**: `lib/core/errors/exceptions.dart`, `lib/data/datasources/chat_remote_datasource.dart`
*   **Actions**:
    *   Update `_extractServerMessage` to preserve `error.code`, `error.name`, and typed details from upstream error payloads.
    *   Ensure that "model not found" or "auth failed" show actionable messages instead of being swallowed into generic "Failed to list permissions" or "Server error" strings.

---

## 🧪 TESTING STRATEGY

1.  **Unit Tests**: Verify `_extractServerMessage` properly parses new structured JSON error arrays. Check that `server.heartbeat` yields no state changes.
2.  **Contract Tests**: Validate the new API payloads (permissions, 409 errors) using the updated mock server harness.
3.  **Integration Validation**:
    *   Connect to a live v1.14.51+ OpenCode server.
    *   Trigger a permission (e.g., executing a bash command) and ensure the card approves it via the session-scoped endpoint.
    *   Send a prompt while a task is running to verify the 409 busy handling logic triggers gracefully without crashing the session.

---

## 🚫 OUT OF SCOPE (DO NOT IMPLEMENT)

*   **OpenChamber UX Features**: Timeline search, SVG sprites, Mini Chat windows, or the new `useChatAutoFollow` scroll system. CodeWalk's ADR-028 scroll system is already robust and tailored for Flutter.
*   **PTY Connect Tokens**: Do not add `connect-token` support to the PTY terminal unless explicitly verified against a live `/doc` endpoint, as it is not documented in the official spec snapshot.
*   **v2 Model Catalog Rewrite**: Do not deprecate the `/provider` endpoint. The v2 API (`/api/provider`) is additive. Only add it as a capability-gated probe if necessary.

---

## 🧠 RATIONALE (Why this plan was chosen)

This plan was synthesized from 7 independent AI planner analyses. It was chosen because it is **evidence-based** and **defensive**.
*   It actively rejects hallucinated regressions (e.g., claims that `prompt_async` was completely broken and returning no events, or that there was a storage persistence bug).
*   It prioritizes verifiable API contract drift (Permissions, 409s, Heartbeats, Workspace queries) over speculative product features.
*   It ensures ADR-023 compliance by treating official OpenCode docs/source as the primary contract and OpenChamber as secondary inspiration only.