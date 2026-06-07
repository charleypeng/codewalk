# CodeWalk Roadmap

## Refactoring

- [x] Aggressive split of oversized Dart files (five large files split into five new part files, test analyzer-budget cleanup) - Commit hash: 8759defc
- [x] Split chat_page_timeline_builder.dart, chat_page.dart, and chat_provider.dart using part clusters - Related commits: ca14f6a 76b5de4 e0cd804 bbcc2e7
- [/] Split chat_remote_datasource.dart - Blocked: class implements 22 abstract REST methods; extensions cannot satisfy abstract overrides. Future direction: mixin-based refactor.
