## 2026-01-19 - Safe In-Place Mutation
**Learning:** `List.retainWhere` avoids allocation but requires a mutable, owned list. Using it on a fresh list returned by a parser is safe and optimal.
**Action:** Verify list ownership before using `retainWhere`.

## 2026-01-20 - Fast-Path String Sanitization
**Learning:** `String.replaceAll(RegExp)` incurs significant overhead even when no match is found. A simple linear scan of `codeUnitAt` to check for presence of target characters is ~3x faster.
**Action:** Use a "check-then-act" pattern for expensive string operations when the target is rare (like control chars in filenames).
