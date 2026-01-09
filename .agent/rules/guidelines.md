---
trigger: always_on
---

This document serves as the primary guide for AI agents and developers working on the `cover` codebase. It outlines the technology stack, architectural patterns, coding standards, and project structure for this code coverage tool.

## 1. Tech Stack

- **Language:** Dart (>=3.0.0)
- **CLI Framework:** `package:args` and `package:args/command_runner.dart`
- **CLI Completion:** `package:cli_completion`
- **Console UI:** `package:dart_console`
- **LCOV Parsing:** `package:lcov_parser`
- **Pubspec Parsing:** `package:pubspec_parse`
- **Linting:** `very_good_analysis`
- **Testing:** `package:test`, `package:mocktail`

## 2. Project Structure

This project is a **Dart CLI Tool** designed to be used as a global activation or a development dependency.

### Top-Level Directories

- **`bin/`**: Contains the executable entry point (`cover.dart`).
- **`lib/`**: Public API and exports.
- **`lib/src/`**: Internal implementation logic.
- **`test/`**: Comprehensive test suite including unit tests and stubs for coverage data.
- **`example/`**: Demonstrates how to use the tool programmatically or via CLI.

### Source Structure (`lib/src/`)

Internal code is organized by responsibility:

- **`commands/`**: Implementation of CLI commands (e.g., `check-coverage`).
- **`services/`**: Core logic and business rules (e.g., `CoverageService` for parsing and processing data).
- **`models/`**: Data structures representing coverage results and tool state.
- **`extensions/`**: Helper extensions on Dart types (e.g., `double`, `record`).
- **`cover_command_runner.dart`**: The main entry point for command orchestration.

## 3. Architecture & Patterns

### Command Pattern

- The CLI uses the `CommandRunner` and `Command` classes from `package:args`.
- Each subcommand is encapsulated in its own class in `lib/src/commands/`.
- Logic should be delegated to services rather than living directly in command classes.

### Service Layer

- Core logic (like parsing `.info` files) resides in the `services/` directory.
- This allows for easier testing and potential reuse in other contexts (e.g., a web dashboard).

### Robust Error Handling

- Custom exit codes are defined in `lib/src/models/exit_code.dart`.
- The `CoverCommandRunner` handles top-level exceptions to provide user-friendly error messages and appropriate exit codes.

## 4. Naming Conventions

- **Files & Directories:** `snake_case` (e.g., `check_coverage_command.dart`).
- **Classes:** `PascalCase` (e.g., `CoverageService`, `CoverageResult`).
- **Variables & Functions:** `camelCase` (e.g., `minCoverage`, `parseLcovFile`).
- **Constants:** `lowerCamelCase` (follow standard Dart style guide).

## 5. Development Commands

Run these commands from the root of the repository:

- **Get Dependencies:** `dart pub get`
- **Analyze Code:** `dart analyze`
- **Run Tests:** `dart test`
- **Run Coverage:** `dart test --coverage && dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info`
- **Run CLI Locally:** `dart bin/cover.dart <args>`

## 6. Rules for Agents

1. **CLI Robustness:** Ensure the tool handles missing files, invalid formats, and edge cases gracefully with clear error messages.
2. **Test-Driven Mentality:** When adding features or fixing bugs, ensure matching tests are updated or added in the `test/` directory.
3. **API Stability:** Be mindful of changes in `lib/` that might break consumers who use `cover` as a library.
4. **Platform Independence:** Pure Dart tools should avoid `dart:html` or other platform-specific libraries unless absolutely necessary.
5. **Console Output:** Use `package:dart_console` for consistent terminal styling and coloring.

## 7. Git & PR Conventions

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):
- **`feat`**: New feature (e.g., a new command or flag).
- **`fix`**: Bug fix.
- **`docs`**: Documentation updates.
- **`test`**: Adding or correcting tests.
- **`chore`**: Maintenance tasks.

**Example:** `feat: support multiple lcov files`

### Pull Requests

- Use the provided template at [.github/pull_request_template.md].
- **Write for a non-technical audience:** Briefly describe the changes made and their impact without diving into technical implementation details.
- The result must be in raw markdown format (wrapped in a ```markdown code block) and in English ready for copy and paste.
- Ensure all tests pass and coverage is maintained.
- Update `CHANGELOG.md` with a summary of the change.

## 8. Release Preparation

1. **Update CHANGELOG.md:** Document all changes since the last release.
2. **Update Version:** Bump the version in `pubspec.yaml`.
3. **Run Analysis & Tests:** Ensure everything is green.

## 9. Publish

To publish to [pub.dev](https://pub.dev):

1. **Dry Run:**
   ```bash
   dart pub publish --dry-run
   ```
2. **Publish:**
   ```bash
   dart pub publish
   ```
