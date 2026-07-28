# Issue #122: Mobile Terminal Extra Keys Execution Plan

## Status

Ready for implementation.

No production code has been changed for this issue. The previous OpenCode compatibility plan is complete and superseded by this file. Issue closure is conditional on successful CI and Android runtime validation; automated iOS coverage is required, while physical iOS validation is best-effort when a supported environment is available.

## Work Item

- Issue: https://github.com/verseles/codewalk/issues/122
- Title: `Adicionar barra de teclas extras acima do teclado no terminal mobile`
- User problem: mobile software keyboards omit terminal keys needed for cursor movement, history navigation, completion, escape, and common control sequences.
- Requested UX: a compact Termux-inspired key strip immediately above the software keyboard, adapted to CodeWalk's Material You design.

## Objective

Add an Android/iOS-only extra-key strip to the embedded terminal with these initial keys:

| Key | Required behavior |
| --- | --- |
| `Esc` | Send terminal Escape. |
| `Tab` | Send terminal Tab. |
| `Ctrl` | Toggle a visible one-shot modifier for the next terminal input. |
| `Alt` | Toggle a visible one-shot modifier for the next terminal input. |
| Left, Up, Down, Right | Send cursor keys and repeat while held. |

The strip must work in inline and maximized terminal surfaces without recreating the terminal or PTY. It must appear only when a supported mobile platform has an active terminal view and the software keyboard is open. Desktop and web behavior must remain unchanged.

## Definition of Done

- The strip appears on Android and iOS when `MediaQuery.viewInsetsOf(context).bottom > 0` and the terminal body is active.
- The strip is absent on desktop, web, when the terminal is hidden, and when the software keyboard is closed.
- Escape, Tab, and all four arrows emit the correct terminal sequence through the existing `Terminal.onOutput` to WebSocket PTY path.
- `Ctrl+C`, `Ctrl+D`, and `Ctrl+L` emit `\x03`, `\x04`, and `\x0c` respectively.
- `Alt+Left`, `Alt+Up`, `Alt+Down`, and `Alt+Right` emit `\x1b[1;3D`, `\x1b[1;3A`, `\x1b[1;3B`, and `\x1b[1;3C` respectively.
- Both modifiers can be armed at the same time; supported combined inputs use normal xterm modifier semantics.
- Armed modifiers are visually and semantically exposed, toggle off when tapped again, and are consumed after one non-modifier input gesture.
- Holding an arrow repeats the sequence resolved for that gesture until release or cancellation.
- Modifier state and repeat timers cannot survive keyboard closure, terminal generation changes, reconnect, hide, close, surface replacement, or disposal.
- Tapping keys does not dismiss the software keyboard or permanently move focus away from the terminal.
- The strip is horizontally scrollable without overflow on narrow and landscape layouts, respects `SafeArea`, and does not double-apply keyboard insets.
- Every control has an adequate Material touch target and localized tooltip or semantic label.
- Existing mobile Backspace behavior, Windows printable input, Windows AltGr, terminal resize, and desktop keyboard shortcuts remain covered and unchanged.
- Focused tests, vendored xterm tests, `make check`, reviewer gates, remote CI, and Android runtime acceptance pass.
- A Portuguese evidence comment is posted to issue #122 and the issue is closed only after every closure gate succeeds.

## Baseline and Architectural Constraints

- Repository: `/home/ubuntu/MEGA/WORK/codewalk`.
- Branch baseline observed during planning: `main` aligned with `origin/main`, with a clean worktree before this plan replacement.
- Current terminal UI entry point: `lib/presentation/widgets/codewalk_terminal_panel.dart`.
- The same `CodewalkTerminalPanel` is composed into inline and maximized chat surfaces, so integration belongs in the panel rather than duplicated chat-page branches.
- `CodewalkTerminalController` creates a new xterm `Terminal` and increments `terminalGeneration` on a new shell/reconnect generation.
- `Terminal.onOutput` already UTF-8 encodes all terminal input and sends it over the existing WebSocket connection. Extra keys must use this path.
- ADR-027 requires the PTY to remain server-hosted and the client to remain a rendering/input surface. Do not change socket endpoints, session creation, resize, reconnect, or close semantics.
- ADR-023 remains aligned because this is client-only terminal input behavior with no OpenCode API or event-contract change.
- Existing Android delete detection and Windows hardware/AltGr fallback in vendored xterm are invariants.
- `Home`, `End`, `Page Up`, and `Page Down` are deferred. They are not part of the initial strip because their mode-dependent behavior and added width are not required by the acceptance criteria.
- Do not modify `third_party/xterm/lib/src/core/input/keytab/keytab_default.dart`. The mobile behavior is CodeWalk-specific and must not alter default desktop xterm mappings.
- Do not recreate `ROADMAP.md`; GitHub Issues remain the canonical task tracker.

