#!/usr/bin/env bash
#
# scan.sh: find secrets and internal network details before they reach git.
#
#   scan.sh --staged      files as they are staged for the next commit (default)
#   scan.sh --unpushed    files changed in commits not yet on the upstream branch
#   scan.sh --all         every tracked file
#   scan.sh FILE...       the given files from disk
#
# Prints file:line:rule with the match redacted, and exits 1 if anything is found.
# A line is skipped if it contains "secret-scan: allow". A repository can list allowed
# matches, one extended regex per line, in .secret-scan-allow at its root; each regex is
# tested against "file:line:match". Needs only bash, git, grep and sed.

set -uo pipefail

RULES=(
  "private-key|-----BEGIN [A-Z ]*PRIVATE KEY-----"
  "github-token|(gh[opusr]_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{40,})"
  "aws-access-key|AKIA[0-9A-Z]{16}"
  "llm-api-key|sk-(ant-|proj-)?[A-Za-z0-9_-]{32,}"
  "slack-token|xox[abprs]-[A-Za-z0-9-]{10,}"
  "blockfrost-token|(mainnet|preprod|preview)[A-Za-z0-9]{32}"
  "private-ipv4|(^|[^0-9.])(10\.[0-9]{1,3}|192\.168|172\.(1[6-9]|2[0-9]|3[01]))\.[0-9]{1,3}\.[0-9]{1,3}([^0-9]|$)"
  "internal-hostname|[A-Za-z0-9][A-Za-z0-9-]*\.(lan|local|internal|home\.arpa)([^A-Za-z0-9.-]|\.([^A-Za-z]|$)|$)"
  "assigned-secret|(seed|mnemonic|private_?key|secret|passw(or)?d|api_?key|auth_?token|access_?token)[\"']?[[:space:]]*[:=][[:space:]]*[\"']?[A-Za-z0-9+/_=-]{16,}"
)

mode="--staged"
files=()
if [[ $# -gt 0 ]]; then
  case "$1" in
    --staged|--unpushed|--all) mode="$1" ;;
    -h|--help) sed -n '3,13p' "$0"; exit 0 ;;
    *) mode="--files"; files=("$@") ;;
  esac
fi

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
allow_file="$root/.secret-scan-allow"

# list_files prints one path per line for the chosen mode.
list_files() {
  case "$mode" in
    --staged)   git diff --cached --name-only --diff-filter=ACMR ;;
    --all)      git ls-files ;;
    --unpushed)
      local base
      base=$(git rev-parse --verify -q '@{upstream}' 2>/dev/null) || base=$(git rev-list --max-parents=0 HEAD | tail -n1)
      git diff --name-only --diff-filter=ACMR "$base" HEAD
      # The root commit itself when nothing is upstream yet.
      git rev-parse --verify -q '@{upstream}' >/dev/null 2>&1 || git show --pretty=format: --name-only --diff-filter=ACMR "$base"
      ;;
    --files)    printf '%s\n' "${files[@]}" ;;
  esac
}

# content PATH prints the version of PATH that this mode scans.
content() {
  case "$mode" in
    --staged)   git show ":$1" 2>/dev/null ;;
    --unpushed) git show "HEAD:$1" 2>/dev/null ;;
    *)          cat -- "$1" 2>/dev/null ;;
  esac
}

redact() { local m="$1"; printf '%s***' "${m:0:4}"; }

allowed() {
  [[ -f "$allow_file" ]] || return 1
  local pat
  while IFS= read -r pat; do
    [[ -z "$pat" || "$pat" == \#* ]] && continue
    [[ "$1" =~ $pat ]] && return 0
  done < "$allow_file"
  return 1
}

found=0
while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  [[ "$f" == ".secret-scan-allow" ]] && continue
  # Skip binary and empty files (grep -I treats binary input as not matching).
  content "$f" | LC_ALL=C grep -Iq . 2>/dev/null || continue
  body=$(content "$f") || continue
  for rule in "${RULES[@]}"; do
    name="${rule%%|*}"; re="${rule#*|}"
    flags=(-nE -o)
    [[ "$name" == "assigned-secret" || "$name" == "internal-hostname" ]] && flags+=(-i)
    while IFS= read -r hit; do
      [[ -n "$hit" ]] || continue
      line="${hit%%:*}"; match="${hit#*:}"
      full=$(printf '%s\n' "$body" | sed -n "${line}p")
      [[ "$full" == *"secret-scan: allow"* ]] && continue
      allowed "$f:$line:$match" && continue
      # Obvious placeholders in example files are not secrets.
      if [[ "$name" == "assigned-secret" ]] && [[ "$match" =~ [:=][[:space:]]*[\"\']?(SET_|CHANGE_?ME|YOUR_|REPLACE|EXAMPLE|PLACEHOLDER) ]]; then continue; fi
      printf '%s:%s:%s: %s\n' "$f" "$line" "$name" "$(redact "$match")"
      found=1
    done < <(printf '%s\n' "$body" | LC_ALL=C grep "${flags[@]}" -- "$re" 2>/dev/null)
  done
done < <(list_files)

if (( found )); then
  echo "secret-hygiene: findings above. Remove them (and rewrite unpushed commits), or allow a false positive." >&2
  exit 1
fi
echo "secret-hygiene: clean ($mode)"
