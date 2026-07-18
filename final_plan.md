# OpenCode v1.18.3 Compatibility Follow-up Plan

## Status

Ready.

## Problem

CodeWalk must remain compatible with the official OpenCode server and cross-client event semantics under ADR-023. OpenCode `v1.18.3`, published on 2026-07-16 at tag commit `127bdb30784d508cc556c71a0f32b508a3061517`, does not introduce a new legacy REST or SSE contract relative to `v1.18.2`, but validating CodeWalk against the exact release exposed three existing compatibility defects and one stale-catalog behavior:

1. `ChatEventModel.fromJson` unwraps the official `/global/event` `payload` but discards the outer `directory`, `project`, and `workspace` fields. The global reducer then cannot route events to the correct CodeWalk context.
2. CodeWalk does not explicitly reconcile `session.next.revert.staged`, `session.next.revert.cleared`, or `session.next.revert.committed`. The per-instance stream ignores them, and the global fallback does not reliably refresh the active timeline.
3. The managed local OpenCode installer detects Windows ARM64 but always selects `opencode-windows-x64.zip`, even though `v1.18.3` publishes `opencode-windows-arm64.zip`.
4. CodeWalk ignores `catalog.updated`, leaving provider/model choices stale until another manual or lifecycle refresh.

The official `v1.18.3` release-note changes to the TUI subagent picker and official Desktop homepage, WSL readiness, help button, custom-agent selector, and command palette do not require equivalent CodeWalk UI changes.

## Objective

Make CodeWalk safely consume the exact OpenCode `v1.18.3` global event envelope, reconcile remote revert lifecycle events, refresh provider/model state after catalog updates, and install the correct managed OpenCode binary on Windows ARM64. Preserve backward compatibility with flat legacy event fixtures and x64 fallback behavior. Add focused regression coverage and update current-behavior documentation.

Completion is verifiable when:

- An official nested `/global/event` frame retains its outer context metadata after parsing.
- Global events are routed to the context identified by the outer `directory` instead of defaulting to the active context.
- All three `session.next.revert.*` events trigger server-authoritative reconciliation on both per-instance and global streams, including when aggressive data saver disables the global stream.
- `catalog.updated` coalesces into the existing provider refresh path.
- Windows ARM64 selects `opencode-windows-arm64.zip` before the x64 fallback, while all existing macOS/Linux/x64 preferences remain unchanged.
- Focused tests and `make check` pass.

## Context and Constraints

- Repository: `/home/ubuntu/MEGA/WORK/codewalk`.
- CodeWalk is a Flutter client targeting Android, Linux, macOS, Windows, and Web.
- ADR-023 at `ADR.md:1001-1015` makes official OpenCode API and event semantics authoritative and requires core compatibility with official CLI/Web behavior.
- The live server OpenAPI document at `/doc` is authoritative for request and response contracts. Local anchors are `ai-docs/opencode_server.md`, `ai-docs/opencode_web.md`, and `ai-docs/opencode_models.md`.
- Official `v1.18.3` `/global/event` frames use outer location metadata and a nested payload:

  ```json
  {
    "directory": "/repo",
    "project": "project-id",
    "workspace": "workspace-id",
    "payload": {
      "id": "evt_...",
      "type": "session.updated",
      "properties": {}
    }
  }
  ```

- Initial `server.connected` and periodic `server.heartbeat` global frames may contain only `payload` and omit location metadata. The parser must continue accepting them.
- Per-instance `/event` frames remain flat `{id, type, properties}` objects.
- Existing tests incorrectly model `/global/event` as a flat event with `directory` inside `properties` at `test/integration/opencode_server_integration_test.dart:269-283`.
- `lib/presentation/providers/chat_provider/chat_provider_event_reducer_global_ops.dart:24-59` depends on `event.properties` containing directory metadata.
- `initializeProviders()` already coalesces refreshes through `_providersRefreshTask` at `lib/presentation/providers/chat_provider.dart:2366-2383`; reuse it instead of adding another debounce or refresh subsystem.
- Managed local OpenCode is desktop-only. Do not alter Web, Android, or iOS runtime availability.
- Do not implement OpenCode provider OAuth, `integration.*`, `reference.updated`, or new v2 storage APIs in this task.
- Do not recreate `ROADMAP.md`; GitHub Issues are the canonical tracker.
- Do not add an ADR exception. The changes restore ADR-023 alignment rather than introduce a divergence.
- Preserve existing style, architecture, naming, data-saver behavior, and server-authoritative state rules.
- Do not locally fabricate or delete messages when the legacy server APIs do not expose enough data to reproduce a v2 revert result.

