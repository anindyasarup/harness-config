#!/usr/bin/env bash

payload=$(cat)
f=$(jq -r '.tool_response.filePath // .tool_input.file_path // .tool_input.notebook_path // ""' <<<"$payload")
[ -f "$f" ] || exit 0

jq -j '
  .tool_input
  | [.content, .new_string, .edits[]?.new_string, (select(.cell_type != "markdown") | .new_source)]
  | map(strings)
  | join("\n")
' <<<"$payload" |
  harness-check "$f" |
  jq -Rs 'rtrim | select(. != "") | {decision: "block", reason: .}'
