---
feature: "featR"
spec: |
  OpenCode parity convergence plan for optimistic reconciliation, child-session
  composition, send/stop lifecycle, realtime cleanup, and final convergence
  sweep.
---

## Task List

### Feature 1: featR - OpenCode parity convergence

Description: Compact tracker for featR steps. Visit the referenced `ROADMAP.featR.gX.md` file for the full implementation brief of each step.

- [x] 1.01 Contract Safety Net and Test Harness - Related commits: be52f3e bd578cb - File: `ROADMAP.featR.g1.md`
- [x] 1.02 Tool Call UI Stabilization and Parity - Related commits: 34f7723 6ae21cc 1ae7a82 - File: `ROADMAP.featR.g2.md`
- [x] 1.03 Child Thread Composer Parity - Related commits: b8aee9c ac91163 - File: `ROADMAP.featR.g3.md`
- [x] 1.04 Optimistic Message IDs and Reconciliation - Related commits: 5cabcf0 a066026 - File: `ROADMAP.featR.g4.md`
- [x] 1.05 Send, Stop, and Queue Parity - Related commits: df4d27e a75b1a4 - File: `ROADMAP.featR.g5.md`
- [x] 1.06 Realtime Lifecycle and Pending Interaction Convergence - Related commit: a22b324 - File: `ROADMAP.featR.g6.md`
- [x] 1.07 Ancillary Parity Cleanup and Final Convergence Sweep - Related commits: 14d4c04 aad66fa fa67fd8 00d331b 2b9460a 6b9464f 9db5d9e 2c5802c - File: `ROADMAP.featR.g7.md`
- [x] 1.08 Busy Progress Surface Clarity Follow-up - Related commits: 8a1edfd d79088f c74d93f 19b256c 9d4be70 3e9181a d6bffc0 - File: `n/a (post-featR follow-up)`

### Feature 2: Chat Hydration Loading State

Description: Replace false empty-state greeting during session/project hydration with a soft loading indicator for better UX.

- [x] 2.01 Replace false chat empty-state greeting during hydration with soft loading indicator - Related commits: 9fea9ff 3f7496e

### Feature 3: featS - OpenCode settings parity

Description: Build settings parity with official OpenCode in a contract-safe order. (See ROADMAP.feat01.md for detailed execution plan)

- [x] 3.01 Contract and parity matrix - Commit hash: 0d700be
- [x] 3.02 Settings ownership and sync boundaries - Commit hash: 29f553f
- [x] 3.03 Theme preset parity foundation - Commit hash: dd4a9b5
- [x] 3.04 Theme UX, persistence, and migration safety - Commit hash: 1441f2c
- [x] 3.05 Verified shared settings parity after theme slice - Related commits: e740abe 4c7a411 75b9ce6 a2eed9c e9aed61 6634786 a3cf43b d386ce5 60b8ff3 b798ba4 a250563 d0468bb
- [x] 3.06 Overlapping permissions/shortcuts parity and provenance labeling - Related commits: 1e578a0 39a019a
- [x] 3.07 Regression coverage, behavior/docs handoff, and divergence record - Related commits: 39a019a

### Feature 4: OpenCode Web Theme Parity and Theme-Aware Code Coloring

Description: Official OpenCode Web built-in theme registry parity, theme preset migration to oc-2, and theme-aware markdown/code-viewer colors.

- [x] 4.01 OpenCode Web theme registry parity, oc-2 preset migration, and theme-aware code coloring - Related commits: 84b63fe c4e2c28
- [x] 4.02 Theme registry regeneration maintenance script - Maintenance script (Python + `make theme-sync`/`make theme-sync-check`) that regenerates `lib/presentation/theme/opencode_web_theme_registry.dart` from official OpenCode Web sources with a check mode - Commit hash: 60fd201
