# Behavior Specification

> How CodeWalk behaves from the user's perspective.
> Only documents **current, implemented** behavior. Planned features live in ROADMAP.md.

---

## Internationalization (i18n)

### Language selection

- **Given** the user is in Settings > Behavior
- **When** the user opens the Language selector
- **Then** the app shows `System default` plus all 14 supported languages with native script display names
- **Then** selecting a language applies immediately and persists across app restarts
- **Then** selecting `System default` makes CodeWalk follow the device locale

### Locale fallback

- **Given** the device locale is a regional variant (e.g. `pt_BR`)
- **When** CodeWalk resolves the active locale
- **Then** `pt_BR` falls back to the `pt` (Brazilian Portuguese) locale
- **Then** unsupported locales fall back to English

### Supported locales

- `ar` (Arabic — RTL), `bn` (Bengali), `de` (German), `en` (English), `es` (Spanish), `fr` (French), `hi` (Hindi), `it` (Italian), `ja` (Japanese), `ko` (Korean), `pt` (Brazilian Portuguese), `ru` (Russian), `zh` (Simplified Chinese), `ur` (Urdu — RTL)

### Non-translatable invariants

- OpenCode wire event types, permission key names, tool state values, `prompt_async` contract fields, REST paths, config key names, model/provider/agent identifiers, and server-originated content remain untranslated (ADR-023 compliance)

---

## Onboarding

### First launch shows setup wizard

- **Given** the app is opened for the first time (no servers configured)
- **When** the app starts
- **Then** a setup wizard is displayed requiring the user to configure at least one OpenCode server

### Successful onboarding stays in the wizard through Ready

- **Given** the user finishes server setup successfully during onboarding
- **When** the connection is saved and the wizard advances to the final success state
- **Then** the onboarding flow remains visible through the `Ready` step instead of dismissing immediately when the first server profile is created
- **Then** the user gets an explicit action to continue into the main chat experience

### Successful onboarding can trigger a first-use chat tour

- **Given** the user leaves onboarding from the successful `Ready` step
- **When** the main chat screen opens for that first post-onboarding session
- **Then** the app starts a guided first-use tour that introduces how to open project/sidebar controls, start a new chat, use the chat input, and send a message
- **Then** the tour adapts its first step to the current layout, using drawer/sidebar access on compact screens and the relevant project/sidebar control on larger layouts
- **Then** the app keeps the one-time handoff armed while the chat surface is still mounting, instead of silently consuming the tour just because the targets were late to appear or a transient dismiss interrupted the first run
- **Then** the tour is only marked as seen after the user explicitly skips it or completes the full walkthrough
- **Then** the handoff runs only once for that successful onboarding completion unless a later onboarding success arms it again

### Chat tour can be replayed from the chat screen

- **Given** the user is already on the main chat screen
- **When** the user opens `Display toggles` from the chat app bar and chooses `Replay chat tour`
- **Then** the app restarts the same guided tour from the chat surface without requiring onboarding or data reset

### Chat tour can be replayed from Settings

- **Given** the user opens the main `Settings` screen from chat
- **When** the user taps the landing-page `Replay chat tour` action
- **Then** the app closes settings, re-arms the same replay flow, and returns to chat so the guided tour can start again without onboarding or data reset

### Chat tour can also be replayed from Settings > About

- **Given** the user cannot easily find the replay shortcut from the chat app bar
- **When** the user opens `Settings` > `About` and taps `Replay chat tour`
- **Then** the app closes settings, re-arms the same replay flow, and returns to chat so the guided tour can start again without onboarding or data reset

### First launch explains the OpenCode relationship

- **Given** the first-run setup wizard is visible
- **When** the welcome step is rendered
- **Then** the UI explains that CodeWalk is the client and OpenCode is the server or engine it needs before chat can work
- **Then** the setup paths describe whether the user should connect to an existing server, follow guided setup steps, or let CodeWalk manage a local desktop install

### OpenCode setup troubleshooting is separate from app logs

- **Given** the user is troubleshooting OpenCode installation or setup
- **When** the user opens the dedicated setup debug surface from onboarding or server settings
- **Then** the app shows OpenCode-specific diagnostics, setup events, and captured setup logs
- **Then** this surface remains separate from the general `App Logs` screen used for CodeWalk runtime logs

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
- **Then** by default the app checks each server's health every 10 seconds and shows a visual online/offline indicator
- **Then** when `Cellular data saver` is active on mobile data, automatic foreground health checks slow to one burst every 1 minute and prioritize the active server only

### Cellular data saver indicator

- **Given** `Cellular data saver` is enabled and the current connection is mobile/cellular
- **When** throttling is active
- **Then** the mobile hamburger button shows a low-priority saver badge when no higher-priority alert/loading badge is active
- **Then** the server status control also shows a compact `Saver` chip so the throttled state stays visible after opening the drawer/sidebar
- **Then** when the mobile drawer is opened while that saver badge is active, a compact notice above `Conversations` explains that cellular data saver is active and links to `Settings` > `Behavior`

### Active server status is simplified to Online / Delayed / Offline

- **Given** the active server status control is visible in the chat chrome
- **When** health or sync state changes
- **Then** the control shows `Online` with a green indicator when the active server is healthy and chat sync is not delayed
- **Then** the control shows `Delayed` with an orange indicator when reconnect/degraded/unknown state is still recoverable or resume-time warning grace is active
- **Then** the control shows `Offline` with a red indicator only after the active server is confirmed unhealthy
- **Then** the compact status text is rendered immediately after the server name instead of being pushed to a far-right metadata slot

### Unhealthy server warning waits for confirmation

- **Given** the active server becomes unhealthy or resume-time connectivity is still settling
- **When** warning-only UI is evaluated
- **Then** the app keeps the short foreground grace window for stale resume probes
- **Then** the unhealthy snackbar waits an additional 5-second debounce before appearing
- **Then** if the server recovers before those windows finish, the unhealthy snackbar is not shown

### Server goes offline during use

- **Given** the active server goes offline while the user is chatting
- **When** the connection is lost
- **Then** the composer input is blocked and the reason is displayed to the user
- **Then** the user cannot send messages until the connection is restored

### Offline startup reloads initial data automatically after recovery

- **Given** an active server is configured but the app starts while that server is unreachable
- **When** connectivity and backend availability return while the chat screen remains active
- **Then** the app automatically retries the initial bootstrap flow without requiring pull-to-refresh or app restart
- **Then** the project list, sidebar session state, and initial session data reload from the recovered server state
- **Then** reconnect flapping is debounced so repeated short connection changes do not trigger duplicate bootstrap reloads

---

## Sessions

### Session lifecycle

- **Given** a connected server
- **When** the user interacts with sessions
- **Then** the user can **create**, **rename**, **archive**, **fork**, and **delete** sessions

