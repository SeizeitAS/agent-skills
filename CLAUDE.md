# Instructions for Claude Code sessions in this repository

## What this is
Claude Code skills for Seize it AS (Trondheim). Sibling repositories that the skills come from:
`SeizeitAS/Compliance-Engine` (public), `SeizeitAS/assetprice` (private), `SeizeitAS/business20-kryptoforvaltning`
(private, proprietary). The plan is in `docs/PLAN.md` and the work items are in `docs/SCRUM.md` (SK-n).

## Rules
- **This repository is public.** Run `skills/process/secret-hygiene/scripts/scan.sh --unpushed` before
  every push. No secrets, wallet seeds, tokens, internal IP addresses, host names or user names.
- **Nothing from the private repositories goes in verbatim**: no code, schemas, customer or accounting data,
  internal URLs. A skill may describe a general procedure learned there, never their content. Skills built
  from Business 20 wait for the owner's ok.
- **English** for skills, code, comments, commit messages and docs. The owner chats in Norwegian; reply in Norwegian.
- **Honest status**: say what was run (verified) and what was not (assumed).
- **Never edit vendored skills** in `skills/vendored/`. To update one, copy it again from a newer source
  commit and record the commit in `NOTICE`.
- A skill is promoted (listed in `.claude-plugin/plugin.json`) only once it has tests in `evals/<skill>/`
  and has been used in at least two real sessions. Bump `version` in `plugin.json` with every release.
- Work items in `docs/SCRUM.md`. Do not invent hours.

## Writing a skill
- `SKILL.md` under about 100 lines. Frontmatter `name` matches the folder name. The `description` says what
  the skill does and the phrases that should trigger it.
- Each step ends with **Done when:** and names the evidence (a command and its output).
- Put details, formats and scripts in files beside `SKILL.md`. Scripts need only bash, git and POSIX tools,
  or Node 22 with no dependencies.
- Add `evals/<skill>/`: behaviour tests (`*.test.sh`, picked up by `evals/run-all.sh`) and, once there is a
  runner, trigger prompts.

## Commands
```
bash evals/run-all.sh                                   # all behaviour tests
bash skills/process/secret-hygiene/scripts/scan.sh --all
claude plugin validate .        # manifests; --strict fails today on the expected CLAUDE.md warning (it is for this repo, not the plugin)
```
