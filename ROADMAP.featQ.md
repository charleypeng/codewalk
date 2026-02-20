# ROADMAP.featQ - Cross-platform UX and Settings Polish

## Scope

- **Group 1 — Platform Reliability and Critical Onboarding** [ ]
  - [x] Fix first-run without config/server: avoid visual loops/errors and do not query without configured server. — `92fa47e`
  - [x] Review server wizard flow on Windows (installation and recognition). — `c62ee3b`, `9e54aea`
  - [x] Confirm real `speech_to_text` (Native) support on Windows and document why fallback to Sherpa happens. Note: Windows native STT is supported; fallback to Sherpa happens when native initialization fails due permission/privacy, online speech availability, or missing language packs.
  - [ ] On Android, after leaving the screen, notifications stop arriving; plan a low-impact permanent consultation/polling strategy to keep notification delivery without draining battery.
  - [x] On Linux, close-to-tray keeps app running instead of fully closing; added `mod+q` quit shortcut and close-to-tray toggle so the window hides on close but quits on shortcut.
  - [x] `mod+j` and `mod+shift+j` switch model correctly; fixed agent cycling logic and added SnackBar feedback on switch. Also fixed bug: `_filterSessionsForCurrentContext` returned fixed-length lists that broke `deleteSession`.
  - [x] Desktop sidebars become horizontally resizable; implemented drag-to-resize with persisted width on both left and right desktop sidebars.
  - [ ] On macOS, investigate square launcher icon and align with macOS icon guidelines.
  - [ ] Standardize fallback icon borders for OSes without specific icon guidelines (Android already OK; investigate Windows and others).
  - [ ] Research and select the fastest, most efficient Flutter caching strategy/system, then implement it in the app with focus on performance and cross-platform consistency.

- **Group 2 — Settings, Wizard, Status, and Update Consistency** [ ]
  - [x] Reorganize Wizard visuals to highlight the recommended option and alternatives. — `92fa47e`
  - [ ] Unify the general Setup Wizard and server Setup Wizard into a single, consistent experience.
  - [ ] Sync Settings > Appearance with the `Display` popover.
  - [x] In Settings, move Servers to first position (before Appearance). — `92fa47e`
  - [ ] In Settings > Logs, remove extra step and open logs screen directly.
  - [ ] On mobile, Back in Settings follows hierarchical navigation: section -> Settings main screen -> app main screen; only after that should Back close the app.
  - [ ] In Settings > Shortcuts, review shortcut coverage and add missing options.
  - [ ] Add shortcut to enable/disable STT in Shortcuts.
  - [ ] In Settings > About, create an independent update system for new versions.
  - [ ] In About, add "check updates on open" option (default on), with toast and update button.
  - [ ] Ensure notifications do not prefix the title with generic labels such as `Finished:`.
  - [ ] In sync status, avoid orange dot for recoverable states (`degraded`/`delayed`/`reconnecting`); show subtle loading in menu when returning from foreground without persistent indicator.
  - [ ] Fix visual desync of the select near Settings vs server popover (reactive status consistency).
  - [ ] Simplify terminology mismatch Project vs Workspace in "Project Context" dialog.
  - [ ] Reorganize the "Project Context" screen for a more dynamic visual UX; tapping a project opens it immediately and closes the dialog, removing the need for a separate open button next to trash.
  - [ ] Fix intermittent stale project selection in "Project Context": after switching projects, the UI must always reflect the newly selected project without requiring reopening the dialog and selecting again.
  - [ ] Add project/workspace context cache to enable faster switching between recently used projects.
  - [ ] Replace the current project selection dialog with an inline rich select/dropdown component.
  - [ ] Investigate and fix project-switch navigation regression (including while app is busy): after changing project, navigation sometimes reopens a sub-conversation from the main session instead of restoring the primary conversation the user was previously viewing.
  - [ ] Context knob shows only the number (without `%`), while popover keeps `%`.

- **Group 3 — Chat UX, Composer, and Tool Bubble Polish** [ ]
  - [ ] Tool-call collapse is standardized: when final assistant response arrives, collapse all tool bubbles into a single collapsed group between user message and assistant response.
  - [ ] Require custom textual descriptions for every tool call; when a tool call finishes, auto-collapse it to icon+title with an inline expand button to reopen details.
  - [ ] Mirror subagent permission prompts/authorization requests in the main conversation so users can respond there too, with a subtle origin badge indicating the request comes from a subagent.
  - [ ] Remove the border around tool-call bubbles.
  - [ ] Investigate and fix mobile-first blank chat screen when opening very large conversations: the screen goes fully white until app restart, and usually opens correctly after relaunch.
  - [ ] Investigate and fix mobile chat-state refresh after app resume: sometimes the latest assistant message is not rendered when returning from background, but appears after switching to another conversation and back.
  - [ ] Investigate and fix conversation-open click behavior: sometimes opening a conversation requires two clicks (first opens the conversation, second closes the sidebar), and a fast double-click on the same item can freeze the screen, especially with large histories.
  - [ ] Investigate and fix intermittent blank history on conversation open: chat can appear empty until pull/scroll, likely due to auto-scroll to the last message overshooting (overscroll) and leaving the viewport outside the content.
  - [ ] After returning from background, position the conversation at the start of the most recent message (top of text) instead of at the end of that message.
  - [ ] In composer, adjust `ArrowUp`/`ArrowDown` without modifiers for multiline behavior before history navigation; with modifiers keep default editor behavior.
  - [ ] In composer, simplify the input placeholder to a single short phrase (e.g., `Type your needs...`) with no extra helper text.
  - [ ] In composer, after clicking `New chat`, focus the composer input automatically so typing can start right away.
  - [ ] In composer, increase slightly the composer status text font size for better readability.
  - [ ] In mic/STT usage, insert text at current cursor position (not always at the end).
  - [ ] Handle `MessageAborted` with an inline friendly red chat message (`"What you want to do different?"`) instead of toast+retry; keep toast flow for punctual/non-abort errors.
  - [ ] Investigate and fix conversation continuity when switching sessions/projects: context changes can unexpectedly abort active conversations, so preserve active streams/chats when appropriate.
  - [ ] Plan the merge between the project selector and the conversations sidebar, grouping conversations by open projects to speed up navigation.
  - [ ] Tasks widget gets a footer progress bar based on total completed items.
  - [ ] Plan support for sending a new message while the assistant is still working (OpenCode CLI/Web parity), following existing OpenCode interaction patterns.
  - [ ] Run a UI experiment: remove assistant bubble borders and reduce assistant bubble padding; in this experiment keep background color only on user bubbles and remove user bubble border line too.

## Goal

Deliver cross-platform UX parity and settings consistency across desktop/mobile surfaces, while removing interaction friction in onboarding, status signaling, shortcuts, and speech input workflows.