### Active session header exposes official session actions

- **Given** an existing session is open in chat
- **When** the user opens the `Session actions` menu from the active session header
- **Then** the app exposes labeled actions for share/unshare, copy share link when available, view tasks, review changes, undo, redo, and compact context
- **Then** task and review actions open a dedicated session-details surface without requiring slash commands or sidebar knowledge
- **Then** unavailable actions are disabled instead of invoking broken flows

### Archiving a root session hides descendant sessions from the active list

- **Given** the active Conversations filter is `Active` and a root session has child/subsessions
- **When** the user archives that root session
- **Then** the root session disappears from the active list immediately
- **Then** descendant sessions of that archived root are also hidden from the active list so they do not remain orphaned as top-level rows

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
- **Then** `Open project folder...` shows inline fuzzy folder suggestions backed by OpenCode directory search when the typed query is specific enough, while preserving manual path entry and directory browsing as fallback
- **Then** tapping a project row switches/reopens that context immediately and closes the picker without requiring a secondary open action
- **Then** removing a closed project from history hides that exact project path from the closed-project history across reloads until the user explicitly reopens or re-enters that path again
- **Then** selector actions are serialized so repeated rapid taps do not trigger overlapping switch/reopen/close/archive operations

### Conversations are grouped by project context

- **Given** the user has conversations from multiple project directories
- **When** the Conversations sidebar is rendered
- **Then** the sidebar shows a dedicated `Projects` card above the conversations list with one row per open project
- **Then** each project row shows a conversation count derived from that project's visible sessions (active scope or cached snapshot)
- **Then** tapping a project row switches context directly from the sidebar (no modal required)
- **Then** when snapshot data exists, the sidebar shows compact session previews for that project; when not available, it shows a "Open project to load conversations" hint
- **Then** inactive project snapshots are patched by global `session.created`, `session.updated`, and `session.deleted` events so remote session renames and count changes can appear before the user returns to that project

### Sidebar hides diff-stat pseudo summaries

- **Given** the Conversations sidebar is rendered for a session whose backend summary payload only contains diff stats such as `additions` and `deletions`
- **When** the session row subtitle is shown
- **Then** the sidebar suppresses that pseudo-summary instead of rendering `additions: ...` / `deletions: ...`

### Recent unread root sessions are highlighted temporarily

- **Given** a root session is out of focus and receives a completed assistant reply
- **When** that reply becomes unread in the current client
- **Then** the root session row receives a subtle theme-aware highlight for up to one hour
- **Then** recent-session title text for that unread root reply also switches to a theme-aware emphasized color during that same one-hour window
- **Then** child/subsessions do not receive that temporary row highlight

### Only root sessions notify for final assistant completions

- **Given** a session finishes a final assistant response and notification feedback is evaluated
- **When** that session is a main/root session
- **Then** the app may emit the normal completion notification or sound according to the user's notification settings
- **When** that session is a child/subsession (`parentId` is present)
- **Then** the app does not emit a final-response completion notification or sound for that child session

### Recent sessions quick access is enabled by default when available

- **Given** a new installation or a context whose display toggles were never customized
- **When** the Conversations sidebar is rendered and recent root sessions exist
- **Then** the `Recent sessions` section is enabled by default and appears above the project groups
- **Then** if there are no recent root sessions yet, the section stays hidden instead of rendering an empty card

- **Given** the user disables `Recent sessions` in `Display Toggles`
- **When** the Conversations sidebar is rendered
- **Then** the sidebar hides that section even when recent root sessions are available

- **Given** the `Recent sessions` section is visible
- **When** the Conversations sidebar is rendered
- **Then** the sidebar shows a `Recent sessions` section above the project groups with up to 5 recent root sessions from currently open/cached project contexts
- **Then** each recent row stays on one line and includes a project badge so the user can identify the source project quickly
- **Then** any recent row whose session is still busy shows the same sweep-style running indicator used by the composer, including sessions from other open/cached project contexts
- **Then** if the currently open session also appears in `Recent sessions`, that row uses the same selected-style background emphasis as the project session list below it

### Project paths preserve the trailing folders in the sidebar

- **Given** a project path is too long to fit in its sidebar row subtitle
- **When** the project group subtitle is truncated
- **Then** the trailing path segments remain visible and the ellipsis appears at the start of the rendered path instead of the end

### Session pinning is context-scoped and sort-stable

- **Given** the user is viewing conversations in a specific server + project context
- **When** the user pins or unpins a session from the conversations list
- **Then** pin state is persisted locally for that exact context only (no cross-server/cross-project leakage)
- **Then** pinned sessions are always ordered before unpinned sessions, independent of the selected sort mode (recent, oldest, or title)
- **Then** standard list filters (for example active vs archived) still apply first; pinning only changes ordering within the currently visible set

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
- **Then** the chat timeline reuses the cached grouped/hydrated presentation for that session instead of visually rebuilding settled history from scratch
- **Then** if the selected existing session has no in-memory messages yet, the chat surface shows a subtle loading indicator instead of the generic `Hello! I am your AI assistant` empty state until hydration finishes
- **Then** if that cached session is still actively processing, the viewport lands directly at the bottom immediately, with no visible reopen animation
- **Then** if that cached session is already settled, the viewport restores directly to the latest assistant response instead of replaying a reopen bottom-snap or reveal thrash
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
- **Then** if the fetched tail has no safe overlap with local cache, the client immediately promotes that authoritative recent server tail, marks older history as incomplete, and automatically falls back to a full fetch to guarantee correctness

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
- **Then** historical assistant work/tool-call groups return collapsed after session return or revalidation (manual expansion is not restored)
- **Then** the latest completed assistant work/tool-call run stays visible inside a bounded internal panel while it remains the newest run, so regrouping does not yank the main chat viewport
- **Then** an already-selected empty session keeps its empty placeholder visible during background refresh (no loading skeleton blink)
- **Then** returning from background or focus with no new chat content restores a settled cached session to the latest assistant response and an active cached session to the bottom, without a second jump
- **Then** if refreshed settled content arrives during resume revalidation, the queued cached restore waits for that refresh to finish and then reveals the newest assistant response once instead of bottom-snapping first
- **Then** passive refreshes, realtime part updates, and status-only busy/retry reconciliation must not start a second auto-scroll owner while the active turn already owns the viewport
- **Then** a transient `idle` status pulse must not settle the current session while a send is still initializing or an assistant message remains incomplete locally
- **Then** unsupported global `message.*` fallback reconcile must refresh the visible timeline only when the event explicitly targets the current session; unrelated sessions/projects may dirty caches and lists but must not move or settle the visible chat
- **Then** reopening a cached session does not replay old-history entrance/loading motion before newer delta content is merged

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

### Sending while processing uses direct follow-up sends