## Resolved Design

### Visibility and Placement

Add `CodewalkTerminalExtraKeys` in `lib/presentation/widgets/codewalk_terminal_extra_keys.dart` and render it directly below the `Expanded` terminal body in `CodewalkTerminalPanel`.

The visibility predicate is:

```text
!kIsWeb
&& (defaultTargetPlatform == TargetPlatform.android
    || defaultTargetPlatform == TargetPlatform.iOS)
&& terminal state renders TerminalView
&& MediaQuery.viewInsetsOf(context).bottom > 0
```

Use the same terminal states that currently render `TerminalView`: `starting`, `running`, and `exited`. The strip is hidden for idle, unavailable, and failed fallback content.

Wrap the strip in `SafeArea(top: false)` and a horizontally scrolling viewport. Do not add `viewInsets.bottom` as padding because the host layout and maximized overlay already subtract the software-keyboard inset; adding it again would shrink the terminal twice. When the strip is visible, the terminal body must not own the panel's bottom corner radius; the strip becomes the bottom-clipped child.

### Input State Owner

Keep the input state and encoding logic beside the widget in `codewalk_terminal_extra_keys.dart` as a small `CodewalkTerminalExtraKeysController`. The panel owns one instance plus one external terminal `FocusNode`; the visual strip listens to the controller.

The controller owns:

- pending one-shot `Ctrl` and `Alt` state;
- the currently attached xterm `Terminal` and its original `TerminalInputHandler`;
- a narrow delegating input-handler wrapper;
- the active arrow-repeat timer and the sequence captured for that gesture;
- attach, detach, reset, dispatch, raw-text fallback, and disposal behavior.

This controller is justified because the same state must be shared by the extra-key widget, `TerminalView` IME fallback, focus/lifecycle handling, and tests. Do not put modifier state in `CodewalkTerminalController`; PTY lifecycle must stay independent from mobile presentation state.

### xterm Input Seam

`Terminal.keyInput(...)` passes single virtual keys, delete/action keys, and hardware key events through `Terminal.inputHandler`. `Terminal.textInput(...)` bypasses that handler. Current `TerminalView._onInsert` uses both paths, including direct `textInput` for unrecognized and multi-character IME commits.

Use both of these narrow, opt-in seams:

1. While the panel owns a supported mobile terminal, replace that terminal's input handler with a delegating wrapper that merges armed one-shot modifiers into the next `TerminalKeyboardEvent` and otherwise returns the original handler's result unchanged.
2. Add an optional consuming raw-text callback to vendored `TerminalView`, invoked immediately before `_onInsert` falls back to `terminal.textInput(text)`. Returning `true` means the callback emitted or deliberately consumed the text; null, absent, or `false` preserves current behavior exactly.

The callback must not replace composing, delete-delta, editing-buffer reset, keyboard-action, shortcut, or hardware-key logic. Add a focused xterm package test proving both consumption and unchanged fallback.

When detaching or moving to a new `terminalGeneration`, restore the old terminal's original handler only if it still points to CodeWalk's wrapper. This avoids retaining panel closures and avoids overwriting another legitimate handler change.

### Sequence Rules

Resolve quick-key output against the current terminal state so unmodified keys preserve application cursor mode and other xterm behavior.

