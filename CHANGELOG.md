## 0.7.1

- **Perf**: Refactored `getVersion` in `CoverCommandRunner` to use asynchronous I/O and improved robustness with file type validation.

## 0.7.0

- **Feat**: Added `--failures-only` (abbr: `-f`) flag to the `check` command to filter the report to show only files failing the coverage threshold.
- **Feat**: Threshold-aware coloring in terminal reports, dynamically adjusting colors based on the user-provided `--min-coverage`.

## 0.6.0

- **Feat**: Added `--baseline` (or `-b`) flag to `check` command for coverage regression detection against a reference LCOV file.
- **Fix**: Enhanced `CoverCommandRunner` and `CheckCoverageCommand` with robust JSON error reporting for usage and formatting errors.
- **Perf**: Optimized `RecordExtension` with manual loops and `StringBuffer` for faster uncovered lines extraction and range formatting.
- **Perf**: Optimized CI/CD performance by implementing parallel jobs and dependency caching.
- **Chore**: Updated Melos scripts for better workspace consistency and fail-fast behavior.

## 0.5.2

- **Docs**: Corrected `README.md` to English and improved features documentation.

## 0.5.1

- **Docs**: Comprehensive overhaul of `README.md` with better features documentation, CLI flags table, and programmatic usage examples.

## 0.5.0

- **Feat**: Added automated Release Manager workflow for AI agents.
- **Fix**: Implemented terminal output sanitization via `StringExtension.sanitize()` to prevent ANSI injection attacks.
- **Fix**: Restored 100% test coverage for CLI error paths and runner exceptions.
- **Chore**: Improved repository hygiene by properly excluding IDE-specific artifacts in `.gitignore`.
- **Perf**: Optimized Melos scripts for parallel execution and increased test concurrency.

## 0.4.0

- **Feat**: Added `--show-uncovered` flag to display missing coverage line numbers.
- **Feat**: Added `--exclude-generated` flag to `check` command to ignore common generated files (e.g., `.g.dart`, `.freezed.dart`, `.mocks.dart`).
- **Feat**: Added `--json` (abbr `-j`) flag to `check` command for machine-readable coverage output.
- **Feat**: Added automated Pull Request reviewer workflow for AI agents.
- **Perf**: Pre-compiled generated files regex for faster parsing.
- **Perf**: Deferred table allocation in check coverage command.
- **Perf**: Optimized coverage aggregation with indexed loop.
- **Perf**: Optimized `Record` extension `toRow` with fast-path for 100% coverage.
- **Refactor**: Consolidated agent guidelines and removed legacy `AGENTS.md`.
- **Fix**: Enhanced `CheckCoverageCommand` with robust error handling and structured JSON error reporting for failure scenarios.
- **Refactor**: Optimized `CoverCommandRunner.getVersion` using non-blocking I/O to prevent event loop blockage and TOCTOU.

## 0.3.0

- **Feat**: Integrated **Melos** as a workspace manager using **Dart Workspaces**.
- **Refactor**: Optimized `CoverageService` with **non-blocking/async I/O** for file operations and path resolution.
- **Fix**: Improved robustness of `min-coverage` validation and enhanced global error handling in CLI commands.
- **Perf**: Optimized file metadata retrieval and path exclusion filtering.
- **Fix**: Resolved exception leakage issues during coverage parsing.
- **Chore**: Upgraded minimum Dart SDK to `3.5.0` and unified development workflows via Melos scripts.

## 0.2.0

- Security improvements:
    - Fixed path traversal via symlinks.
    - Added output sanitization to prevent potential vulnerabilities.
    - Fixed TOCTOU vulnerability in `CoverageService`.
    - Protected against ReDoS in excluded paths.
    - Fixed version spoofing vulnerability.
- Optimizations:
    - Optimized coverage calculation and formatting.
    - Improved excluded paths filtering and coverage file filtering.
    - Optimized regex usage in `RecordExtension`.
    - Optimized filename sanitization in coverage reports.
- Bug fixes:
    - Fixed path exclusion logic to support spaces.
    - Enforced file path constraints.
    - Fixed exception leakage in CLI Runner.
- Documentation:
    - Added `AGENTS.md` guide for AI agents and developers.

## 0.1.0

- Refactored architecture to introduce `CoverageService` for better testability and programatic usage.
- Added `CheckCoverageCommand` support for programatic usage.
- Upgraded dependencies to support latest Dart versions.
- Added full example package in `example/`.
- Updated development dependencies.

## 0.0.4

- Flag `--excluded-paths` was added in order to exclude folders/files from coverage 

## 0.0.3

- Fixed an issue with the final coverage percentage calculation

## 0.0.2

- Flag `--version` was added in order to show the current version
- Flag `--display-files` was added in order to show/hide coverage files 

## 0.0.1

- Initial version.