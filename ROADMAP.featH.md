# ROADMAP.featH - Settings, Onboarding, and Operational Readiness

## Scope

- Task 18: Async background refresh for providers/model on app open.
- Task 19: Add basic OpenCode server install/run instructions in add-server screen.
- Task 20: Limit tool-call expanded height.
- Task 22: Collapse tool-call chain once final assistant response arrives.
- Task 38: Thinking bubble max 4 lines with smooth vertical motion and bounded expansion.

## Goal

Improve first-run comprehension and runtime readability by delivering smarter startup refresh, clearer setup guidance, and compact response surfaces.

## Research Notes

- Startup lifecycle hooks:
  - https://api.flutter.dev/flutter/widgets/WidgetsBinding-class.html
  - https://docs.flutter.dev/app-architecture/guide
- Rich text truncation/expansion:
  - https://api.flutter.dev/flutter/widgets/Text-class.html
  - https://api.flutter.dev/flutter/widgets/AnimatedSwitcher-class.html
- Bounded panels with nested scrolling:
  - https://api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html
  - https://api.flutter.dev/flutter/widgets/Scrollbar-class.html

## Implementation Plan

1. Launch provider/model refresh as non-blocking startup task with cancellation safeguards.
2. Add concise server setup card in add-server flow (install, run, verify health endpoint).
3. Standardize tool-call max-height behavior and auto-collapse policy post-final response.
4. Implement thinking preview box:
   - max 4 lines in collapsed mode;
   - smooth incoming text movement;
   - `Show more` opens bounded scroll region.

## Backend/Contract Considerations

- Startup refresh should avoid duplicate concurrent fetch storms.
- Auto-collapse must preserve full payload in expand state (no data loss).

## Validation

- Startup integration tests for async refresh and race safety.
- Widget tests for thinking 4-line clamp and expansion behavior.
- UX verification for tool-call collapse after final message.

## Definition of Done

- Startup feels responsive while providers/models refresh in background.
- Add-server screen helps users self-serve setup quickly.
- Tool/thinking blocks remain compact without hiding critical info.
