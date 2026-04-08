---
trigger: always_on
---

# Cover CLI Blueprint & Developer Guide

This document serves as the primary guide for AI agents and developers working on the `cover` codebase. It outlines the technology stack, architectural patterns, coding standards, and project structure for this Dart CLI code coverage tool.

## 1. Tech Stack

- **Language:** Dart (^3.5.0)
- **Version Management:** FVM (Flutter Version Management) - *MUST use `fvm dart` for all commands.*
- **Monorepo Manager:** [Melos](https://melos.invertase.dev/) (to manage the CLI tool and its `example/` package).
- **CLI Framework:** `package:args` and `package:args/command_runner.dart`
- **CLI Completion:** `package:cli_completion`
- **Console UI:** `package:dart_console`
- **LCOV Parsing:** `package:lcov_parser`
- **Pubspec Parsing:** `package:pubspec_parse`
- **Linting:** `very_good_analysis`
- **Testing:** `package:test`, `package:mocktail`

## 2. Project Structure

This project is a **Pure Dart CLI Tool** designed to be used as a global activation or a development dependency.

### Top-Level Directories

- **`bin/`**: Contains the executable entry point (`cover.dart`). This file should be as minimal as possible, delegating execution to the `CoverCommandRunner`.
- **`lib/`**: Public API and exports (`cover.dart`). Contains only what is necessary if someone uses `cover` as a library dependency.
- **`lib/src/`**: Internal implementation logic (Not exposed to library consumers).
- **`test/`**: Comprehensive test suite including unit tests, IO mocks, security tests, and stubs for coverage `.info` data.
- **`example/`**: Demonstrates how to use the tool programmatically or via CLI, including benchmark scripts.

### Source Structure (`lib/src/`)

Internal code is strictly organized by responsibility:

- **`commands/`**: Implementation of CLI subcommands (e.g., `check_coverage_command.dart`). Extends `Command`.
- **`services/`**: Core logic and business rules (e.g., `CoverageService` for parsing and processing LCOV data).
- **`models/`**: Data structures representing coverage results, configurations, and strict `ExitCode` mappings.
- **`extensions/`**: Helper extensions on Dart types (e.g., `double_extension.dart`, `record_extension.dart`).
- **`cover_command_runner.dart`**: The main entry point for command orchestration and global flag parsing.

## 3. Architecture & Patterns

### The "Thin Command, Fat Service" Pattern
- The CLI uses the `CommandRunner` and `Command` classes from `package:args`.
- **Commands are strictly for UX:** A class in `lib/src/commands/` should ONLY define arguments/flags, parse user input, and format the final console output.
- **Services are for Logic:** File reading, parsing, math calculations, and data transformation MUST be delegated to classes in `services/`. 

### Robust Error Handling & Sanitization
- Custom exit codes are strictly mapped in `lib/src/models/exit_code.dart` (e.g., `ExitCode.success`, `ExitCode.usage`, `ExitCode.software`).
- **Exception Leaking Prevention:** The tool must NEVER print a raw Dart stack trace to the user's terminal unless running in a specific `--verbose` or `--debug` mode. The `CoverCommandRunner` acts as a top-level boundary catching all exceptions, sanitizing the message, and returning a graceful `ExitCode.software`.

### Abstracted IO for Testing
- File system operations and console outputs should be easily mockable. Rely on dependency injection (passing a mockable Console or FileSystem wrapper) to allow tests to run without writing/reading real files on disk. (See `test/mocks/io_mocks.dart` and `test/mocks/console_mock.dart`).

## 4. Naming Conventions

- **Files & Directories:** `snake_case` (e.g., `check_coverage_command.dart`).
- **Classes:** `PascalCase` (e.g., `CoverageService`, `CoverageResult`).
- **Variables & Functions:** `camelCase` (e.g., `minCoverage`, `parseLcovFile`).
- **Constants:** `lowerCamelCase` or `SCREAMING_SNAKE_CASE` depending on context.
- **Tests:** Must end with `_test.dart`.

## 5. Development Commands

This project uses Melos and FVM. Run these commands from the root:

- **Get Dependencies:** `melos bootstrap` (or `melos bs`)
- **Analyze Code:** `melos run analyze`
- **Run Tests:** `melos run test`
- **Run Coverage:** `melos run coverage`
- **Check Coverage (Dogfooding):** `melos run check-coverage`
- **Run CLI Locally:** `fvm dart bin/cover.dart <args>`

## 6. Rules for Agents (CLI Golden Rules)

1. **Thin Command `run()` Methods:** The `run()` method inside a Command should not exceed ~50 lines. Extract processing logic to a Service.
2. **Never Leak Exceptions:** When modifying commands or the runner, wrap external operations in `try-catch` blocks. Output a localized, sanitized error message using `dart_console` and return an explicit `ExitCode`. Never let the app crash with a raw stack trace.
3. **Test-Driven Mentality:** Any new parsing logic or command flag MUST include a test. Use the stubs in `test/stubs/` (e.g., `lcov_incomplete.info`) to test edge cases.
4. **Mock IO Interactions:** When testing Commands, DO NOT create real files. Use `io_mocks.dart` and `console_mock.dart` to assert that the correct text was printed to the console and the right exit code was returned.
5. **Platform Independence:** Pure Dart tools should avoid `dart:html` or strictly OS-dependent libraries unless checking for `Platform.isWindows` etc. is absolutely necessary.

## 7. Git & PR Conventions

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):
- **`feat`**: New feature (e.g., a new command or flag).
- **`fix`**: Bug fix.
- **`docs`**: Documentation updates.
- **`test`**: Adding or correcting tests.
- **`chore`**: Maintenance tasks.

**Example:** `feat(parser): support multiple lcov files merging`

### Pull Requests

- Use the provided template at `.github/pull_request_template.md`.
- **Write for a non-technical audience:** Briefly describe the changes made and their impact on the CLI user experience.
- Generate also the most accurate title for the PR.
- The result must be in raw markdown format (wrapped in a ```markdown code block) and in English ready for copy and paste.
- Ensure all tests pass and coverage is maintained.
- Update `CHANGELOG.md` with a summary of the change.

## 8. Release Preparation

When preparing a release for the CLI:
1. **Update CHANGELOG.md:** Document all changes since the last release, categorized properly.
2. **Update Version:** Bump the version in `pubspec.yaml` matching Semantic Versioning (SemVer).
3. **Run Analysis & Tests:** Ensure `melos run analyze` and `melos run test` are entirely green.

## 9. Publish

To publish to [pub.dev](https://pub.dev):

1. **Dry Run:** Ensure the package structure is valid without publishing:
   ```bash
   fvm dart pub publish --dry-run
   ```
2. **Publish:**
   ```bash
   fvm dart pub publish
   ```