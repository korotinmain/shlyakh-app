# Coverage thresholds check — design

Date: 2026-09-27
Status: approved in chat (sections 1–2 of the conversation), pending spec review

## Goal

Enforce the line coverage floors of `docs/AGENT_RULES.md` 8.5 automatically,
locally and on CI, so an untested layer or an untested new file fails the
build.

## Success criteria

- CI fails when a layer is below its threshold or when a measured file is
  not loaded by any test; the output names the layer and the files.
- CI passes on the current `main` (no `domain/`, `data/` or providers yet).
- The script's own logic (lcov parsing, classification, evaluation) is
  covered by unit tests.

## Out of scope

- "Coverage must not decrease" ratchet (no baseline file, no base-branch
  run). Thresholds only; the no-decrease rule stays a review requirement
  in AGENT_RULES 8.5.
- Branch or function coverage. Line coverage only.
- New dependencies.

## Decisions

| Topic | Decision |
|---|---|
| No-decrease rule | Not automated; thresholds only |
| Layer detection | By path convention (table below) |
| Files missing from lcov | Fail and list them ("not loaded by any test") |
| Explicit opt-out | `// coverage:ignore-file` stays available for rare cases; the comment must say why |

## Layers

Paths are relative to the package root, as they appear in `lcov.info`
(`SF:lib/...`).

| Path | Layer | Threshold |
|---|---|---|
| `*.g.dart`, `*.freezed.dart`, `lib/l10n/**`, `lib/main.dart`, `lib/app/**` | excluded | — |
| `lib/features/*/domain/**` | domain | 100% |
| `lib/features/*/data/**` | data | ≥ 85% |
| `lib/features/*/presentation/providers/**` | presentation logic | ≥ 85% |
| other `lib/features/*/presentation/**` | excluded (widgets) | — |
| `lib/core/**` | core | only in the overall total |
| anything else under `lib/` | core | only in the overall total |

Rules are evaluated top to bottom; the first match wins (so a generated
file under `domain/` is excluded). Overall total = domain + data +
presentation logic + core, threshold ≥ 85%.

## Structure

```
tool/coverage/
├── check_coverage.dart   # CLI entry point, the only code doing IO
└── src/
    ├── lcov.dart         # parse lcov text
    ├── layers.dart       # classify a path into a Layer
    └── thresholds.dart   # evaluate coverage against thresholds
test/tool/coverage/
├── lcov_test.dart
├── layers_test.dart
└── thresholds_test.dart
```

### Units

- `parseLcov(String content) → Map<String, FileCoverage>` where
  `FileCoverage(linesFound, linesHit)`. Counts come from `DA:` records
  (a line is hit when its count > 0), not from `LF`/`LH`, which are
  optional in the format. Multiple records for the same file are merged.
- `classify(String path) → Layer` with
  `Layer { domain, data, presentationLogic, core, excluded }`.
- `evaluate({required Map<String, FileCoverage> coverage, required List<String> measuredCandidates}) → CoverageReport`:
  - `measuredCandidates` = all `lib/**.dart` paths that are not excluded
    and do not contain `coverage:ignore-file`.
  - Per layer: files, lines hit/found, percentage, threshold, pass/fail.
  - A layer with zero lines found is `n/a` and passes.
  - `missingFiles`: candidates absent from the lcov map → failure.
  - Threshold comparison uses integers (`hit * 100 >= threshold * found`)
    so 100% is exact.
- CLI `dart run tool/coverage/check_coverage.dart [path/to/lcov.info]`
  (default `coverage/lcov.info`):
  - exit 0: all pass; exit 1: a threshold or missing-file failure;
    exit 2: lcov file not found (message: run `flutter test --coverage`).
  - Prints a table per layer and, below it, the failing files with their
    percentage, and the missing files.

## CI and docs

- `.github/workflows/ci.yml`: the Test step becomes
  `flutter test --coverage`, followed by a step
  `dart run tool/coverage/check_coverage.dart`.
- `CLAUDE.md`: add the coverage command to Commands; add
  `presentation/providers/` to the project structure.
- `docs/AGENT_RULES.md` 8.5: point to the script; state that the
  no-decrease rule is checked in review.

## Testing

Unit tests, table-driven where there are thresholds:

- `lcov_test.dart`: single file; several files; a line with count 0 is not
  hit; duplicate `SF` records merge; `LF`/`LH` ignored when inconsistent
  with `DA`; empty input → empty map.
- `layers_test.dart`: one case per table row, including a `.g.dart` under
  `domain/` → excluded, `presentation/providers/` → presentation logic,
  `presentation/widgets/x.dart` → excluded, `lib/core/...` → core.
- `thresholds_test.dart`: domain 100% passes, 99.x% fails; data exactly
  85% passes, 84.9% fails; empty layer is `n/a`; missing file fails;
  overall total below 85% fails even when each layer passes.
- CLI: verified manually (missing lcov → exit 2; current `main` → exit 0;
  a temporary `domain/` file without tests → exit 1 listing it), plus
  CI going red on that temporary file before it is removed.

## Risks

- `flutter test --coverage` path format (`SF:lib/...` relative) is taken
  from the current output; if it ever becomes absolute, `classify` must
  normalize. Tests pin the relative form.
- Files that contain only declarations (abstract interfaces, enums,
  constants, typedefs) get no lcov record at all, even when a test loads
  them (verified during final review). The CLI therefore skips candidates
  without executable code (`hasExecutableCode`: `=>` or `) {` outside
  comments and strings). Heuristic risk: a file whose only code is a
  constructor initializer list is treated as declaration-only.
- `hasIgnoreFileComment` uses package:coverage's own regex, so the script
  omits exactly the files `flutter test --coverage` omits. A reason must
  go on the next line (`// coverage:ignore-file reason: x` is not
  recognised by flutter).
- `lib/features/*/presentation/providers/` is a new convention; a provider
  placed elsewhere in `presentation/` is silently treated as a widget and
  not measured. Mitigated by documenting the convention in CLAUDE.md.
