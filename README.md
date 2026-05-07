# cover 🎯

[![Cover pub.dev badge](https://img.shields.io/pub/v/cover.svg)](https://pub.dev/packages/cover)
[![cover](https://github.com/aosorio-avilez/cover/actions/workflows/cover.yaml/badge.svg?branch=main)](https://github.com/aosorio-avilez/cover/actions/workflows/cover.yaml)
[![codecov](https://codecov.io/gh/aosorio-avilez/cover/branch/main/graph/badge.svg?token=ZWOS98VTND)](https://codecov.io/gh/aosorio-avilez/cover)

`cover` is the simplest and most robust way to check your Dart/Flutter code coverage directly from the terminal or your scripts.

## ✨ Features

- 📊 **Clear Reports**: Generates an elegant table with coverage summaries per file.
- 🚀 **CI/CD Ready**: Returns explicit exit codes to fail pipelines if coverage is insufficient.
- 🔍 **Missing Lines**: Shows exactly which line numbers are missing coverage with `--show-uncovered`.
- 🧹 **Smart Filters**: Ignore generated files (`.g.dart`, `.freezed.dart`, etc.) with a single flag.
- 🤖 **JSON Output**: Perfect for integration with other tools.
- 🛡️ **Secure**: Protected against ANSI injection attacks and features robust error handling.

## 📦 Installation

### Global Usage (Recommended)
```sh
dart pub global activate cover
```

### As a Dev Dependency
Add it to your `pubspec.yaml`:
```yaml
dev_dependencies:
  cover: ^0.5.2
```

## 🚀 CLI Usage

```sh
# Basic check (looks for coverage/lcov.info by default)
$ cover check

# Enforce minimum coverage and show missing lines
$ cover check --min-coverage 90 --show-uncovered

# Ignore generated files and exclude specific paths
$ cover check --exclude-generated --excluded-paths "lib/generated, lib/src/legacy"

# Get output in JSON format
$ cover check --json
```

### Available Flags

| Flag | Abbr | Description | Default |
| :--- | :--- | :--- | :--- |
| `--path` | `-p` | Path to the `lcov.info` file | `coverage/lcov.info` |
| `--min-coverage` | `-m` | Minimum required coverage percentage | `100.0` |
| `--show-uncovered`| `-u` | Displays line numbers for missing coverage | `false` |
| `--exclude-generated`| | Ignores `.g.dart`, `.freezed.dart`, etc. | `false` |
| `--excluded-paths`| `-e` | Comma-separated paths to exclude | `""` |
| `--json` | `-j` | Output in JSON format | `false` |

## 🛠️ Programmatic Usage

You can integrate `cover` directly into your Dart logic:

```dart
import 'package:cover/cover.dart';

void main() async {
  final service = CoverageService();
  
  final result = await service.checkCoverage(
    filePath: 'coverage/lcov.info',
    minCoverage: 80.0,
    excludeGenerated: true,
  );

  print('Total coverage: ${result.coverage}%');
}
```

## 📸 Output Example

<img src="https://raw.githubusercontent.com/aosorio-avilez/cover/main/resources/cover_example.png" width="600" />

## 🤝 Issues and Feedback
If you find a bug or have a feature request, please open an issue in our [issue tracker](https://github.com/aosorio-avilez/cover/issues).