| Input | Encoding rule |
| --- | --- |
| Unmodified Escape, Tab, arrows | Delegate a `TerminalKeyboardEvent` to the original xterm input handler. |
| `Ctrl+A` through `Ctrl+Z` | Use standard control bytes `0x01` through `0x1a`. |
| `Alt` plus printable input | Prefix the modified character with Escape. |
| `Ctrl+Alt` plus supported printable input | Prefix Escape to the corresponding control byte. |
| `Alt+arrow` | Emit CSI `1;3` plus `A`, `B`, `C`, or `D`. |
| `Ctrl+arrow` | Emit CSI `1;5` plus the direction suffix. |
| `Ctrl+Alt+arrow` | Emit CSI `1;7` plus the direction suffix. |

The direction suffixes are `A` for Up, `B` for Down, `C` for Right, and `D` for Left.

For a multi-scalar IME commit while a modifier is armed, apply the one-shot modifier to the first scalar and forward any remaining committed text normally. Clear the pending state after the attempted non-modifier input even if the terminal has disconnected, preventing stale accidental combinations.

Do not depend on the current keytab's Alt-arrow entries. They do not produce the required `1;3` sequences consistently.

### One-Shot and Repeat Behavior

- Tapping `Ctrl` or `Alt` toggles that modifier independently.
- Tapping an active modifier again cancels it without emitting bytes.
- The next Escape, Tab, arrow, virtual-key event, hardware-key event on mobile, or committed IME input consumes all armed modifiers.
- A normal arrow tap emits one resolved sequence.
- A long press resolves and emits one sequence when the long press activates, then repeats that exact captured sequence at a fixed interval until pointer up/cancel.
- Use named constants for repeat delay/interval so widget tests can advance fake time deterministically. Prefer Flutter's normal long-press threshold followed by approximately 70-100 ms repetition rather than a custom immediate gesture recognizer.
- If `Alt` was armed before an arrow hold, every repeat in that one hold remains the same Alt-arrow sequence even though the visible one-shot state clears after the first emission.
- Starting another repeat cancels the previous timer.

### Focus and Accessibility

- Pass a panel-owned external `FocusNode` to `TerminalView`.
- Make strip controls unable to become the lasting keyboard focus owner and request terminal focus after dispatch when needed.
- Do not close or recreate the `CustomTextEdit` input connection.
- Keep visible labels compact: `Esc`, `Tab`, `Ctrl`, `Alt`, and directional icons.
- Give each control at least a 48 dp interactive target even if the painted button is visually denser.
- Expose the strip as a semantic container and each key as a semantic button.
- Expose modifiers as toggled/selected and use Material color roles for a distinct active state.
- Avoid a Tooltip long-press recognizer on repeatable arrows if it competes with hold repetition; localized semantics satisfy the accessibility requirement.

### Localization

Add these English source keys and translations for every currently supported locale in `tool/i18n/arb_strings.dart`:

- `terminalExtraKeys`
- `terminalExtraKeyEscape`
- `terminalExtraKeyTab`
- `terminalExtraKeyControl`
- `terminalExtraKeyAlt`
- `terminalExtraKeyArrowLeft`
- `terminalExtraKeyArrowUp`
- `terminalExtraKeyArrowDown`
- `terminalExtraKeyArrowRight`

Before running any generator, perform a non-mutating key-set comparison between `arb_strings.dart` and existing `lib/l10n/app_*.arb` files. Abort rather than deleting newer keys. Use `generate_translation_payload.py` and `merge_back_translations.py` for missing per-locale values, keep temporary payloads out of the final diff, then regenerate Flutter localization output. Verify that generated diffs add only the intended keys and do not remove or rewrite unrelated translations.

## Files

### Production

- `lib/presentation/widgets/codewalk_terminal_extra_keys.dart` (new): strip UI, modifier state/controller, sequence resolution, and repeat lifecycle.
- `lib/presentation/widgets/codewalk_terminal_panel.dart`: visibility, placement, focus, terminal-generation attachment, raw IME callback, and lifecycle wrappers.
- `third_party/xterm/lib/src/terminal_view.dart`: optional consuming raw-text fallback callback only.
- `tool/i18n/arb_strings.dart`: source labels and all supported translations.
- `lib/l10n/app_*.arb`: generated localization resources.
- `lib/l10n/generated/app_localizations*.dart`: generated delegates.

