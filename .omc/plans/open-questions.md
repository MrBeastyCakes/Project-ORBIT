# Open Questions

## MVP Plan - 2026-03-01

- [ ] **Isar vs Hive decision** — The CLAUDE.md mentions "Hive or Isar" but the plan commits to Isar for its full-text search indexing capability. Confirm Isar is the preferred choice, or switch to Hive (which would require a separate search index solution).
- [ ] **Isar 3.x vs 4.x** — Isar 4 is in development and may introduce breaking changes. Should the project pin Isar 3.1.x for stability, or adopt Isar 4 if it becomes stable before MVP launch?
- [ ] **flutter_quill version pinning** — flutter_quill has frequent breaking changes. The plan targets ^10.8 but the exact version should be locked after confirming Delta JSON compatibility with the persistence layer.
- [ ] **Maximum note size limit** — The questionnaire says "target something reasonable." The plan proposes 500KB for the Delta JSON document. Confirm this limit is acceptable or adjust.
- [ ] **Planet color preset palette** — The plan proposes 12 preset colors. Should these be the exact 12 listed (red, orange, yellow, green, teal, cyan, blue, indigo, purple, pink, grey, white), or does the user want a different palette?
- [ ] **Atmosphere color-to-meaning mapping** — The description references "green = urgent, blue = reference" but the plan treats these as suggestions, not enforced semantics. Confirm: are atmosphere colors purely cosmetic (user's choice), or should the app suggest/enforce meanings?
- [ ] **Orbital decay threshold (dwarf planet)** — The plan uses 90 days of inactivity. Is 90 days the right threshold, or should it be shorter (60 days) or longer (120 days)?
- [ ] **Nebula remnant lifetime** — Post-supernova nebula remnants are set to disappear after 30 days. Confirm this duration or adjust.
- [ ] **Onboarding flow** — The plan includes a 3-tip overlay for first-time users. Should this be more elaborate (interactive tutorial) or is a simple dismissible overlay sufficient for v1?
- [ ] **Firebase project setup** — A Firebase project needs to be created in the Firebase console with Android/iOS apps registered. Who handles this setup, and are the bundle IDs / package names decided? (Suggested: `com.orbit.projectorbit` for Android, similar for iOS.)
- [ ] **Paid tier implementation** — The plan stubs the paid tier check as always returning "free." What payment provider should be used when this is implemented? (Google Play Billing + Apple StoreKit via `in_app_purchase` package is the standard Flutter approach.)
- [ ] **Conflict resolution UI for cloud sync** — The questionnaire mentions "manually approved merge with option to split the planet." This is deferred past MVP (cloud sync is paid/future), but the data model should be forward-compatible. No action needed now, but flag for future planning.
