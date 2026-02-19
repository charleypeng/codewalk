# ROADMAP.featG - Model favorites and variant selector ergonomics

## Status: Completed (2026-02-19)

## Scope

- Task 34: Add favorite models support.
- Task 35: Reduce variant selector popover width.

## Goal

Improve model selection ergonomics with faster preference access and cleaner compact popover behavior.

## Implementation Summary

- **Task 34 — Model favorites**: Star toggle in model selector, persisted locally via SharedPreferences (scoped per server+project). "Favorites" section rendered above "Recent" in the model selector list. mod+m keyboard shortcut cycles through favorites+recents.
- **Task 35 — Variant popover auto-fit**: Replaced fixed 220px popover width with TextPainter-measured width + padding, yielding compact content-aware sizing across breakpoints.

## Commits

- `af0b5ed` — Tasks 34 & 35

## Definition of Done

- [x] Users can pin/unpin favorite models quickly.
- [x] Variant popover is compact and readable across breakpoints.