- **Given** the assistant is actively streaming a response and the user has typed a new prompt
- **When** the user taps the primary composer action
- **Then** the app sends that prompt immediately through the normal async send path without locally batching or draining other drafts
- **Then** the app does not auto-abort the active response as part of that send action

### Busy-state UI does not invent local queue lifecycle

- **Given** the assistant is actively streaming a response
- **When** the user interacts with the composer and timeline
- **Then** the app does not show a client-invented `Queued` message state for follow-up prompts
- **Then** the app does not expose a `Send now` action or any local queue-dispatch control
- **Then** busy/idle feedback comes from the active server-backed lifecycle rather than local queue bookkeeping

### Stop remains an explicit abort action

- **Given** the assistant is actively streaming a response and the composer has no pending draft to send
- **When** the user taps `Stop`
- **Then** the app calls the session abort endpoint for the active session
- **Then** the current response stops and any partial assistant output remains visible

### Failed send returns message to composer

- **Given** the user sends a message
- **When** the send fails (network error, server error, etc.)
- **Then** the message text is returned to the composer input — the user's text is never lost

### Undo and redo reflect immediately in the current client

- **Given** the active session has at least one persisted user turn
- **Then** the latest visible revertible user bubble exposes an inline `Undo this turn` action that triggers the same undo flow as the toolbar and `/undo`
- **When** the user triggers `Undo` from the toolbar or `/undo` from the composer
- **Then** the current client immediately hides the reverted user turn and every later turn from the visible timeline without waiting for another client or a manual refresh
- **Then** the reverted user prompt is restored into the composer so the user can edit or resend it locally
- **When** the user sends a new prompt after `Undo` instead of triggering `Redo`
- **Then** the client treats that send as a replacement branch immediately: the abandoned reverted tail stays hidden, `Redo` is no longer available for that branch, and stale refreshes must not resurrect the reverted tail visually
- **When** the user triggers `Redo` from the toolbar or `/redo`
- **Then** the visible timeline immediately restores the next reverted turn (or all reverted turns when the revert boundary is fully cleared)
- **Then** a full redo clears the composer draft that had been restored by undo
- **Then** toolbar and slash-command wording stays explicit about operating on the last turn so the inline bubble action, toolbar actions, and composer actions describe the same behavior
- **Then** timeline visibility and undo/redo availability are driven by the server-authoritative session revert boundary, aligned with official OpenCode Web semantics

### Composer drafts persist per session

- **Given** the user types an unsent composer draft in a session
- **When** the user switches to another session in the same server/project context and later returns
- **Then** the original session restores its own locally persisted draft text, shell mode, and supported attachments
- **Then** sessions with no saved draft reopen with an empty composer
- **Then** transient drafts restored after a rejected send or undo/redo history action keep priority over the persisted session draft until that transient state is consumed

### Composer extras menu includes canned answers and attachments

- **Given** the user is composing a message
- **When** the user taps the `+` extras button on the left side of the composer bubble
- **Then** the app opens or closes the inline extras popover above the input without changing the current keyboard/focus state
- **Then** if the keyboard is already open, tapping `+` keeps it open; if the keyboard is already closed, tapping `+` keeps it closed
- **Then** the extras popover stays compact, starts directly with the action row, and avoids redundant title lines above the actions or canned-answer list
- **Then** the extras popover shows a top action row with quick actions such as `New quick reply` and `Attach files`, leaving room for future actions
- **Then** attachment entry is opened from that extras popover instead of a separate attachment button near the model controls
- **Then** selecting an item inserts canned text according to item mode: `Append at cursor` inserts at current selection, `Replace` overwrites composer text
- **Then** if that canned answer has `Send automatically` enabled, the app sends the resulting composer message immediately after insertion, still using the same insertion mode first
- **Then** long-pressing a canned item opens edit/delete actions
- **Then** add/edit supports an optional label, required text, insertion mode, optional `Send automatically`, and scope mode (`Global` or `Project-only`)
- **Then** global items are available across all contexts, while project-only items are restricted to the active `serverId::scopeId` context
- **Then** global canned answers are indicated inline with a globe icon instead of a standalone textual `Global` subtitle line
- **Then** each canned-answer row stays on a single line and shows only one text source: the optional label when present, otherwise the canned text truncated with ellipsis

### Optimistic user message ID uses local prefix — never server format

- **Given** the user sends a message in an active session
- **When** the client appends the optimistic user bubble and dispatches `prompt_async`
- **Then** the client assigns the optimistic message a `local_user_<timestamp>_<seq>` ID — it intentionally does NOT use a server-format ID (`msg_*` or similar)
- **Then** the `messageId` field is NOT forwarded in the `prompt_async` send payload — the server assigns its own canonical ID
- **Then** if the server returns a fully completed assistant payload directly in the `prompt_async` HTTP response, the client accepts that payload immediately instead of waiting for the fallback polling path
- **Then** duplicate detection for the server echo uses a content-signature match (normalized text), gated by the `local_user_` prefix check
- **Then** server-echo replay may temporarily coexist with the optimistic bubble during an active turn, but reconciliation must never hide in-flight tool/work output or block the final assistant reveal

> **INVARIANT — do not violate**: The `local_user_*` prefix and the absence of `messageId` in the send payload are load-bearing contracts.
> Changing the prefix to any server-format value (e.g. `msg_*`) or forwarding `messageId` in the payload causes the SSE event stream to fail reconciliation for all turns after the first — assistant responses are received and audio/notifications fire, but the UI update is silently discarded and the UI stays stuck on the previous state.
> Active refresh/reconcile must preserve visible tool/work output for the current turn until the final assistant response is available.
> This regression was introduced and reverted in commit `b0660a2`. See ADR-023 "Known Pitfalls" for the full incident analysis.

### Tool call work groups collapse after completion

