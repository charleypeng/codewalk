---
feature: "featN - Material You Design System Revamp"
created_on: "2026-02-14"
status: "pending"
priority: "medium (design polish + UX enhancement)"
isolation: "high - can run independently of feature work"
scope: "visual design, theming, layout, responsive patterns, accessibility"
---

## Overview

Execute a comprehensive design revamp of the CodeWalk Flutter app to fully embrace **Material Design 3 (Material You)** philosophy and guidelines. This includes implementing dynamic color theming, improving responsive layouts across all screen sizes, refining spacing/typography, and ensuring all components meet current Material Design 3 specifications.

## Context

### Current State

- **Material 3 enabled**: `useMaterial3: true` already set in `ThemeData`
- **Dynamic color ready**: `dynamic_color` package already in dependencies
- **Theme structure**: Centralized in `lib/presentation/theme/app_theme.dart`
- **Density support**: Already has `AppDensity` enum (extra-dense/dense/normal/spacious/extra-spacious)
- **Color palette**: Currently using fixed `seedColor: 0xFF3A6EA5` (blue)

### What's Missing

1. **Dynamic color extraction** from Android 12+ wallpaper
2. **Alternative color themes** (brand colors, custom palettes, high-contrast)
3. **Responsive layout** patterns for tablet/landscape modes
4. **Adaptive components** that adjust to screen size breakpoints
5. **Modern M3 shape** system (consistent corner radius scales)
6. **Advanced M3 features** (elevation, surface tints, semantic colors)
7. **Motion & transitions** aligned with M3 spec
8. **Accessibility enhancements** (semantic density, text contrast, touch targets)

## Design Principles from Material You

### 1. Personalization

Material You is fundamentally about **personal expression** through color. The system should:
- Extract dominant colors from device wallpaper (Android 12+)
- Let users choose alternative brand colors or custom palettes
- Adapt typography and spacing to user preferences (density)
- Remember theme choice across app launches

### 2. Expressiveness

- **Color roles**: Use semantic color names (`primary`, `secondary`, `tertiary`, `error`) consistently
- **Surface hierarchy**: Different `surface*` colors create visual depth
- **Tonal elevation**: Use `surfaceTint` to show component elevation without drop shadows
- **Shape**: Rounded corners express brand personality (scale from 0 to 28)

### 3. Adaptability

- **Responsive layouts**: Different at mobile (compact), tablet (medium), and desktop (expanded)
- **Orientation changes**: Handle portrait↔landscape transitions smoothly
- **Accessibility**: Support high-contrast mode, scaling text, and larger touch targets
- **Dark/Light**: Smooth transitions between modes with semantic color application

### 4. Cross-Platform Consistency

- Consistent spacing grid (4dp baseline, 8dp, 12dp, 16dp, 24dp, etc.)
- Unified typography scale (Display, Headline, Title, Body, Label)
- Standard motion curves and durations (150ms, 200ms, 300ms standard)
- Component sizing based on touch target minimums (48x48dp)

## Research Summary

### Material Design 3 Specifications

| Aspect | Details |
|--------|---------|
| **Color System** | tonal palette system with 5 tonal levels (0-100 hue-based); 5 color roles (Primary, Secondary, Tertiary, Neutral, Neutral Variant) |
| **Shape Scale** | corner radius: 0, 4, 8, 12, 16, 20, 24, 28 dp for different components; icons/avatars typically use 0 or 28 |
| **Typography** | 15-scale system: Display (large/medium/small), Headline (large/medium/small), Title (large/medium/small), Body (large/medium/small), Label (large/medium/small) |
| **Spacing** | 4dp grid baseline; multiples: 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52+ |
| **Elevation** | expressed via `surfaceTint` color overlay (no drop shadows); levels 0-5 with increasing tint opacity |
| **Motion** | easing curves (standard, emphasized, decelerated); durations: 150ms (small), 200ms (medium), 300ms (large) |
| **Semantics** | on-brand colors, error/warning/success/info roles, high-contrast accessible defaults |

### Dynamic Color (Android 12+)

**Implementation strategy:**

```dart
// 1. Extract colors from wallpaper
final dynamicColorScheme = await DynamicColorPlugin.getCoreDynamicColors();

// 2. Fall back to seed color if unavailable
final colorScheme = dynamicColorScheme ?? ColorScheme.fromSeed(seedColor: Color(0xFF3A6EA5));

// 3. Create theme with dynamic palette
final theme = AppTheme.lightFrom(colorScheme);
```

**Platform support:**
- ✅ Android 12+ (Material You built-in)
- ✅ iOS 15+ (can use dominant image colors via plugins)
- ✅ Desktop/Web (falls back to seed color)
- ✅ Older Android (falls back to seed color)

