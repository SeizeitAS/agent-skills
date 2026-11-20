# Work items (SK-n)

The numbering is a proposal: the owner has not yet decided between SK-n and CE-34 in Compliance-Engine.

| ID | Item | State | Notes |
|---|---|---|---|
| SK-1 | Repository skeleton: README, CLAUDE.md, NOTICE, plugin manifests, CI, vendored `wizard` and `domain-modeling` | DONE 2026-11-20 | The plugin lists no skills until one is promoted |
| SK-2 | `secret-hygiene`: scanner, skill, behaviour tests | IN PROGRESS | 22 tests pass. Run once with `--all` on the three source repositories on 2026-11-20: Assetprice clean after two false-positive fixes, Business 20 (`ccr` branch) clean, Compliance-Engine has three known public dev values to mark with `secret-scan: allow`. Promote after a second real session |
| SK-3 | `honest-status` | BACKLOG | Phase 1 |
| SK-4 | `scrum-and-time` (CE, AP and P numbers, timelog, no invented hours) | BACKLOG | Phase 1. Needs the P-number scheme in Business 20 `TIDBRUKREGNSKAP.md` (only owner-approved, general parts) |
| SK-5 | `handoff` (keep CLAUDE.md current for the next session) | BACKLOG | Phase 1 |
| SK-6 | `zk-reference-first` | BACKLOG | Phase 2 |
| SK-7 | `compact-toolchain` | BACKLOG | Phase 2 |
| SK-8 | `midnight-network-run` | BACKLOG | Phase 2. Acceptance: a new session re-runs CE-29 with only the skills |
| SK-9 | Trigger tests with the skill-creator eval tooling | BACKLOG | |
| SK-10 | License | BLOCKED | Owner to choose (Apache-2.0 proposed) |
