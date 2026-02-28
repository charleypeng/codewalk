# MessageAborted Inline UX Plan

> **Status**: In progress (async send stale-ID protection and idle bypass implemented)
> **Feature**: featQ / Group 3 / MessageAborted inline feedback
> **Related Task**: `ROADMAP.featQ.md` item about replacing toast+retry for MessageAborted (Implemented in 745c0a8, f1faf4a)

## Objective

Replace abort-like toast feedback with an inline, friendly chat bubble message when interruption is expected (local stop or interrupt-and-send), while preserving toast behavior for real non-abort failures.

## Target UX

- For expected aborts (`MessageAborted`, user stop, interrupt-and-send):
  - no global error state;
  - no snackbar retry CTA;
  - show inline assistant/system-style red-friendly message:
    - `What you want to do different?`
- For non-abort runtime failures (network, rate limit, provider errors):
  - keep existing error/toast behavior.

## Current Gaps

- `session.error` with abort-like signature can still surface as remote-abort notice (`ChatUiNoticeType.remoteAbort`) instead of inline chat content.
- Abort suppression is time-window based and should be complemented by explicit inline rendering policy.
- Interrupt-and-send already suppresses abort failure UI, but no inline marker exists yet for the aborted response context.

## Technical Plan

1. Add explicit provider path for abort-like terminal events:
   - convert abort-like session error into an inline transient message model;
   - keep `ChatState.loaded` and avoid setting `_errorMessage`.
2. Reuse message rendering pipeline:
   - inject inline message as a normal timeline item (non-toast) with subtle red styling token.
3. Keep strict separation:
   - abort-like => inline message;
   - non-abort => existing toast/error flow.
4. Ensure interrupt-and-send path keeps silent suppression and never emits abort snackbar.

## Validation Plan

- Unit tests:
  - abort-like `session.error` produces inline message and no global error;
  - non-abort `session.error` keeps current error behavior.
- Widget tests:
  - inline abort message appears in timeline with expected text;
  - no retry snackbar appears for abort-like interruption;
  - retry snackbar still appears for non-abort remote errors.

## Rollout

1. Provider state/event mapping for inline abort message.
2. Timeline UI style and accessibility text.
3. Tests and regression pass (`make check`).
4. Android build validation (`HEY_CAPTION=... make android`).