## Decisions (Resolved)

1. Preserve global envelope metadata by copying non-empty outer `directory`, `project`, and `workspace` values into a fresh parsed properties map. Outer location values are authoritative when a payload property has the same key.
2. Keep `ChatEvent` and downstream reducer interfaces unchanged. Enriching the parsed properties map is the smallest compatible change because existing reducers already extract context from `event.properties`.
3. Continue accepting flat legacy events and nested global frames without location metadata.
4. Treat all three `session.next.revert.*` events as context-affecting session events. Route them through `_applyChatEvent`, refresh session metadata/status, and refresh active messages when the event targets the visible session or lacks a usable session ID.
5. Use server responses as the only source of revert state. If refreshed legacy APIs do not expose a v2 commit, retain the server-returned timeline and do not infer deletions locally.
6. Handle `catalog.updated` by invoking the existing coalesced `initializeProviders()` path. Do not map `integration.*` to `/provider`, because the v2 integration credential store is not proven to update the legacy provider endpoint.
7. Extract the release-asset name preference into a deterministic top-level helper in `local_opencode_server_runtime_io.dart` so it can be unit tested without network access or host-architecture dependence.
8. On Windows ARM64, prefer `opencode-windows-arm64.zip` and then fall back to `opencode-windows-x64.zip`. On Windows x64, select only the x64 asset. Preserve current macOS and Linux ordering exactly.
9. Update current-behavior and compatibility documentation only after code and tests establish the final behavior.

## Why This Plan

- It fixes concrete contract drift discovered against the exact immutable release rather than copying unrelated official Desktop UI changes.
- It reuses existing parsing, reducer, provider-refresh, and fallback mechanisms instead of adding parallel abstractions.
- It preserves old server compatibility while making the official nested envelope authoritative.
- It avoids unsafe local reconstruction when the legacy API cannot expose v2-only state.
- It adds deterministic tests for the two previously inaccurate or untested boundaries: global event envelopes and platform asset selection.

## Overview

First correct the transport model so all downstream routing receives the official context metadata. Then extend session event reconciliation and catalog refresh behavior using existing ChatProvider paths. Correct Windows ARM64 asset preference through a small pure selector seam. Finish by updating compatibility documentation and running focused and full validation.

## Steps

### 1. Preserve official `/global/event` context metadata

- **Files**:
  - `lib/data/models/chat_realtime_model.dart`
  - `test/unit/models/chat_realtime_model_test.dart` (create)
  - `test/integration/opencode_server_integration_test.dart`
- **Changes**:
  1. In `ChatEventModel.fromJson`, continue detecting a nested `payload` map.
  2. Always create a mutable copy of the selected properties map with `Map<String, dynamic>.from(...)`; do not mutate the caller's decoded JSON map.
  3. For nested payloads, inspect outer keys `directory`, `project`, and `workspace`. Copy each non-empty string into the properties copy. Make the outer value override a same-named payload property because it identifies the event-routing context.
  4. Do not add missing keys with null or empty-string values.
  5. Keep flat `{type, properties}` parsing unchanged.
  6. Keep unknown event types parseable as today; do not introduce an event enum or rejection list.
  7. Replace the flat scripted event in `test/integration/opencode_server_integration_test.dart:269-283` with the official nested global envelope and retain the assertion that the resulting event exposes the directory.
- **Tests**:
  - Parse a nested official global event and assert that payload properties plus outer `directory`, `project`, and `workspace` are retained.
  - Assert that an outer location value wins over a conflicting payload property.
  - Parse nested `server.connected` without outer metadata and assert that no empty context keys are synthesized.
  - Parse a flat `/event` frame and assert existing behavior remains unchanged.
