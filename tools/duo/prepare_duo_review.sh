#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Duo Review Prompt Preparer (no zip):
# - Prints a single paste-ready prompt with inline HLD/LLD/story + staged diff
# - Also saves the identical prompt to: .duo/pack_<branch>_<sha>_<ts>/review_prompt.txt
#
# Usage:
#   tools/duo/prepare_duo_review.sh [--max-diff-lines N] [--max-doc-chars N]
#
# Defaults:
#   --max-diff-lines 2000   Trim staged diff to first N lines (0 = unlimited)
#   --max-doc-chars  200000 Trim each doc to first N chars (0 = unlimited)
#
# Globs (edit to match your repo):
HLD_GLOB='docs/md/**/*HLD*.md'
LLD_GLOB='docs/md/**/*LLD*.md'
STORY_GLOB='docs/md/**/*story*.md'
# ------------------------------------------------------------------------------

MAX_DIFF_LINES=2000
MAX_DOC_CHARS=200000

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-diff-lines) MAX_DIFF_LINES="${2:-2000}"; shift 2;;
    --max-doc-chars)  MAX_DOC_CHARS="${2:-200000}"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

# ----- helpers -----
ts()  { date +"%Y-%m-%d_%H-%M-%S_%z"; }
sha() { git rev-parse --short HEAD 2>/dev/null || echo "nostage"; }

pick_one() {
  # prefer staged; else most recently committed match
  local glob="$1"
  local staged
  staged=$(git diff --cached --name-only -- "$glob" | head -n1 || true)
  if [[ -n "$staged" ]]; then echo "$staged"; return 0; fi
  local latest
  latest=$(git ls-files -- "$glob" | xargs -I{} git log -1 --format="%ct {}" -- {} 2>/dev/null \
            | sort -nr | head -n1 | awk '{ $1=""; sub(/^ /,""); print }' || true)
  [[ -n "$latest" ]] && echo "$latest" || true
}

append_section_header() {
  local title="$1" out="$2"
  {
    echo "===== $title ====="
  } >> "$out"
}

append_file_with_limit() {
  local path="$1" out="$2" max_chars="$3"
  if [[ "$max_chars" -gt 0 ]]; then
    awk -v max="$max_chars" '
      BEGIN{c=0}
      {
        if (c + length($0) + 1 <= max) { print; c += length($0)+1 }
        else {
          remain = max - c
          if (remain > 0) { print substr($0,1,remain) }
          exit
        }
      }' "$path" >> "$out"
    local chars
    chars=$(wc -c <"$path" | tr -d ' ')
    if [[ "$chars" -gt "$max_chars" ]]; then
      echo "" >> "$out"
      echo "[Truncated to first ${max_chars} chars]" >> "$out"
    fi
  else
    cat "$path" >> "$out"
  fi
}

append_doc_section() {
  local title="$1" path="$2" out="$3"
  append_section_header "$title" "$out"
  if [[ -z "$path" ]]; then
    echo "(not found)" >> "$out"; echo >> "$out"; return
  fi
  echo "[path]: $path" >> "$out"
  if [[ ! -f "$path" ]]; then
    echo "(missing on disk)" >> "$out"; echo >> "$out"; return
  fi
  append_file_with_limit "$path" "$out" "$MAX_DOC_CHARS"
  echo >> "$out"
}

append_text_section() {
  local title="$1" out="$2"
  append_section_header "$title" "$out"
  cat >> "$out"
  echo >> "$out"
}

# ----- collect inputs -----
HLD_FILE=$(pick_one "$HLD_GLOB")
LLD_FILE=$(pick_one "$LLD_GLOB")
STORY_FILE=$(pick_one "$STORY_GLOB")

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-branch")
AUTHOR=$(git config user.name 2>/dev/null || echo "unknown")
EMAIL=$(git config user.email 2>/dev/null || echo "unknown")
SHORTSHA=$(sha)
STAMP=$(ts)

# Set up output dirs/files
OUT_DIR=".duo"
PACK_DIR="$OUT_DIR/pack_${BRANCH//\//_}_${SHORTSHA}_$STAMP"
mkdir -p "$PACK_DIR"
PROMPT_FILE="$PACK_DIR/review_prompt.txt"
MANIFEST="$PACK_DIR/manifest.json"
DIFF_FILE="$PACK_DIR/diff.patch"

