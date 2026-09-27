# 0001. Generated files are not committed

Date: 2026-09-26
Status: accepted

## Context

build_runner (Riverpod, freezed, json_serializable) and gen-l10n produce
Dart files from annotated sources and ARB files. They can be committed, or
regenerated on every machine and on CI.

## Decision

Generated files are not committed: `*.g.dart`, `*.freezed.dart` and
`lib/l10n/app_localizations*.dart` are in `.gitignore`. They are produced by
`dart run build_runner build --delete-conflicting-outputs` and
`flutter gen-l10n`. Because `generate: true` is set in `pubspec.yaml`,
`flutter pub get` also regenerates the l10n files; `flutter test` does not.

## Consequences

- Pull request diffs contain only hand-written code; generated files never
  drift from their sources and cannot conflict in merges.
- After a clone or a branch switch, run build_runner before analyzing or
  testing. Forgetting it fails loudly: the code does not compile.
- CI must run `flutter pub get` (regenerates l10n) and build_runner
  before `dart analyze --fatal-infos` and `flutter test`, which makes it
  slightly slower.
- Pigeon (native bridge) splits: its Dart output is `*.g.dart` and follows
  this rule (regenerate with `dart run pigeon --input <file>`), but its
  Swift output (`*.g.swift`) is committed, because Xcode compiles it
  directly and does not run Dart tooling.
- `dart run drift_dev make-migrations` output is committed: the schema
  snapshots in `drift_schemas/` and, from schema version 2 on, the
  generated migration steps and tests. Old schema versions cannot be
  regenerated from the current code, and CI must never create a snapshot
  on its own.
