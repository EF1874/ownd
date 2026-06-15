# Project Rules

## User-Facing Messages

- All user-facing messages must be understandable to non-technical users.
- Do not expose permission constants, exception class names, endpoint names, ports, stack traces, internal error codes, or raw English infrastructure errors in UI text.
- Permission flows should open the relevant system settings page directly when possible. Do not show custom confirmation prompts if the buttons do not grant the permission themselves.
- Error text must explain what happened in plain language and, when useful, tell the user what to do next.