- **Risk**: Medium. Incorrect precedence can route an event to the wrong context.
- **Mitigation**: Make outer metadata authoritative and cover collision, missing metadata, nested, and flat cases.
- **Validation gate**: Run the new model test and the integration SSE test before proceeding.

### 2. Reconcile OpenCode revert lifecycle events

- **Files**:
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_global_ops.dart`
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_session_ops.dart`
  - `test/contract/chat_event_contract_test.dart`
  - `test/unit/providers/chat_provider_realtime_test.dart`
- **Changes**:
  1. Add these exact types to the global reducer's supported incremental event set:
     - `session.next.revert.staged`
     - `session.next.revert.cleared`
     - `session.next.revert.committed`
  2. Add one shared switch branch for the three types in `_applyChatEvent`.
  3. Extract the event session ID with the existing event-session helpers. Mark the active context dirty.
  4. Schedule a server-authoritative refresh with `refreshSessions: true` and `refreshStatus: true`.
  5. Set `refreshActiveSession: true` when the extracted session ID matches the visible session. Also set it to true when no usable session ID is available, because retaining a stale visible timeline is riskier than an extra scoped fetch.
  6. Do not locally mutate `_messages`, delete tail messages, or construct `SessionRevert` data from the event body. Let refreshed session/message responses drive state.
  7. Keep existing `session.next.moved` handling intact.
  8. Preserve recent-event deduplication so the same event arriving on `/event` and `/global/event` does not start duplicate reconciliation.
- **Tests**:
  - Emit each exact event type on the per-instance stream and assert that session/status refresh occurs.
  - Emit an active-session revert event and assert that active messages are reloaded and visible-message filtering follows the refreshed server `revert` boundary.
  - Emit a non-current-session event with a known session ID and assert that the current timeline is not replaced.
  - Emit an event without a usable session ID and assert the safe current-context fallback runs.
  - Enable aggressive data saver so `/global/event` is absent, emit the event on `/event`, and assert reconciliation still occurs.
  - Emit duplicate equivalent events across both streams and assert refresh is coalesced/deduplicated.
- **Fallback behavior**: If a live `v1.18.3` server emits a committed v2 revert but the legacy session/message endpoints still return the unreverted timeline, display the refreshed legacy server response, retain the context as dirty for later SWR, and do not fabricate local deletions.
- **Risk**: High. Incorrect local truncation could hide or lose messages; excessive refreshes could disrupt active streaming.
- **Mitigation**: Perform reads only, target the active session precisely, reuse current scheduling/deduplication, and never synthesize revert state.
- **Validation gate**: Run the contract event suite and ChatProvider realtime suite before proceeding.

### 3. Refresh provider/model state on `catalog.updated`

