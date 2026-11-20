# Plan: our own agent skills

Status: **plan.** Date: 2026-11-20. Copied from Compliance-Engine `docs/agent-skills-plan.md`; this copy is now the one kept current. Progress: `docs/SCRUM.md`.

## Goal
Write the way Seize it AS builds software down once, as Claude Code skills, so every session in
Compliance-Engine, Assetprice and Business 20 works the same way without re-explaining it. Scope:
zero-knowledge compliance on Midnight, the NOK price oracle, and crypto bookkeeping. Each skill encodes a
procedure we have already carried out by hand, and points to where it was carried out.

## What we take from mattpocock/skills
Read 2026-11-20 at commit `abeeaf9` (MIT). We copy the approach, not the content:

| Lesson | How we apply it |
|---|---|
| Small, composable skills. Each does one job and skills call each other (`grill-with-docs` is just two skill calls) | One skill per procedure. A larger flow is a short skill that calls the smaller ones |
| The `description` decides when a skill triggers | Every description says what the skill does and the phrases that trigger it. Every skill gets trigger tests (see Quality) |
| Progressive disclosure: a short `SKILL.md`, with details, formats and templates in separate files | `SKILL.md` under about 100 lines. Formats and scripts sit beside it |
| A "Done when" line for each step | Same, and "done" must name the evidence, for example a command and its output |
| Bundled scripts with a fixed library (`wizard/template.sh`) | Shared scripts in `lib/`, which nobody edits by hand per use |
| Create files lazily | Same |
| An ADR only when the change is hard to reverse, surprising and a real trade-off | Same. We have the first four ADRs in `docs/adr/` |
| Bucket folders: promoted, in-progress, deprecated. A plugin manifest lists only the promoted skills | Same layout, shipped as a Claude Code plugin with its own marketplace file |
| Redact secrets in everything you show (`diagnosing-bugs`) | Built into every skill, plus a dedicated skill for it (`secret-hygiene`) |

What we add, because our work needs it:
- **An evidence ladder.** Every check is reported as verified (run, with output) or assumed.
  `ledger:check` verifies nothing. "Proved" does not mean "verified by a node".
- **Network discipline.** Compile for the network you deploy to. Run locally first, then Preprod, then
  mainnet. Never create wallets, accounts or tokens without the owner's explicit ok.
- **The language rule.** Code, documentation and commit messages are in English, and the agent replies
  to the owner in Norwegian. Display text lives only in `locales/`.
- **Traceability for grants and audits.** Each change has an item number (CE-n, AP-n, P-n) and hours are
  logged. No hours are invented. SkatteFUNN work packages must be traceable.

## The repository
I suggest the name `SeizeitAS/agent-skills`. The owner decides the name, license and visibility
(see Open questions). The session cannot create repositories, so the owner creates an empty one and the
session attaches it.

```
agent-skills/
├── .claude-plugin/{plugin.json, marketplace.json}   lists the promoted skills only
├── skills/
│   ├── process/        promoted: cross-repo working rules
│   ├── midnight/       promoted: Compact, proofs, networks
│   ├── compliance/     promoted: regulation and reserves
│   ├── in-progress/    not shipped
│   └── vendored/       third-party skills, unchanged, with license and source commit
├── lib/                shared scripts (redaction scan, wizard library)
├── evals/<skill>/      trigger prompts and expected behaviour
├── GLOSSARY.md         shared terms (links to each repo's own glossary)
├── docs/adr/
└── LICENSE, NOTICE
```

Installation in each repo: `claude plugin marketplace add SeizeitAS/agent-skills`, then
`claude plugin install seizeit-skills@seizeit`. Until then, skills are copied into
`.claude/skills/`, as was done today with `wizard` and `domain-modeling`.

## Skill catalogue, in build order
Each skill names the procedure it encodes. "Source" is where we have already done it by hand.

### Phase 1: working rules for all three repos (built first, because every session uses them)
| Skill | Does | Source |
|---|---|---|
| `honest-status` | Reports work as verified or assumed, with the command and the result, and updates the status table in `CLAUDE.md` | `CLAUDE.md` rules; CE-29 and CE-30 write-ups |
| `scrum-and-time` | Picks or creates an item (CE, AP or P number), updates `SCRUM.md`, and adds a timelog line only with hours the owner gives or start and end times that are known | `docs/SCRUM.md`, `docs/TIME_TRACKING.md`, `TIDBRUKREGNSKAP.md` (alignment with the P numbers is still open) |
| `secret-hygiene` | Scans staged changes and unpushed commits for keys, seeds, tokens, IP addresses and internal host names before a push, and redacts them in output | Host name cleanup 2026-11-20; AP10 (review before first push) |
| `handoff` | Updates `CLAUDE.md` so the next session can continue (local or cloud) | `CLAUDE.md` in this repo; Pocock `handoff` |