### Responsive Layout Patterns

**Material Design breakpoints:**

| Breakpoint | Width | Device | Layout |
|-----------|-------|--------|--------|
| Compact | 0-599dp | Phone (portrait) | Single-column, stacked navigation |
| Medium | 600-839dp | Tablet (portrait), foldable | Two-column, rail navigation |
| Expanded | 840dp+ | Tablet/Desktop (landscape) | Three-column or full-width with sidebars |

**CodeWalk-specific adaptations:**

- **Compact**: Mobile view (current)
  - Bottom sheet for modals
  - List-to-detail navigation pattern
  - Stacked sidebars (Conversations → Files → Utility)

- **Medium**: Tablet portrait
  - Split-pane layout (sessions on left, chat on right)
  - Persistent rail or drawer
  - Floating compose action

- **Expanded**: Desktop/Landscape
  - Three-column layout (sessions, chat, utilities)
  - Collapsible sidebars with persistent visibility state
  - Multi-window support (floating panels, tabs)

### Component Updates

**Deprecated → Modern M3:**

| Old | New M3 | Change |
|-----|--------|--------|
| `FloatingActionButton` | `FloatingActionButton` (updated) | Extended FAB with label, improved appearance |
| `OutlinedButton` | `OutlinedButton` (updated) | Thinner border, updated padding |
| `ElevatedButton` | `FilledButton` / `FilledButton.tonal` | Clearer intent, better visual hierarchy |
| `NavigationDrawer` | `NavigationDrawer` | Preferred over old drawer for side navigation |
| `BottomNavigationBar` | `NavigationBar` | Wider touch targets, better mobile affordance |
| `AppBar` with drop shadow | `AppBar` with `surfaceTint` | Elevation via color, not shadow |
| `RaisedButton` | Removed (use `ElevatedButton` or `FilledButton`) | Deprecated in M3 |

**CodeWalk-specific components to audit:**

- Chat message bubbles (ensure consistent corner radius from M3 scale)
- Composer input (refine surface color and border treatment)
- Session list items (update elevation and padding)
- Server settings cards (apply tonal surface colors)
- Popover/tooltip styling (material spec compliance)
- Buttons across Settings, Chat, Files panels

## Feature Execution Plan

### Phase 1: Color System & Theming (Foundation)

**Goals:** Implement dynamic color and extended theme customization.

**Tasks:**

1. **Implement `dynamic_color` integration**
   - Add `DynamicColorBuilder` to `main.dart`
   - Extract wallpaper colors on Android 12+ (graceful fallback to seed)
   - Persist user color choice in `SharedPreferences`
   - Provide theme toggle in Settings → Appearance

2. **Expand color palette options**
   - Create `BrandColor` enum: Codewalk Blue (default), Deep Purple, Ocean Teal, Sunset Orange, Forest Green
   - Add "Custom Color" option with color picker in Settings
   - Store selected brand in `ExperienceSettings`
   - Update `AppTheme` to accept `BrandColor` parameter

3. **Enhance `AppTheme` structure**
   - Extract color generation logic into helper functions
   - Add support for high-contrast mode (semantic color overrides)
   - Implement color harmony validation (accessibility)
   - Document color role mapping

4. **Update `SettingsProvider` and UI**
   - Add `Appearance` section in Settings
   - Options: Dynamic Color (Android only), Brand Color picker, High Contrast toggle
   - Real-time theme preview as user changes colors
   - Reset to default button

**Expected outcome:**
- App respects dynamic color on Android 12+
- User can choose from 5 brand colors + custom picker
- Settings page shows theme customization with live preview

### Phase 2: Responsive Layout & Breakpoints (Structure)

**Goals:** Implement adaptive layouts for different screen sizes.

**Tasks:**

1. **Define responsive breakpoints**
   - Create `lib/presentation/utils/responsive_layout.dart`
   - Constants: compact (0-599), medium (600-839), expanded (840+)
   - Helper class `ResponsiveLayout` with screen size detection
   - Provide `BuildContext` extension: `context.screenSize`, `context.breakpoint`

2. **Implement adaptive shell layouts**
   - **Compact (mobile)**: Keep current chat-first + bottom sidebars
   - **Medium (tablet)**: Side-by-side layout (sessions rail | chat | files drawer)
   - **Expanded (desktop)**: Three-column (sessions | chat | utilities)
   - Smooth transitions when resizing window or rotating device

3. **Refactor sidebar navigation**
   - Current sidebars (Conversations, Files, Utility) should adapt to breakpoint
   - Compact: Bottom navigation or drawer
   - Medium: Left rail + collapsible panels
   - Expanded: Persistent left + right sidebars (resizable)

