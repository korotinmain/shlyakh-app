#!/usr/bin/env bash
# PostToolUse(Edit|Write): format the edited Dart file so CI's format check
# never fails on agent edits.
f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')
[[ "$f" == *.dart && -f "$f" ]] || exit 0
dart format "$f" >/dev/null
