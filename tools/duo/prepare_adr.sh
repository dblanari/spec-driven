#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# ADR Draft Review Prompt Creation and Validation (no git usage)
# - Builds a paste-ready prompt aggregating: Business Context, Data ADR drafts, template, examples.
# - Emphasis: validating draft ADR against template & business context alignment.
#
# Usage:
#   tools/duo/prepare_adr.sh [--max-doc-chars N]
#
# Defaults:
#   --max-doc-chars 200000   Trim each doc to first N chars (0 = unlimited)
#
# Source directories (adjust if your layout differs):
DATA_DIR='docs/md/ADRs/ADR3/data'
EXAMPLES_DIR='docs/md/ADRs/examples'
BUSINESS_CONTEXT_DIR='docs/md/ADRs/business_context'
TEMPLATE_DIR='docs/md/ADRs/template'
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
You are a senior architecture. Use the inline ADR materials below.

SECTIONS PROVIDED (order):
- BUSINESS CONTEXT
- ADR TEMPLATE (authoritative required structure & section purposes)
- DATA ADR (drafts to validate)
- EXAMPLE ADR (reference patterns)

PRIMARY FOCUS
- Create ADR drafts (DATA ADR) for completeness, validate, and alignment with business context.

TASKS
1) Draft Completeness & Template Adherence
   - Enforce required sections exactly as defined in ADR TEMPLATE section below (names, order, intent).
2) Context Alignment
   - Ensure decisions are consistent with business domain, payment flows, constraints, KPIs found in Business Context.
3) Validation Criteria
   - Confirm each ADR defines measurable KPIs / acceptance tests enabling post-decision evaluation.
4) Risk & Impact
   - Identify operational, security, scalability, compliance, migration risks; propose mitigations.
5) Cross-ADR Consistency
   - Flag conflicting or duplicate decisions; note if any ADR supersedes another.
6) Improvement Suggestions
   - Provide concise actionable edits (section + recommendation).
7) Follow-up & Validation Plan
   - List concrete next steps, open questions, required experiments or metrics instrumentation.

OUTPUT FORMAT
- Template adherence summary
- Context alignment issues
- Cross-ADR conflicts / overlaps
- Risks & mitigations
- Validation gaps (missing KPIs/tests)
- Improvement suggestions
- Follow-up action list
- Verdict: Ready / Needs Revisions (with rationale)
EOF

echo >> "$TMP_PROMPT_FILE"

# Insert Business Context section before ADR for alignment.
append_group_section "BUSINESS CONTEXT" "$BUSINESS_CONTEXT_DIR" "$TMP_PROMPT_FILE"
append_group_section "ADR TEMPLATE"     "$TEMPLATE_DIR"          "$TMP_PROMPT_FILE"
append_group_section "DATA ADR"         "$DATA_DIR"              "$TMP_PROMPT_FILE"
append_group_section "EXAMPLE ADR"      "$EXAMPLES_DIR"          "$TMP_PROMPT_FILE"

{
  echo "[meta]: generation_timestamp=$STAMP max_doc_chars=$MAX_DOC_CHARS"
} | append_text_block "META" "$TMP_PROMPT_FILE"

echo "-------------------------------- CUT ABOVE ---------------------------------------------------------------" >> "$TMP_PROMPT_FILE"

cat "$TMP_PROMPT_FILE"
rm -f "$TMP_PROMPT_FILE"