- **Files**:
  - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_global_ops.dart`
  - `test/contract/chat_event_contract_test.dart`
  - `test/unit/providers/chat_provider_realtime_test.dart`
- **Changes**:
  1. Handle `catalog.updated` before the context-prefix filter that currently rejects non-session events.
  2. Invoke `initializeProviders()` with `unawaited`; rely on `_providersRefreshTask` to coalesce concurrent catalog events.
  3. Keep the existing provider catalog visible while refresh is in progress.
  4. On refresh failure, preserve the existing cached catalog and existing refresh-error behavior.
  5. Do not handle `integration.updated`, `integration.connection.updated`, or `reference.updated` in this task.
- **Tests**:
  - Emit one `catalog.updated` event and assert one provider refresh updates available models.
  - Emit several catalog events while a refresh is in flight and assert the existing task coalescing prevents parallel provider requests.
  - Force refresh failure and assert the prior provider/model selection remains available.
- **Risk**: Medium. A refresh loop could restart realtime subscriptions repeatedly.
- **Mitigation**: Reuse the existing in-flight task guard and verify one request for a burst of events.
- **Validation gate**: Run focused ChatProvider provider/realtime tests.

### 4. Select the native Windows ARM64 OpenCode asset

- **Files**:
  - `lib/presentation/services/local_opencode_server_runtime_io.dart`
  - `test/unit/services/local_opencode_release_asset_selector_test.dart` (create)
- **Changes**:
  1. Extract the preferred asset-name ordering into a deterministic top-level helper that accepts:
     - available asset names,
     - `TargetPlatform`,
     - `bool isArm64`.
  2. Keep the helper free of network, filesystem, and `Abi.current()` calls. `_selectAssetForCurrentPlatform` must compute the real platform/ABI and pass them into the helper.
  3. Use these exact Windows preferences:
     - Windows ARM64: `opencode-windows-arm64.zip`, then `opencode-windows-x64.zip`.
     - Windows x64: `opencode-windows-x64.zip` only.
  4. Preserve these existing macOS preferences:
     - ARM64: `opencode-darwin-arm64.zip`.
     - x64: `opencode-darwin-x64.zip`, then `opencode-darwin-x64-baseline.zip`.
  5. Preserve these existing Linux preferences:
     - ARM64: `opencode-linux-arm64.tar.gz`, then `opencode-linux-arm64-musl.tar.gz`.
     - x64: `opencode-linux-x64.tar.gz`, `opencode-linux-x64-baseline.tar.gz`, `opencode-linux-x64-musl.tar.gz`, then `opencode-linux-x64-baseline-musl.tar.gz`.
  6. Continue returning no asset when none of the platform preferences exist. Do not select Desktop application installers such as `opencode-desktop-win-arm64.exe`.
  7. Preserve SHA-256 extraction and verification unchanged.
- **Tests**:
  - Windows ARM64 prefers the native archive when both native and x64 assets exist.
  - Windows ARM64 falls back to x64 when the native archive is absent.
  - Windows x64 never chooses the ARM64 archive.
  - Existing macOS and Linux preference order remains unchanged.
  - Unrelated Desktop assets are ignored.
  - No matching CLI archive returns null.
- **Risk**: Medium. A selector regression could break managed installation on another desktop platform.
- **Mitigation**: Preserve all current non-Windows orderings verbatim and test every supported platform family.
- **Validation gate**: Run the pure selector unit test and targeted analysis for the runtime file.

### 5. Update compatibility and current-behavior documentation

- **Files**:
  - `ai-docs/opencode_server.md`
  - `ai-docs/opencode_models.md`
  - `CONTRACT_MATRIX.md`
  - `BEHAVIOR.md`
- **Changes**:
  1. Document the exact `v1.18.3` `/event` and `/global/event` envelopes, including that initial connected/heartbeat global frames may omit location metadata.
  2. Document the cumulative EventV2 families relevant to CodeWalk: `catalog.updated` and `session.next.revert.*`.
  3. Record that `integration.*` belongs to newer integration behavior and is not assumed to update the legacy `/provider` contract.
  4. Update the realtime contract row in `CONTRACT_MATRIX.md` to name outer-context preservation and revert reconciliation as tested invariants.
  5. Update `BEHAVIOR.md` to describe only the implemented final behavior: global context routing, server-authoritative remote revert refresh, catalog refresh coalescing, and native Windows ARM64 managed-runtime selection.
  6. Do not add release-note history or planned behavior to `BEHAVIOR.md`.
  7. Do not recreate `ROADMAP.md`.
- **Risk**: Low.
- **Mitigation**: Pin upstream links to `v1.18.3` and distinguish exact-release changes from behavior merely present cumulatively in the tag.
- **Validation gate**: Review links and terminology against official tag-pinned sources and the live `/doc` output.

### 6. Run final validation and independent review

- **Commands**: Run from `/home/ubuntu/MEGA/WORK/codewalk`.

  ```bash
  export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/models/chat_realtime_model_test.dart
  export PATH="$HOME/flutter/bin:$PATH" && flutter test test/integration/opencode_server_integration_test.dart
  export PATH="$HOME/flutter/bin:$PATH" && flutter test test/contract/chat_event_contract_test.dart
  export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/providers/chat_provider_realtime_test.dart
  export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/services/local_opencode_release_asset_selector_test.dart
  export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/data/models/chat_realtime_model.dart lib/presentation/providers/chat_provider lib/presentation/services/local_opencode_server_runtime_io.dart test/unit/models/chat_realtime_model_test.dart test/integration/opencode_server_integration_test.dart test/contract/chat_event_contract_test.dart test/unit/providers/chat_provider_realtime_test.dart test/unit/services/local_opencode_release_asset_selector_test.dart
  export PATH="$HOME/flutter/bin:$PATH" && make check
  ```

- **Live verification**:
  1. Start OpenCode `v1.18.3` with an isolated test directory and verify `/global/health` reports the expected version.
  2. Inspect `http://127.0.0.1:4096/doc` and confirm `/event`, `/global/event`, `/session/:sessionID/revert`, `/session/:sessionID/unrevert`, and `/provider` contracts.
  3. Connect CodeWalk and a second official client to the same server. Create/update a session in the second client and confirm CodeWalk routes the event to the correct directory.
  4. Exercise staged, cleared, and committed revert behavior from the official client. Confirm CodeWalk refreshes without local data loss.
  5. Trigger or simulate `catalog.updated` and confirm available provider/models refresh once.
  6. Validate the release asset selector against the official `v1.18.3` GitHub asset list. When Windows ARM64 hardware or CI is available, perform one managed direct-binary install and verify `opencode --version` reports `1.18.3`.
