#!/usr/bin/env bash
# Stop: the "done" gate from CLAUDE.md. When the working tree has changed
# hand-written Dart files, run dart analyze --fatal-infos and flutter test;
# on failure, keep the agent working (exit 2) with the error tail.
input=$(cat)
# Already continuing because of this hook: let it stop to avoid a loop.
[[ $(jq -r '.stop_hook_active // false' <<<"$input") == true ]] && exit 0
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

changed=$(git status --porcelain -- '*.dart' |
  grep -v -E '\.(g|freezed)\.dart$|lib/l10n/app_localizations')
[[ -z "$changed" ]] && exit 0

if ! out=$(dart analyze --fatal-infos 2>&1); then
  printf 'Done gate: dart analyze --fatal-infos failed.\n%s\n' "$(tail -n 40 <<<"$out")" >&2
  exit 2
fi
if ! out=$(TZ=Europe/Kyiv flutter test 2>&1); then
  printf 'Done gate: flutter test failed.\n%s\n' "$(tail -n 40 <<<"$out")" >&2
  exit 2
fi
exit 0
