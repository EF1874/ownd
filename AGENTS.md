# Project Rules

## Git And Release Rules

- All git commit messages must follow Conventional Commits.
- Use `feat:` for new user-facing features, `fix:` for bug fixes, `chore:` for maintenance, `docs:` for documentation, `refactor:` for behavior-preserving code changes, `test:` for tests, `ci:` for CI/CD changes, and `build:` for build-system changes.
- Every app version change should include committed release notes before the version bump is pushed.
- Use `docs/releases/vX.Y.Z.md` for the GitHub Release body and `docs/releases/vX.Y.Z.app.txt` for the in-app update popup text.
- The release pipeline must prefer committed release notes when present, then fall back to automatic commit-message release notes.
- Keep the manual App release-notes update workflow available for post-release text fixes.
- GitHub Releases should show a concise user-facing summary first, followed by the detailed changelog.

## User-Facing Messages

- All user-facing messages must be understandable to non-technical users.
- Do not expose permission constants, exception class names, endpoint names, ports, stack traces, internal error codes, or raw English infrastructure errors in UI text.
- Permission flows should open the relevant system settings page directly when possible. Do not show custom confirmation prompts if the buttons do not grant the permission themselves.
- Error text must explain what happened in plain language and, when useful, tell the user what to do next.

## UI And Product Rules

- New UI must follow existing project patterns and nearby examples before adding new styles or controls.
- Default text must use regular font weight. Use bold only for explicit titles, selected states, or existing matching examples.
- If nearby code conflicts with the project's main style, call it out and follow the main style instead of copying the inconsistency.
