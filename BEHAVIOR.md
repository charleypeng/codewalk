# Behavior Specification

> How CodeWalk behaves from the user's perspective.
> Only documents **current, implemented** behavior. Planned features live in ROADMAP.md.

---

## Onboarding

### First launch shows setup wizard

- **Given** the app is opened for the first time (no servers configured)
- **When** the app starts
- **Then** a setup wizard is displayed requiring the user to configure at least one OpenCode server

### No server = no functionality

- **Given** no server is configured
- **When** the user tries to access any feature
- **Then** the app blocks access — configuring a server is a prerequisite for all functionality

### No-server chat state is stable and actionable

- **Given** no server is configured and the chat screen is visible (for example, onboarding was skipped/dismissed)
- **When** the screen initializes
- **Then** startup connection checks are skipped (no transient connection-error flicker)
- **Then** the main area shows a dedicated empty state with `No server configured yet`
- **Then** a `Set up server` button opens the setup wizard directly in the server-connection flow

---

## Servers

### Multiple server profiles

- **Given** the user is in server settings
- **When** the user adds a new server profile (local, remote, work, etc.)
- **Then** the profile is saved and the user can switch between profiles at any time

### Automatic health checks

- **Given** server profiles are configured
- **When** the app is active
- **Then** the app checks each server's health every 10 seconds and shows a visual online/offline indicator
- **Then** health checks are independent of session data sync — messages and events arrive via real-time SSE, not polling

### Server goes offline during use

- **Given** the active server goes offline while the user is chatting
- **When** the connection is lost
- **Then** the composer input is blocked and the reason is displayed to the user
- **Then** the user cannot send messages until the connection is restored

> **Current state**: the offline error is too aggressive (full-screen error with "Retry"). The desired behavior is a subtle composer block with a clear reason message.

---

## Sessions

### Session lifecycle

- **Given** a connected server
- **When** the user interacts with sessions
- **Then** the user can **create**, **rename**, **archive**, **fork**, and **delete** sessions

### New Chat opens as draft immediately

- **Given** a connected server and the chat screen is open
- **When** the user taps `New Chat` (or uses the equivalent shortcut/command)
- **Then** the composer opens immediately in a draft state without waiting for remote session creation
- **Then** the session is created lazily on the first send action

### New Chat draft is not replaced by background refreshes

- **Given** the user is in `New Chat` draft mode (no active session selected yet)
- **When** session snapshots, SWR revalidation, or realtime events from other sessions arrive
- **Then** draft mode remains active and the app does not auto-switch back to another session
- **Then** draft mode remains visible until the user sends the first message or explicitly selects another session

### New Chat draft skips the select-or-create empty state

- **Given** `New Chat` draft mode is active
- **When** the chat timeline is rendered
- **Then** the app does not show `Select or create a conversation to start chatting`
- **Then** the draft-ready chat view remains visible so the user can start typing/sending immediately

### Fork creates an independent copy

- **Given** an existing session with conversation history
- **When** the user forks the session
- **Then** a new independent session is created as a full copy of the session at the moment of the fork action — changes to either session do not affect the other

### Sessions are scoped to a project

- **Given** the user has multiple projects/folders
- **When** the user switches to a different project
- **Then** the visible session list changes to show only sessions belonging to that project

### Project context picker is folder-first

- **Given** the user opens the project context picker (`Choose Directory`)
- **When** the user interacts with context options
- **Then** the UI uses project/folder language only (no workspace distinction in this flow)
- **Then** the action `Open project folder...` allows opening any folder as project context, including non-Git folders
- **Then** tapping a project row switches/reopens that context immediately and closes the picker without requiring a secondary open action
- **Then** selector actions are serialized so repeated rapid taps do not trigger overlapping switch/reopen/close/archive operations

### Conversations are grouped by project context

- **Given** the user has conversations from multiple project directories
- **When** the Conversations sidebar is rendered
- **Then** the sidebar shows a dedicated `Projects` card above the conversations list with one row per open project
- **Then** each project row shows a conversation count derived from that project's visible sessions (active scope or cached snapshot)
- **Then** tapping a project row switches context directly from the sidebar (no modal required)
- **Then** when snapshot data exists, the sidebar shows compact session previews for that project; when not available, it shows a "Open project to load conversations" hint