4. **Update chat message layout**
   - Compact: Full width with small margins
   - Medium: Constrained width (max 600dp) for better readability
   - Expanded: Side-by-side layout with two conversations or detail pane

5. **Compose area responsive design**
   - Compact: Full width at bottom with stacked buttons
   - Medium: Wider input with suggestions popover adaptive positioning
   - Expanded: Optional right-side suggestion panel instead of floating popover

**Expected outcome:**
- App looks intentional on all screen sizes (phone, tablet, desktop)
- Window resize/device rotation triggers smooth layout transitions
- Each breakpoint provides optimized UX without horizontal scrolling

### Phase 3: Component Polish (Refinement)

**Goals:** Update all UI components to Material Design 3 specs.

**Tasks:**

1. **Shape system normalization**
   - Audit all `BorderRadius.circular()` calls
   - Map to M3 shape scale: 4, 8, 12, 16, 20, 24 (cards), 28 (buttons)
   - Create `AppShapes` static class with constants
   - Update `CardTheme`, button themes, dialog shapes, input borders

2. **Button & interactive element updates**
   - Replace deprecated `RaisedButton` calls if any
   - Ensure all buttons have 48x48 minimum touch target
   - Standardize padding: `EdgeInsets.symmetric(horizontal: 24, vertical: 12)` for standard buttons
   - Use `FilledButton` for primary actions, `OutlinedButton` for secondary, `TextButton` for tertiary

