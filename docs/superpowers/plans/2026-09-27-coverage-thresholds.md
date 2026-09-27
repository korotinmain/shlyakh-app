# Coverage Thresholds Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A dependency-free Dart CLI that checks `coverage/lcov.info` against the AGENT_RULES 8.5 floors per layer, wired into CI.

**Architecture:** Three pure modules under `tool/coverage/src/` (parse lcov, classify paths, evaluate thresholds) and one CLI that does all IO. Unit tests live in `test/tool/coverage/` and run with the normal `flutter test`.

**Tech Stack:** Dart 3.13 (`new(...)` constructors, records, patterns), `dart:io` only in the CLI, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-27-coverage-thresholds-design.md`

## Global Constraints

- Branch `chore/coverage-thresholds`; Conventional Commits ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- No new dependencies. Only `dart:io` / `dart:core` in `tool/`.
- Thresholds: domain 100, data 85, presentationLogic 85, overall 85 (percent, integers). Core has no own threshold.
- Comparison: `linesHit * 100 >= threshold * linesFound`. A layer with `linesFound == 0` passes and prints `n/a`.
- Exit codes: 0 pass, 1 threshold or missing-file failure, 2 lcov file not found.
- Paths are package-relative with forward slashes (`lib/...`), exactly as in `SF:` records.
- `very_good_analysis` applies to `tool/`: no `print` (use `stdout.writeln` / `stderr.writeln`).
- Gate before each commit: `dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && flutter test`.

## Review Focus

- lcov with CRLF line endings → parsed exactly like LF. Test in Task 1.
- Nested folders inside a layer (`lib/features/a/domain/sub/x.dart`) → still domain. Test in Task 2.
- A source file whose header contains `// coverage:ignore-file` → not a measured candidate (otherwise it would be reported missing, since lcov omits it). Test in Task 2.
- Stale lcov entry for a file that is no longer a candidate (deleted or now excluded) → ignored in totals. Test in Task 3.
- Nothing measurable at all (today's `main`) → every layer `n/a`, overall `n/a`, report passes. Test in Task 3.

---

### Task 1: lcov parser

**Files:**
- Create: `tool/coverage/src/lcov.dart`
- Test: `test/tool/coverage/lcov_test.dart`

**Interfaces:**
- Produces:
  - `class FileCoverage { const new({required int linesFound, required int linesHit}); final int linesFound; final int linesHit; }` with value equality (`==`/`hashCode`) so tests can compare maps.
  - `Map<String, FileCoverage> parseLcov(String content)`

- [ ] **Step 1: Write the failing tests** (`group('parseLcov', ...)`):
  - `'counts found and hit lines from DA records'`: `SF:lib/a.dart\nDA:1,1\nDA:2,0\nDA:3,5\nend_of_record\n` → `{'lib/a.dart': FileCoverage(linesFound: 3, linesHit: 2)}`
  - `'parses several files'`: two records → two entries with their own counts.
  - `'ignores LF and LH in favour of DA'`: record with `LF:10\nLH:10` but DA `1,1` and `2,0` → `(2, 1)`.
  - `'merges duplicate records for the same file'`: two records for `lib/a.dart`, DA lines `1,1` / `2,0` in the first and `2,3` / `3,0` in the second → `(3, 2)` (line 2 is hit once any record hits it).
  - `'handles CRLF line endings'`: the first case with `\r\n` → same result.
  - `'returns an empty map for empty input'`: `''` → `{}`.

- [ ] **Step 2: Run** `flutter test test/tool/coverage/lcov_test.dart` — Expected: FAIL, `parseLcov` / `FileCoverage` not defined.

- [ ] **Step 3: Implement `parseLcov`** — track per-file `Map<int, bool>` of line → hit so duplicates merge; split on `\n` and trim `\r`.

- [ ] **Step 4: Run** the same command — Expected: 6 PASS.

- [ ] **Step 5: Commit** `feat(tool): parse lcov coverage records`

### Task 2: layer classification

**Files:**
- Create: `tool/coverage/src/layers.dart`
- Test: `test/tool/coverage/layers_test.dart`

**Interfaces:**
- Produces:
  - `enum Layer { domain, data, presentationLogic, core, excluded }`
  - `Layer classify(String path)` — rules top to bottom, first match wins, exactly the spec's Layers table.
  - `bool hasIgnoreFileComment(String source)` — true when any line, trimmed, equals `// coverage:ignore-file` or starts with `// coverage:ignore-file ` (a reason may follow).

- [ ] **Step 1: Write the failing tests** — table-driven `classify` cases (name, path, expected):

```dart
('generated g.dart', 'lib/features/x/domain/a.g.dart', Layer.excluded),
('generated freezed', 'lib/features/x/data/a.freezed.dart', Layer.excluded),
('l10n output', 'lib/l10n/app_localizations.dart', Layer.excluded),
('main', 'lib/main.dart', Layer.excluded),
('bootstrap', 'lib/app/router.dart', Layer.excluded),
('domain', 'lib/features/steps/domain/xp.dart', Layer.domain),
('nested domain', 'lib/features/steps/domain/rules/level.dart', Layer.domain),
('data', 'lib/features/steps/data/steps_repository.dart', Layer.data),
('providers', 'lib/features/steps/presentation/providers/today.dart', Layer.presentationLogic),
('widget', 'lib/features/steps/presentation/widgets/ring.dart', Layer.excluded),
('screen', 'lib/features/home/presentation/home_screen.dart', Layer.excluded),
('core', 'lib/core/time/clock_provider.dart', Layer.core),
('other lib file', 'lib/shared/x.dart', Layer.core),
```

  plus `hasIgnoreFileComment`: `'// coverage:ignore-file'` → true; `'// coverage:ignore-file reason: FFI glue'` → true; `'// coverage:ignore-line'` → false; `'final s = "// coverage:ignore-file";'` → false.

- [ ] **Step 2: Run** `flutter test test/tool/coverage/layers_test.dart` — Expected: FAIL, not defined.

- [ ] **Step 3: Implement** `classify` (string checks on the path; `lib/features/<name>/<layer>/...` via `split('/')`) and `hasIgnoreFileComment`.

- [ ] **Step 4: Run** — Expected: 17 PASS.

- [ ] **Step 5: Commit** `feat(tool): classify source files into coverage layers`

### Task 3: threshold evaluation

**Files:**
- Create: `tool/coverage/src/thresholds.dart`
- Test: `test/tool/coverage/thresholds_test.dart`

**Interfaces:**
- Consumes: `FileCoverage` (Task 1), `Layer`, `classify` (Task 2).
- Produces:
  - `const layerThresholds = {Layer.domain: 100, Layer.data: 85, Layer.presentationLogic: 85};` and `const overallThreshold = 85;`
  - `class LayerResult` with `String name`, `int fileCount`, `int linesFound`, `int linesHit`, `int? threshold`, `bool get isEmpty` (`linesFound == 0`), `bool get passed` (empty, or no threshold, or integer comparison holds).
  - `class CoverageReport` with `List<LayerResult> layers` (domain, data, presentationLogic, core — in that order), `LayerResult overall`, `List<String> missingFiles` (sorted), `List<(String path, FileCoverage coverage)> filesBelowThreshold` (files in a thresholded layer whose own coverage is below that layer's threshold, sorted by path), `bool get passed` (all layers + overall passed and `missingFiles` empty).
  - `CoverageReport evaluate({required Map<String, FileCoverage> coverage, required List<String> candidates})` — only paths in `candidates` count; lcov entries not in `candidates` are ignored.

- [ ] **Step 1: Write the failing tests** (`group('evaluate', ...)`), candidates built with the paths from Task 2's table:
  - `'passes domain at exactly 100%'`: domain file `(4, 4)` → domain passed.
  - `'fails domain below 100%'`: `(200, 199)` → domain failed, file listed in `filesBelowThreshold`.
  - `'passes data at exactly 85%'`: `(20, 17)` → passed.
  - `'fails data just below 85%'`: `(1000, 849)` → failed.
  - `'treats a layer without lines as n/a and passing'`: no data files → data `isEmpty` and `passed`.
  - `'fails when a candidate is missing from lcov'`: candidate `lib/features/s/domain/x.dart` absent from coverage → `missingFiles == [that path]`, `passed == false`.
  - `'fails overall below 85% even when every layer passes'`: domain `(10, 10)`, core `(90, 60)` → layers pass (core has no threshold), overall 70/100 fails.
  - `'ignores lcov entries that are not candidates'`: coverage has `lib/features/s/domain/old.dart (10, 0)`, candidates do not → domain `isEmpty`, report passes.
  - `'passes when nothing is measurable'`: `coverage: {}`, `candidates: []` → all layers and overall `isEmpty`, `passed == true`.

- [ ] **Step 2: Run** `flutter test test/tool/coverage/thresholds_test.dart` — Expected: FAIL, not defined.

- [ ] **Step 3: Implement `evaluate`** — group candidates by `classify`, sum per layer, overall = sum of domain + data + presentationLogic + core.

- [ ] **Step 4: Run** — Expected: 9 PASS.

- [ ] **Step 5: Commit** `feat(tool): evaluate coverage against layer thresholds`

### Task 4: CLI, CI and docs

**Files:**
- Create: `tool/coverage/check_coverage.dart`
- Modify: `.github/workflows/ci.yml`, `CLAUDE.md`, `docs/AGENT_RULES.md` (8.5), `lib/core/time/clock_provider.dart` (opt-out comment)

**Interfaces:**
- Consumes: `parseLcov`, `classify`, `hasIgnoreFileComment`, `evaluate`, `CoverageReport`.
- Produces: `Future<void> main(List<String> args)`; `args.firstOrNull ?? 'coverage/lcov.info'`. Candidates = every `*.dart` under `lib/` (recursive, paths made package-relative with `/`) where `classify != Layer.excluded` and `!hasIgnoreFileComment(source)`. Sets `exitCode` 0/1/2 per Global Constraints; exit 2 prints `No coverage file at <path>. Run: flutter test --coverage` to stderr.

- [ ] **Step 1: Implement the CLI.** Output: one line per layer and the overall line, e.g. `domain              3 files   120/120  100.0%  (min 100%)  OK`, `data                0 files     n/a            (min 85%)   OK`, `core                2 files     9/10   90.0%  (no min)    OK`; then `Below threshold:` and `Not loaded by any test:` sections with one path per line, only when non-empty; last line `Coverage check passed.` or `Coverage check FAILED.`

- [ ] **Step 2: Verify the three exit paths manually**

Run: `dart run tool/coverage/check_coverage.dart /nonexistent; echo "exit=$?"`
Expected: stderr message, `exit=2`.

Run: `flutter test --coverage && dart run tool/coverage/check_coverage.dart; echo "exit=$?"`
Expected: `lib/core/time/clock_provider.dart` is a core candidate that no test loads → listed under `Not loaded by any test:`, `exit=1`. This is a real finding, not a script bug. Do NOT write a test for it: a test of the real clock needs real time (forbidden by AGENT_RULES 8.4) and would be a hollow test of trivial wiring (8.3). It is DI wiring like `lib/app/`, so add as its first line `// coverage:ignore-file reason: DI wiring for the real clock; tests override clockProvider.` (the spec's opt-out with a reason). Re-run → `exit=0`.

Run: create `lib/features/probe/domain/probe.dart` with `int probe(int x) => x + 1;`, `flutter test --coverage && dart run tool/coverage/check_coverage.dart; echo "exit=$?"`
Expected: the file under `Not loaded by any test:`, `exit=1`. Keep it for Step 4.

- [ ] **Step 3: Wire CI.** In `ci.yml` replace the Test step's `flutter test` with `flutter test --coverage` and add a step `Coverage thresholds` running `dart run tool/coverage/check_coverage.dart`. `CLAUDE.md`: Commands gains `dart run tool/coverage/check_coverage.dart` after `flutter test --coverage`; project structure gains `presentation/providers/` under `<feature>/presentation/`. `AGENT_RULES.md` 8.5: add "Checked by `tool/coverage/check_coverage.dart` (CI); the no-decrease rule is checked in review." and "Presentation logic lives in `presentation/providers/`."

- [ ] **Step 4: Prove CI goes red.** Commit and push everything with the probe file, open the PR. Expected: the `Coverage thresholds` step fails listing the probe. Then `git revert` the probe commit (or delete the file in a new commit) and push. Expected: CI green.

- [ ] **Step 5: Commits**
  - `feat(tool): add coverage thresholds CLI and CI step` (CLI, CI, docs, clock_provider opt-out)
  - `test: TEMPORARY untested domain file to prove coverage gate (will be reverted)` (probe only)
  - the revert
