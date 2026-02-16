# ROADMAP.featI - Agent, Shortcut, and Productivity Parity

## Scope

### Group 1 — Header/toolbar layout `[x]`
- [x] Task 24: Move context button to session title card (from AppBar actions to compact session header Row).
- [x] Task 25: Remove pencil button; single-tap on title text to edit (was double-tap + pencil icon).
- [x] Task 26: Files button icon changed to `account_tree_outlined`.
- [x] Backlog follow-up: Desktop project selector width increased (300px normal, 400px large desktop; was 240px fixed).

### Group 2 — UX/content features `[x]`
- [x] Task 14: Show `Shortcuts` section on mobile when physical keyboard is connected.
- [x] Task 23: Add todo tooling support (`todowrite`, `todoread`, related flows).
- [x] Task 37: One-line tips while waiting for first server tokens.

### Group 3 — Chat attachments and media
- [ ] Add attachment download/open actions in chat messages (handle data://, http://, file://, and local paths)
- [ ] Implement image preview inline in chat message bubbles (support data URLs and network images)

### Group 4 — External integrations
- Task 40: Replace ch.at title service with native OpenCode 'title' agent, maintaining 6-message cadence.
- Task 15: Check updates via public GitHub Releases API.

### Group 5 — Platform
- Task 10: Background behavior settings (mobile persistent notification, desktop tray).

### Done
- Task 39: Add soft loading state visual to conversation list item icon while session is receiving data/response. - Commit: fb6e118

## Goal

Increase productivity and discoverability with stronger keyboard/background behavior, update awareness, and clearer session-header ergonomics.

## Research Notes

- GitHub Releases API (latest/version compare):
  - https://docs.github.com/en/rest/releases/releases#get-the-latest-release
- App version retrieval:
  - https://pub.dev/packages/package_info_plus
- Notifications and tray:
  - https://pub.dev/packages/flutter_local_notifications
  - https://pub.dev/packages/system_tray
- Keyboard presence/input modality:
  - https://docs.flutter.dev/ui/adaptive-responsive/input
- Timed tip rotation:
  - https://api.dart.dev/stable/dart-async/Timer-class.html

## Implementation Plan

1. Refactor session header controls (context button position, pencil cleanup, better Files icon, desktop selector width).
2. Detect physical keyboard and conditionally expose shortcuts section on mobile.
3. Define todo domain models + UI surface integration for todo read/write actions.
4. Add waiting-state rotating tip line before first token arrives.
5. Replace ch.at title service with native OpenCode 'title' agent.
6. Poll GitHub latest release in settings/about with semver compare and dismissible update banner.
7. Add background execution policy setting by platform capabilities.

## Backend/Contract Considerations

- Todo support must align with upstream event/part schemas.
- Update check must be rate-limited and resilient to offline mode.

## Validation

- Unit tests for semantic version comparison and update availability states.
- Widget tests for conditional shortcuts visibility with hardware keyboard flag.
- Integration tests for todo action rendering and header control behavior.

## Definition of Done

- Background behavior is configurable and platform-correct.
- Update checks are reliable and non-intrusive.
- Todo functionality and header ergonomics improve day-to-day flow.
- Desktop project selector is readable on large layouts without wasting compact-space behavior.
- Title generation uses native OpenCode agent instead of external ch.at service.

---

## Task 40: Native OpenCode Title Agent Migration

### Current Implementation

**Service:** `ChatAtTitleGenerator` calls external ch.at API (`https://ch.at/v1/chat/completions`)

**Behavior:**
- Generates titles every 6 messages (3 user + 3 assistant text messages)
- Max 80 characters, platform-aware word limit (4 mobile, 6 desktop)
- Per-server privacy toggle in Settings
- Background generation with consolidation guard

**Location:** `lib/presentation/services/chat_title_generator.dart`

**Interface:**
```dart
abstract class ChatTitleGenerator {
  Future<String?> generateTitle(
    List<ChatTitleGeneratorMessage> messages, {
    int maxWords,
  });
}
```

### Target Implementation

**Service:** Native OpenCode 'title' system agent

**Agent Details:**
- Hidden system agent in OpenCode
- Optimized for lightweight title generation
- Uses `small_model` configuration (cheaper model)
- Can be invoked via `/session/{id}/message` with `agent: "title"` parameter

**Benefits:**
- ✅ No external service dependency
- ✅ Works offline with local models
- ✅ Respects user's OpenCode configuration
- ✅ No privacy concerns (data stays in user's infrastructure)
- ✅ Consistent with OpenCode's native behavior
- ✅ Reduces network latency (local call vs external API)

### Implementation Plan

1. **Create `OpenCodeTitleGenerator` class**
   - Implement `ChatTitleGenerator` interface
   - Use existing `ChatRemoteDataSource` to call `/session/{id}/message`
   - Pass `agent: "title"` in payload
   - Format messages as prompt (similar to current ch.at format)
   - Extract title from assistant response

2. **Payload Structure**
   ```dart
   {
     "agent": "title",
     "parts": [
       {
         "type": "text",
         "text": "<formatted prompt with conversation history>"
       }
     ],
     // Optional: specify small model if not using agent's default
     "model": {
       "providerID": "...",
       "modelID": "..."
     }
   }
   ```

3. **Session Strategy**
   - Option A: Create ephemeral session for title generation (clean, isolated)
   - Option B: Reuse current session with agent override (simpler, but pollutes history)
   - **Recommended: Option A** (create temp session, get title, delete session)

4. **Update Dependency Injection**
   - Replace `ChatAtTitleGenerator` with `OpenCodeTitleGenerator` in `injection_container.dart`
   - Keep same interface so existing code doesn't need changes

5. **Remove ch.at References**
   - Remove toggle from Settings (no longer needed for privacy)
   - Clean up imports and unused code
   - Update documentation

6. **Fallback Strategy**
   - If title agent fails, fall back to timestamp-based default
   - Log errors for debugging but don't block session creation
   - Same as current behavior (graceful degradation)

### API Reference

**OpenCode Agent Invocation:**
```bash
POST /session/{sessionId}/message
Content-Type: application/json

{
  "agent": "title",
  "parts": [
    {
      "type": "text",
      "text": "Based on the texts below, generate a title...\n\n1. USER: ..."
    }
  ]
}
```

**Response Extraction:**
- Listen to SSE events from `/event` stream
- Extract text from `message.part.updated` events (type: "text")
- Normalize title (remove quotes, trim, limit length)
- Delete temporary session after extraction

### Testing Strategy

1. **Unit Tests**
   - Test prompt formatting with different message counts
   - Test title extraction from various response formats
   - Test normalization logic (quotes, whitespace, length)

2. **Integration Tests**
   - Mock OpenCode server with title agent endpoint
   - Verify session creation/deletion lifecycle
   - Test timeout and error handling

3. **Manual Testing**
   - Test with real OpenCode server (local or remote)
   - Verify titles generate correctly after 6 messages
   - Check Settings toggle removal doesn't break existing preferences
   - Test with different models (via `small_model` config)

### Migration Path

**Phase 1: Implement new generator**
- Create `OpenCodeTitleGenerator` class
- Add to DI container alongside existing implementation
- Feature flag to switch between ch.at and OpenCode

**Phase 2: Test and validate**
- Run integration tests
- Manual validation with real OpenCode instances
- Compare title quality between ch.at and OpenCode agent

**Phase 3: Migrate and cleanup**
- Remove feature flag, use OpenCode agent by default
- Remove `ChatAtTitleGenerator` and ch.at dependencies
- Remove Settings toggle for AI-generated titles (always on now)
- Update CODEBASE.md and ADR

### Risks and Mitigation

**Risk:** Title agent might not be available in older OpenCode versions
- **Mitigation:** Version detection and fallback to timestamp-based titles

**Risk:** Quality of titles might differ from ch.at
- **Mitigation:** Test with multiple prompts, adjust formatting if needed

**Risk:** Creating ephemeral sessions might impact performance
- **Mitigation:** Use async background generation, same as current approach

**Risk:** Session pollution if using Option B
- **Mitigation:** Use Option A (ephemeral sessions) to keep history clean

### Success Criteria

- [ ] `OpenCodeTitleGenerator` implemented with full `ChatTitleGenerator` interface
- [ ] Integration tests passing with mock OpenCode server
- [ ] Manual tests confirm titles generate correctly
- [ ] No ch.at dependencies remaining in codebase
- [ ] Settings section updated (privacy toggle removed)
- [ ] CODEBASE.md and ADR documentation updated
- [ ] No regressions in title generation cadence (still every 6 messages)
