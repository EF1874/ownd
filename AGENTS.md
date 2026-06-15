# Project Rules

## Git And Release Rules

- All git commit messages must follow Conventional Commits.
- Use `feat:` for new user-facing features, `fix:` for bug fixes, `chore:` for maintenance, `docs:` for documentation, `refactor:` for behavior-preserving code changes, `test:` for tests, `ci:` for CI/CD changes, and `build:` for build-system changes.
- Every version change must produce release notes automatically in the release pipeline.
- GitHub Releases should show a concise user-facing summary first, followed by the automatically generated changelog.

## User-Facing Messages

- All user-facing messages must be understandable to non-technical users.
- Do not expose permission constants, exception class names, endpoint names, ports, stack traces, internal error codes, or raw English infrastructure errors in UI text.
- Permission flows should open the relevant system settings page directly when possible. Do not show custom confirmation prompts if the buttons do not grant the permission themselves.
- Error text must explain what happened in plain language and, when useful, tell the user what to do next.
