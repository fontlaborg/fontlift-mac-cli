# PRINCIPLES.md

## Core Principles for fontlift-mac-cli

### Scope adherence
- One sentence scope: Install, uninstall, list, and remove fonts on macOS via CLI, supporting both file paths and internal font names.
- No feature creep beyond core font operations.
- No enterprise bloat (analytics, monitoring, complex logging).

### Simplicity first
- Minimal dependencies: Use macOS native frameworks (Core Text, FileManager).
- Single-purpose functions: Each function does one thing well.
- Clear error messages: Tell users exactly what went wrong and how to fix it.

### Safety by default
- Confirm before destructive operations (remove command).
- Validate inputs before acting on them.
- Handle font collections (.ttc/.otc) correctly.
- Prevent deletion of system fonts.

### Build and release
- **Required**: Repository must have `./build.sh` for building the project.
- **Required**: Repository must have `./publish.sh` for releasing/publishing.
- Build scripts should be simple, documented, and work out of the box.

### Testing rigor
- Every function must have tests.
- Test edge cases: invalid files, permissions, missing fonts.
- Integration tests with real font operations.
- Manual verification in Font Book.

### Code quality
- Swift naming conventions (camelCase, descriptive).
- Prefer Swift error handling (`throws`, `Result`) over error codes.
- Keep functions under 20 lines.
- Keep files under 200 lines.
- Maintain `this_file` path comments in all source files.

### macOS native approach
- Use Core Text APIs correctly.
- Respect user vs system font scope.
- Follow macOS conventions for CLI tools.
- Handle permissions gracefully.
