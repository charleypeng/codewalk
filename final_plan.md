# CodeWalk — LaTeX Math Rendering Execution Plan

**Feature**: #7 — LaTeX/Math Rendering
**Phase**: 2 — Rich Chat Output and Mobile Accessibility
**Status**: [ ] Not started
**Priority**: P2
**Source**: `feature_gap_tracker.md` via `final_plan/07_latex_rendering.md`

---

## Original User Request (verbatim)

Plan the next pending recommend feature of @feature_gap_tracker.md using git multi-step. Even though the plan seems complete, whenever you feel it's necessary, confirm or investigate the execution—especially if you aren't sure how to resolve a specific issue.
It is not necessary to generate the build or send it via Android. When all steps are completed, release a minor version. While the CI is running, take the opportunity to update the file feature_gap_tracker.md and docs. In the end, please let me know what changes I should look for in the new version and where to find them.

---

## Objective

Add LaTeX math rendering to CodeWalk chat messages. Assistant messages containing inline `$...$` or block `$$...$$` math expressions should render as visual typeset math, with styled raw-source fallback on parse failure, while avoiding false positives on currency values (`$5`), shell variables (`$PATH`), and code fences.

---

## Why This Plan

- **ADR-023 compliance**: Official OpenCode Web uses KaTeX with `$...$` / `$$...$$` delimiters and `throwOnError: false`. CodeWalk must match this contract.
- **Architectural consistency**: CodeWalk already injects custom `InlineSyntax` and `MarkdownElementBuilder` for file paths and Mermaid diagrams. Math rendering follows the same pattern — custom syntax detection + dedicated renderer widget.
- **Pure Dart, all platforms**: `flutter_math_fork` (KaTeX port, pure Dart) runs on Linux desktop, macOS, Windows, Android, iOS, and Web — no WebView dependency.
- **Avoid `flutter_markdown_latex` bridge**: Its `LatexInlineSyntax` uses naive `$...$` matching that false-positives on currency and shell text. Implementing our own syntax gives us a false-positive guard and avoids an extra dependency bridge that may conflict with `flutter_markdown_plus`.

---

## Scope

### In scope

- Render inline `$...$` math and block `$$...$$` math in assistant chat messages.
- Parse/render via pure-Dart KaTeX port (`flutter_math_fork`).
- Styled raw-source fallback on parse/render failure.
- False-positive guard: require at least one LaTeX command token inside delimiters.
- Exclude `$` inside code fences and inline code (naturally via markdown syntax ordering).
- Horizontal scroll for wide formulas; no vertical scroll lock.
- Responsive sizing for compact/mobile.
- i18n labels for the fallback header.
- Tests: math syntax detection, false-positive rejection, widget rendering, fallback, markdown integration non-regression (Mermaid, code blocks, file paths, links, search highlight).
- Feature flag (behavior toggle) to enable/disable math rendering, default enabled.

### Out of scope

- `\(...\)` / `\[...\]` delimiters (can be added later as a preprocessor).
- Math input/composition in the user composer.
- Math rendering in the file viewer.
- LaTeX rendering in exported sessions.

---

## Research Summary

| Topic | Finding |
|-------|---------|
| Official OpenCode | Uses KaTeX with `$...$`/`$$...$` delimiters, `throwOnError: false`, excludes code blocks, custom regex post-render pass |
| OpenChamber (community) | Added LaTeX rendering in v1.9.6 |
| Flutter packages | `flutter_math_fork` (pure Dart, all platforms, production-proven in AppFlowy) is the best choice |
| False-positive risk | `$5`, `$0.02/GB`, `$PATH` — mitigated by requiring LaTeX command inside delimiters |
| `flutter_markdown_latex` | Uses naive `$...$` without false-positive guard; not recommended |

**Recommendation**: Use `flutter_math_fork` directly with custom markdown syntax/builders, matching the Mermaid pattern exactly.

---

## Current Context