### Tests

- `third_party/xterm/test/src/terminal_view_test.dart`: opt-in raw-text callback contract and no-callback fallback.
- `test/widget/codewalk_terminal_extra_keys_test.dart` (new): sequence, one-shot, repeat, focus, semantics, visibility, and compact-layout coverage.
- `test/widget/terminal_mobile_backspace_test.dart`: regression coverage for Android IME delete behavior and modifier-aware IME insertion without weakening Windows tests.
- `test/widget/chat_page_test.dart`: inline/maximized composition, mobile keyboard inset visibility, no overflow, and same-session behavior.
- `test/unit/services/codewalk_terminal_controller_test.dart`: only add a narrow transport assertion if needed to prove emitted bytes still reach the existing socket; do not change production controller behavior.

### Documentation

- `BEHAVIOR.md`: document implemented mobile strip visibility, one-shot modifiers, arrow repeat, and unchanged PTY/session lifecycle.
- `CODEBASE.md`: add the new production widget/input-state module through the `codemapper` subagent after code is final.
- `ADR.md`: no change expected. ADR-027 already authorizes client rendering/input over the existing server PTY, and no ADR-023 exception is needed.

## Execution Plan

Execution of this file must use the repository's plan-anchored commit protocol. Before implementation, create a new immutable `plan:` commit containing `AGENT_PLAN_ANCHOR`, the verbatim user authorization, this full plan, constraints, validation gates, and the exact step sequence below. Do not reuse the completed compatibility anchor.

### Step 1 of 3: Add the mobile input protocol seam

Implement the opt-in `TerminalView` raw-text callback and `CodewalkTerminalExtraKeysController` input translation/lifecycle logic without integrating the visual strip yet.

Required checks:

```bash
# From repository root
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/terminal_mobile_backspace_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/unit/services/codewalk_terminal_controller_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/presentation/widgets/codewalk_terminal_extra_keys.dart third_party/xterm/lib/src/terminal_view.dart test/widget/terminal_mobile_backspace_test.dart test/unit/services/codewalk_terminal_controller_test.dart

# From third_party/xterm
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/src/terminal_view_test.dart
```

Run `make check` from the repository root before the first code progress commit because this is the first stable code gate. Run the full Reviewer Loop with up to three independent read-only reviewers. Fix judge-approved correctness, lifecycle, encoding, and regression findings, then repeat focused validation/review until no approved correction remains.

Commit only Step 1 files as:

```text
chore(agent): [Step 1/3] Add mobile terminal input protocol
```

Include `PLAN_REF` and `PREVIOUS_STEP` in the required progress-commit body.

### Step 2 of 3: Build and integrate the extra-key strip

Add the Material You strip, panel placement, focus ownership, mobile/inset visibility, compact scrolling, semantics, localization, and inline/maximized integration. Preserve the existing panel and PTY instance during maximize/restore.

Required focused coverage:

- exact Escape, Tab, arrow, `Ctrl+C`, `Ctrl+D`, `Ctrl+L`, all four `Alt+arrow`, and combined modifier bytes;
- modifier visual/semantic state, cancellation, one-shot consumption, and generation/keyboard/dispose reset;
- tap versus hold behavior, repeat cancellation, and captured modified repeat sequence;
- Android and iOS visibility with a non-zero keyboard inset;
- absence on desktop/web and with zero keyboard inset;
- 320-390 dp compact widths and landscape constraints without overflow;
- terminal focus/input connection after taps;
- inline to maximized to restored rendering without PTY recreation;
- unchanged Android Backspace, Windows printable characters, and Windows AltGr.

Required commands:

```bash
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/codewalk_terminal_extra_keys_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/terminal_mobile_backspace_test.dart
export PATH="$HOME/flutter/bin:$PATH" && flutter test test/widget/chat_page_test.dart --plain-name "mobile terminal"
export PATH="$HOME/flutter/bin:$PATH" && flutter analyze lib/presentation/widgets/codewalk_terminal_panel.dart lib/presentation/widgets/codewalk_terminal_extra_keys.dart test/widget/codewalk_terminal_extra_keys_test.dart test/widget/terminal_mobile_backspace_test.dart test/widget/chat_page_test.dart
export PATH="$HOME/flutter/bin:$PATH" && make check
```

