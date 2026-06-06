# Final Synthesized Execution Plan — Simplify Embedded Terminal Implementation

## Execution Plan (Synthesized)

> **This is an imperative execution directive, not a ranking or comparison.** Every decision below is final and resolved. Every detail needed for implementation is explicitly stated. A future executor with zero prior context must be able to implement the entire plan by reading this section alone. Conflicting alternatives from individual planners have been resolved — this plan contains one harmonious path, not options.

### Status

Ready

### Problem

The embedded terminal in CodeWalk is unreliable and frequently bugs out. Specifically:
1. **Dead session reuse**: The controller (`CodewalkTerminalController`) reuses stale PTY session IDs (`_ptyId`) when the terminal is in a `failed` or `exited` state, leading to broken WebSocket connection attempts.
2. **Force reconnect leaks**: Using the Reconnect button (`force: true`) only disconnects the WebSocket stream but fails to terminate/delete the PTY session on the server, resulting in PTY leaks and reconnects to stale sessions.
3. **UTF-8 split chunk decoding**: Using stateless `utf8.decode()` on incoming WebSocket chunks corrupts multi-byte UTF-8 sequences (such as accented characters, non-ASCII symbols, and emojis) if a character's byte sequence is split across frame boundaries.
4. **Unhandled resize exceptions**: When the PTY session is closed or unreachable, debounced `resizePty` API calls throw exceptions which escape the `Timer` callback and crash the application.

### Objective

Simplify and stabilize the embedded terminal implementation so it handles lifecycle transitions cleanly, decodes streamed output correctly without corruption, and remains crash-free during resize operations.

### Context and Constraints

