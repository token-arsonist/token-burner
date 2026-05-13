#!/usr/bin/env bash
# Test harness for transcript.sh. Exercises private helper directly
# by setting up a fake $HOME/.claude/projects/ tree per fixture.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../transcript.sh"
PASS=0
FAIL=0

run_case() {
  local name="$1" fixture="$2" expected="$3"
  local tmp; tmp=$(mktemp -d)
  local project_key="-tmp-tokenburner-test"
  mkdir -p "$tmp/.claude/projects/$project_key"
  cp "$HERE/fixtures/$fixture" "$tmp/.claude/projects/$project_key/test-session.jsonl"

  local got
  got=$(HOME="$tmp" CLAUDE_CODE_SESSION_ID="test-session" \
         CLAUDE_PROJECT_DIR="/tmp/tokenburner/test" \
         bash "$SCRIPT")
  rm -rf "$tmp"

  if [ "$got" = "$expected" ]; then
    echo "PASS  $name (expected $expected, got $got)"
    PASS=$((PASS+1))
  else
    echo "FAIL  $name (expected $expected, got $got)"
    FAIL=$((FAIL+1))
  fi
}

run_case "empty"       empty.jsonl       0
run_case "single-turn" single-turn.jsonl 3
run_case "multi-turn"  multi-turn.jsonl  70

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