If the final chat test names differ, run the exact newly added names individually; do not silently skip them because a broad `--plain-name` filter matches nothing.

Run the full Reviewer Loop again on the cumulative plan diff. Validate findings against the issue protocol, terminal modes, focus behavior, and lifecycle. Apply only judge-approved fixes. After micro-fixes, rerun focused checks by default; rerun `make check` only if shared infrastructure, generated localization, or another full-check assumption changed.

Commit only Step 2 files as:

```text
chore(agent): [Step 2/3] Add mobile terminal extra-key strip
```

### Step 3 of 3: Document and validate acceptance

Update `BEHAVIOR.md` only with behavior that now exists. Delegate `CODEBASE.md` to `codemapper` because the new production module changes the structural map. Do not add an ADR or recreate a roadmap.

Perform a final cumulative reviewer pass, including documentation accuracy against the implementation. Verify generated localization files and run focused tests for any reviewer-requested code fix. Run `make check` again only if the final code state is no longer covered by the passing Step 2 check.

Commit Step 3 documentation as:

```text
chore(agent): [Step 3/3] Document mobile terminal extra keys
```

### Runtime Acceptance

This planning host reports `aarch64`; project policy says local release APK builds are unreliable on ARM64 Linux. Do not claim Android validation from a failed or skipped `make android`.

Before closing #122, validate on a real or emulated Android environment that supports the app:

1. Open a live server-hosted terminal and software keyboard.
2. Verify strip visibility inline and maximized.
3. Run `printf`/`od` or a small PTY reader to verify control and Alt-arrow bytes.
4. Verify shell history/cursor navigation, Tab completion, Escape in an interactive application, `Ctrl+C`, `Ctrl+D`, and `Ctrl+L`.
5. Hold each arrow, release it, and confirm repetition stops immediately.
6. Reconnect, minimize/restore, maximize/restore, and close/reopen; confirm no stale modifier/repeat and no unintended PTY recreation for hide/maximize transitions.
7. Rotate or use a narrow viewport and confirm the strip scrolls without covering or overflowing the terminal.
8. Check TalkBack labels and modifier state announcement.

If a supported x86_64 signing/build host is available and an APK is useful, run this only after checks pass:

```bash
HEY_CAPTION="CodeWalk mobile terminal extra keys for issue #122" make android
```

On iOS, run the equivalent software-keyboard, VoiceOver, and PTY sequence checks when a supported macOS/iOS environment is available. Automated iOS platform-variant widget tests remain mandatory even when physical iOS hardware is unavailable.

If Android runtime validation cannot be performed, push the tested implementation only if still authorized, post a progress comment with the missing gate, and leave issue #122 open.

## Delivery

After all local code, documentation, reviewer, and Android acceptance gates pass:

1. Inspect `git status`, the cumulative diff, and recent commits; stage only plan-owned files and never include temporary translation payloads or unrelated user changes.
2. Push the completed plan commits from `main` to `origin/main`. This is a normal feature push, not a release; do not bump a version, tag, or invoke the releaser.
3. Delegate CI monitoring to `cimonitor` and continue checking at the required interval until the pushed commit has a final result.
4. If CI fails, diagnose the concrete failure, apply the smallest correction, run focused validation and the Reviewer Loop, create a `fix:` commit with `PLAN_REF`, push, and monitor the replacement run.
5. Confirm the required `quality`, main-branch `coverage`, and `windows_build` jobs are successful. Record their run URL.
6. Post a concise Portuguese issue comment listing the implementation commit(s), focused/full test evidence, reviewer result, Android validation evidence, CI URL, and any unavailable iOS physical-device caveat.
7. Close issue #122 with reason `completed` only after the comment and every mandatory gate pass.

## Risks and Mitigations

