#!/usr/bin/env bash
# Behaviour tests for skills/process/secret-hygiene/scripts/scan.sh.
# The fake secrets are built at run time from pieces, so this file never contains one and
# neither GitHub push protection nor the scanner itself flags it.
set -uo pipefail

SCAN="$(cd "$(dirname "$0")/../.." && pwd)/skills/process/secret-hygiene/scripts/scan.sh"
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
cd "$work" && git init -q . && git config user.email t@example.invalid && git config user.name t

pass=0; fail=0
expect() { # expect hit|clean "description" "file content"
  local want="$1" desc="$2" body="$3" out rc
  printf '%s\n' "$body" > f.txt && git add f.txt
  out=$(bash "$SCAN" --staged 2>&1); rc=$?
  if { [[ $want == hit ]] && (( rc == 1 )); } || { [[ $want == clean ]] && (( rc == 0 )); }; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1)); printf 'FAIL (%s expected): %s\n%s\n' "$want" "$desc" "$out"
  fi
  if [[ $want == hit && $rc == 1 && "$out" == *"$4"* ]]; then :; elif [[ $want == hit && $rc == 1 ]]; then
    fail=$((fail + 1)); printf 'FAIL: %s did not report rule %s\n%s\n' "$desc" "$4" "$out"
  fi
}

R=$(printf 'A%.0s' {1..36})
expect hit   "PEM private key"         "-----BEGIN ""OPENSSH PRIVATE KEY-----"            private-key
expect hit   "GitHub token"            "token: gh""p_$R"                                     github-token
expect hit   "AWS key"                 "AKI""A$(printf 'B%.0s' {1..16})"                      aws-access-key
expect hit   "Anthropic key"           "sk-""ant-$(printf 'x%.0s' {1..40})"                   llm-api-key
expect hit   "Blockfrost token"        "BLOCKFROST=pre""prod$(printf 'k%.0s' {1..32})"        blockfrost-token
expect hit   "private IPv4 10/8"       "host is 10.""0.12.7 on the LAN"                       private-ipv4
expect hit   "private IPv4 192.168"    "db=192.""168.1.20:3306"                               private-ipv4
expect hit   "internal host name"      "ssh owner@compiler-box.l""an"                         internal-hostname
expect hit   "seed assignment"         "SEED=\"$(printf 'ab%.0s' {1..32})\""                  assigned-secret
expect hit   "password assignment"     "pass""word: hunter2hunter2hunter2"                      assigned-secret
expect clean "localhost proof server"  "MIDNIGHT_PROOF_SERVER=http://127.0.0.1:6301"
expect clean "public IPv4"             "resolver 1.1.1.1"
expect clean "version numbers"         "compiler 0.36.0, runtime 0.21.0, 172.15.0.1 is public"
expect clean "SHA-256 hash in vectors" "\"root\": \"$(printf 'ab%.0s' {1..32})\""
expect clean "code reading a token"    "const token = getToken();"
expect clean "env var reference"       "seed: process.env.SEED"
expect clean "file name with .local"    "read state/measurements.local.jsonl first"
expect hit   "host name at sentence end" "connect to db.intern""al."                         internal-hostname
expect clean "placeholder in example"  "const PYTH_API_KEY = 'SET_IN_PRIVATE_FILE_ONLY';"
expect clean "inline allow marker"     "example host build.local  # secret-scan: allow"

printf 'build.lo''cal\n' > .secret-scan-allow
expect clean "allow file"              "see build.lo""cal in the docs"
rm .secret-scan-allow

# --unpushed scans committed files when there is no upstream.
printf 'x=10.''1.2.3\n' > g.txt && git add g.txt && git commit -qm c
git rm -q --cached f.txt 2>/dev/null
if bash "$SCAN" --unpushed >/dev/null 2>&1; then fail=$((fail + 1)); echo "FAIL: --unpushed missed a committed IP"; else pass=$((pass + 1)); fi

echo "secret-hygiene scan tests: $pass passed, $fail failed"
(( fail == 0 ))
