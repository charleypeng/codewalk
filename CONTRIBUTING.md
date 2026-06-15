# Contributing to CodeWalk

Thanks for contributing. This project keeps changes small, testable, and releasable.

## Workflow

1. Create a branch from `main`.
2. Run local validation:
   - `make check`
   - `HEY_CAPTION="specific caption" make android` only when an APK artifact is needed
3. Open a PR with:
   - problem statement
   - change summary
   - test evidence (`flutter test`, screenshots, or logs)

## Commit Convention

Use Conventional Commits:

- `feat:` new behavior
- `fix:` bug fix
- `docs:` documentation only
- `refactor:` non-behavioral code change
- `test:` test-only changes
- `chore:` maintenance

## Quality Gates

- Keep generated code committed (`*.g.dart`).
- Do not introduce new analyzer debt beyond current budget.
- Keep coverage above the repository threshold.
- Use `make check` and `make android` as separate gates; do not rely on a combined local target as normal validation.

## Coding Guidelines

- Avoid `print`; use `AppLogger`.
- Keep public APIs backward compatible unless explicitly planned.
- Prefer small focused PRs over large multi-topic changes.

## Reporting Issues

Include:

- platform and OS version
- Flutter and Dart versions
- reproducible steps
- expected vs actual behavior
- logs or screenshots when available
