# Feature 18: Custom JSON Themes

**Phase**: 5 — Advanced and Experimental Features
**Status**: [ ] Not started
**Priority**: P4
**CodeWalk Status**: Missing

## Why Later

Nice power-user feature; CodeWalk already has strong theme coverage through Material You and OpenCode presets.

## Target

- Load user JSON theme files from a documented local directory.
- Validate schema and skip invalid files safely.
- Merge into existing OpenCode theme preset picker.

## Likely Files

- `lib/presentation/theme/opencode_theme_presets.dart`
- `lib/presentation/theme/app_theme.dart`
- `lib/presentation/providers/settings_provider.dart`
- New theme loader service

## Validation

- Unit tests for JSON parse/validation.
- Manual theme switch test.