- **Version**: `1.82.0` (minor release → `1.83.0`)
- **Branch**: `main` (clean except uncommitted `feature_gap_tracker.md` Phase 1 checkbox fix)
- **Existing patterns**: `chat_message_text_part.dart` injects custom `InlineSyntax` (`FilePathSyntax`) and custom `MarkdownElementBuilder` (`_MarkdownCodeBlockTapBuilder` routes `language == 'mermaid'` to `MermaidDiagramWidget`). Math will follow the identical architecture.
- **Missing**: `ai-docs/opencode_models.md` (referenced by ADR-023 but absent) — not a blocker for this feature.
- **Uncommitted tracker change**: Phase 1 completion checkboxes already set to `[x]` in `feature_gap_tracker.md`. Implementation must preserve this.

---

## Constraints, Preferences, and Biases to Preserve

- **ADR-023 compliance must be verified**: match OpenCode's `$...$/$$...$$` delimiters and `throwOnError: false` semantics.
- **Mobile-first UI**: math widget must work on compact viewports with horizontal scroll.
- **No passive scroll regressions**: math rendering must not fight `_ScrollOwner`.
- **No file mutations without explicit user action**: math is read-only rendering.
- **Existing markdown pipeline must not regress**: Mermaid, code blocks, file paths, inline code taps, links, search highlight.
- **Large-message truncation guard** (`_maxMarkdownCharsForRichRender = 64000`) must still apply.

---

## Assumptions to Validate

1. **`flutter_math_fork` renders on all target platforms**
   - Validation: `flutter test` on Linux (the build host), CI covers Android.
   - If false: fall back to `flutter_tex` Math2SVG widget (but lose Linux desktop).

2. **`$...$` false-positive guard is sufficient**
   - Validation: Unit tests with `$5`, `$PATH`, `$0.02/GB`, `$variable`, `$$block math$$`.
   - If false: add stronger heuristic (e.g., require operator `+ = - * /` or Greek letter).

3. **Flutter_math_fork throws on invalid LaTeX**
   - Validation: Test with invalid source and verify fallback renders.
   - If not: wrap in try/catch and show fallback on any exception.

---

## Options Considered

- **Accepted**: Custom `InlineSyntax` + `MarkdownElementBuilder` using `flutter_math_fork`
  - Matches existing Mermaid/file-path architecture exactly.
  - Gives full control over false-positive suppression.

- **Rejected**: `flutter_markdown_latex` bridge package
  - Naive `$...$` matching without false-positive guard.
  - Extra dependency that may conflict with `flutter_markdown_plus`.

- **Rejected**: `flutter_tex` with Math2SVG or WebView
  - No Linux desktop support on WebView path.
  - Heavier bundle, slower render.

- **Rejected**: `fat_markdown` (2026)
  - Zero stars, too new for production.

---

## Execution Plan

- [ ] Step 1: Add `flutter_math_fork` dependency and math parser utilities
  - Why now: Dependency must be available before any widget/syntax code can compile.
  - Validation: `flutter pub get` succeeds; unit tests for math syntax detection pass.

- [ ] Step 2: Create responsive `MathExpressionWidget` with fallback
  - Why now: Renderer widget must exist before wiring into chat markdown.
  - Validation: Widget tests for inline, block, fallback, and mobile width.

- [ ] Step 3: Wire math syntax/builders into chat markdown pipeline
  - Why now: Integration point — math appears in real chat messages.
  - Validation: Chat message widget tests for math, currency, shell, code fences, Mermaid non-regression.

- [ ] Step 4: Add i18n labels and behavior spec updates
  - Why now: UI strings and behavior docs are required before final quality gate.
  - Validation: `make check` passes; `BEHAVIOR.md` entries are accurate.

- [ ] Step 5: Final quality gate — test, lint, desloppify, reviewer loop
  - Why now: All code is integrated; final validation before release.
  - Validation: `make check` clean, desloppify scan clean, reviewers approve.

- [ ] Step 6: Release minor version (`make release V=minor`)
  - Why now: Feature is complete and validated.
  - Validation: CI/release workflow passes.