### Auto-generated session titles

- **Given** a new session with no custom title
- **When** each new message is added to the conversation
- **Then** the app automatically generates (or re-generates) a title based on the conversation content
- **Then** title generation stops once the session has accumulated 3 or more user messages **and** 3 or more assistant messages — sufficient context has been established by that point
- **Then** dynamic title generation runs only for main/root sessions; subsessions (child sessions with `parentId`) do not trigger auto-title updates

### Session reopening is cache-first

- **Given** the user already opened a session recently in the same server+project scope
- **When** the user switches back to that session
- **Then** cached messages are rendered immediately without waiting for a full network reload
- **Then** the app revalidates the session in background (SWR) and merges newer server state when available

### Project switching is cache-first and non-blocking

- **Given** the user switches project/directory context and that context has cached sessions
- **When** the switch is triggered from the project context picker (open/reopen/close/switch)
- **Then** the new context renders immediately from cached scope data without waiting for network revalidation
- **Then** session list revalidation runs in background and refreshes to server state when the response arrives
- **Then** if background revalidation fails, the cached visible state remains stable (no forced blank/loading fallback)
- **Then** when returning to a recently visited project that was marked dirty by global events, the previously cached session list remains visible immediately and is revalidated in background
- **Then** project-switch transition teardown uses bounded cancellation time, so the `Loading project context...` blocker is brief and does not wait for long stream cancellation timeouts

### Active session SWR prefers delta-like refresh

- **Given** the active session already has cached messages visible
- **When** background revalidation runs after project/session switch
- **Then** the client first fetches a limited recent tail window (delta-like refresh) instead of full history
- **Then** if the fetched tail has no safe overlap with local cache, the client automatically falls back to a full fetch to guarantee correctness

### New Chat draft state is isolated per project context

- **Given** the user starts `New Chat` draft mode in project A (no active session yet)
- **When** the user switches to project B
- **Then** project B must not inherit draft mode from project A
- **Then** project B restores its own cached/current session state via project-switch SWR
- **Then** when the user returns to project A, draft mode is restored only for project A

### Long-session revalidation avoids forced viewport jumps

- **Given** a cached session is visible and background revalidation finishes
- **When** newer server messages are applied
- **Then** the timeline updates in place without clearing to an empty skeleton first
- **Then** collapsed history groups keep their per-session expansion state during switch and revalidation
- **Then** assistant work/tool-call groups return collapsed after session return or revalidation (manual expansion is not restored)
- **Then** an already-selected empty session keeps its empty placeholder visible during background refresh (no loading skeleton blink)

### Older history loads on demand at top reach

- **Given** a conversation has older messages not yet loaded in the current viewport
- **When** the user scrolls to the top threshold of the chat timeline
- **Then** the app loads older message batches incrementally
- **Then** the viewport anchor is restored after prepend so reading position stays stable (no sudden jump)

---

## Chat

### Messages are streamed in real time

- **Given** a connected server and an active session
- **When** the user sends a message
- **Then** the message is sent to the OpenCode server and the assistant's response streams back via SSE, rendering in real time as text arrives

### First send from draft bootstraps a session automatically

- **Given** `New Chat` is in draft state (no active session yet)
- **When** the user sends the first message
- **Then** the client creates a new session automatically and sends that message in the same action

### User can cancel a response

- **Given** the assistant is actively streaming a response
- **When** the user taps the cancel/stop button
- **Then** the response generation stops and the partial response remains visible

### Sending while processing enqueues messages

- **Given** the assistant is actively streaming a response
- **When** the user sends one or more new messages
- **Then** each new message is shown in the timeline immediately as queued (with `Queued` state)
- **Then** the app does not interrupt the running response automatically

### Queued messages are batched into one send

