---
name: secret-hygiene
description: Scan staged changes, unpushed commits or a whole repository for private keys, wallet seeds, API tokens, private IP addresses and internal host names, and redact them in anything you show. Use before every commit or push, before publishing a repository or making it public, when the user says "check for secrets", "is it safe to push", "remove the host name", or when a command's output may contain a credential.
---

# Secret hygiene

Keep credentials and the owner's internal network out of git, chat and logs. A leak in a public repository
cannot be undone by deleting it: assume it was copied the moment it was pushed.

## Rules that always apply
- **Never print a secret.** In anything you show, write `<REDACTED>` or the first four characters followed by `***`.
  Point to where a value lives (a git-ignored `.env.<network>` file, a credential store) instead of showing it.
- **Never put a secret into a command line, a commit, a test fixture, an issue or a chat message.** Build
  fake secrets in tests at run time from pieces (see `evals/secret-hygiene/scan.test.sh`).
- **Internal network details count as secrets:** private IPv4 addresses, LAN host names (`*.lan`, `*.local`,
  `*.internal`), user names on the owner's machines. Use role names in docs instead, such as "the compiler
  host" or "the test host". `127.0.0.1` is fine.
- A well-known development value, such as the local Midnight genesis seed, is allowed only with an inline
  `secret-scan: allow` comment that says why, and must never be used on a public network.

## Process

### 1. Scan
Run the bundled scanner from the repository root:

```
bash <skill-dir>/scripts/scan.sh --staged     # before a commit (default)
bash <skill-dir>/scripts/scan.sh --unpushed   # before a push
bash <skill-dir>/scripts/scan.sh --all        # before publishing, or making a repository public
```

It prints `file:line:rule` with the match redacted, and exits 1 on a finding. It needs only bash, git,
grep and sed.

**Done when:** the scanner prints `clean` for the mode that fits the next action.

### 2. Judge each finding
For each hit, read the line yourself (still redacting) and decide:
- **Real secret or internal detail:** remove it. Move a value the code needs into a git-ignored env file
  and read it from the environment.
- **Already committed but not pushed:** rewrite the unpushed commits (`git commit --amend`, or an
  interactive-free rebase with `git rebase --exec`) so the value is in no commit at all. Ask the user first.
- **Already pushed:** tell the user at once, in plain words. The secret must be **rotated** (revoked and
  replaced); rewriting history is not enough. Do not force-push without the user's explicit ok.
- **False positive:** add `secret-scan: allow` with a reason on that line, or add a narrow regex to
  `.secret-scan-allow` at the repository root. Never widen a rule to silence a real finding.

**Done when:** every finding has one of the four outcomes, and you have told the user which.

### 3. Report
Say what was scanned (mode and repository), what was found (rule and file only), and what was done.
Report a scan as verified only if you ran it in this session.

## Limits
Pattern matching misses secrets that have no recognisable shape (a random password in prose, a seed phrase
in words) and it will flag some harmless values. It complements GitHub secret scanning and push protection,
which should also be turned on. It does not replace them.