- **Given** the assistant executes tool calls during a response (file reads, commands, etc.)
- **When** tool updates are still arriving for the active response
- **Then** manual expansion of a visible tool call or tool-call chain is preserved while the response is still streaming
- **Then** if a single visible tool block grows into a multi-tool chain during that same active response, the user-open state is carried into the grouped view instead of snapping shut
- **Then** collapsed multi-tool chains surface an active progress summary (for example `1 running • 1 queued`) while the response is still in flight
- **Then** the composer status slot surfaces the latest live tool, patch, or reasoning activity in a fixed position so the newest progress stays visible without shifting the main chat viewport
- **Then** if that fixed progress slot mirrors the active in-flight reasoning block, the matching inline Thinking bubble is temporarily hidden until the assistant response settles, avoiding a misleading stuck-looking duplicate
- **Then** completed tool badges use an explicit success-green treatment so finished work stays visually distinct from queued, active, and error states
- **Then** when a contiguous visible run contains multiple `task` tool bubbles, settled task bubbles render before still-active running or queued task bubbles without crossing the surrounding text/reasoning boundaries of that same assistant message
- **Then** a running `task` tool bubble prefers the latest internal child-session tool label inline when task metadata or cached child-session messages expose it; otherwise it falls back to the latest extracted command, and finally to `Running task`
- **Then** a completed `task` tool bubble shows `N tool calls` when child-session totals are available, so finished work stays compact while still hinting at the amount of internal activity
- **When** the assistant finishes the complete response
- **Then** tool-call chains and tool-detail sections start collapsed by default
- **Then** collapse never happens while the assistant is still streaming
- **Then** content shrink from active tool/work regrouping, collapse deferral, or inline reasoning suppression must not trigger outer chat snap-back while that same response is still active
- **Then** manual expansion is temporary and is not restored after return/revalidation
- **Then** when the final completed assistant-work group is compacted for the finished response, that completed group is shown collapsed by default even if a streaming-era tool block was manually expanded earlier in the turn
- **Then** the user can manually re-expand any collapsed work group by tapping its Details toggle
- **Then** once manually expanded, a completed tool-call group stays expanded during normal timeline rebuilds (scroll state updates, background refresh, and other parent re-renders) so the user can keep reading without involuntary collapse
- **Then** automatic collapse is only applied when collapse mode is activated for that rendered group, not on every subsequent rebuild
- **Then** once a completed turn has settled, transient realtime status pulses do not auto re-open or rapidly re-collapse that same work group
- **Then** the rendered identity of a settled assistant-work group is anchored to the final completed assistant turn, not to volatile intermediate work message ids, so same-turn passive refreshes reuse the existing grouped surface instead of remounting it
- **Then** passive status-only or background refresh pulses must not re-enter active-response collapse deferral for an already settled turn unless a newer revealable assistant message actually exists
- **Then** long tool output is rendered inside a bounded inner viewport with its own scrollbar so tool growth does not keep stretching the outer chat timeline while the user is reading
- **Then** when tool output continues updating inside that bounded viewport, the inner scroll may follow the latest tail only while the user is already near the bottom of that tool output; it must not yank the main chat viewport

### Empty assistant-work groups disappear after display filtering

- **Given** `Display toggles` hides all visible items inside an assistant work/tool group
- **When** the timeline is rebuilt from cache or fresh grouping
- **Then** that now-empty group is omitted entirely instead of rendering an empty shell
- **Then** display-toggle state participates in timeline cache reuse so stale filtered groups are not resurrected

### Review changes display can be hidden

- **Given** the active session has changed files available for review
- **When** `Review changes` is enabled in `Display toggles`
- **Then** the timeline or desktop utility pane shows the review-changes file list when that surface is otherwise eligible to render it
- **When** the user disables `Review changes` in `Display toggles`
- **Then** the review-changes file list block is hidden without clearing or mutating the session diff data

### Sub-conversation threads keep a full composer with parent return

- **Given** the user opens a child thread from a subtask/task bubble in the main conversation
- **When** that source bubble represents a `task` tool with a matching child session
- **Then** the entire task bubble surface acts as the navigation affordance instead of rendering a dedicated `View` button
- **When** the child thread is active (`parentId` is set)
- **Then** the full chat composer remains available inside the child thread, including text send, slash input, attachments, and voice input
- **Then** a dedicated `Return to main conversation` control remains visible so the user can navigate back to the parent thread at any time
- **Then** when that child thread is actively responding, the same composer stop behavior remains available without leaving the child thread
- **Then** agent/model/effort selectors remain non-interactive in the child thread
- **Then** the locked model chip reflects the child-thread metadata (not the parent selection)
- **Then** the effort chip is shown only when an explicit child-thread variant is known

### Sub-conversation navigation is deterministic

- **Given** assistant output contains a `SubtaskPart` or `task` tool bubble in the main conversation
- **When** the user taps `Open sub-conversation`
- **Then** navigation prefers explicit child-session IDs from the part payload
- **Then** if explicit IDs are unavailable, fallback mapping uses anchor order for the same part type (`SubtaskPart`→subtask anchors, `task` tool→task anchors) against child sessions sorted by creation time
- **Then** if no mapping can be resolved, the app keeps the current session and shows non-blocking feedback

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

### New chat content enters progressively

- **Given** the chat timeline receives new tail messages in the active session
- **When** those entries are rendered
- **Then** each new entry uses a short one-shot entrance transition with bounded stagger for clustered arrivals
- **Then** existing history does not replay entrance animations when reopening or switching sessions

### Streamed tool parts animate inside visible assistant bubbles

- **Given** an assistant bubble is already visible and new tool/patch parts are appended during streaming
- **When** those parts arrive
- **Then** only newly appended parts use a short entrance transition inside the existing bubble
- **Then** already-rendered parts do not restart their entrance animation on unrelated rebuilds

### Reduced-motion accessibility disables entrance motion

- **Given** the platform or app accessibility settings request reduced motion (`disableAnimations`)
- **When** new messages or streamed parts are rendered
- **Then** entrance motion is skipped and content appears immediately without slide transitions

### Tool-only busy turns keep live follow behavior

- **Given** the active session is still busy/retrying during a multi-step tool turn
- **When** the latest assistant chunk is completed but the turn still emits tool/patch updates
- **Then** the chat keeps active follow/reveal behavior for that same turn
- **Then** idle/background status snapshots without live tool/patch updates do not trigger autonomous jumps
- **Then** provider-side passive updates (refresh merges, realtime part deltas, and status pulses) must defer to the runtime viewport owner instead of causing a visible extra scroll-to-bottom correction for that same turn
- **Then** when the user is still passively following the active turn, growth from tool/reasoning/text updates keeps the viewport visually pinned to bottom without per-delta jump churn
- **Then** tool-only assistant messages stay as raw bubbles while the active turn is still responding; they are not live-merged into a synthetic grouped bubble mid-turn
- **Then** tool-only assistant messages may merge/collapse only after the final assistant message arrives and the turn settles
- **Then** active-turn tool/work rendering must not structurally shrink the visible timeline in a way that creates a temporary blank vacuum at the bottom while the user is still passively following the turn
- **Then** if a future optimization would merge, compact, or replace active-turn tool-only messages before settlement, it must be rejected unless it proves it cannot create viewport shrink/reflow or typing-lag regressions
- **Then** if active-turn content still shrinks while passive follow is enabled, the runtime may perform an immediate non-animated bottom-anchor heal to remove the bottom vacuum, but only while the user has not manually scrolled away
- **Then** active-turn tool-chain body size transitions must not animate while the session is still responding if that animation would introduce shrink/reflow churn or typing lag

### Recoverable current-session refresh failures stay scoped

