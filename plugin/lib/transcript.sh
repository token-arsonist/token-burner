#!/usr/bin/env bash
# Resolve current Claude Code session's transcript files and print
# total OUTPUT tokens. Output is what /burn actually controls; input
# and cache costs are dominated by uncontrollable context overhead.
# Reads CLAUDE_CODE_SESSION_ID and CLAUDE_PROJECT_DIR from env.
set -uo pipefail

session_id="${CLAUDE_CODE_SESSION_ID:-}"
project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
project_key=$(printf '%s' "$project_dir" | tr '/' '-')
base="$HOME/.claude/projects/$project_key"

files=()
if [ -n "$session_id" ] && [ -f "$base/$session_id.jsonl" ]; then
  files+=("$base/$session_id.jsonl")
fi
if [ -n "$session_id" ] && [ -d "$base/$session_id/subagents" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] && files+=("$f")
  done < <(find "$base/$session_id/subagents" -name "*.jsonl" 2>/dev/null)
fi

# Fallback: most recently modified jsonl under projects/
if [ ${#files[@]} -eq 0 ]; then
  fallback=$(find "$HOME/.claude/projects" -name "*.jsonl" -type f -print0 2>/dev/null \
    | xargs -0 ls -t 2>/dev/null | head -1)
  [ -n "$fallback" ] && files+=("$fallback")
fi

if [ ${#files[@]} -eq 0 ]; then
  echo 0
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  jq -s '[.[] | (.message?.usage?.output_tokens // 0)] | add // 0' "${files[@]}"
else
  python3 - "${files[@]}" <<'PY'
import json, sys
total = 0
for path in sys.argv[1:]:
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except Exception:
                    continue
                usage = (obj.get("message") or {}).get("usage")
                if not usage:
                    continue
                total += usage.get("output_tokens", 0)
    except FileNotFoundError:
        pass
print(total)
PY
fi