- **Given** there are multiple queued messages for the same session
- **When** the queue is dispatched (either on first idle opportunity or via `Send now`)
- **Then** all queued message texts are merged and sent as a single payload
- **Then** each original queued message becomes one line in that payload (simple `\n` line breaks between messages)
- **Then** the individual queued messages are removed from the timeline and replaced by the single consolidated message

### Send now forces immediate queued dispatch

- **Given** there are queued messages while the assistant is still processing
- **When** the user taps `Send now`
- **Then** the app performs the same stop behavior as `Stop` for the active response
- **Then** as soon as the session becomes ready, the app sends the full queued batch as one payload

### Failed send returns message to composer

- **Given** the user sends a message
- **When** the send fails (network error, server error, etc.)
- **Then** the message text is returned to the composer input — the user's text is never lost

### Optimistic user message ID uses local prefix — never server format

- **Given** the user sends a message in an active session
- **When** the client appends the optimistic user bubble and dispatches `prompt_async`
- **Then** the client assigns the optimistic message a `local_user_<timestamp>_<seq>` ID — it intentionally does NOT use a server-format ID (`msg_*` or similar)
- **Then** the `messageId` field is NOT forwarded in the `prompt_async` send payload — the server assigns its own canonical ID
- **Then** duplicate detection for the server echo uses a content-signature match (normalized text), gated by the `local_user_` prefix check
- **Then** once the server echo arrives, the local optimistic bubble is dropped and replaced by the server-authoritative message

> **INVARIANT — do not violate**: The `local_user_*` prefix and the absence of `messageId` in the send payload are load-bearing contracts.
> Changing the prefix to any server-format value (e.g. `msg_*`) or forwarding `messageId` in the payload causes the SSE event stream to fail reconciliation for all turns after the first — assistant responses are received and audio/notifications fire, but the UI update is silently discarded and the UI stays stuck on the previous state.
> This regression was introduced and reverted in commit `b0660a2`. See ADR-023 "Known Pitfalls" for the full incident analysis.

### Tool call work groups collapse after completion

- **Given** the assistant executes tool calls during a response (file reads, commands, etc.)
- **When** the assistant finishes the complete response
- **Then** tool-call chains and tool-detail sections start collapsed by default
- **Then** collapse never happens while the assistant is still streaming
- **Then** manual expansion is temporary and is not restored after return/revalidation
- **Then** the user can manually re-expand any collapsed work group by tapping its Details toggle
- **Then** once a completed turn has settled, transient realtime status pulses do not auto re-open or rapidly re-collapse that same work group

### Compact mobile collapsed copy is concise

- **Given** the app is rendered on a compact viewport (mobile width)
- **When** reasoning and tool-call boxes are collapsed
- **Then** headers/toggles use short labels (`Thinking`, `Show`, `Hide`, `More`, `Less`) to reduce visual noise
- **Then** collapsed tool-call groups use count-first summaries (for example, `2 calls`) and hide secondary helper subtext in the collapsed state
- **Then** expanded content and desktop wording remain unchanged

### UI remains fluid during streaming

- **Given** the assistant is streaming a long response
- **When** text, code blocks, or tool calls render incrementally
- **Then** the UI remains smooth without stuttering, freezing, or perceptible lag

### Tool-only busy turns keep live follow behavior

- **Given** the active session is still busy/retrying during a multi-step tool turn
- **When** the latest assistant chunk is completed but the turn still emits tool/patch updates
- **Then** the chat keeps active follow/reveal behavior for that same turn
- **Then** idle/background status snapshots without live tool/patch updates do not trigger autonomous jumps

### Final response is revealed from the beginning

- **Given** a response finishes after tool/work messages
- **When** the final assistant message becomes available
- **Then** the chat reveals the **start** of the final assistant message (not the end)
- **Then** the reveal is anchored at the top of the viewport so reading starts from the first line

### Final response reconcile is resilient to transient abort suppression

- **Given** the assistant turn ends and `session.idle` arrives while a short abort-suppression window is still active
- **When** the latest assistant message still has only tool/work surface content (no final visible text yet)
- **Then** the app still runs a targeted final-message reconcile for the active session
- **Then** the final assistant response becomes visible without requiring the user to switch sessions and return

