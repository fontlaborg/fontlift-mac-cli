# DEPENDENCIES.md
<!-- this_file: DEPENDENCIES.md -->

This document lists all external dependencies and explains why each was chosen.

## Runtime Dependencies

### Swift Argument Parser
- **Version**: 1.6.2
- **Repository**: https://github.com/apple/swift-argument-parser
- **License**: Apache 2.0
- **Stars**: 3.3k+
- **Maintenance**: Active (Apple maintained)

**Why chosen**:
- Type-safe, declarative CLI argument parsing
- Official Apple package with excellent support
- Automatic help generation and validation
- Clean, modern Swift API
- Reduces boilerplate significantly vs manual parsing
- Well-documented with extensive examples
- Zero additional dependencies
- Perfect fit for our use case (CLI with subcommands)

**Alternative considered**:
- Manual argument parsing using CommandLine.arguments
  - **Pros**: No dependencies, full control
  - **Cons**: More code, more bugs, no help generation, no validation
  - **Decision**: ArgumentParser provides better quality and maintainability

## Development Dependencies

None currently. All testing uses built-in XCTest framework.

## System Dependencies

### macOS Core Text Framework
- **Version**: Built into macOS
- **Minimum**: macOS 12 (Monterey)
- **Purpose**: Font registration and management

**Why chosen**:
- Native macOS API for font operations
- No external dependencies
- Official Apple framework
- Direct access to font registration/unregistration
- Handles font collections (.ttc/.otc) correctly
- Required for core functionality

## Dependency Policy

Following PRINCIPLES.md, we:
- Minimize dependencies ruthlessly
- Prefer well-maintained packages (>200 stars, active development)
- Use macOS native frameworks when possible
- Avoid enterprise bloat (no logging frameworks, monitoring, analytics)
- Choose simplicity over flexibility
- Only add dependencies for core functionality

## Dependency Updates

Check for updates quarterly:
```bash
swift package update
```

Review release notes before updating major versions.