- **Given** the user is already inside a selected session
- **When** that session refresh fails before any messages load
- **Then** the chat surface shows a scoped recovery card for that session instead of replacing the whole chat view with the old global `Retry` takeover
- **Then** the scoped recovery actions keep the user in context with `Keep working` and `Retry refresh`

### Final response is revealed from the beginning

- **Given** a response finishes after tool/work messages
- **When** the final assistant message becomes available
- **Then** the chat reveals the **start** of the final assistant message (not the end)
- **Then** if the whole final assistant message already fits in the current viewport, the chat does not perform an extra reposition
- **Then** otherwise the reveal lands with the start of the final assistant message around 40% of the viewport height so reading starts near the middle of the screen instead of hard at the top

### Post-completion reading remains stable

- **Given** the final assistant response is already visible
- **When** the user is reading without sending new input
- **Then** the chat does not perform autonomous jump/scroll corrections
- **Then** auto-follow resumes only after explicit user intent (e.g., sending a new message or tapping `Go to latest`)
- **Then** once the final response settles, shrink-correction may clean up empty space below the last message, but only after the active-turn viewport owner has been released

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
- **When** the user presses the up/down arrow key in the desktop composer
- **Then** normal multiline editor movement takes priority first — explicit newlines and soft-wrapped lines consume ArrowUp/ArrowDown while the caret can still move vertically inside the current draft/history entry
- **Then** once the caret is already on the first visual line (`ArrowUp`) or last visual line (`ArrowDown`), the composer resumes sent-message history navigation
- **Then** the composer cycles through previously sent messages
- **Then** for single-line history entries, if the cursor is not already at the start/end boundary, the first key press moves it there; the second press continues cycling
- **Then** ArrowUp/ArrowDown with modifier keys (`Shift`, `Ctrl`, `Alt`, `Meta`) stay with the text field's default editing behavior and do not trigger history navigation

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
- **Then** selecting a builtin command from that picker runs the local action immediately
- **Then** selecting a non-builtin command inserts the slash-command prefix into the composer so the user can add optional arguments before sending

The following commands are always available (builtin):

| Command | Action |
|---------|--------|
| `/new` | Start a new conversation |
| `/model` | Open the model selector |
| `/models` | Open the model selector |
| `/sessions` | Open the conversations surface |
| `/agent` | Open the agent selector |
| `/open` | Quick-open a project file |
| `/help` | Show available commands |
| `/compact` | Compact (summarize) the current session context |
| `/thinking` | Toggle Thinking bubbles |
| `/undo` | Undo the last visible user turn |
| `/redo` | Redo the last undone turn |

Additional commands may be provided by the connected OpenCode server and merged into the picker alongside the builtins.

- **Given** the user sends a slash command from the composer
- **When** the command name matches a builtin slash command
- **Then** CodeWalk runs the local builtin action instead of sending a normal chat prompt

- **Given** the user sends a non-builtin slash command from the composer
- **When** the command is dispatched
- **Then** CodeWalk executes it through the OpenCode slash-command API (`POST /session/:id/command`) instead of the normal prompt send path
- **Then** the typed slash command remains visible as the initiating user turn while the server response renders in the conversation

### Terminal workspace

- **Given** the user is in the chat workspace with an active OpenCode server connection
- **When** the user taps the AppBar terminal button
- **Then** CodeWalk toggles an embedded terminal panel inside the chat workspace instead of reusing the composer input mode
- **Then** CodeWalk creates or reconnects to a server-hosted PTY terminal rooted in the active project directory on the OpenCode host and renders it inside the embedded panel
- **Then** `Close terminal` fully closes the panel and terminates the active server PTY session, while `Minimize terminal` hides the panel without stopping that session
- **Then** `Maximize terminal` expands the panel to a larger workspace view and `Restore terminal size` returns it to the saved panel height
- **Given** the user is on a compact/mobile chat layout
- **When** the embedded terminal is open
- **Then** CodeWalk hides the composer input area until the terminal is minimized or closed so the terminal can use the available screen space
- **Given** the user is on an unsupported platform
- **When** the user taps the same terminal button
- **Then** CodeWalk opens an informational sheet explaining that the embedded server terminal is unavailable there and points the user to composer shell mode instead
- **Then** composer shell mode remains a separate one-shot command path backed by `POST /session/:id/shell`

### Host quota / rate-limit monitoring

- **Given** the user opens the `Context usage` popup from the chat status bar
- **When** quota data is available from the connected host
- **Then** CodeWalk shows a `Provider Quotas` section at the bottom of that popup after the `Compact now` action
- **Then** providers are grouped by parent organisation; each group shows a severity-colored progress bar for the most constrained sub-quota and a `Pace` chip that shows the predicted percentage of the window that will be consumed at the current usage rate
- **Then** tapping a provider group row expands it to reveal individual quota entries (requests, tokens, cost, etc.) each with its own bar and remaining figure
- **Then** on desktop, hovering the `Pace` chip shows a tooltip explaining the prediction; on mobile, tapping it shows a dismissible snackbar
- **Given** the host exposes OpenChamber-compatible REST endpoints (`GET /api/quota/providers`)
- **When** the popup is opened (or every 60 seconds in background)
- **Then** CodeWalk fetches live quota data from those endpoints without any client-side credentials
- **Given** the host does not expose OpenChamber endpoints
- **When** quota data is requested
- **Then** CodeWalk falls back to a hidden ephemeral shell session that probes `CW_QUOTA_JSON` without appearing in the user's conversation list
- **Given** the host's OpenCode `auth.json` has an `opencode-go` key and dashboard credentials are available from either the host environment or CodeWalk's secure server-scoped storage
- **When** the `Provider Quotas` popup is opened
- **Then** CodeWalk shows rolling, weekly, and monthly usage bars for the `OpenCode Go` provider
- **Given** OpenCode Go is configured but dashboard credentials are missing or expired
- **When** the `Provider Quotas` popup is opened
- **Then** CodeWalk shows an `OpenCode Go detected` setup card with a `Connect` or `Reconnect` action
- **Then** the setup dialog can open `https://opencode.ai/auth`, save the workspace ID and auth cookie in secure storage, refresh the quota probe, and forget saved credentials later
- **Then** if neither path returns data, the `Provider Quotas` section is silently omitted from the popup
- **Then** outside the explicit OpenCode Go dashboard opt-in, the client never stores, manages, or forwards provider credentials; quota ownership stays on the server host by default

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
- **Then** keyboard shortcut activation uses the same start/stop flow as the microphone button
- **Then** if the composer is disabled, keyboard shortcut activation is ignored and voice input does not start

### Cross-platform support

- **Given** any supported platform (Android, Linux, macOS, Windows, Web)
- **When** the user activates voice input
- **Then** the STT feature works on all platforms where the device has a microphone

The app uses a platform-aware speech engine strategy with automatic fallback where supported:

