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

---

## Servers

### Multiple server profiles

- **Given** the user is in server settings
- **When** the user adds a new server profile (local, remote, work, etc.)
- **Then** the profile is saved and the user can switch between profiles at any time

### Automatic health checks

- **Given** server profiles are configured
- **When** the app is active
- **Then** the app periodically checks each server's health and shows a visual online/offline indicator

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

### Fork creates an independent copy

- **Given** an existing session with conversation history
- **When** the user forks the session
- **Then** a new independent session is created as a copy from that point — changes to either session do not affect the other

### Sessions are scoped to a project

- **Given** the user has multiple projects/workspaces
- **When** the user switches to a different project
- **Then** the visible session list changes to show only sessions belonging to that project

### Auto-generated session titles

- **Given** a new session with no custom title
- **When** the conversation progresses
- **Then** the app automatically generates a title based on the conversation content

---

## Chat

### Messages are streamed in real time

- **Given** a connected server and an active session
- **When** the user sends a message
- **Then** the message is sent to the OpenCode server and the assistant's response streams back via SSE, rendering in real time as text arrives

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

### Send now forces immediate queued dispatch

- **Given** there are queued messages while the assistant is still processing
- **When** the user taps `Send now`
- **Then** the app performs the same stop behavior as `Stop` for the active response
- **Then** as soon as the session becomes ready, the app sends the full queued batch as one payload

### Failed send returns message to composer

- **Given** the user sends a message
- **When** the send fails (network error, server error, etc.)
- **Then** the message text is returned to the composer input — the user's text is never lost

### Tool call work groups collapse after completion

- **Given** the assistant executes tool calls during a response (file reads, commands, etc.)
- **When** the assistant finishes the complete response
- **Then** the intermediate tool call groups collapse to keep the chat clean
- **Then** collapse never happens while the assistant is still streaming

### UI remains fluid during streaming

- **Given** the assistant is streaming a long response
- **When** text, code blocks, or tool calls render incrementally
- **Then** the UI remains smooth without stuttering, freezing, or perceptible lag

---

## Composer

### Message history navigation

- **Given** the user has sent previous messages in the session
- **When** the user presses the up/down arrow keys in the composer
- **Then** the composer cycles through previously sent messages

### File mentions with @

- **Given** the user is typing in the composer
- **When** the user types `@`
- **Then** a file/context mention picker appears, allowing the user to reference project files in the message

### Slash commands with /

- **Given** the user is typing in the composer
- **When** the user types `/`
- **Then** a command picker appears with available slash commands

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

---

## Interactive Prompts

### Permission requests

- **Given** the server needs user approval to perform an action (e.g., execute a command, write a file)
- **When** the server sends a permission request
- **Then** an interactive card appears in the chat with approve/deny options
- **Then** the server waits for the user's response before proceeding

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

---

## Layout

### Mobile: chat-first with drawer

- **Given** the app is running on a mobile device (compact screen)
- **When** the user navigates the app
- **Then** the chat occupies the full screen, with the session list accessible via a lateral drawer

### Mobile drawer status indicator (hamburger)

- **Given** the mobile AppBar hamburger button is visible
- **When** the app is in a non-urgent state (server health unknown or recoverable sync without escalation)
- **Then** no status dot badge is shown on the hamburger icon
- **When** the app is resynchronizing right after foreground resume (recoverable state)
- **Then** a subtle loading spinner may appear on the hamburger icon instead of a dot
- **When** an urgent state is present (server unhealthy/offline or escalated recoverable sync)
- **Then** a red dot badge is shown after the alert grace period
- **Then** non-urgent blue/gray dot badges are never shown on the hamburger icon

### Desktop: split view

- **Given** the app is running on a desktop (expanded screen)
- **When** the user navigates the app
- **Then** the session list is always visible alongside the chat in a split-view layout

### Keyboard shortcuts

- **Given** a physical keyboard is connected (desktop or mobile with external keyboard)
- **When** the user presses a keyboard shortcut
- **Then** the corresponding action is executed (shortcuts work on desktop and on mobile with an external keyboard)

### Mobile keyboard collapses auxiliary panels

- **Given** an auxiliary panel is open (task list, drawer, etc.) on mobile
- **When** the on-screen keyboard appears
- **Then** auxiliary panels auto-collapse to maximize available space for the chat and composer

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

### Background notifications

- **Given** the app is in the background
- **When** the assistant finishes a response → push notification
- **When** a permission request arrives → push notification
- **When** a question prompt arrives → push notification

### Server offline does NOT notify

- **Given** the active server goes offline
- **When** the app detects the disconnection
- **Then** no push notification is sent — server availability is not the app's responsibility. The user sees the status when they open the app.

### Android persistent notification

- **Given** the app is running on Android
- **When** the app is active or in background
- **Then** a persistent notification acts as a tray icon, enabling reliable notification delivery

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

### Never cancel responses on session switch

If the assistant is streaming a response and the user switches to a different session, the in-flight response must be preserved — not cancelled. The user can return to the original session and see the completed response.

### Never collapse work groups during streaming

Tool call work groups must only collapse after the assistant has fully completed its response. Premature collapse causes visual flicker and hides active work.

### Never show stale data after resume

When the app returns from background, it must refresh the current session to show the latest state. However, refresh must not re-inject stale abort data that was already handled.

### Never break layout with keyboard

On mobile, the on-screen keyboard must never cause overflow, clipping, or layout breakage. Fixed minimum heights must account for the keyboard-reduced viewport.

### Errors: only show blocking ones

The user should see error feedback only when the error prevents them from continuing (send failed, server unreachable). Non-blocking warnings from the server (partial timeouts, transient issues) should be silent.
