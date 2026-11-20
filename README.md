# Agent skills from Seize it AS

Claude Code skills for the software Seize it AS builds: zero-knowledge compliance on
[Midnight](https://midnight.network), a NOK price oracle, and crypto bookkeeping. Each skill is a procedure
we have already carried out by hand in our own repositories, written down so every agent session follows it
the same way.

The structure follows [mattpocock/skills](https://github.com/mattpocock/skills): small skills that do one job
each and can be combined, a short `SKILL.md` with details in files beside it, and a "Done when" line for each step.
We add our own rules: every result is reported as verified or assumed, contracts run on the local network
before any public one, and secrets and internal network details never reach git.

## Status
Early. Nothing is promoted yet, so the plugin ships no skills. A skill is promoted only after it has tests
and has been used in at least two real sessions.

| Skill | Bucket | State |
|---|---|---|
| `secret-hygiene` | `process` | Built 2026-11-20: scanner with 22 behaviour tests; run once on our three repositories |
| `wizard` | `vendored` | Copied unchanged from mattpocock/skills (MIT) |
| `domain-modeling` | `vendored` | Copied unchanged from mattpocock/skills (MIT) |

The full plan and build order are in [docs/PLAN.md](docs/PLAN.md). Work items are [GitHub issues](https://github.com/SeizeitAS/agent-skills/issues) titled `SK-n`.

## Layout
```
skills/process/      working rules for every repository
skills/midnight/     Compact contracts, proofs, networks (planned)
skills/compliance/   regulation and proof of reserves (planned)
skills/in-progress/  drafts, not shipped
skills/vendored/     third-party skills, unchanged, with their license and source commit
evals/<skill>/       trigger prompts and behaviour tests
docs/adr/            decisions
```

## Use
Until skills are promoted, copy a skill folder into a project's `.claude/skills/`. Later:
```
claude plugin marketplace add SeizeitAS/agent-skills
claude plugin install seizeit-skills@seizeit
```

## Tests
```
bash evals/run-all.sh
```

## License
Apache License 2.0 (`LICENSE`). The vendored skills keep their MIT License
(`skills/vendored/LICENSE-mattpocock-skills`, see `NOTICE`).
