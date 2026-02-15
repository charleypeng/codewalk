---
feature: "featM - Icons to Material Symbols Migration"
created_on: "2026-02-14"
status: "pending"
priority: "low (technical debt)"
isolation: "high - can run anytime independently"
---

## Overview

Migrate all icon references from Flutter's built-in `Icons.*` class to Google's modern `Symbols.*` class from the `material_symbols_icons` package. This migration ensures access to the complete Material Symbols icon set (3,800+ icons) and aligns with Google's current design system direction.

## Context

- **Current state**: ~283 uses of `Icons.*` across 111 files
- **Trigger**: User selected `bottom_panel_close` icon from fonts.google.com/icons, which only exists in Material Symbols (not in built-in Material Icons)
- **Package already added**: `material_symbols_icons: ^4.2906.0` is already in `pubspec.yaml`

## Research Summary

### Material Icons vs Material Symbols

| Aspect | Material Icons (`Icons.*`) | Material Symbols (`Symbols.*`) |
|--------|---------------------------|-------------------------------|
| **Status** | Legacy set, no longer updated | Current set, actively maintained |
| **Technology** | Traditional font files per style | Variable font (single file) |
| **Icon count** | ~2,000 icons | ~3,800+ icons |
| **Flexibility** | Static styles only | Variable axes (fill, weight, grade, optical size) |
| **Package** | Built into Flutter | Requires `material_symbols_icons` package |
| **Future** | Deprecated direction | Flutter native support planned |

### Performance Considerations

**Tree Shaking:**
- Both icon sets support tree shaking during release builds
- Material Icons: full font ~1.6 MB → <20 KB after tree shaking (99% reduction)
- Material Symbols: default ~295 KB payload for all 3,800+ icons, can be optimized further

**Bundle Size Impact:**
- Adding `material_symbols_icons` package increases initial bundle size
- Tree shaking minimizes final impact
- Variable font technology is more efficient than multiple style variants

**Migration Cost:**
- One-time refactor effort
- No runtime performance difference
- Better long-term maintenance (actively maintained set)

### Package Compatibility

- The `material_symbols_icons` package is designed to be fully compatible with Flutter's planned native Symbols implementation
- Once Flutter adds native support, only the import statement needs removal
- Package uses GitHub CI to stay in-sync with latest Material Symbols definitions

## Migration Strategy

### Phase 1: Discovery & Mapping

1. **Extract all Icon usages**
   ```bash
   # Find all Icons.* references with context
   grep -rn "Icons\." lib/ --include="*.dart" -A 1 -B 1 > /tmp/icons_audit.txt
   ```

2. **Generate mapping candidates**
   - Common patterns that map 1:1 (e.g., `Icons.add` → `Symbols.add`)
   - Icons that need manual research on fonts.google.com/icons
   - Icons that may not have direct equivalents

3. **Create mapping file**
   - Document all `Icons.X → Symbols.Y` conversions
   - Note any visual differences or required manual review

### Phase 2: Automated Replacement

1. **Import statement updates**
   ```dart
   // Remove or keep Icons import if still needed temporarily
   import 'package:flutter/material.dart';

   // Add Symbols import
   import 'package:material_symbols_icons/symbols.dart';
   ```

2. **Bulk replace common patterns**
   - Use sed/awk for straightforward 1:1 mappings
   - Process file-by-file to track changes

3. **Handle variants**
   ```dart
   // Old
   Icons.home_rounded
   Icons.home_outlined
   Icons.home_sharp

   // New - Material Symbols use suffixes
   Symbols.home           // default (outlined)
   Symbols.home_rounded
   Symbols.home_sharp
   ```

### Phase 3: Manual Review & Testing

1. **Visual regression check**
   - Build app and verify all icons render correctly
   - Check for any missing or mismatched icons
   - Validate icon sizes and alignment

2. **Test all screens**
   - Session list
   - Chat page
   - Settings
   - Files panel
   - Composer
   - All popups/dialogs

