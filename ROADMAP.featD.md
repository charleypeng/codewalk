# ROADMAP.featD - Thinking and Tool UX Polish

## Scope

- Task 16: Quick toggle to show/hide Thinking.
- Task 17: Density setting (dense/normal/spacious) for app UI.
- Task 21: Personalize common tool-call titles and soften response appearance.
- Task 27: Remove/replace session status icon near title with elegant loading behavior.
- Task 29: Limit expanded tool-call content height.

## Goal

Give users direct control over verbosity and density while keeping message/tool surfaces readable and stable on mobile and desktop.

## Execution Update (2026-02-14)

- Completed.
- Implemented global top-bar display toggles (all devices) with popover entries for `Thinking bubbles` and `Tool call bubbles`.
- Added app-wide density preference (`dense`, `normal`, `spacious`) in Settings > Appearance and wired it to theme visual density.
- Applied product-friendly tool-call titles/status labels and capped expanded tool output with internal scroll (`min(300px, 40vh)` behavior, capped at `300px`).
- Removed header status icon near session title and applied a transient lantern/shimmer animation to composer status text (`Thinking`, `Receiving`, dynamic status labels).

## Research Notes

- Material 3 density/theming:
  - https://m3.material.io/styles/spacing/overview
  - https://api.flutter.dev/flutter/material/ThemeData-class.html
- Expand/collapse content with constrained height:
  - https://api.flutter.dev/flutter/widgets/AnimatedSize-class.html
  - https://api.flutter.dev/flutter/widgets/ConstrainedBox-class.html
- Cross-platform adaptive UI guidance:
  - https://docs.flutter.dev/ui/adaptive-responsive

## Implementation Plan

1. Add a global thinking visibility toggle in message header/composer area.
2. Introduce app density token set (`compact`, `normal`, `comfortable`) feeding paddings, list tile density, and message spacing.
3. Normalize common tool-call titles and apply softer copy for non-fatal/recoverable states.
4. Replace session status glyph with context knob loading state while streaming.
5. For tool-call expansion, cap content viewport height and enable internal scroll.

## Backend/Contract Considerations

- Thinking toggle is presentation-only; no server payload contract changes.
- Density preference persisted locally per profile/device.

## Validation

- Widget tests for density token propagation.
- Widget tests for tool-call title mapping and softened status copy.
- Golden tests for thinking hidden/visible and loading-state variants.
- Manual checks on Android small screens and desktop wide layouts.

## Definition of Done

- Users can instantly toggle thinking visibility.
- Density choice applies consistently across primary surfaces.
- Tool-call cards use clearer, softer, and consistent naming/status text.
- Session loading indicator is subtle and informative.
- Expanded tool-call panels never overtake viewport height.
