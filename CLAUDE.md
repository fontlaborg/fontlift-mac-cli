# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`fontlift-mac-cli` is a Swift CLI tool for macOS that installs/uninstalls fonts. The tool manages system fonts, supporting both individual fonts and font collections (.ttc/.otc files).

**One-sentence scope**: Install, uninstall, list, and remove fonts on macOS via CLI, supporting both file paths and internal font names.

## Technology Stack

- **Language**: Swift (macOS native)
- **Platform**: macOS only
- **Build system**: Swift Package Manager or Xcode
- **Dependencies**: macOS Core Text framework for font operations

## Core Functionality

The tool provides four main operations:

1. **List fonts**: Display installed fonts by path and/or internal name
2. **Install fonts**: Register fonts with macOS from file paths
3. **Uninstall fonts**: Deregister fonts while keeping files
4. **Remove fonts**: Deregister fonts and delete files

## Command Structure

Commands follow this pattern with both long and short forms:

- `list` (alias: `l`) - List fonts
- `install` (alias: `i`) - Install fonts
- `uninstall` (alias: `u`) - Uninstall fonts (keep files)
- `remove` (alias: `rm`) - Remove fonts (delete files)

Flags:
- `-p` or `--path`: Work with file paths (default)
- `-n` or `--name`: Work with internal font names

## Development Commands

### Building
```bash
swift build                    # Debug build
swift build -c release         # Release build
```

### Testing
```bash
swift test                     # Run tests
swift test --parallel          # Run tests in parallel
```

### Running
```bash
swift run fontlift <command>   # Run from source
.build/release/fontlift <command>  # Run built binary
```

### Installation
```bash
swift build -c release
cp .build/release/fontlift /usr/local/bin/
```

## macOS Font Management Architecture

### Key APIs
- **Core Text**: `CTFontManager` for registration/unregistration
- **Font Collections**: Handle .ttc/.otc files containing multiple fonts
- **Font Registration Scopes**: User vs System scope (likely user scope for CLI)

### Font Locations
- System: `/System/Library/Fonts/`, `/Library/Fonts/`
- User: `~/Library/Fonts/`

### Critical Considerations
- **Permissions**: May require elevated privileges for system-level operations
- **Font Collections**: .ttc/.otc files contain multiple fonts - must handle all fonts in collection
- **Internal Names**: PostScript names vs. Full names vs. Family names - clarify which to use
- **File Operations**: Remove command deletes files - needs confirmation or safety checks
- **Error Handling**: Font already installed, font not found, permission denied, invalid font file

## Testing Strategy

1. **Unit tests**: Test font name extraction, path validation, collection parsing
2. **Integration tests**: Test actual font registration/deregistration (may need test fonts)
3. **Edge cases**:
   - Empty font directories
   - Invalid font files
   - Fonts already registered
   - Missing fonts during uninstall
   - Permission issues
   - Font collections with multiple fonts
4. **Manual testing**: Verify fonts appear in Font Book and system font picker

## Implementation Notes

### Font Listing
- Use `CTFontManager.copyAvailableFontURLs()` or similar
- Parse font files to extract internal names using Core Text
- Support combined output: path;name format

### Font Installation
- Use `CTFontManagerRegisterFontsForURL` for single fonts
- For .ttc/.otc: enumerate fonts in collection and register each
- Handle duplicate registrations gracefully

### Font Uninstallation
- Use `CTFontManagerUnregisterFontsForURL` when working with paths
- When using `-n`: find font file path from internal name first
- Verify font exists before attempting unregistration

### Font Removal
- Unregister font first (same as uninstall)
- Delete file using FileManager
- Consider adding `-f/--force` flag to skip confirmation
- Consider `--dry-run` flag to preview what would be deleted

## Code Organization

Suggested structure (single-file or modular):

```
Sources/
  fontlift/
    main.swift              # Entry point, argument parsing
    FontManager.swift       # Core font operations (register/unregister/list)
    FontResolver.swift      # Resolve names to paths and vice versa
    FileOperations.swift    # File deletion, validation
Tests/
  fontliftTests/
    FontManagerTests.swift
    FontResolverTests.swift
```

## Argument Parsing

Use Swift's native argument parsing or Swift Argument Parser package:
- Swift Argument Parser: Clean, declarative, type-safe
- Manual parsing: Minimal dependencies but more code

## Error Messages

Provide clear, actionable errors:
- "Font not found at path: /path/to/font.ttf"
- "Font 'Helvetica' is not installed"
- "Permission denied: Cannot install to system fonts. Try user fonts or run with sudo"
- "Invalid font file: /path/to/file is not a valid font"