3. **Surface & elevation refinement**
   - Replace drop shadow elevations with `surfaceTint` colors
   - Audit AppBar, Cards, Dialogs, BottomSheets
   - Ensure semantic color hierarchy: `surface`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest`

4. **Typography scale application**
   - Ensure text styles follow M3 15-scale naming
   - Apply semantic styles: Headline for titles, Body for content, Label for UI text
   - Check contrast ratios (WCAG AA minimum, AAA preferred)
   - Test with scaled fonts (120%, 150%) for accessibility

5. **Motion & transitions**
   - Add standard M3 motion curves to animate transitions
   - Use `MaterialPageRoute` with appropriate animations
   - Apply 200-300ms durations for standard transitions
   - Smooth FAB morphing between states

**Expected outcome:**
- All UI components visually cohesive and polished
- Consistent spacing, corner radius, and elevation across app
- Accessible touch targets and readable text everywhere

### Phase 4: Accessibility & Testing (Validation)

**Goals:** Ensure app meets WCAG 2.1 AA standards and is tested across devices.

**Tasks:**

1. **Semantic labeling**
   - Add `Semantics` widgets where needed for screen readers
   - Label all interactive elements with meaningful text
   - Use `GestureDetector.onTap` with accessible feedback

2. **Color contrast validation**
   - Use WebAIM contrast checker for all text + background combinations
   - Ensure minimum WCAG AA (4.5:1 normal text, 3:1 large text)
   - Test in both light and dark modes

3. **Touch target sizing**
   - Verify minimum 48x48 dp touch targets
   - Especially for mobile buttons and interactive list items
   - Use `SizedBox` or padding to expand if needed

4. **Device testing**
   - Test on actual devices: phone (compact), tablet (medium), desktop (expanded)
   - Test orientation changes and window resizing
   - Verify dynamic color extraction on Android 12+ device (or emulator)

5. **Visual regression testing**
   - Screenshot tests for key screens in each breakpoint
   - Document expected appearances
   - Compare before/after for polish phase

**Expected outcome:**
- App is WCAG 2.1 AA compliant
- Tested on at least 3 different screen sizes
- No visual regressions from refactoring

## Implementation Strategy

### Discovery Phase

1. **Baseline audit**
   - Document current theme configuration
   - List all UI components and their current styling
   - Identify deprecated or non-M3 patterns
   - Screenshot current app on multiple devices

2. **Research phase**
   - Deep-dive into official M3 documentation
   - Study best practices from Material Design team
   - Review Flutter M3 migration guide
   - Research dynamic color implementation patterns

### Execution Phases (Can be parallelized)

**Phase 1 (Color)** → **Phase 2 (Layout)** → **Phase 3 (Polish)** → **Phase 4 (Testing)**

Or combine with concurrent branches:
- **Branch A**: Dynamic color + brand colors (Phase 1)
- **Branch B**: Responsive breakpoints + adaptive layouts (Phase 2)
- **Branch C**: Component polish (Phase 3 — depends on Phase 1)

### Testing Strategy

1. **Automated**: Widget tests for responsive layout at different breakpoints
2. **Manual**: Visual inspection on emulators/devices
3. **Accessibility**: Semantic label audit + contrast checking
4. **Regression**: Screenshot tests before/after polish phase

### Documentation Updates

- **ADR**: Document dynamic color strategy, responsive layout architecture, M3 adoption decisions
- **CODEBASE.md**: Update theme section with new structures and color system
- **README**: Add screenshots showing Material You customization

## Risk Assessment

**Low Risk:**
- Theming changes are mostly additive (new options, not breaking current)
- Responsive layout improvements are largely UI-only
- Component polish is visual, unlikely to cause functional issues

**Medium Risk:**
- Large refactoring scope across many files
- Layout changes could introduce regressions (especially responsive behavior)
- Interaction between dynamic color and user preferences requires careful testing

**Mitigation:**
- Comprehensive test suite before/after changes
- Feature flag for responsive layout rollout (if needed)
- Incremental commits for each phase with clear rollback points
- User feedback on real devices before release

## Expected Outcomes

✅ **Visual Improvements:**
- Professional, modern appearance aligned with Google design standards
- Consistent spacing, typography, and color application
- Smooth theme transitions (dynamic color, brand selection, density changes)

✅ **UX Enhancements:**
- Optimized layouts for phone, tablet, and desktop
- Improved readability on large screens
- Better use of available space without wasted whitespace
- Seamless orientation/window-size transitions

✅ **Technical Debt Reduction:**
- Centralized shape/elevation/motion definitions
- Removed deprecated Material design patterns
- Improved accessibility compliance
- Easier future maintenance (clear M3 pattern library)

✅ **User Customization:**
- Dynamic color extraction (Android 12+)
- Brand color choices
- High-contrast mode option
- Density preferences (already exists, will be enhanced)

## Acceptance Criteria

- [ ] Dynamic color system working on Android 12+ (graceful fallback elsewhere)
- [ ] User can select from 5 brand colors + custom picker in Settings
- [ ] App displays optimally at compact (phone), medium (tablet), and expanded (desktop) breakpoints
- [ ] All Material Design 3 components visually updated (buttons, cards, dialogs, etc.)
- [ ] No deprecated Material/Flutter APIs in theme code
- [ ] WCAG 2.1 AA contrast and accessibility compliance
- [ ] Tested and validated on at least 3 screen sizes
- [ ] No visual regressions (screenshot tests pass)
- [ ] Documentation updated (CODEBASE.md, ADR)
- [ ] Commits are atomic with clear messages

## Related Files

**Current theme:**
- `lib/presentation/theme/app_theme.dart` — Main theme configuration
- `lib/domain/entities/experience_settings.dart` — User preferences (density, colors)
- `lib/presentation/providers/settings_provider.dart` — Settings state management
- `lib/presentation/pages/settings/` — Settings UI
- `lib/presentation/pages/chat_page.dart` — Main layout (will need responsive updates)
- `lib/main.dart` — App setup (add `DynamicColorBuilder`)

**New files to create:**
- `lib/presentation/utils/responsive_layout.dart` — Breakpoint helpers
- `lib/presentation/theme/app_shapes.dart` — M3 shape scale
- `lib/presentation/theme/brand_colors.dart` — Color palette definitions
- `test/widget/responsive_layout_test.dart` — Responsive behavior tests

## References

**Official Documentation:**
- [Material Design 3 Color System](https://m3.material.io/styles/color/the-color-system/color-roles)
- [Material Design 3 for Flutter](https://m3.material.io/develop/flutter)
- [Flutter Theming Documentation](https://docs.flutter.dev/cookbook/design/themes)
- [Dynamic Color Plugin](https://pub.dev/packages/dynamic_color)
- [Material Design Responsive Layout](https://m3.material.io/foundations/layout/applying-layout)

**Flutter Resources:**
- [Material Design 3 Migration Guide](https://docs.flutter.dev/release/breaking-changes/material-3-migration)
- [ThemeData API Reference](https://api.flutter.dev/flutter/material/ThemeData-class.html)
- [ColorScheme API Reference](https://api.flutter.dev/flutter/material/ColorScheme-class.html)

**Community Guides:**
- [Mastering Material Design 3 Theming](https://www.christianfindlay.com/blog/flutter-mastering-material-design3)
- [Material You Color Implementation](https://dartling.dev/dynamic-theme-color-material-3-you-flutter)

## Notes

- This feature can run in parallel with other development (isolated UI/theme changes)
- Consider breaking into smaller PRs per phase for easier review
- Coordinate with `featM` (Icons migration) as some components may change appearance together
- Keep `useMaterial3: true` flag enabled throughout (already enabled in current code)
- Validate changes on actual devices when possible (especially Android 12+ for dynamic color)