# staged diff for entire repo
DIFF_RAW=$(git diff --cached || true)
DIFF_LINE_COUNT=$(printf "%s" "$DIFF_RAW" | wc -l | tr -d ' ')
if [[ "$MAX_DIFF_LINES" -gt 0 && "$DIFF_LINE_COUNT" -gt "$MAX_DIFF_LINES" ]]; then
  DIFF_PRINT=$(printf "%s" "$DIFF_RAW" | head -n "$MAX_DIFF_LINES")
  DIFF_TRUNC_MSG="[Truncated to first ${MAX_DIFF_LINES} lines of ${DIFF_LINE_COUNT}]"
else
  DIFF_PRINT="$DIFF_RAW"
  DIFF_TRUNC_MSG=""
fi

# Save side files for convenience
[[ -n "$HLD_FILE"   && -f "$HLD_FILE"   ]] && cp "$HLD_FILE"   "$PACK_DIR/hld.md"   || true
[[ -n "$LLD_FILE"   && -f "$LLD_FILE"   ]] && cp "$LLD_FILE"   "$PACK_DIR/lld.md"   || true
[[ -n "$STORY_FILE" && -f "$STORY_FILE" ]] && cp "$STORY_FILE" "$PACK_DIR/story.md" || true
printf "%s" "$DIFF_RAW" > "$DIFF_FILE" || true

# Manifest
cat > "$MANIFEST" <<EOF
{
  "branch": "$BRANCH",
  "author": "$AUTHOR",
  "email": "$EMAIL",
  "short_sha": "$SHORTSHA",
  "timestamp": "$STAMP",
  "hld": "$(printf %s "$HLD_FILE")",
  "lld": "$(printf %s "$LLD_FILE")",
  "story": "$(printf %s "$STORY_FILE")",
  "diff_file": "$(printf %s "$DIFF_FILE")"
}
EOF

# ----- build prompt file (plain text, no ANSI) -----
: > "$PROMPT_FILE"  # truncate
echo "-------------------------------- CUT BELOW (paste into Duo Chat) --------------------------------" >> "$PROMPT_FILE"
cat >> "$PROMPT_FILE" <<EOF
You are a senior reviewer. Use the inline materials below (no attachments):

METADATA
- branch: $BRANCH
- author: $AUTHOR <$EMAIL>
- commit: $SHORTSHA
- timestamp: $STAMP
- scope: staged diff for the entire repo; docs from HLD/LLD/story globs.

TASKS
1) SPEC–CODE PARITY
   - List any mismatches between HLD/LLD/story and the diff (API, data shapes, invariants).
   - Call out missing doc updates if code introduces or changes behavior not reflected in HLD/LLD/story.
2) RISK REVIEW
   - Identify risks (edge cases, failure modes, migrations).
3) TEST GAPS
   - Propose concrete tests derived from story acceptance & LLD flows.
4) ACTIONABLE FEEDBACK
   - Provide line-anchored suggestions referencing diff hunks.
5) VERDICT
   - “Spec–code parity OK” or clear block reason.

OUTPUT FORMAT
- Mismatches
- Risks
- Test cases
- Inline suggestions
- Verdict (block/approve) + rationale

EOF

append_doc_section "HLD (hld.md)"     "${HLD_FILE:-}" "$PROMPT_FILE"
append_doc_section "LLD (lld.md)"     "${LLD_FILE:-}" "$PROMPT_FILE"
append_doc_section "Story (story.md)" "${STORY_FILE:-}" "$PROMPT_FILE"

{
  echo "[note]: staged diff for entire repository"
  [[ -n "$DIFF_TRUNC_MSG" ]] && echo "$DIFF_TRUNC_MSG"
  echo
  printf "%s" "$DIFF_PRINT"
} | append_text_section "DIFF (staged changes)" "$PROMPT_FILE"

echo "-------------------------------- CUT ABOVE ----------------------------------------------------------------" >> "$PROMPT_FILE"

# ----- print to stdout the same content -----
cat "$PROMPT_FILE"

# ----- user hints -----
echo
echo "Saved prompt to: $PROMPT_FILE"
[[ -z "$HLD_FILE" || -z "$LLD_FILE" || -z "$STORY_FILE" ]] && \
  echo "Warning: one or more of HLD/LLD/story files were not found (check your globs)." >&2
[[ -z "$DIFF_RAW" ]] && \
  echo "Warning: no staged diff found (did you 'git add' your changes?)." >&2