| Platform | Primary engine | Notes |
|----------|---------------|-------|
| Android | Native (system speech recognizer) | Sherpa/Moonshine runtimes excluded from Android build; Native only |
| Linux | Sherpa ONNX or Moonshine via sherpa_onnx | On-device models are downloaded on demand; Native not supported on Linux |
| macOS | Native (system speech recognizer) | Falls back to Sherpa ONNX if native unavailable; Moonshine is an optional desktop engine |
| iOS | Native (system speech recognizer) | Native only in the current app build |
| Windows | Native (system speech recognizer) | Falls back to Sherpa ONNX if native unavailable; Moonshine is an optional desktop engine |
| Web | Native (system speech recognizer) | Browser speech only |

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
- **Then** the owning session always shows its own permission card
- **Then** when the user is viewing the main/root session of that same thread, descendant sub-session permission cards are mirrored there as well with a source badge that identifies where they came from
- **Then** switching to an unrelated session does not surface that request there
- **When** the user allows (once or always), the server continues the operation
- **Then** the resolved permission request is removed from the local pending state immediately
- **When** the user rejects, the server receives a rejection and the session pauses — the assistant stops and waits for the user to send a new message before continuing

### Composer permission auto-approve toggle

- **Given** the user is in a main/root conversation with the composer controls visible
- **When** the composer is rendered
- **Then** a permission auto-approve toggle is shown to the left of the agent selector
- **Then** the toggle defaults to enabled and persists when the user turns it off
- **When** the toggle is enabled and the current thread receives a permission request
- **Then** the app automatically replies with `Always` when that permission request exposes remembered approval, otherwise it falls back to `Allow Once`
- **Then** mirrored descendant/sub-session permission requests shown in the root thread are auto-approved as part of that same thread scope
- **Then** on Android, the background worker keeps that same thread-scoped permission auto-approve path alive while the app is backgrounded, instead of waiting for foreground return
- **Then** when the active server or project scope changes, the Android background auto-approve context is cleared before the transition finishes so that permission replies cannot leak into the next scope
- **Then** if background auto-approve fails, the permission notification and inline card still remain as the visible/manual fallback path
- **Then** question prompts are never auto-answered by this toggle and still require a human choice
- **Then** the existing inline permission cards remain available as the visible/manual fallback path

### Question prompts

- **Given** the server needs the user to choose between options
- **When** the server sends a question prompt
- **Then** an interactive card appears with the question and selectable options
- **Then** the server waits for the user's response before proceeding
- **Then** the owning session always shows its own question card
- **Then** when the user is viewing the main/root session of that same thread, descendant sub-session question cards are mirrored there as well with a source badge that identifies where they came from
- **Then** switching to an unrelated session does not surface that question there
- **When** the user replies or rejects the question
- **Then** the resolved question request is removed from the local pending state immediately

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

### Task snackbars without actions dismiss on tap

- **Given** the chat page shows a snackbar without an explicit action button
- **When** the user taps anywhere on that snackbar
- **Then** the snackbar dismisses immediately without waiting for timeout

---

## Layout

### Mobile: chat-first with drawer

- **Given** the app is running on a mobile device (compact screen)
- **When** the user navigates the app
- **Then** the chat occupies the full screen, with the session list accessible via a lateral drawer

### Mobile back follows conversation hierarchy

- **Given** the app is running on mobile and the chat page owns the system back action
- **When** the current session is a sub-conversation
- **Then** the first back action returns to the parent/root conversation
- **When** the current session is already the root conversation and the drawer is closed
- **Then** the next back action opens the conversations drawer
- **When** the drawer is already open
- **Then** the next back action sends the app to the background

### Mobile drawer status indicator (hamburger)

The hamburger icon has exactly one active state at a time:

- **Default (no badge)**: normal operation; no urgent or loading condition is active
- **Attention dot**: shown when another visible conversation in the current project needs attention because it has an error, is waiting for user input, or received a new unread assistant reply
- **Loading spinner**: shown only when all three conditions are true simultaneously:
  1. The app returned from background and is actively resynchronizing (`isForegroundResumeSyncing`)
  2. The sync state is recoverable (reconnecting, delayed, or degraded — not failed)
  3. The Android foreground service is NOT running
- **Red dot badge**: shown when an urgent condition persists beyond the grace period:
  - Active server health probe is `unhealthy` (including offline probe failures), OR
  - Recoverable sync alert has escalated (unresolved for too long)
- **Saver dot**: shown when `Cellular data saver` is actively throttling mobile network work and no higher-priority alert/attention/loading state is active

Transient connectivity blips that do not escalate are surfaced via loading/sync states, not as urgent red health alerts.

### Mobile drawer explains the active hamburger indicator

- **Given** the mobile drawer is open and the hamburger indicator is showing a dot or loading spinner
- **When** the `Conversations` section is rendered
- **Then** a compact notice appears above `Conversations` explaining the current active reason
- **Then** if the reason has a natural destination, tapping the notice opens the relevant settings section or conversation
- **Then** the notice has no close button and disappears automatically as soon as the hamburger indicator returns to its default no-badge state

### Desktop: split view

- **Given** the app is running on a desktop (expanded screen)
- **When** the user navigates the app
- **Then** the session list is always visible alongside the chat in a split-view layout

### Desktop conversations list is denser than mobile

- **Given** the Conversations sidebar is rendered on desktop
- **When** project groups and session rows are shown
- **Then** desktop uses compact spacing between project groups and conversation rows to increase visible item density
- **Then** conversation rows use floating attention badges instead of a dedicated leading session icon so more horizontal space stays available for the title and metadata
- **Then** mobile keeps its original touch-friendly spacing

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
| `alt+s` / `option+s` | Start or stop voice input | `Option` label on macOS |
| `mod+p` | Quick-open project file | |
| `mod+,` | Open Settings | |
| `mod+m` | Cycle recent/favorite models | |
| `mod+t` | Cycle model variants | |
| `mod+j` | Next agent | |
| `mod+shift+j` | Previous agent | |
| `mod+w` | Close app | On desktop, follows close-to-tray/minimize/close settings; on Android and iOS it exits the app surface |
| `Escape` | Close drawer / focus input | Double-press stops active response |
| `mod+q` | Force-exit app | On desktop, bypasses close-to-tray/minimize; on Android and iOS it exits the app surface |

### Enter confirms safe modal primary actions

- **Given** a modal dialog has a single clear, non-destructive primary action
- **When** the user presses `Enter` or `NumpadEnter`
- **Then** the dialog may trigger that primary action without requiring a tap/click
- **Then** destructive confirmations, shortcut-capture dialogs, multiline canned-answer editing, and picker/search/selector bottom sheets remain excluded from this shortcut policy

### Single `Escape` restores composer focus when available