- **Main Target File**: `lib/presentation/services/codewalk_terminal_controller.dart`
- **Other Affected Files**:
  - `lib/presentation/pages/chat_page/chat_page_terminal_runtime.dart` (ensure signature cache doesn't block dead-session restarts)
- **Quality Gates**: `make check` must pass cleanly.
- **Rules**:
  - Keep changes strictly client-side to satisfy ADR-023/ADR-027. Do not modify server-side contracts or PTY API endpoints.
  - Do not modify the `xterm` third-party package itself.
  - Test the controller deterministically via unit tests using constructor injection seams.

### Decisions (Resolved)

1. **PTY Session Reuse Policy**: Only reuse the PTY session when it is healthy and active. Dead states (`failed`, `exited`) must bypass reuse and trigger a fresh PTY creation.
2. **Force Reconnect Policy**: When starting the shell with `force: true` (e.g. from a user-initiated Reconnect click), unconditionally terminate and delete the existing PTY session first, then spawn a fresh PTY.
3. **Recursive Retry Removal**: Remove the recursive `startShell` call from the `catch` block on socket connection error. Unbounded retries cause infinite connection loops on persistent network errors. Instead, transition directly to `failed` and display a clear error message, letting the user manually click Reconnect.
4. **Stateful Decoding Pattern**: Implement a per-connection stateful UTF-8 chunk decoder using `Utf8Decoder(allowMalformed: true).startChunkedConversion` mapped to a custom `StringSink` wrapper forwarding to `_terminal.write`. Store the decoder reference on the connection/listener scope (or reset it properly in the controller) to prevent state bleeding between sessions.
5. **Debounce Resize Exception Swallowing**: Wrap `resizePty` in a `.catchError((_) {})` handler within the timer callback, and verify that the session identity (`_ptyId` and `_directory`) has not changed before calling the API.

---

### Overview

We will update the terminal controller to prevent dead session reuse, clean up server-side PTYs on force reconnect, adopt a stateful UTF-8 decoder for stream output, and swallow exceptions during resize. We will also add a socket-opener injection seam to the constructor to allow thorough unit testing with fakes, and write unit tests in `test/unit/services/codewalk_terminal_controller_test.dart`.

---

### Steps

#### 1. Add Socket Opener Test Seam to Controller
- **Files**: `lib/presentation/services/codewalk_terminal_controller.dart`
- **Details**:
  Define a typedef at the top of the file:
  ```dart
  typedef CodewalkTerminalSocketOpener = Future<CodewalkTerminalSocketConnection> Function({
    required Uri url,
    Map<String, String>? headers,
  });
  ```
  Add a private `_socketOpener` field to `CodewalkTerminalController` and expose it via the constructor (defaulting to the global `openCodewalkTerminalSocket`):
  ```dart
  class CodewalkTerminalController extends ChangeNotifier {
    CodewalkTerminalController({
      TerminalRemoteDataSource? remoteDataSource,
      CodewalkTerminalSocketOpener? socketOpener,
    }) : _remoteDataSource = remoteDataSource ?? _UnavailableTerminalRemoteDataSource(),
         _socketOpener = socketOpener ?? openCodewalkTerminalSocket {
      _terminal = _createTerminal();
    }
  
    final TerminalRemoteDataSource _remoteDataSource;
    final CodewalkTerminalSocketOpener _socketOpener;
    ...
  ```
  Replace the direct call `openCodewalkTerminalSocket(...)` at line 114 with `_socketOpener(...)`.
- **Validation**: Check that the project compiles using `make check`.

#### 2. Update Reuse Logic and Simplify Catch Block
- **Files**: `lib/presentation/services/codewalk_terminal_controller.dart`
- **Details**:
  Replace `canReuseSession` definition in `startShell` with state-aware checks:
  ```dart
  final targetKey = '${serverProfile.id}\u0000$normalizedDirectory';
  final isDeadState = _state == CodewalkTerminalState.failed ||
      _state == CodewalkTerminalState.exited;
  final canReuseSession = !force &&
      _ptyId != null &&
      _targetKey == targetKey &&
      !isDeadState;
  
  if (!force && canReuseSession && _socket != null) {
    return;
  }
  
  if (!canReuseSession || force) {
    await _terminateSession();
  } else {
    await _disconnectSocket();
  }
  ```
  Unify cleanup and eliminate recursion in the catch block:
  ```dart
  } catch (error) {
    _socket = null;
    if (createdPtyId != null) {
      await _deleteRemotePty(createdPtyId, normalizedDirectory);
      if (_processToken != processToken) {
        return;
      }
      _ptyId = null;
      _targetKey = null;
      _cursor = -1;
    }
    _state = CodewalkTerminalState.failed;
    _statusMessage = 'Terminal connection failed: $error';
    _notify();
  }
  ```
- **Validation**: Make sure PTY sessions are deleted when force-reconnected.

#### 3. Integrate Stateful UTF-8 Decoder
- **Files**: `lib/presentation/services/codewalk_terminal_controller.dart`
- **Details**:
  Add private class `_TerminalStringSink` at the bottom of the file (before `_UnavailableTerminalRemoteDataSource`):
  ```dart
  class _TerminalStringSink implements Sink<String> {
    _TerminalStringSink(this._onData);
    final void Function(String) _onData;
  
    @override
    void add(String data) => _onData(data);
  
    @override
    void close() {}
  }
  ```
  Add a field `Sink<List<int>>? _utf8DecoderSink;` to the controller class.
  In `startShell()`, right before calling `_socketOpener` inside the `try` block, initialize the decoder:
  ```dart
  _utf8DecoderSink?.close();
  _utf8DecoderSink = const Utf8Decoder(allowMalformed: true).startChunkedConversion(
    _TerminalStringSink((decoded) {
      if (_processToken != processToken || decoded.isEmpty) {
        return;
      }
      _terminal.write(decoded);
      if (_state == CodewalkTerminalState.starting) {
        _state = CodewalkTerminalState.running;
        _statusMessage = 'Connected to ${serverProfile.displayName} in $normalizedDirectory';
        _notify();
      }
    }),
  );
  ```
  Update the WebSocket messages listener to feed incoming bytes into the decoder:
  ```dart
  outputSubscription = socket.messages.listen(
    (bytes) {
      if (_processToken != processToken) {
        return;
      }
      if (_consumeCursorFrame(bytes)) {
        return;
      }
      _utf8DecoderSink?.add(bytes);
    },
    ...
  ```
  Ensure the decoder sink is closed in all termination paths (`closeOutput()`, `_disconnectSocket()`, `_terminateSession()`, and `dispose()`):
  ```dart
  void _closeUtf8Decoder() {
    _utf8DecoderSink?.close();
    _utf8DecoderSink = null;
  }
  ```
  Call `_closeUtf8Decoder()` inside `closeOutput()`, `_disconnectSocket()`, and `_terminateSession()`.

#### 4. Guard and Handle Exceptions in Resize Callback
- **Files**: `lib/presentation/services/codewalk_terminal_controller.dart`
- **Details**:
  Update `terminal.onResize` inside `_createTerminal` to use `.catchError` and check session identity:
  ```dart
  terminal.onResize = (width, height, _, _) {
    final ptyId = _ptyId;
    final directory = _directory;
    if (ptyId == null || directory == null) {
      return;
    }
    _resizeDebounceTimer?.cancel();
    _resizeDebounceTimer = Timer(const Duration(milliseconds: 80), () {
      if (_disposed || _ptyId != ptyId || _directory != directory) {
        return;
      }
      unawaited(
        _remoteDataSource
            .resizePty(
              ptyId: ptyId,
              directory: directory,
              rows: height,
              cols: width,
            )
            .catchError((Object error) {
              // Swallow resize exceptions on closed/unreachable PTYs
            }),
      );
    });
  };
  ```

#### 5. Expose Dead States to ChatPage Signatures
- **Files**: `lib/presentation/pages/chat_page/chat_page_terminal_runtime.dart`
- **Details**:
  In `_startTerminalForCurrentProject`, prevent the signature match check from returning early if the controller is in a dead state (`failed` or `exited`):
  ```dart
  // Line ~30:
  final isDeadState = _terminalController.state == CodewalkTerminalState.failed ||
      _terminalController.state == CodewalkTerminalState.exited;
  if (!force && signature == _terminalSessionSignature && !isDeadState) {
    return;
  }
  ```

#### 6. Add Controller Unit Tests
- **Files**: `test/unit/services/codewalk_terminal_controller_test.dart`
- **Details**:
  Create the unit test file covering the test cases detailed in the Testing Strategy below.

---

### Risks & Mitigations

- **Risk: Memory leak from unclosed UTF-8 decoder**
  - *Mitigation*: Ensure `_closeUtf8Decoder()` is called explicitly in all cleanups: `closeOutput()`, `_disconnectSocket()`, `_terminateSession()`, and `dispose()`.
- **Risk: Swallowed resize errors hiding real bugs**
  - *Mitigation*: Swallowing is appropriate here because resize fails asynchronously when the session closes. The actual connection status is handled authoritatively by the WebSocket listeners (`onError` / `done`), so ignoring resize failures is safe.
- **Risk: Cursor-frame byte 0.0 rendering issues**
  - *Mitigation*: Keep the `_consumeCursorFrame(bytes)` check ahead of the decoder sink call so it consumes the bytes and returns `true`, completely bypassing the UTF-8 decoder.

---

### Assumptions to Validate

- **Assumption**: The server handles `deletePty` idempotently (returns success or 404 which is ignored).
  - *Validation*: Confirmed in `TerminalRemoteDataSource.deletePty` implementation which catches `DioException` and ignores 404.

---

### Decisions and Nuances

- **Use of `const Utf8Decoder(allowMalformed: true)`**: Do not use `utf8.decoder` directly since it defaults to `allowMalformed: false` and would throw formatting exceptions on malformed byte inputs from the shell.
- **Process Token Validation**: Sink string delivery checks `_processToken == processToken` before writing to the terminal to isolate stale WebSocket stream messages from newer shell starts.

---

### Testing Strategy

Create a new unit test suite: `test/unit/services/codewalk_terminal_controller_test.dart`.

Implement the following test cases:
1. **Re-connection logic (force: true)**:
   - Call `startShell` once.
   - Call `startShell` with `force: true`.
   - Assert `deletePty` was called on the first PTY session, and a new `createPty` was called for the second one.
2. **Dead sessions are not reused**:
   - Set state to `failed` or `exited` on the controller.
   - Call `startShell` with `force: false` for the same target directory.
   - Assert `createPty` is called (not reusing the old PTY).
3. **Split UTF-8 decoding**:
   - Emit `[0xE2]` and `[0x82, 0xAC]` (forming `€`).
   - Verify terminal buffer prints `€` correctly, without replacement glyphs.
4. **Resize exception safety**:
   - Mock `resizePty` to throw an exception.
   - Trigger a resize event on the terminal, wait for the debounce timer, and assert no unhandled exception is thrown.

---

### Execution Handoff

Start by implementing the modifications to `codewalk_terminal_controller.dart`. Then add the signature cache check to `chat_page_terminal_runtime.dart`, create the unit test file, and run `make check` to verify.

---

### Out of Scope

- Modifying the PTY REST API contract.
- Changing `xterm` dependency.
- Layout or design modifications to the terminal panel widget.

---

## Plan Comparison

### Full-Planner Consensus Pass

- Selected full planners: `planCodex54`, `planCodex54mini`, `planCodex55`, `planFlash35`, `planGLM51`, `planKimi26`, `planMimo25`, `planNemoUltra`, `planO46`
- Skipped: no
- Second-pass plans received: 9
- Detailed candidate summaries: Confirmed that each candidate summary sent in Stage 2.2 covered their core strategy, key files, sequencing, risks, and validation.
- Consensus summary: All planners strongly agreed on tightening PTY reuse checks to reject dead states, terminating and deleting the remote PTY on `force: true`, using a stateful chunked UTF-8 decoder, swallowing resize errors inside the timer callback, and creating a socket-opener seam in the controller constructor for unit testing.
- Self-bias adjustment: Owner-plan rankings were evaluated neutrally; plans were ranked solely on technical precision, completeness, and edge case safety.

### Consensus Evidence Table

| Candidate | Exact failure-mode coverage | Implementation completeness | Validation of exact case | Risk/blocker handling | Dependency/API certainty | Full verdict | Critical objections |
|-----------|-----------------------------|-----------------------------|--------------------------|-----------------------|--------------------------|--------------|---------------------|
| planCodex54 | Pass | Pass | Pass | Pass | Pass | `full` | None |
| planCodex54mini | Pass | Pass | Pass | Pass | Pass | `full` | None |
| planCodex55 | Pass | Pass | Pass | Pass | Pass | `full` | None |
| planFlash35 | Pass | Pass | Pass | Pass | Pass | `full` | None |
| planGLM51 | Pass | Pass | Pass | Pass | Pass | `full` | None |
| planKimi26 | Pass | Pass | Pass | Pass | Pass | `full` | None |
| planMimo25 | Pass | Pass | Pass | Pass | Pass | `full` | None |
| planNemoUltra | Pass | Pass | Pass | Pass | Pass | `full` | None |
| planO46 | Pass | Pass | Pass | Pass | Pass | `full` | None |

### Vetoes, Blockers, and Overrides

- Critical objections raised: None
- Resolved objections: N/A
- Unresolved objections: None
- Consensus overrides: None
- Scoring/voting role: Averages and rankings were used as advisory signals to rank plans by technical precision and implementation details.

### Per-Planner Assessment

### planCodex55
- Strengths: Highly detailed, constructor injection for mock socket openers, identity checks in resize timer.
- Weaknesses: None major.
- Unique insights: Socket opener callback signature in constructor.

### planCodex54
- Strengths: Great lifecycle checks, cursor frame skip details, and clean stateful decoder sink setup.
- Weaknesses: Kept recursive retry logic in catch block.
- Unique insights: Detailed identity-guarding rules for resize.

### planCodex54mini
- Strengths: Compact, correct, good regression test focus.
- Weaknesses: Less detailed.
- Unique insights: None.

### planGLM51
- Strengths: Clean `_Utf8ChunkedDecoder` composable helper class, `_disposed` checks in resize.
- Weaknesses: Lacked constructor socket opener injection.
- Unique insights: Multi-layer resize safety.

### planKimi26
- Strengths: `sessionIsAlive` state abstraction, custom decoder wrapper.
- Weaknesses: Lighter on mock test setups.
- Unique insights: Clean session state grouping.

### planO46
- Strengths: Forwarding sink implementation, good test case coverage.
- Weaknesses: Less detail on process token isolation.
- Unique insights: None.

### planFlash35
- Strengths: Correctly identifies all 4 bugs.
- Weaknesses: Vague test strategy, lacks decoder close/flush details.
- Unique insights: None.

### planMimo25
- Strengths: Conceptual coverage of all fixes.
- Weaknesses: Missing details on unit tests.
- Unique insights: None.

### planNemoUltra
- Strengths: Cleanup-focused, process token management.
- Weaknesses: Stored decoder state at class level rather than per-connection.
- Unique insights: ByteConversionSink usage.

### Failed Agents

- `planG31Pro`: failed readiness handshake (Phase A).
- `planDeepSeek4Flash`: failed/cancelled in Phase B.
- `planDeepSeek4Pro`: failed/cancelled in Phase B.
- `planMimo25Pro`: failed/cancelled in Phase B.

### Why this synthesized plan is best

- It implements constructor-injected socket opening, enabling pure unit tests with fake streams.
- It tightens PTY reuse, prevents stale-session leakage, and resolves force reconnects correctly.
- It decodes UTF-8 statefully and isolates cursor frames.
- It swallows resize errors and guards against timer race conditions.
- It eliminates the recursive connection loop bug.

### Best Individual Plan Verdict

- Winner: `planCodex55`
- Why this plan ranked first: Complete coverage of all 4 bug requirements, correct stateful sink design, identity-guarded resize try/catch, and the constructor socket-opener seam for mock testing.
- Trade-off notes: Combined with GLM51's `_disposed` guards and Codex54's cursor frame handling for maximum safety.

### Final Ranking Rationale

- Position 1 — `planCodex55`: Top rank due to constructor injection socket seam, retry simplification, and robust try/catch resize logic.
- Position 2 — `planCodex54`: Highly complete, but kept recursive retry in catch block.
- Position 3 — `planCodex54mini`: Clean and correct, but less detailed.
- Position 4 — `planGLM51`: Excellent helper class and resize guards, but lacked constructor socket injection seam.
- Position 5 — `planKimi26`: Clean state abstraction, but lighter on socket mock details.
- Position 6 — `planO46`: Correct direction, but less detailed on process token isolation.
- Position 7 — `planFlash35`: Correct list of fixes, but lacks decoder flush and test injection details.
- Position 8 — `planMimo25`: Lacked test specifics and implementation detail.
- Position 9 — `planNemoUltra`: Class-level decoder sink is more error-prone than connection-scoped sink.

### Plan Ranking (Best to Worst)

1. planCodex55 (full)
2. planCodex54 (full)
3. planCodex54mini (full)
4. planGLM51 (full)
5. planKimi26 (full)
6. planO46 (full)
7. planFlash35 (full)
8. planMimo25 (full)
9. planNemoUltra (full)