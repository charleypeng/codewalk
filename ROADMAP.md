# CodeWalk Roadmap

## Features

- [x] 10 OpenChamber quota providers parity (Issue #45) - Commit hash: [pending]
- [x] OpenCode v1.17 compatibility updates - Related commits: 2bf8931 33e66b6
- [x] OpenChamber drift-watch compatibility updates for v1.11-v1.12 - Related commits: 5742865 9597f93 10fa428 - All checks passed: focused tests, make check, reviewer loop, desloppify objective scan

## Refactoring

- [x] Aggressive split of oversized Dart files (five large files split into five new part files, test analyzer-budget cleanup) - Commit hash: 8759defc
- [x] Split chat_page_timeline_builder.dart, chat_page.dart, and chat_provider.dart using part clusters - Related commits: ca14f6a 76b5de4 e0cd804 bbcc2e7
- [/] Split chat_remote_datasource.dart - Blocked: class implements 22 abstract REST methods; extensions cannot satisfy abstract overrides. Future direction: mixin-based refactor.