| Risk | Mitigation |
| --- | --- |
| Wrong control/escape bytes reach interactive programs | Centralize deterministic encoding and assert exact output strings/bytes for every accepted combination. |
| One-shot modifiers leak into later commands | Clear after every attempted non-modifier input and at all keyboard, generation, visibility, and disposal boundaries. |
| Arrow timer writes to a replaced terminal | Capture terminal identity, cancel on attach/detach/reset, and guard timer callbacks against the current attachment. |
| Input-handler wrapper retains panel state or overwrites another handler | Save/delegate the original handler and restore it only when CodeWalk's wrapper is still installed. |
| IME text bypasses modifiers | Use the opt-in raw-text callback immediately before `TerminalView` falls back to `textInput`. |
| Vendored xterm change regresses existing clients | Default the hook to null, preserve the old path byte-for-byte, and test inside the xterm package plus CodeWalk regressions. |
| Extra buttons dismiss the keyboard | Keep terminal focus ownership external, prevent lasting button focus, and test the input connection after interaction. |
| Keyboard inset is applied twice | Use the inset as a visibility signal only; rely on existing layout resize and `SafeArea` for placement. |
| Narrow screens overflow or shrink the terminal excessively | Use a single compact horizontal strip with fixed touch targets and scrolling rather than wrapping to multiple rows. |
| Localization generation deletes newer keys | Audit key sets first, use the safe payload/merge workflow, and reject unrelated deletions in the generated diff. |
| Automated tests pass but Android IME behavior differs | Keep real/emulated Android runtime evidence as an issue-closure gate. |

## Out of Scope

- `Home`, `End`, `Page Up`, `Page Down`, function keys, configurable rows, macros, or user-reorderable keys.
- Sticky/locked modifier mode, double-tap lock, or modifier persistence across gestures.
- Changes to desktop quick keys, global shortcuts, the xterm default keytab, or Windows AltGr behavior.
- PTY protocol, socket transport, server endpoints, reconnect semantics, terminal process ownership, or OpenCode API/event behavior.
- Replacing vendored xterm or upstreaming the generic callback as part of this issue.
- Version bump, release tag, or release workflow.

## References

- Issue #122: https://github.com/verseles/codewalk/issues/122
- ADR-023: `ADR.md` (`Contract-First OpenCode Compatibility Policy`)
- ADR-027: `ADR.md` (`Server-Hosted PTY Terminal with Embedded Client Rendering`)
- Current behavior: `BEHAVIOR.md` (`Terminal workspace`)
- Local official anchors: `ai-docs/opencode_server.md`, `ai-docs/opencode_web.md`, `ai-docs/opencode_models.md`
- Existing panel: `lib/presentation/widgets/codewalk_terminal_panel.dart`
- Existing PTY controller: `lib/presentation/services/codewalk_terminal_controller.dart`
- Existing xterm input: `third_party/xterm/lib/src/terminal.dart`, `third_party/xterm/lib/src/terminal_view.dart`, `third_party/xterm/lib/src/core/input/handler.dart`
- Existing keytab evidence: `third_party/xterm/lib/src/core/input/keytab/keytab_default.dart`
- Existing mobile/desktop input regressions: `test/widget/terminal_mobile_backspace_test.dart`
- Secondary OpenChamber quick-key reference pinned to the inspected snapshot: https://github.com/openchamber/openchamber/blob/ff1b39ffa91f860593b70c76d0ea6f13a5d8e3f6/packages/ui/src/components/views/TerminalView.tsx
- Secondary OpenChamber labels pinned to the inspected snapshot: https://github.com/openchamber/openchamber/blob/ff1b39ffa91f860593b70c76d0ea6f13a5d8e3f6/packages/ui/src/lib/i18n/messages/en.ts

## Handoff Notes

- Read the current worktree before implementation and preserve unrelated changes.
- Recover the latest anchor only to confirm the old compatibility plan is complete, then create a new issue #122 anchor.
- Keep one `in_progress` execution todo at a time and record start/end timestamps for non-trivial work.
- Do not start documentation before the final UI behavior and focused tests are stable.
- Do not close the issue based only on widget tests or CI; Android runtime evidence is mandatory.