3. **Handle edge cases**
   - Icons that don't have Symbols equivalents → find closest match or keep original
   - Custom icon sizes or colors → verify they still work
   - Conditional icon rendering → test all branches

### Phase 4: Cleanup

1. **Remove Icons import** where fully replaced
2. **Update documentation** if any icon usage is documented
3. **Commit atomically** with descriptive message

## Execution Checklist

- [ ] **Discovery Phase**
  - [ ] Run comprehensive grep to find all `Icons.*` usages
  - [ ] Categorize icons by replacement complexity (direct/manual/edge-case)
  - [ ] Create mapping CSV/JSON file for reference

- [ ] **Research Phase**
  - [ ] For top 50 most-used icons, verify Symbols equivalents exist
  - [ ] Identify icons without direct equivalents
  - [ ] Document special cases (variants, custom styling, etc.)

- [ ] **Implementation Phase**
  - [ ] Add `Symbols` import to all files using icons
  - [ ] Replace direct mappings programmatically (sed/script)
  - [ ] Replace manual mappings file-by-file
  - [ ] Handle edge cases individually

- [ ] **Testing Phase**
  - [ ] Build app in debug mode
  - [ ] Visual inspection of all major screens
  - [ ] Test both mobile and desktop layouts
  - [ ] Test light/dark themes
  - [ ] Verify density settings (dense/normal/spacious)

- [ ] **Cleanup Phase**
  - [ ] Remove unused `Icons` imports
  - [ ] Update CODEBASE.md with new icon convention
  - [ ] Create ADR documenting the migration decision
  - [ ] Commit with detailed message listing affected files

## Risk Assessment

**Low Risk:**
- Icons are purely visual, no functional impact
- Tree shaking prevents bundle bloat
- Can be rolled back easily if issues arise

**Medium Risk:**
- ~111 files to modify - potential for typos/mistakes
- Visual differences between Icons and Symbols versions
- Some icons might not have exact equivalents

**Mitigation:**
- Thorough visual testing before committing
- Keep Icons import temporarily for fallbacks
- Process in batches with frequent testing
- Use automated tooling for bulk replacements

## Expected Outcomes

✅ **Benefits:**
- Access to full Material Symbols icon set (3,800+ vs 2,000)
- Alignment with Google's current design direction
- Future-proof when Flutter adds native support
- Consistency with icons selected from fonts.google.com/icons

⚠️ **Trade-offs:**
- One-time migration effort (~1-2 hours)
- Slightly larger package dependency (already added)
- Need to retrain muscle memory for icon names

## Related Files

- `lib/presentation/pages/chat_page.dart` — already uses `Symbols.bottom_panel_close`
- All files in `lib/presentation/` — likely contain icon usage
- `pubspec.yaml` — already has `material_symbols_icons: ^4.2906.0`

## References

**Official Documentation:**
- [Material Symbols Icons Package](https://pub.dev/packages/material_symbols_icons)
- [Material Symbols Guide (Google)](https://developers.google.com/fonts/docs/material_symbols)
- [Material Symbols Browser](https://fonts.google.com/icons)

**Technical Details:**
- [Package Documentation](https://pub.dev/documentation/material_symbols_icons/latest/)
- [Flutter Icons Class](https://api.flutter.dev/flutter/material/Icons-class.html)
- [Material Icons vs Symbols Comparison](https://deepwiki.com/google/material-design-icons/1.2-material-icons-vs.-material-symbols)

**Performance & Tree Shaking:**
- [Flutter Tree Shaking Guide](https://www.technaureus.com/blog-detail/flutter-tree-shaking-and-bundle-optimization-guide)
- [Icon Tree Shaking PR](https://github.com/flutter/flutter/pull/55417)

## Notes

- This is an isolated track that can run independently of other features
- Consider running this after `featH` is complete to avoid conflicts
- Migration can be done incrementally (screen-by-screen) if preferred
- Keep `Icons` fallback for truly missing Symbols until verified
