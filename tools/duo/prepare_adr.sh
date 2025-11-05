#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# ADR Draft Review Prompt Preparer (no git usage)
# - Prints a single paste-ready prompt with inline ADR template, data ADRs, and example ADRs
# - Does NOT inspect git state; purely reads documentation files.
# - Portable (no bash globstar dependency; uses find)
#
# Usage:
#   tools/duo/prepare_adr.sh [--max-doc-chars N]
#
# Defaults:
#   --max-doc-chars 200000   Trim each doc to first N chars (0 = unlimited)
#
# Source directories (adjust if your layout differs):
TEMPLATE_DIR='docs/md/ADR/template'
DATA_DIR='docs/md/ADR/data'
EXAMPLES_DIR='docs/md/ADR/examples'
# ------------------------------------------------------------------------------

MAX_DOC_CHARS=200000

while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-doc-chars)  MAX_DOC_CHARS="${2:-200000}"; shift 2;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

# ----- helpers -----
ts() { date +"%Y-%m-%d_%H-%M-%S_%z"; }

append_section_header() {
  local title="$1" out="$2"
  echo "===== $title =====" >> "$out"
}

append_file_with_limit() {
  local path="$1" out="$2" max_chars="$3"
  if [[ ! -f "$path" ]]; then
    echo "(missing: $path)" >> "$out"
    return
  fi
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

list_md_recursive() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    find "$dir" -type f -name '*.md' | sort || true
  else
    return 0
  fi
}

append_group_section() {
  local title="$1" dir="$2" out="$3"
  append_section_header "$title" "$out"
  local files
  IFS=$'\n' read -r -d '' -a files < <(list_md_recursive "$dir" && printf '\0') || true
  if [[ ${#files[@]} -eq 0 ]]; then
    echo "(no markdown files in: $dir)" >> "$out"
    echo >> "$out"
    return
  fi
  for f in "${files[@]}"; do
    echo "--- file: $f" >> "$out"
    append_file_with_limit "$f" "$out" "$MAX_DOC_CHARS"
    echo >> "$out"
  done
}

append_text_block() {
  local title="$1" out="$2"
  append_section_header "$title" "$out"
  cat >> "$out"
  echo >> "$out"
}

STAMP=$(ts)
TMP_PROMPT_FILE=$(mktemp)
: > "$TMP_PROMPT_FILE"

cat >> "$TMP_PROMPT_FILE" <<'EOF'
-------------------------------- CUT BELOW (paste into ADR Review) --------------------------------
You are a senior architecture reviewer. Use the inline ADR materials below:

TASKS
1) Consistency & Clarity
   - Verify each ADR conforms to template sections (Context, Decision, Alternatives, Consequences, etc.).
   - Flag missing or vague rationale.
2) Decision Cohesion
   - Identify conflicts or redundancy across ADRs; note if newer ADRs should supersede older ones.
3) Risk & Impact
   - Highlight operational, security, scalability, and migration risks implied by decisions.
4) Validation & Metrics
   - Ensure each ADR specifies measurable validation criteria / KPIs.
5) Improvement Suggestions
   - Provide actionable edits (section + concise recommendation).
6) Follow-up Items
   - Derive concrete next steps for open questions.

OUTPUT FORMAT
- Template adherence summary
- Cross-ADR conflicts / overlaps
- Risks & mitigations
- Metrics & validation gaps
- Improvement suggestions
- Follow-up action list
- Verdict: Ready / Needs Revisions (with rationale)
EOF

echo >> "$TMP_PROMPT_FILE"
append_group_section "ADR TEMPLATE"   "$TEMPLATE_DIR"   "$TMP_PROMPT_FILE"
append_group_section "DATA ADRs"       "$DATA_DIR"       "$TMP_PROMPT_FILE"
append_group_section "EXAMPLE ADRs"    "$EXAMPLES_DIR"   "$TMP_PROMPT_FILE"

{
  echo "[meta]: generation_timestamp=$STAMP max_doc_chars=$MAX_DOC_CHARS"
} | append_text_block "META" "$TMP_PROMPT_FILE"

echo "-------------------------------- CUT ABOVE ---------------------------------------------------------------" >> "$TMP_PROMPT_FILE"

cat "$TMP_PROMPT_FILE"
rm -f "$TMP_PROMPT_FILE"