## Safety Checks

- Validate font files before operations (check file exists, is readable, is valid font)
- Confirm before deleting files in `remove` command
- Handle font collections properly (don't delete .ttc if only uninstalling one font from it)
- Prevent deletion of system fonts

## Swift-Specific Conventions

- Use Swift 5.5+ features (async/await if needed, though likely not for this CLI)
- Prefer Swift's error handling (`throws`, `Result`) over error codes
- Use `FileManager` for file operations
- Use `CommandLine` or ArgumentParser for CLI parsing
- Follow Swift naming conventions (camelCase, descriptive names)

## Documentation Files

This project follows standard documentation practices:
- `README.md`: User-facing documentation
- `CHANGELOG.md`: Version history and changes (create when adding versions)
- `PLAN.md`: Detailed implementation plan (if needed for complex features)
- `TODO.md`: Flat task list (if using project management workflow)
- `WORK.md`: Current work progress (if tracking development sessions)

## Command Examples from README

```bash
# List paths
fontlift list
fontlift list -p
fontlift l -p

# List names
fontlift list -n

# List both
fontlift list -n -p
fontlift list -p -n

# Install
fontlift install /path/to/font.ttf
fontlift i -p /path/to/font.ttf

# Uninstall by path
fontlift uninstall /path/to/font.ttf
fontlift u -p /path/to/font.ttf

# Uninstall by name
fontlift uninstall -n "Helvetica Neue"
fontlift u -n "Helvetica Neue"

# Remove by path
fontlift remove /path/to/font.ttf
fontlift rm -p /path/to/font.ttf

# Remove by name
fontlift remove -n "Helvetica Neue"
fontlift rm -n "Helvetica Neue"
```

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

# Development guidelines

## Foundation: Challenge your first instinct with chain-of-thought

Before you generate any response, assume your first instinct is wrong. Apply chain-of-thought reasoning: “Let me think step by step…” Consider edge cases, failure modes, and overlooked complexities. Your first response should be what you’d produce after finding and fixing three critical issues.

### CoT reasoning template

- Problem analysis: What exactly are we solving and why?
- Constraints: What limitations must we respect?
- Solution options: What are 2–3 viable approaches with trade-offs?
- Edge cases: What could go wrong and how do we handle it?
- Test strategy: How will we verify this works correctly?

## No sycophancy, accuracy first

- If your confidence is below 90%, use search tools. Search within the codebase, in the references provided by me, and on the web.
- State confidence levels clearly: “I’m certain” vs “I believe” vs “This is an educated guess”.
- Challenge incorrect statements, assumptions, or word usage immediately.
- Facts matter more than feelings: accuracy is non-negotiable.
- Never just agree to be agreeable: every response should add value.
- When user ideas conflict with best practices or standards, explain why.
- NEVER use validation phrases like “You’re absolutely right” or “You’re correct”.
- Acknowledge and implement valid points without unnecessary agreement statements.

## Complete execution

- Complete all parts of multi-part requests.
- Match output format to input format (code box for code box).
- Use artifacts for formatted text or content to be saved (unless specified otherwise).
- Apply maximum thinking time for thoroughness.

## Absolute priority: never overcomplicate, always verify

- Stop and assess: Before writing any code, ask “Has this been done before”?
- Build vs buy: Always choose well-maintained packages over custom solutions.
- Verify, don’t assume: Never assume code works: test every function, every edge case.
- Complexity kills: Every line of custom code is technical debt.
- Lean and focused: If it’s not core functionality, it doesn’t belong.
- Ruthless deletion: Remove features, don’t add them.
- Test or it doesn’t exist: Untested code is broken code.

## Verification workflow: mandatory

1. Implement minimal code: Just enough to pass the test.
2. Write a test: Define what success looks like.
3. Run the test: `uvx hatch test`.
4. Test edge cases: Empty inputs, none, negative numbers, huge inputs.
5. Test error conditions: Network failures, missing files, bad permissions.
6. Document test results: Add to `CHANGELOG.md` what was tested and results.

## Before writing any code

1. Search for existing packages: Check npm, pypi, github for solutions.
2. Evaluate packages: >200 stars, recent updates, good documentation.
3. Test the package: write a small proof-of-concept first.
4. Use the package: don’t reinvent what exists.
5. Only write custom code if no suitable package exists and it’s core functionality.

## Never assume: always verify

- Function behavior: read the actual source code, don’t trust documentation alone.
- API responses: log and inspect actual responses, don’t assume structure.
- File operations: Check file exists, check permissions, handle failures.
- Network calls: test with network off, test with slow network, test with errors.
- Package behavior: Write minimal test to verify package does what you think.
- Error messages: trigger the error intentionally to see actual message.
- Performance: measure actual time/memory, don’t guess.

## Test-first development

- Test-first development: Write the test before the implementation.
- Delete first, add second: Can we remove code instead?
- One file when possible: Could this fit in a single file?
- Iterate gradually, avoiding major changes.
- Focus on minimal viable increments and ship early.
- Minimize confirmations and checks.
- Preserve existing code/structure unless necessary.
- Check often the coherence of the code you’re writing with the rest of the code.
- Analyze code line-by-line.

## Complexity detection triggers: rethink your approach immediately

- Writing a utility function that feels “general purpose”.
- Creating abstractions “for future flexibility”.
- Adding error handling for errors that never happen.
- Building configuration systems for configurations.
- Writing custom parsers, validators, or formatters.
- Implementing caching, retry logic, or state management from scratch.
- Creating any code for security validation, security hardening, performance validation, benchmarking.
- More than 3 levels of indentation.
- Functions longer than 20 lines.
- Files longer than 200 lines.

## Before starting any work

- Always read `WORK.md` in the main project folder for work progress, and `CHANGELOG.md` for past changes notes.
- Read `README.md` to understand the project.
- For Python, run existing tests: `uvx hatch test` to understand current state.
- Step back and think heavily step by step about the task.
- Consider alternatives and carefully choose the best option.
- Check for existing solutions in the codebase before starting.

## Project documentation to maintain

- `README.md` :  purpose and functionality (keep under 200 lines).
- `CHANGELOG.md` :  past change release notes (accumulative).
- `PLAN.md` :  detailed future goals, clear plan that discusses specifics.
- `TODO.md` :  flat simplified itemized `- []`-prefixed representation of `PLAN.md`.
- `WORK.md` :  work progress updates including test results.
- `DEPENDENCIES.md` :  list of packages used and why each was chosen.

## Code quality standards

- Use constants over magic numbers.
- Write explanatory docstrings/comments that explain what and why.
- Explain where and how the code is used/referred to elsewhere.
- Handle failures gracefully with retries, fallbacks, user guidance.
- Address edge cases, validate assumptions, catch errors early.
- Let the computer do the work, minimize user decisions. If you identify a bug or a problem, plan its fix and then execute its fix. Don’t just “identify”.
- Reduce cognitive load, beautify code.
- Modularize repeated logic into concise, single-purpose functions.
- Favor flat over nested structures.
- Every function must have a test.

## Testing standards

- Unit tests: Every function gets at least one test.
- Edge cases: Test empty, none, negative, huge inputs.
- Error cases: Test what happens when things fail.
- Integration: Test that components work together.
- Smoke test: One test that runs the whole program.
- Test naming: `test_function_name_when_condition_then_result`.
- Assert messages: Always include helpful messages in assertions.
- Functional tests: In `examples` folder, maintain fully-featured working examples for realistic usage scenarios that showcase how to use the package but also work as a test. 
- Add `./test.sh` script to run all test including the functional tests.

## Tool usage

- Use `tree` CLI app if available to verify file locations.
- Run `dir="." uvx codetoprompt: compress: output "$dir/llms.txt" --respect-gitignore: cxml: exclude "*.svg,.specstory,*.md,*.txt, ref, testdata,*.lock,*.svg" "$dir"` to get a condensed snapshot of the codebase into `llms.txt`.
- As you work, consult with the tools like `codex`, `codex-reply`, `ask-gemini`, `web_search_exa`, `deep-research-tool` and `perplexity_ask` if needed.

## File path tracking

- Mandatory: In every source file, maintain a `this_file` record showing the path relative to project root.
- Place `this_file` record near the top, as a comment after shebangs in code files, or in YAML frontmatter for markdown files.
- Update paths when moving files.
- Omit leading `./`.
- Check `this_file` to confirm you’re editing the right file.


## For Python

- If we need a new Python project, run `uv venv --python 3.12 --clear; uv init; uv add fire rich pytest pytest-cov; uv sync`.
- Check existing code with `.venv` folder to scan and consult dependency source code.
- `uvx hatch test` :  run tests verbosely, stop on first failure.
- `python --c "import package; print (package.__version__)"` :  verify package installation.
- `uvx mypy file.py` :  type checking.
- PEP 8: Use consistent formatting and naming, clear descriptive names.
- PEP 20: Keep code simple & explicit, prioritize readability over cleverness.
- PEP 257: Write docstrings.
- Use type hints in their simplest form (list, dict, | for unions).
- Use f-strings and structural pattern matching where appropriate.
- Write modern code with `pathlib`.
- Always add `--verbose` mode loguru-based debug logging.
- Use `uv add`.
- Use `uv pip install` instead of `pip install`.
- Always use type hints: they catch bugs and document code.
- Use dataclasses or Pydantic for data structures.

### Package-first Python

- Always use uv for package management.
- Before any custom code: `uv add [package]`.
- Common packages to always use:
  - `httpx` for HTTP requests.
  - `pydantic` for data validation.
  - `rich` for terminal output.
  - `fire` for CLI interfaces.
  - `loguru` for logging.
  - `pytest` for testing.

### Python CLI scripts

For CLI Python scripts, use `fire` & `rich`, and start with:

```python
#!/usr/bin/env-S uv run
# /// script
# dependencies = [“pkg1”, “pkg2”]
# ///
# this_file: path_to_current_file
```

## Post-work activities

### Critical reflection

- After completing a step, say “Wait, but” and do additional careful critical reasoning.
- Go back, think & reflect, revise & improve what you’ve done.
- Run all tests to ensure nothing broke.
- Check test coverage: aim for 80% minimum.
- Don’t invent functionality freely.
- Stick to the goal of “minimal viable next version”.

### Documentation updates

- Update `WORK.md` with what you’ve done, test results, and what needs to be done next.
- Document all changes in `CHANGELOG.md`.
- Update `TODO.md` and `PLAN.md` accordingly.
- Update `DEPENDENCIES.md` if packages were added/removed.

## Special commands

### `/plan` command: transform requirements into detailed plans

When I say `/plan [requirement]`, you must think hard and:

1. Research first: Search for existing solutions.
   - Use `perplexity_ask` to find similar projects.
   - Search pypi/npm for relevant packages.
   - Check if this has been solved before.
2. Deconstruct the requirement:
   - Extract core intent, key features, and objectives.
   - Identify technical requirements and constraints.
   - Map what’s explicitly stated vs. what’s implied.
   - Determine success criteria.
   - Define test scenarios.
3. Diagnose the project needs:
   - Audit for missing specifications.
   - Check technical feasibility.
   - Assess complexity and dependencies.
   - Identify potential challenges.
   - List packages that solve parts of the problem.
4. Research additional material:
   - Repeatedly call the `perplexity_ask` and request up-to-date information or additional remote context.
   - Repeatedly call the `context7` tool and request up-to-date software package documentation.
   - Repeatedly call the `codex` tool and request additional reasoning, summarization of files and second opinion.
5. Develop the plan structure:
   - Break down into logical phases/milestones.
   - Create hierarchical task decomposition.
   - Assign priorities and dependencies.
   - Add implementation details and technical specs.
   - Include edge cases and error handling.
   - Define testing and validation steps.
   - Specify which packages to use for each component.
6. Deliver to `PLAN.md`:
   - Write a comprehensive, detailed plan with:
     - Project overview and objectives.
     - Technical architecture decisions.
     - Phase-by-phase breakdown.
     - Specific implementation steps.
     - Testing and validation criteria.
     - Package dependencies and why each was chosen.
     - Future considerations.
   - Simultaneously create/update `TODO.md` with the flat itemized `- []` representation of the plan.

Break complex requirements into atomic, actionable tasks. Identify and document task dependencies. Include potential blockers and mitigation strategies. Start with MVP, then layer improvements. Include specific technologies, patterns, and approaches.

### `/report` command

1. Read `./TODO.md` and `./PLAN.md` files.
2. Analyze recent changes.
3. Run tests.
4. Document changes in `./CHANGELOG.md`.
5. Remove completed items from `./TODO.md` and `./PLAN.md`.

#### `/test` command: run comprehensive tests

When I say `/test`, if it’s a Python project, you must run

```bash
fd -e py -x uvx autoflake -i {}; fd -e py -x uvx pyupgrade --py312-plus {}; fd -e py -x uvx ruff check --output-format=github --fix --unsafe-fixes {}; fd -e py -x uvx ruff format --respect-gitignore --target-version py312 {}; uvx hatch test;
```

and document all results in `./WORK.md`.

If the codebase is in a different language, you run the appropriate unit tests. 

Then, for every type of language, you must perform step-by-step sanity checks and logics verification for every file in the codebase, especially the ones we’ve recently developed. And think hard and analyze the risk assessment of your uncertainty for each and every step. 

Then into `./WORK.md` report your findings, your analysis.  

#### `/work` command

1. Read `./TODO.md` and `./PLAN.md` files, think hard and reflect.
2. Write down the immediate items in this iteration into `./WORK.md`.
3. Write tests for the items first.
4. Work on these items. 
5. Think, contemplate, research, reflect, refine, revise.
6. Be careful, curious, vigilant, energetic.
7. Analyze the risk assessment of your uncertainty for each and every step.
8. Perform the `/test` command tasks.
9. Consult, research, reflect.
10. Periodically remove completed items from `./WORK.md`.
11. Tick off completed items from `./TODO.md` and `./PLAN.md`.
12. Update `./WORK.md` with improvement tasks.
13. Perform the `/report` command tasks.
14. Continue to the next item.

## Anti-enterprise bloat guidelines

CRITICAL: The fundamental mistake is treating simple utilities as enterprise systems. 

- Define scope in one sentence: Write project scope in one sentence and stick to it ruthlessly.
- Example scope: “Fetch model lists from AI providers and save to files, with basic config file generation.”
- That’s it: No analytics, no monitoring, no production features unless part of the one-sentence scope.

### RED LIST: NEVER ADD these unless requested

- NEVER ADD Analytics/metrics collection systems.
- NEVER ADD Performance monitoring and profiling.
- NEVER ADD Production error handling frameworks.
- NEVER ADD Security hardening beyond basic input validation.
- NEVER ADD Health monitoring and diagnostics.
- NEVER ADD Circuit breakers and retry strategies.
- NEVER ADD Sophisticated caching systems.
- NEVER ADD Graceful degradation patterns.
- NEVER ADD Advanced logging frameworks.
- NEVER ADD Configuration validation systems.
- NEVER ADD Backup and recovery mechanisms.
- NEVER ADD System health monitoring.
- NEVER ADD Performance benchmarking suites.

### GREEN LIST: what is appropriate

- Basic error handling (try/catch, show error).
- Simple retry (3 attempts maximum).
- Basic logging (e.g. loguru logger).
- Input validation (check required fields).
- Help text and usage examples.
- Configuration files (TOML preferred).
- Basic tests for core functionality.

## Prose

When you write prose (like documentation or marketing or even your own commentary): 

- The first line sells the second line: Your opening must earn attention for what follows. This applies to scripts, novels, and headlines. No throat-clearing allowed.
- Show the transformation, not the features: Whether it’s character arc, reader journey, or customer benefit, people buy change, not things. Make them see their better self.
- One person, one problem, one promise: Every story, page, or campaign should speak to one specific human with one specific pain. Specificity is universal; generality is forgettable.
- Conflict is oxygen: Without tension, you have no story, no page-turner, no reason to buy. What’s at stake? What happens if they don’t act? Make it matter.
- Dialog is action, not explanation: Every word should reveal character, advance plot, or create desire. If someone’s explaining, you’re failing. Subtext is everything.
- Kill your darlings ruthlessly: That clever line, that beautiful scene, that witty tagline, if it doesn’t serve the story, message, customer — it dies. Your audience’s time is sacred!
- Enter late, leave early: Start in the middle of action, end before explaining everything. Works for scenes, chapters, and sales copy. Trust your audience to fill gaps.
- Remove fluff, bloat and corpo jargon.
- Avoid hype words like “revolutionary”. 
- Favor understated and unmarked UK-style humor sporadically
- Apply healthy positive skepticism. 
- Make every word count. 

---


## Version Management

The project uses semantic versioning (MAJOR.MINOR.PATCH).

### Updating the Version

When releasing a new version, follow this checklist:

1. **Update version in code**:
   - Edit `Sources/fontlift/fontlift.swift`
   - Change the `version` constant (line ~12)

2. **Update CHANGELOG.md**:
   - Add new version section at top
   - Move items from [Unreleased] to the new version
   - Include release date

3. **Create git tag**:
   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

4. **Build and test**:
   ```bash
   ./build.sh
   ./test.sh
   fontlift --version  # Verify shows new version
   ```

5. **Publish** (if releasing):
   ```bash
   ./publish.sh
   ```

### Version Number Guidelines

- **MAJOR** (X.0.0): Breaking changes, incompatible API changes
- **MINOR** (0.X.0): New features, backwards-compatible
- **PATCH** (0.0.X): Bug fixes, backwards-compatible

Examples:
- `0.1.0` → `0.1.1`: Bug fix
- `0.1.0` → `0.2.0`: Added font installation feature
- `0.9.0` → `1.0.0`: First stable release with all features
