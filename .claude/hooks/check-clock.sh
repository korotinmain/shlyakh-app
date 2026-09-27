#!/usr/bin/env bash
# PostToolUse(Edit|Write): "now" must come from an injected Clock
# (docs/decisions/0002). Flags DateTime.now() in lib/ outside clockProvider.
f=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty')
[[ "$f" == */lib/*.dart && -f "$f" ]] || exit 0
[[ "$f" == */lib/core/time/clock_provider.dart ]] && exit 0
hits=$(grep -n 'DateTime\.now()' "$f" | grep -v -E '^[0-9]+:[[:space:]]*//')
[[ -z "$hits" ]] && exit 0
echo "DateTime.now() in $f violates docs/decisions/0002-explicit-clock-injection.md. Inject a Clock (constructor in domain, clockProvider in presentation):" >&2
echo "$hits" >&2
exit 2