- **Review gate**:
  - Run the project Reviewer Loop on the final code diff after tests pass.
  - Apply only correctness, regression, concurrency, contract, or maintainability findings validated against local evidence.
  - Rerun focused tests for reviewer-requested micro-fixes; rerun `make check` only if a fix invalidates the completed full check.
- **Delivery**:
  - Do not build an Android APK unless explicitly requested; this task has no Android-specific UI delivery.
  - Do not commit or push unless authorized by the active execution protocol.

## Risks & Mitigations

1. **High — wrong-context state mutation**: Losing or trusting the wrong directory can apply a global event to another project.
   - Mitigation: Treat outer global-envelope location metadata as authoritative and test conflicting values.
2. **High — message loss during revert reconciliation**: Local truncation based only on an event could hide data the legacy API still considers present.
   - Mitigation: Never delete locally; fetch server session/message state and render only the server-authoritative result.
3. **Medium — refresh storms or subscription churn**: Event bursts can trigger repeated provider or session requests.
   - Mitigation: Reuse `_providersRefreshTask`, existing current-context scheduling, and cross-stream deduplication.
4. **Medium — Windows architecture regression**: Changing asset ordering could select an incompatible archive.
   - Mitigation: Make platform/architecture selection deterministic, preserve x64 fallback, and test every platform preference list.
5. **Medium — upstream v2/legacy store mismatch**: A v2 revert commit may not be fully represented by legacy message endpoints.
   - Mitigation: Keep the legacy response visible, mark the context dirty for later SWR, and record an upstream compatibility issue rather than fabricating state.
6. **Low — documentation drift**: Moving `dev` links can stop representing the reviewed release.
   - Mitigation: Use tag-pinned `v1.18.3` links and record the review date.

## Assumptions to Validate

1. **Official global envelopes match the tag source.**
   - Validation: Capture frames from a running `v1.18.3` `/global/event` endpoint.
   - If false: Preserve support for the observed shape additively; do not remove nested or flat parsing.
2. **Revert events expose a usable session ID through existing extraction helpers.**
   - Validation: Capture all three event payloads during live cross-client revert operations.
   - If false: Use the documented safe current-context refresh fallback and do not infer an ID.
3. **Legacy session/message endpoints reflect enough state to render remote revert behavior.**
   - Validation: Compare responses before staging, after staging, after clearing, and after committing.
   - If false: Keep the server-returned legacy timeline, do not synthesize deletions, and document the upstream limitation.
4. **`catalog.updated` may arrive in bursts.**
   - Validation: Emit multiple events in tests while provider refresh is delayed.
   - If false: Retain coalescing anyway because it is harmless and protects future server behavior.
5. **The Windows ARM64 CLI asset name is stable for `v1.18.3`.**
   - Validation: Confirm `opencode-windows-arm64.zip` in the official release assets API.
   - If false in a future release: Fall back to `opencode-windows-x64.zip`; do not select a Desktop installer.

## Decisions and Nuances

