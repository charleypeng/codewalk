# ROADMAP.featK - First-Run Onboarding Wizard

## Scope

- Task 36: First-open onboarding wizard with central dialog for server setup and ch.at service toggle.

## Goal

Reduce first-run friction by guiding server selection/creation and optional service toggles before entering chat.

## Research Notes

- Flutter dialog and multi-step flow patterns:
  - https://api.flutter.dev/flutter/material/AlertDialog-class.html
  - https://api.flutter.dev/flutter/material/Stepper-class.html
- First-run persistence:
  - https://pub.dev/packages/shared_preferences
- UX principles for onboarding:
  - https://www.nngroup.com/articles/onboarding-tutorials/

## Implementation Plan

1. Add first-run gate flag (`hasCompletedOnboarding`) persisted locally.
2. Build modal wizard with steps:
   - pick existing server or add new;
   - validate connection;
   - toggle optional ch.at service;
   - finish and enter app.
3. Allow skip path with explicit warning and later access from settings.
4. Ensure responsive layout for phone and desktop widths.

## Backend/Contract Considerations

- Reuse existing server profile model and validation endpoints.
- ch.at toggle must map to existing settings contract.

## Validation

- Widget tests for first-run visibility, skip, and completion persistence.
- Integration test confirming wizard appears once and reopens from settings.

## Definition of Done

- New users can configure a working server in first launch flow.
- Onboarding is non-blocking, repeatable from settings, and mobile-first.