- [ ] Step 7: Post-release docs sync (feature_gap_tracker, CODEBASE, ROADMAP, README)
  - Why now: While CI runs, update tracking docs.
  - Validation: Docs reflect v1.83.0 reality.

---

## Do

- Follow Mermaid rendering pattern exactly (custom syntax → builder → widget).
- Use `flutter_math_fork`'s `Math.tex()` widget.
- Add false-positive guard requiring LaTeX command tokens.
- Add behavior toggle in settings for math rendering.
- Run `make check` before each commit.
- Run `desloppify scan --path lib --profile objective` before each commit.
- Use anchored plan commit protocol (`plan:` + `AGENT_PLAN_ANCHOR`).

## Do Not

- Use `flutter_markdown_latex` or any WebView-based math package.
- Add `\(...\)` / `\[...\]` support in this iteration.
- Break Mermaid rendering, code blocks, file path taps, link taps, or search highlight.
- Introduce scroll lock from math widget touch events.
- Commit before `make check` passes.
- Run `make android` (ARM64 host, and user explicitly excluded it).
- Overwrite the existing uncommitted `feature_gap_tracker.md` Phase 1 checkbox fix.

---

## References

- `final_plan/07_latex_rendering.md` — Feature #7 brief
- `lib/presentation/widgets/mermaid_diagram_widget.dart` — pattern to follow
- `lib/presentation/widgets/chat_message/chat_message_text_part.dart` — integration point
- `lib/l10n/app_en.arb` — i18n source
- Official OpenCode: https://github.com/anomalyco/opencode/blob/dev/packages/ui/src/context/marked.tsx
- `flutter_math_fork`: https://pub.dev/packages/flutter_math_fork
- ADR-023 (lines 958–1080 of `ADR.md`)

---

## Risks and Dependencies

- **Risk**: `flutter_math_fork` may have subtle rendering differences vs official KaTeX
  - Mitigation: Use `throwOnError: false` equivalent; fallback to raw source on any failure.

- **Risk**: False-positive guard may be too strict or too loose
  - Mitigation: Comprehensive unit tests; toggle to disable math rendering if needed.

- **Dependency**: `flutter_math_fork` must support all CodeWalk platforms
  - Mitigation: Pure Dart (no native code) — platform support is guaranteed.

---

## Handoff Notes

- The markdown syntax must be added to the `inlineSyntaxes` list in `_buildTextPart`, before `FilePathSyntax` so math is processed first (math delimiters precede file path detection).
- The math builder must be added to the `builders` map alongside the existing `pre`, `code`, and `filepath` builders.
- Mermaid routing (`language == 'mermaid'`) must not be affected — it lives in `_MarkdownCodeBlockTapBuilder` which is a block element; math blocks are separate.
- The existing uncommitted change in `feature_gap_tracker.md` (Phase 1 checkboxes) must be preserved.

---

## Definition of Done

- [ ] `make check` passes with zero errors.
- [ ] Math rendering toggle appears in settings, defaults to enabled.
- [ ] `$$...$$` block math renders as typeset math.
- [ ] `$...$` inline math renders as typeset math.
- [ ] Invalid/unparseable math shows styled raw-source fallback.
- [ ] `$5`, `$PATH`, `$0.02/GB`, `$variable` are NOT rendered as math.
- [ ] Code fences containing `$` are NOT rendered as math.
- [ ] Mermaid diagrams, code blocks, file path taps, link taps, search highlight all work.
- [ ] Horizontal scroll works for wide formulas; vertical scroll does not lock.
- [ ] `feature_gap_tracker.md` marks Feature #7 as done.
- [ ] `BEHAVIOR.md` documents math rendering behavior.
- [ ] `CODEBASE.md` updated (via codemapper agent).
- [ ] `README.md` highlights updated.
- [ ] `ROADMAP.md` updated (via roadmapper agent).
- [ ] Release `v1.83.0` tagged and CI passed.
