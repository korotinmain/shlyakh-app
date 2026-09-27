#!/usr/bin/env bash
# PreToolUse(Edit|Write): generated files are overwritten on the next
# generation (docs/decisions/0001); point to the source instead.
f=$(jq -r '.tool_input.file_path // empty')
case "$f" in
  *.g.dart | *.freezed.dart | *.g.swift | */lib/l10n/app_localizations*.dart)
    echo "Blocked: $f is generated. Edit its source instead (ARB file for l10n, the annotated Dart class for build_runner, the pigeons/ definition for Pigeon) and regenerate." >&2
    exit 2
    ;;
esac
exit 0