- **Given** no drawer, dialog, or composer popover owns the `Escape` key
- **When** the user presses `Escape` once and the composer is not currently focused
- **Then** the composer input becomes focused
- **Then** if the composer already owns focus, composer-level `Escape` handling keeps priority (for example popover close, shell exit, or double-`Escape` stop while responding)

### Mobile keyboard collapses the task panel

- **Given** the task list panel is expanded on mobile
- **When** the on-screen keyboard appears
- **Then** the task list panel automatically collapses to free space for the chat and composer
- **Then** when the keyboard is dismissed, the panel returns to its previous state (expanded or collapsed)

### Physical-keyboard send keeps composer focus

- **Given** the app is running with a physical keyboard available (desktop, or mobile with external keyboard)
- **When** the user sends a message from the composer
- **Then** the composer input keeps focus so the user can continue typing immediately

---

## Provider and Model Selection

### Selecting a provider and model

- **Given** the connected OpenCode server has providers configured (e.g., Claude, OpenAI, Gemini)
- **When** the user opens the model selector
- **Then** all available providers and their models are listed, sourced directly from the server
- **Then** the app restores the last successful provider/model catalog snapshot for the active server immediately and revalidates it in the background, so same-server project switches avoid showing an empty selector whenever possible
- **Then** the user can select any model to use for the current session

### Model variants and reasoning effort

- **Given** the selected model supports variants (e.g., reasoning effort levels)
- **When** the user opens the variant selector
- **Then** the available variants are listed and one can be selected for the session

### Favorite models

- **Given** the user stars a model in the model selector
- **When** the model selector is opened again
- **Then** starred models appear in a **Favorites** section above recent models
- **Then** favorites are persisted locally per server, shared across projects on that same server, and not shared across different servers

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

### Agent changes restore the last compatible local model choice

- **Given** the user previously used a specific provider/model/variant combination with an agent in the current server/project context
- **When** the user switches back to that agent later
- **Then** the app restores the last compatible local provider/model selection remembered for that agent
- **Then** the remembered variant is restored only when that variant still exists for the restored model
- **Then** explicit remote/session-scoped selections still take precedence over this local per-agent memory

---

## Settings

### Settings pickers are searchable

- **Given** the user opens a settings select field (for example theme presets, OpenCode-backed defaults, sound type, active server, or Sherpa language)
- **When** the user taps the field
- **Then** the app opens a searchable picker with a search input inside the picker surface
- **Then** typing filters the available options locally so long lists are faster to navigate on mobile and desktop

### Theme selection

- **Given** the user is in settings
- **When** the user selects a theme
- **Then** the app supports light, dark, and AMOLED themes, plus Material You dynamic color from the system wallpaper
- **Then** the `OpenCode Presets` picker mirrors the official OpenCode Web built-in theme registry rather than the older limited docs list

### OpenCode presets recolor markdown and code surfaces

- **Given** the user has an OpenCode preset active
- **When** chat markdown or the file viewer renders inline code, fenced code blocks, or syntax-highlighted files
- **Then** those surfaces use theme-aware colors derived from the active OpenCode Web theme instead of a generic brightness-only fallback
- **Then** changing the preset updates those markdown/code colors without requiring an app restart

### Local persistence

- **Given** the user changes any setting
- **When** the setting is saved
- **Then** it persists locally (survives app restart) via SharedPreferences / SecureStorage

### Shared settings show provenance explicitly

- **Given** the user opens Settings sections that mix OpenCode-compatible behavior with CodeWalk-specific behavior
- **When** provenance context matters for maintenance or cross-client expectations
- **Then** the UI labels the surface as `OpenCode-backed`, `CodeWalk-local`, or `CodeWalk exception`
- **Then** those labels describe ownership only; they do not imply full editing support for every OpenCode config file

### OpenCode-backed defaults cover the completed shared settings slice

- **Given** the user opens `Behavior` settings
- **When** the shared defaults card loads successfully from `/config`
- **Then** the user can edit the completed OpenCode-backed settings in CodeWalk: default model, default agent, small model, autoupdate, share, username, and snapshot
- **Then** these changes are written back to `/config` only when the server is idle, so active responses are not aborted by config mutation timing

### Permission handling provenance is documented in settings

- **Given** the user opens `Behavior` settings
- **When** the permissions provenance card is visible
- **Then** the app explains that official OpenCode permission policy is file-based (`opencode.json`) rather than fully edited from the GUI
- **Then** the card also identifies the composer permission auto-approve toggle as the approved CodeWalk exception covered by ADR-023

### Cellular data saver is documented in Behavior settings

- **Given** the user opens `Behavior` settings
- **When** the cellular data saver card is visible
- **Then** the app exposes a `CodeWalk exception` toggle that defaults to enabled
- **Then** the card explains that mobile/cellular connections suppress automatic background network work and throttle automatic foreground refreshes to one burst every 1 minute

### Keyboard shortcuts are CodeWalk-local

- **Given** the user opens `Shortcuts` settings on a platform that supports the section
- **When** the shortcuts screen is rendered
- **Then** the UI labels the bindings as `CodeWalk-local`
- **Then** editing those bindings updates CodeWalk runtime preferences only and does not write OpenCode `tui.json` keybinds

### Automatic update checks while app is open

- **Given** `Check for updates on open` is enabled
- **When** the app remains open
- **Then** a silent update check runs at startup and repeats every 1 hour while the app process is alive
- **Then** the automatic check never shows a manual spinner/up-to-date confirmation; it only surfaces UI when a newer, non-dismissed version is found

### Desktop update install snackbars

- **Given** an update install is started on desktop (Linux, macOS, Windows)
- **When** the installer script is running
- **Then** the app shows an indefinite loading snackbar (`Installing update...`) until the install state settles
- **Then** on success, the app shows a completion warning snackbar with a `Restart` action so the user can relaunch into the new version

### Snackbars are always manually dismissible

- **Given** the app shows any snackbar
- **When** the snackbar is visible
- **Then** it always includes a close (`X`) affordance so the user can dismiss it immediately without waiting for timeout
- **Then** existing semantic actions (for example `Retry`, `Restart`, or `Install`) remain available alongside the dismiss affordance

---

## Notifications

> The OpenCode server does not support traditional push notifications. The app uses platform-native techniques to deliver background alerts reliably while minimizing battery impact.

### Background alerts (Android)