### Final response reconcile triggers latest-message reveal

- **Given** a tool/work-heavy turn finishes and the final assistant text is applied by active-session revalidation
- **When** the latest session message changes during reconcile
- **Then** the timeline schedules a latest-message reveal/scroll update for that active session
- **Then** the user sees the final response immediately without needing a manual session switch

### Async send completion ignores stale assistant IDs

- **Given** async send fallback needs to resolve the assistant message ID from session history
- **When** older assistant messages already exist in that history
- **Then** the client excludes pre-send known assistant IDs and prioritizes in-progress/fresh IDs from the current turn
- **Then** if baseline prefetch fails, a timestamp guard is kept as fallback to avoid stale completion selection
- **Then** when `session.idle` appears before any `busy` signal right after send, completion waits for a short guard window before accepting idle-only candidates
- **Then** if idle reconciliation still has no fresh assistant candidate, the client keeps waiting and escalates to direct message polling before concluding the turn, avoiding false "completed" states without assistant output
- **Then** when a stale `session.idle` from a previous turn arrives while the current send stream is still active, the app suppresses turn-complete feedback/reconcile for that stale idle and keeps the current turn in-flight
- **Then** once that active send stream finishes, any deferred stale-idle reconcile is executed exactly once to fetch and reveal the final assistant message without requiring a session switch

### Async send completion keeps data usage bounded

- **Given** async send reconciliation needs periodic `GET /session/{id}/message` lookups
- **When** the client fetches message history during fallback/idle completion resolution
- **Then** requests use a bounded tail limit (`limit=120`) instead of full-history list fetches to reduce transfer volume on mobile networks
- **Then** known assistant IDs are cached per session with a bounded LRU-like cap (64 sessions) to avoid repeated baseline fetches and unbounded memory growth
- **Then** if completion ends without a resolvable assistant message (`no_message_id` or `no_message`), the session cache entry is invalidated to avoid carrying stale baseline state into the next send

### Post-completion reading remains stable

- **Given** the final assistant response is already visible
- **When** the user is reading without sending new input
- **Then** the chat does not perform autonomous jump/scroll corrections
- **Then** auto-follow resumes only after explicit user intent (e.g., sending a new message or tapping `Go to latest`)

---

## Composer

### Microphone button visual behavior

- **Given** the composer input is visible
- **When** voice input is idle (not listening)
- **Then** the microphone button uses a transparent background, preserving the composer bubble look
- **When** voice input is active (or starting)
- **Then** the microphone button background turns red to indicate active capture
- **Then** the button is visually aligned with the right edge curvature of the composer input

### Message history navigation

- **Given** the user has sent previous messages in the session
- **When** the user presses the up arrow key while the cursor is at the beginning of the input (or down arrow at the end)
- **Then** the composer cycles through previously sent messages
- **Then** if the cursor is not already at the boundary, the first key press moves it there; the second press begins cycling

### File and agent mentions with @

- **Given** the user is typing in the composer
- **When** the user types `@`
- **Then** a mention picker appears with two types of suggestions: project files and available agents
- **Then** file results are fetched live from the server's project file search API (up to 12 results per query)
- **Then** agent results come from the locally cached agent list provided by the server

### Slash commands with /

- **Given** the user is typing in the composer
- **When** the user types `/`
- **Then** a command picker appears with available slash commands

The following commands are always available (builtin):

| Command | Action |
|---------|--------|
| `/new` | Start a new conversation |
| `/model` | Open the model selector |
| `/agent` | Open the agent selector |
| `/open` | Quick-open a project file |
| `/help` | Show available commands |
| `/compact` | Compact (summarize) the current session context |

Additional commands may be provided by the connected OpenCode server and merged into the picker alongside the builtins.

---

## Attachments

### Image and PDF attachments

- **Given** the user is composing a message
- **When** the user attaches an image or PDF
- **Then** the file is attached to the message and sent along with the text

### Model capability gating

- **Given** the selected model does not support vision
- **When** the user tries to attach an image
- **Then** the attachment option is disabled or shows clear feedback that the model cannot process images

---

## Voice Input

