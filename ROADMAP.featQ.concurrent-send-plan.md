# Concurrent Send While Responding - Technical Plan

> **Status**: Planning (implementation-ready)
> **Feature**: featQ / Group 3 / Item 27
> **Scope**: Allow a new user message while assistant is still streaming in the same session

---

## 1. Objective

Support OpenCode-style flow where users can submit a new message while a response is in progress, with deterministic semantics:

- Same session keeps a single active run.
- New send during active run interrupts the current run, then starts the new one.
- No parallel assistant runs in one session.

---

## 2. Current Behavior (CodeWalk)

- Composer blocks send while responding in `lib/presentation/widgets/chat_input/chat_input_state_machine.dart` (`_handleSendMessage` returns early when `widget.isResponding`).
- Send button switches to Stop while responding in `lib/presentation/widgets/chat_input_widget.dart`.
- Provider already has stream-generation protection and can replace same-session stream on new send in `lib/presentation/providers/chat_provider.dart`.
- Abort flow already exists (`abortActiveResponse`) and is wired to Stop button and double-ESC behavior.

Main gap: UI does not expose interrupt-and-send path, even though provider foundations are close.

---

## 3. Target UX Contract (CLI/Web Parity)

### 3.1 Primary behavior

- If assistant is responding and composer has draft content, `Enter`/send performs **Interrupt + Send**.
- If assistant is responding and composer is empty, action remains **Stop**.
- Keep current double-ESC stop behavior.

### 3.2 Feedback behavior

- Show short composer status while interrupting (example: `Interrupting previous response...`).
- Keep draft editable during all states.
- Do not open extra dialogs for this path.

### 3.3 Platform behavior

- Desktop and mobile share the same semantics.
- Visual affordance may differ by layout density, but action outcome must be identical.

---

## 4. Execution Model

Introduce a dedicated provider path:

`interruptAndSendMessage(...)`

Flow:

1. Detect active response for current session.
2. Trigger abort for the in-flight response.
3. Wait for local stream teardown and idle transition (bounded timeout).
4. Send the new user message.
5. Ignore stale chunks from the aborted run.

Notes:

- Reuse existing stream-generation invalidation.
- Keep abort suppression logic for expected abort-like errors.
- Keep cross-session behavior unchanged (other session streams continue).

---

## 5. UI/Composer Changes

In `ChatInputWidget`:

- Allow send path while responding when draft/attachments/context exist.
- Resolve action button by state:
  - Responding + empty draft => Stop
  - Responding + draft => Interrupt + Send
  - Idle + draft => Send
- Keep keyboard submit parity with button behavior.

In `ChatPage`:

- Route composer submit to provider interrupt-aware API.

---

## 6. Reliability and Guardrails

- Single active run per session remains invariant.
- Stale event chunks from previous generation must be ignored.
- If abort fails, keep draft and show actionable notice (no silent drop).
- If send fails after successful abort, draft restore remains mandatory.

---

## 7. Test Plan

### Provider tests

- Abort-before-send call ordering.
- Stale stream events ignored after interrupt.
- Failure cases: abort failure, send failure, timeout path.

### Widget tests

- Responding + draft shows interrupt-send affordance and submits successfully.
- Responding + empty draft still shows stop affordance.
- Desktop `Enter` mirrors button semantics while busy.

### Regression tests

- Existing stop behavior (button and double ESC) still works.
- Existing cross-session stream preservation still works.

---

## 8. Incremental Rollout

1. Provider API for interrupt-and-send + unit tests.
2. Composer state/affordance update + widget tests.
3. Status copy and edge-case polish.
4. Validate mobile and desktop interaction parity.

---

## 9. References

- https://www.9.agency/blog/streaming-ai-responses-vercel-ai-sdk
- https://google.github.io/adk-docs/streaming/dev-guide/part1/
- https://github.com/vercel/ai/issues/9021
