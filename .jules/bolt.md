## 2026-01-19 - Safe In-Place Mutation
**Learning:** `List.retainWhere` avoids allocation but requires a mutable, owned list. Using it on a fresh list returned by a parser is safe and optimal.
**Action:** Verify list ownership before using `retainWhere`.