### Speech-to-text in the composer

- **Given** the user activates voice input
- **When** the user speaks
- **Then** the speech is converted to text and inserted into the composer input

### Cross-platform support

- **Given** any supported platform (Android, Linux, macOS, Windows, Web)
- **When** the user activates voice input
- **Then** the STT feature works on all platforms where the device has a microphone

The app uses a dual-engine strategy with automatic fallback:

| Platform | Primary engine | Notes |
|----------|---------------|-------|
| Android | Native (system speech recognizer) | Sherpa excluded from Android build; Native only |
| Linux | Sherpa ONNX | On-device models downloaded from HuggingFace; Native not supported on Linux |
| macOS / iOS | Native (system speech recognizer) | Falls back to Sherpa ONNX if native unavailable |
| Windows / Web | Native (system speech recognizer) | Falls back to Sherpa ONNX if native unavailable |

---

## Interactive Prompts

### Permission requests

- **Given** the server needs user approval to perform an action (e.g., execute a command, write a file)
- **When** the server sends a permission request
- **Then** an interactive card appears in the chat with three response options:
  - **Allow Once** — approves the action for this single occurrence
  - **Always** — approves the action permanently for this session
  - **Reject** — denies the action
- **Then** the server waits for the user's response before proceeding
- **When** the user allows (once or always), the server continues the operation
- **When** the user rejects, the server receives a rejection and the session pauses — the assistant stops and waits for the user to send a new message before continuing

### Question prompts

- **Given** the server needs the user to choose between options
- **When** the server sends a question prompt
- **Then** an interactive card appears with the question and selectable options
- **Then** the server waits for the user's response before proceeding

---

## File Explorer

### Read-only project tree

- **Given** the user opens the file explorer panel
- **When** the project tree loads
- **Then** the user sees the file/folder structure of the current project in read-only mode (no create, edit, or delete)

### File preview

- **Given** the file explorer is open
- **When** the user taps a file
- **Then** a preview/visualization of the file content is shown

---

## Task List

### Agent-controlled task list

- **Given** the AI agent is executing a multi-step task
- **When** the agent reports its task progress
- **Then** a task list is displayed in the session showing the agent's current and completed steps
- **Then** the task list is read-only for the user — it is controlled entirely by the server/agent

### Header progress indicator for tasks

- **Given** the current session has a visible task list
- **When** the task list is rendered in either collapsed or expanded mode
- **Then** a single thin, full-width progress bar appears directly below the task header (same position in both states)
- **Then** the progress value represents completed tasks divided by total tasks
- **Then** progress changes animate smoothly with an ease-in-out transition between values

### Compact mobile collapsed task summaries are count-first

- **Given** the session task panel is collapsed on a compact viewport (mobile width)
- **When** at least one task is in progress
- **Then** the header summary uses compact count-first text (`x/y in progress`) without including task content text
- **When** no task is in progress
- **Then** the header summary uses compact completion text (`x/y done`)

---

## Layout

### Mobile: chat-first with drawer

- **Given** the app is running on a mobile device (compact screen)
- **When** the user navigates the app
- **Then** the chat occupies the full screen, with the session list accessible via a lateral drawer

### Mobile drawer status indicator (hamburger)

The hamburger icon has exactly three states — only one can be active at a time:

- **Default (no badge)**: normal operation; no urgent or loading condition is active
- **Loading spinner**: shown only when all three conditions are true simultaneously:
  1. The app returned from background and is actively resynchronizing (`isForegroundResumeSyncing`)
  2. The sync state is recoverable (reconnecting, delayed, or degraded — not failed)
  3. The Android foreground service is NOT running
- **Red dot badge**: shown when an urgent condition persists beyond the grace period:
  - Active server health probe is `unhealthy` (including offline probe failures), OR
  - Recoverable sync alert has escalated (unresolved for too long)

Transient connectivity blips that do not escalate are surfaced via loading/sync states, not as urgent red health alerts.

Non-urgent (blue/gray) dot badges are never shown on the hamburger icon.

### Desktop: split view