- The release API's `target_commitish` points to `c69abee0c73253aebae65e87e4e1b9bfa8c38021`, while the immutable `v1.18.3` tag points to release commit `127bdb30784d508cc556c71a0f32b508a3061517`. Use the tag as the source reference.
- The EventV2 types covered here were already present in `v1.18.2`; do not describe them as newly introduced by `v1.18.3`.
- The release-note Desktop fixes belong to the official Desktop application, not CodeWalk's Flutter desktop UI.
- `server.connected` and `server.heartbeat` can legitimately lack outer directory metadata. Missing context on those transport events is not a parser failure.
- The parser must make a fresh properties map before enrichment to avoid mutating decoded input shared elsewhere.
- Provider/model identifiers remain untranslated and server-defined. Do not add allowlists.
- OpenChamber may be inspected only as a secondary community implementation reference. Official OpenCode tag source and `/doc` override it.
- `CODEBASE.md` does not require an update because this plan does not add a new production module or change architectural entry points.

## Blockers and Open Questions

None. The live-server checks may expose an upstream legacy/v2 limitation, but the safe fallback behavior is already defined and does not block the local compatibility fixes.

## Testing Strategy

- Cover parsing at the model boundary with exact wire fixtures.
- Cover reducer behavior with both event streams and aggressive-data-saver conditions.
- Cover context routing with conflicting active and event directories.
- Cover provider refresh coalescing and failure retention.
- Cover release-asset selection as a pure platform/architecture matrix.
- Run focused tests first, targeted analysis second, and `make check` only after the implementation is stable.
- Perform live cross-client verification with OpenCode `v1.18.3` because mocks cannot prove legacy/v2 revert-store behavior.
- Skip `make android` unless a testable APK is explicitly requested; `make check` covers the shared Dart behavior in this task.

## Execution Handoff

1. Start in `/home/ubuntu/MEGA/WORK/codewalk` with a clean understanding of any user-owned working-tree changes; do not overwrite them.
2. Read `AGENTS.md`, `BEHAVIOR.md`, ADR-023 in `ADR.md`, and the three `ai-docs/opencode_*` anchors before editing.
3. Recover the latest `AGENT_PLAN_ANCHOR`. When the user authorizes execution of this file, follow the required plan-anchored commit protocol before modifying code.
4. Open these first:
   - `lib/data/models/chat_realtime_model.dart`
   - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_global_ops.dart`
   - `lib/presentation/providers/chat_provider/chat_provider_event_reducer_session_ops.dart`
   - `lib/presentation/services/local_opencode_server_runtime_io.dart`
   - `test/integration/opencode_server_integration_test.dart`
5. Implement Steps 1 through 4 in order. Do not start documentation until code behavior and focused tests are stable.
6. Complete the full validation and reviewer gates before any requested commit or push.

## Out of Scope

- Reproducing official OpenCode Desktop homepage, command-palette, WSL readiness, help-button, or custom-agent-selector changes.
- Implementing OpenCode provider OAuth or connector setup UI.
- Migrating CodeWalk wholesale to v2 session, message, integration, or durable sync APIs.
- Acting on `integration.updated`, `integration.connection.updated`, or `reference.updated`.
- Changing message send, `prompt_async`, permission, question, or legacy revert endpoint contracts.
- Adding provider/model allowlists.
- Recreating `ROADMAP.md`.
- Android APK delivery, release versioning, push, deployment, or CI monitoring unless separately requested.

## Official References

- OpenCode `v1.18.3` release: https://github.com/anomalyco/opencode/releases/tag/v1.18.3
- Global event schema: https://github.com/anomalyco/opencode/blob/v1.18.3/packages/opencode/src/server/routes/instance/httpapi/groups/global.ts#L35-L46
- Global event handler: https://github.com/anomalyco/opencode/blob/v1.18.3/packages/opencode/src/server/routes/instance/httpapi/handlers/global.ts#L16-L58
- Instance event handler: https://github.com/anomalyco/opencode/blob/v1.18.3/packages/opencode/src/server/routes/instance/httpapi/handlers/event.ts#L12-L78
- Revert event definitions: https://github.com/anomalyco/opencode/blob/v1.18.3/packages/schema/src/session-event.ts#L434-L443
- Catalog event definition: https://github.com/anomalyco/opencode/blob/v1.18.3/packages/schema/src/catalog.ts#L5-L6
- Windows ARM64 CLI asset: https://github.com/anomalyco/opencode/releases/download/v1.18.3/opencode-windows-arm64.zip
- Secondary community reference: https://github.com/openchamber/openchamber