### Phase 2: Midnight and zero knowledge
| Skill | Does | Source |
|---|---|---|
| `zk-reference-first` | The development order: TypeScript reference, then golden vectors, circuit, crosscheck, runtime checks, proof, node verification. It says which step proves what. Never edit a test to hide a mismatch | CE-2, CE-5, CE-6, CE-29 |
| `compact-toolchain` | Matches the compiler, language, runtime and proof server versions to the ledger of the target network. Migrates and re-runs every check | CE-5, CE-20; `docs/toolchain.md` |
| `midnight-network-run` | Moves from the local network to Preprod: a throwaway wallet in a git-ignored `.env.<network>`, the faucet, saved wallet state, logging addresses, and stopping a negative test on a public chain. Generates a wizard for the human steps | CE-29, CE-30, AP28; `docs/network-plan.md` |
| `wizard` (vendored) | Scripts for steps only the owner can take | Copied 2026-11-20 |

### Phase 3: compliance
| Skill | Does | Source |
|---|---|---|
| `regulatory-mapping` | Traces each requirement from article (MiCA, AMLR, hvitvaskingsloven) to control, circuit or verifier, and test. Marks legal questions for an adviser and never answers them as fact | Blueprint, `docs/security-review.md`, D3 open question |
| `proof-of-reserves` | Document everything, count only what is proven. Package, haircuts, reconciliation, report for the auditor | ADR 0004, CE-6, CE-27 |
| `security-review` | An internal review with SR-n findings, severity and status. No production claim until the findings are closed and an external review is done | CE-15 |
| `domain-modeling` (vendored) | Glossary and ADRs | Copied 2026-11-20 |

### Phase 4: oracle and bookkeeping (after the owner has read the Phase 1 and 2 skills)
| Skill | Does | Source |
|---|---|---|
| `price-oracle-anchoring` | Append-only history, closed windows, salted leaves, window root on chain, proof endpoint, freshness. Store times in UTC | AP14, AP21, AP23, AP25 to AP28 |
| `price-source-blending` | Compares blending methods on real history before production. Manipulation scenarios | AP29, AP30 |
| `bookkeeping-voucher` | Canonical vouchers and the accounting trail in Business 20 | Business 20 (private; **not read yet**, so this row is an assumption and needs the owner's ok, ADR 0001) |

Not planned: general skills that Pocock or Anthropic already cover well (TDD, code review, PR flow). We
install or vendor them instead.

## Quality
- **Trigger tests.** In `evals/<skill>/triggers.json`, prompts that should and should not trigger the
  skill, run with the `skill-creator` eval tooling.
- **Behaviour tests.** One or two real tasks per skill, with expected evidence. For example,
  `secret-hygiene` must catch a planted test token in a staged file, and `honest-status` must not call a
  `ledger:check` run "verified".
- **Dogfooding.** A skill is promoted only after it has been used in at least two real sessions, in at
  least two of the three repos where that applies.
- **Versioning.** A semver tag. `plugin.json` and `package.json` are bumped together. A changelog entry
  for every change in behaviour.

## Order of work
1. The owner creates the empty repository and answers the open questions. The session attaches it,
   adds the skeleton, license and vendored skills, and moves today's two skills over.
2. Phase 1: four skills, each with tests, dogfooded in this repo and in Assetprice.
3. Phase 2: three skills. Acceptance test: a new session re-runs CE-29 with only the skills and the
   wizard, without reading the old conversation.
4. Phases 3 and 4, in the order the backlogs need them. `price-oracle-anchoring` first, if AP14 moves to
   mainnet.
5. Install the plugin in all three repos, and slim `CLAUDE.md` in each repo down to project facts.

## Open questions for the owner
1. Name and visibility: public `SeizeitAS/agent-skills` (it helps the community and the sisit.no
   articles), or private? Public needs the `secret-hygiene` scan on every push from day one.
2. License: Apache-2.0, as in Compliance-Engine? Business 20 is closed and proprietary, so skills built
   from it may have to stay out of a public repository.
3. Item numbering: a new series, for example `SK-n`, or under CE-34?