- **Given** the app is running on a desktop (expanded screen)
- **When** the user navigates the app
- **Then** the session list is always visible alongside the chat in a split-view layout

### Desktop: system tray

- **Given** the app is running on Linux, macOS, or Windows
- **When** the app is open (foreground or background)
- **Then** a tray icon is shown in the system notification area
- **Then** the tray menu provides two actions: **Show** (bring the window to front) and **Quit** (force-quit the app, bypassing close-to-tray)

### Keyboard shortcuts

- **Given** a physical keyboard is connected (desktop or mobile with external keyboard)
- **When** the user presses a keyboard shortcut
- **Then** the corresponding action is executed (shortcuts work on desktop and on mobile with an external keyboard)

All shortcuts use `mod` (Cmd on macOS, Ctrl on other platforms) and are user-configurable in Settings:

| Shortcut | Action | Notes |
|----------|--------|-------|
| `mod+n` | New conversation | |
| `mod+r` | Refresh data | |
| `mod+l` | Focus composer input | |
| `mod+p` | Quick-open project file | |
| `mod+,` | Open Settings | |
| `mod+m` | Cycle recent/favorite models | |
| `mod+t` | Cycle model variants | |
| `mod+j` | Next agent | |
| `mod+shift+j` | Previous agent | |
| `Escape` | Close drawer / focus input | Double-press stops active response |
| `mod+q` | Quit app | Desktop only; bypasses close-to-tray |

### Mobile keyboard collapses the task panel

- **Given** the task list panel is expanded on mobile
- **When** the on-screen keyboard appears
- **Then** the task list panel automatically collapses to free space for the chat and composer
- **Then** when the keyboard is dismissed, the panel returns to its previous state (expanded or collapsed)

---

## Provider and Model Selection

### Selecting a provider and model

- **Given** the connected OpenCode server has providers configured (e.g., Claude, OpenAI, Gemini)
- **When** the user opens the model selector
- **Then** all available providers and their models are listed, sourced directly from the server
- **Then** the user can select any model to use for the current session

### Model variants and reasoning effort

- **Given** the selected model supports variants (e.g., reasoning effort levels)
- **When** the user opens the variant selector
- **Then** the available variants are listed and one can be selected for the session

### Favorite models

- **Given** the user stars a model in the model selector
- **When** the model selector is opened again
- **Then** starred models appear in a **Favorites** section above recent models
- **Then** favorites are persisted locally, scoped per server and project (not shared across servers)

### Recent model cycling

- **Given** the user has previously selected models in the session
- **When** the user presses `mod+m`
- **Then** the app cycles through favorite models first, then recent models, applying the selection immediately

### Alt+Tab-style shortcut cycling (model, agent, variant)

- **Given** the user is using keyboard cycling shortcuts (`mod+m`, `mod+j`, `mod+shift+j`, `mod+t`)
- **When** the user triggers one of these shortcuts
- **Then** the first trigger behaves like Alt+Tab and switches to the previously used item in that domain (model, agent, or variant)
- **Then** if the user triggers again within 3 seconds, cycling continues through a burst snapshot in recency order
- **Then** the snapshot prioritizes the two most recent items first, but is **not limited to two** — third and later candidates are reachable with repeated quick presses
- **Then** if the user waits more than 3 seconds between triggers, the burst session resets and the next trigger starts again from the previous-item hop
- **Then** shortcut keybindings themselves do not change; only cycling behavior changes

### Agent selection

- **Given** the connected server provides agents (specialized AI configurations)
- **When** the user opens the agent selector or types `/agent`
- **Then** all available agents are listed and one can be selected
- **When** the user presses `mod+j` / `mod+shift+j`
- **Then** the app cycles forward/backward through the available agents

---

## Settings

### Theme selection

- **Given** the user is in settings
- **When** the user selects a theme
- **Then** the app supports light, dark, and AMOLED themes, plus Material You dynamic color from the system wallpaper

### Local persistence

- **Given** the user changes any setting
- **When** the setting is saved
- **Then** it persists locally (survives app restart) via SharedPreferences / SecureStorage

---

## Notifications

