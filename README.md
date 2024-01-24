# cover

[![Cover pub.dev badge](https://img.shields.io/pub/v/cover.svg)](https://pub.dev/packages/cover)
[![cover](https://github.com/aosorio-avilez/cover/actions/workflows/cover.yaml/badge.svg?branch=main)](https://github.com/aosorio-avilez/cover/actions/workflows/cover.yaml)
[![codecov](https://codecov.io/gh/aosorio-avilez/cover/branch/main/graph/badge.svg?token=ZWOS98VTND)](https://codecov.io/gh/aosorio-avilez/cover)

Package that provide an easy way to check your code coverage.

## Getting Started

Activate globally via:

```sh
dart pub global activate cover
```

## Usage

```sh
# Check code coverage
$ cover check

# Check code coverage with specific path
$ cover check --path coverage/lcov.info

# Check code coverage with specific minimun coverage
$ cover check --min-coverage 80

# Check code coverage without display files
$ cover check --no-display-files

# Check code coverage excluding some paths
$ cover check --excluded-paths "/folder1, /folder2, file.txt"

# Show current version
$ cover --version

# Show usage help
$ cover --help
```

## Example

<img src="https://raw.githubusercontent.com/aosorio-avilez/cover/main/resources/cover_example.png" />

## Issues and feedback
Please put Cover specific issues, bugs, or feature requests in our [issue tracker](https://github.com/aosorio-avilez/cover/issues/new/choose).