- **Given** the app is running on Android and `Background alerts on Android` is enabled
- **When** the app goes to background without a known active response
- **Then** the app relies on sparse WorkManager checks only; it does not start an immediate fast probe just because the screen was left
- **When** the app goes to background with a known active response
- **Then** the app may keep realtime alive briefly, schedule low-data probes every 3 minutes, and run one 5-minute tail probe after the active work settles
- **Then** the worker fetches only the minimum data needed for completion, error, permission, and question alerts; session metadata is fetched only when needed to label a notification or suppress child-session completion alerts
- **When** `Cellular data saver` is active on mobile data
- **Then** Android background network checks are suppressed entirely, including periodic probes, active-response probes, and tail probes
- **When** the user disables Android background alerts in Settings
- **Then** no Android background checks run and the persistent monitor notification is removed
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
- **When** a known active response is being temporarily monitored after the app moves to background
- **Then** a persistent notification is shown in the notification drawer for that temporary live-monitor window only
- **When** Android background alerts are disabled or there is no active live-monitor window
- **Then** the persistent monitor notification is not shown

---

## Background and Lifecycle

### Android foreground service

- **Given** the app is running on Android during a long operation
- **When** the app goes to background while a known response is still active and temporary live monitoring is enabled
- **Then** a foreground service keeps the app alive for that short monitoring window
- **Then** the foreground service is not used as an always-on idle monitor

### Battery optimization prompt

- **Given** the app is running on Android
- **When** battery optimization may interfere with background operation
- **Then** the app prompts the user to disable battery optimization

### Automatic reconnection on resume

- **Given** the app was in background
- **When** the user returns to the app
- **Then** the app automatically reconnects to the server and resynchronizes state (missed messages, updated sessions, etc.)
- **Then** transient resume-time probe failures use a short confirmation window before unhealthy/disconnected warning UI is shown, so false alerts do not flash while connectivity is still settling
- **Then** pending question and permission refreshes merge with live SSE updates during reconnect/resume instead of wiping newer in-memory prompts that arrived while the HTTP refresh was in flight
- **Then** when `Cellular data saver` is active on mobile data, resume-time automatic sync is limited to one immediate foreground burst and idle realtime may stay paused afterward until the next 1-minute window or an explicit user action

### No duplicate refresh on resume

- **Given** the app resumes from background
- **When** both lifecycle and reconnect triggers fire
- **Then** only one refresh cycle executes — no duplicate network calls

---

## Speech Input

### New Linux installs default to Parakeet when Native is unavailable

- **Given** the app is opened on Linux for the first time with default settings
- **When** speech-to-text settings are initialized
- **Then** the app selects `Parakeet` as the default engine instead of `Sherpa`
- **Then** explicit existing non-native user selections remain unchanged

### Desktop can use Parakeet for offline multilingual speech-to-text

- **Given** the user opens `Settings` > `Speech to text` on Linux, macOS, or Windows
- **When** the user selects the `Parakeet` engine
- **Then** the settings screen shows a dedicated Parakeet model card with install status, download, remove, and refresh actions
- **Then** the app keeps Parakeet downloadable and out of the shipped app bundle

### First Parakeet use prompts model download

- **Given** the user starts voice input with `Parakeet` selected and no local Parakeet model installed
- **When** the composer starts speech input
- **Then** the app opens a blocking `Parakeet Voice Setup` dialog instead of failing silently
- **Then** after the download finishes successfully, the app retries the speech-input start flow automatically

### Parakeet stays desktop-only

- **Given** the app runs on Android, iOS, or Web
- **When** speech-engine availability is evaluated from persisted settings
- **Then** `Parakeet` is treated as unavailable and the app falls back to a supported engine instead of exposing a broken selection

### Desktop can use SenseVoice for CJK-focused offline speech-to-text

- **Given** the user opens `Settings` > `Speech to text` on Linux, macOS, or Windows
- **When** the user selects the `SenseVoice` engine
- **Then** the settings screen shows a dedicated SenseVoice model card with install status, download, remove, and refresh actions
- **Then** the app presents SenseVoice as the strongest built-in option for Chinese, Cantonese, Japanese, Korean, and English

### First SenseVoice use prompts model download

- **Given** the user starts voice input with `SenseVoice` selected and no local SenseVoice model installed
- **When** the composer starts speech input
- **Then** the app opens a blocking `SenseVoice Setup` dialog instead of failing silently
- **Then** after the download finishes successfully, the app retries the speech-input start flow automatically

### SenseVoice stays desktop-only

- **Given** the app runs on Android, iOS, or Web
- **When** speech-engine availability is evaluated from persisted settings
- **Then** `SenseVoice` is treated as unavailable and the app falls back to a supported engine instead of exposing a broken selection

---

## Anti-behaviors

> Things that must **never** happen, regardless of circumstances.

### Never lose user messages

The app must never silently discard a user's message. If sending fails, the message text returns to the composer input.

### Never freeze the UI

All operations (streaming, sync, network) are asynchronous. The UI must never become unresponsive, even during heavy operations.

### Never expose tokens or credentials

Server tokens, API keys, and credentials must never appear in logs, error screens, exports, or any user-visible surface.

### Never auto-approve permissions outside the approved exception

Permission requests from the server must require explicit user action unless the user has the ADR-023-approved composer auto-approve toggle enabled. Outside that exception, the app must never approve automatically.

### Never leak pending prompts across sessions

Permission and question cards must remain owned by their originating session. The app may mirror descendant thread prompts into the active main/root session for visibility, but it must never surface pending interactions in unrelated sessions.

### Never show false aborts

When a connection drops and reconnects (especially on mobile background/resume), the app must not display false "message aborted" errors from stale SSE events.

### Never accept mutating actions during confirmed reconnect failure

If realtime transport failures have already pushed the app into a confirmed reconnect cycle, mutating actions such as sending a message, replying to a permission/question, or compacting context must fail fast with explicit user feedback instead of pretending the action was accepted.

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

The grouped surface for that settled turn must keep the same rendered identity across same-turn passive refreshes, and passive status pulses must not temporarily treat that settled turn as active again unless a newer revealable assistant message exists.

### Never misread viewport shrink as top-history intent

Top-history loading must only trigger from real upward user scrolling. Content shrink from collapse, re-layout, or other viewport-clamp side effects must never be interpreted as intent to load older messages, because that causes jumps into old history and then snap-back recovery.

### Never let passive busy-turn updates fight the viewport owner

During an active busy/retry turn, only one viewport owner may control the outer chat scroll position. Passive refresh merges, realtime part deltas, status pulses, and collapse/re-layout side effects must never stack a second autonomous scroll correction on top of the active-turn follow/reveal policy, because that causes the classic up/down bounce regression.

### Never show stale data after resume

When the app returns from background, it must refresh the current session to show the latest state. However, refresh must not re-inject stale abort data that was already handled.

### Never break layout with keyboard

On mobile, the on-screen keyboard must never cause overflow, clipping, or layout breakage. Fixed minimum heights must account for the keyboard-reduced viewport.

### Errors: only show blocking ones

The user should see error feedback only when the error prevents them from continuing (send failed, server unreachable). Non-blocking warnings from the server (partial timeouts, transient issues) should be silent.