> The OpenCode server does not support traditional push notifications. The app uses platform-native techniques to deliver background alerts reliably while minimizing battery impact.

### Background alerts (Android)

- **Given** the app is running on Android and goes to background
- **When** the assistant finishes a response, a permission request arrives, or a question prompt arrives
- **Then** the app delivers a local notification via a combination of:
  - A persistent foreground notification (always visible while the app process is alive)
  - A WorkManager background worker that polls for active session state at regular intervals
  - A short-lived one-off probe scheduled when the app moves to background
- **Then** notifications are intended to fire only while the app is in the background; while in foreground, the user receives real-time updates directly in the chat UI

### Background alerts (Desktop)

- **Given** the app is running on Linux, macOS, or Windows
- **When** background alerts would be relevant
- **Then** the system tray icon serves as the always-present indicator; local notifications may be shown through the OS notification system

### Server offline does NOT notify

- **Given** the active server goes offline
- **When** the app detects the disconnection
- **Then** no notification is sent — server availability is not the app's responsibility. The user sees the status when they open the app.

### Android persistent notification

- **Given** the app is running on Android
- **When** the app is active or in background
- **Then** a persistent notification is shown in the notification drawer, keeping the app process alive and enabling reliable alert delivery

---

## Background and Lifecycle

### Android foreground service

- **Given** the app is running on Android during a long operation
- **When** the app goes to background
- **Then** a foreground service keeps the app alive so the operation is not killed by the system

### Battery optimization prompt

- **Given** the app is running on Android
- **When** battery optimization may interfere with background operation
- **Then** the app prompts the user to disable battery optimization

### Automatic reconnection on resume

- **Given** the app was in background
- **When** the user returns to the app
- **Then** the app automatically reconnects to the server and resynchronizes state (missed messages, updated sessions, etc.)

### No duplicate refresh on resume

- **Given** the app resumes from background
- **When** both lifecycle and reconnect triggers fire
- **Then** only one refresh cycle executes — no duplicate network calls

---

## Anti-behaviors

> Things that must **never** happen, regardless of circumstances.

### Never lose user messages

The app must never silently discard a user's message. If sending fails, the message text returns to the composer input.

### Never freeze the UI

All operations (streaming, sync, network) are asynchronous. The UI must never become unresponsive, even during heavy operations.

### Never expose tokens or credentials

Server tokens, API keys, and credentials must never appear in logs, error screens, exports, or any user-visible surface.

### Never auto-approve permissions

Permission requests from the server always require explicit user action (approve or deny). The app must never approve automatically.

### Never show false aborts

When a connection drops and reconnects (especially on mobile background/resume), the app must not display false "message aborted" errors from stale SSE events.

### Never corrupt state on rapid actions

If the user taps rapidly (double-tap on sessions, fast project switching), the app processes one transition at a time. Concurrent transitions must never corrupt state or cause navigation errors.

### Never block project context switches on remote refresh

Switching project/directory context must complete from local scope snapshots when available. Server revalidation may run after the transition, but it must not keep the UI stuck in a transition/loading state.

### Never cancel responses on session switch

If the assistant is streaming a response and the user switches to a different session, the in-flight response must be preserved — not cancelled. The user can return to the original session and see the completed response.

### Never collapse work groups during streaming

Tool call work groups must only collapse after the assistant has fully completed its response **and** the final response is visible. Premature collapse causes visual flicker, aggressive auto-scroll, and hidden active work.

### Never flicker settled work groups on sync jitter

After a tool/work group settles for a completed turn, transient realtime sync/status jitter must not cause rapid open/close loops or repeated remount flashes.

### Never show stale data after resume

When the app returns from background, it must refresh the current session to show the latest state. However, refresh must not re-inject stale abort data that was already handled.

### Never break layout with keyboard

On mobile, the on-screen keyboard must never cause overflow, clipping, or layout breakage. Fixed minimum heights must account for the keyboard-reduced viewport.

### Errors: only show blocking ones

The user should see error feedback only when the error prevents them from continuing (send failed, server unreachable). Non-blocking warnings from the server (partial timeouts, transient issues) should be silent.
