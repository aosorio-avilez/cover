## 0.0.1

- Initial version.

## 0.0.2

- Flag `--version` was added in order to show the current version
- Flag `--display-files` was added in order to show/hide coverage files 

## 0.0.3

- Fixed an issue with the final coverage percentage calculation

## 0.0.4

- Flag `--excluded-paths` was added in order to exclude folders/files from coverage 

## 0.1.0

- Refactored architecture to introduce `CoverageService` for better testability and programatic usage.
- Added `CheckCoverageCommand` support for programatic usage.
- Upgraded dependencies to support latest Dart versions.
- Added full example package in `example/`.
- Updated development dependencies.

## 0.3.0

- Integrated **Melos** as a workspace manager using **Dart Workspaces**.
- Upgraded minimum Dart SDK to `3.5.0`.
- Unified local development and CI/CD commands via Melos scripts.
- Updated project documentation for developer workflows.

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