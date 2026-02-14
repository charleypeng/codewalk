# ROADMAP.featG - Files Authoring Architecture (Planning Pack)

## Scope

- Task 34: Add favorite models support.
- Task 35: Reduce variant selector popover width.

## Goal

Improve model selection ergonomics with faster preference access and cleaner compact popover behavior.

## Research Notes

- Chip/list selection patterns for favorites:
  - https://m3.material.io/components/chips/overview
  - https://api.flutter.dev/flutter/material/FilterChip-class.html
- Popover/menu constraints:
  - https://api.flutter.dev/flutter/material/MenuAnchor-class.html
  - https://api.flutter.dev/flutter/widgets/Align-class.html
- Local preference persistence:
  - https://pub.dev/packages/shared_preferences

## Implementation Plan

1. Add `favoriteModelIds` persistence keyed by server+project context.
2. Show favorites first in model selector with visual pin state.
3. Clamp variant popover width by breakpoint and content-based max.
4. Keep full label available via tooltip/secondary line if truncated.

## Backend/Contract Considerations

- Favorites remain client preference; no required backend schema change.
- Optional future sync can reuse app-scoped config namespace.

## Validation

- Unit tests for favorite ordering and persistence.
- Widget tests for compact popover width on mobile/desktop.

## Definition of Done

- Users can pin/unpin favorite models quickly.
- Variant popover is compact and readable across breakpoints.
