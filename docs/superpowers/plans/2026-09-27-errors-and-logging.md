# Error Handling and Logging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A sealed `Failure` type with localized messages, a typed logger that cannot log free-form text, and app-level handlers that route unhandled errors to it.

**Architecture:** `lib/core/error/` (failures and their messages), `lib/core/logging/` (events, logger, provider), `lib/app/error_handlers.dart` (functions installed by `main.dart`). No new dependencies: `dart:developer` only.

**Tech Stack:** Dart 3.13 (`new(...)`, sealed classes, exhaustive switch), flutter_riverpod 3, gen-l10n, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-27-errors-and-logging-design.md`

## Global Constraints

- Branch `feat/errors-logging`; Conventional Commits ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- No new dependencies.
- Nothing logs an exception's `toString()` or message, a `Failure.cause`'s message, steps, XP, dates or ids. Output contains only event names, `LogValue`s, runtime type names and stack traces.
- `dart:developer` `log` is imported only in `lib/core/logging/app_logger.dart`.
- Copy: the spec's message table, verbatim, in `app_en.arb` / `app_uk.arb`.
- Gate before each commit: `dart format --output=none --set-exit-if-changed . && dart analyze --fatal-infos && flutter test --coverage && dart run tool/coverage/check_coverage.dart`.
- Verified signatures: `dart:developer` `log(String message, {..., String name, Object? error, StackTrace? stackTrace})`; `PlatformDispatcher.onError` is `bool Function(Object, StackTrace)`; `FlutterError.onError` is `void Function(FlutterErrorDetails)`.

## Review Focus

- A `cause` whose message contains sensitive text (e.g. `'steps=12345 user=abc'`) never appears in logger output. Test in Task 2.
- String interpolation of a `Failure` (`'$failure'`) never reveals its cause. Test in Task 1.
- An error that is not a `Failure` still gets a user-facing message (the generic one) instead of throwing in the UI mapping. Test in Task 1.
- A release build writes nothing, for all three logger methods. Test in Task 2.
- An unhandled async error is logged and reported as handled (`true`), so it neither disappears nor crashes. Test in Task 3.

---

### Task 1: Failures and their messages

**Files:**
- Create: `lib/core/error/failure.dart`, `lib/core/error/failure_message.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_uk.arb` (5 keys, `@` descriptions in en)
- Test: `test/core/error/failure_message_test.dart`

**Interfaces:**
- Produces: the spec's `Failure` hierarchy (each with `const new({super.cause})`, `toString()` → variant name, e.g. `'StorageFailure'`); `String failureMessage(AppLocalizations l10n, Object error)`.

- [ ] **Step 1: Write the failing tests** — table of `(Object error, String en, String uk)` with all four variants and `StateError('x')` (→ `errorGeneric`), asserting `failureMessage(lookupAppLocalizations(Locale(...)), error)` equals the spec's text; plus `'toString names the variant only'`: `StorageFailure(cause: Exception('steps=12345')).toString() == 'StorageFailure'` and `'$failure'` does not contain `'12345'`.

- [ ] **Step 2: Run** `flutter test test/core/error` — Expected: FAIL, not defined.

- [ ] **Step 3: Implement** failures, ARB keys (`flutter gen-l10n`), `failureMessage` as `switch (error) { HealthAccessDenied() => …, …, _ => l10n.errorGeneric }` — the inner `Failure` part must be exhaustive (use a nested `switch` on `Failure` so adding a variant breaks compilation).

- [ ] **Step 4: Run** — Expected: 6 PASS; commit `feat(core): sealed Failure type with localized messages`.

### Task 2: Typed logger

**Files:**
- Create: `lib/core/logging/log_events.dart`, `lib/core/logging/app_logger.dart`, `lib/core/logging/logger_provider.dart`, `test/helpers/recording_logger.dart`
- Test: `test/core/logging/app_logger_test.dart`

**Interfaces:**
- Consumes: `Failure` (Task 1).
- Produces:
  - `sealed class LogValue` with `const factory LogValue.flag(bool)`, `.kind(Enum)`, `.duration(Duration)`, `.count(int)` (private final subclasses) and `String render()` → `true`/`false`, `enum.name`, `'${ms}ms'`, `'$count'`.
  - `abstract class LogEvent { const new(); String get name; Map<String, LogValue> get fields; }` — `abstract` (not sealed) is required because test-only events must subclass it from another library; the "all events in one file" rule is enforced by AGENT_RULES 5 and review. Ruling to record.
  - `typedef LogSink = void Function(String message, {StackTrace? stackTrace});`
  - `abstract interface class AppLogger { void log(LogEvent); void failure(Failure); void error(Object, StackTrace); }`
  - `final class DeveloperLogger implements AppLogger` — `const new({required bool enabled, LogSink sink = _developerSink})`; `_developerSink` calls `developer.log(message, name: 'shlyakh', stackTrace: stackTrace)`. Output lines: `event <name> k=v …` (fields in insertion order), `failure <failure.runtimeType> cause=<cause.runtimeType or none>`, `error <error.runtimeType>` with `stackTrace` passed to the sink.
  - `@Riverpod(keepAlive: true) AppLogger logger(Ref ref) => const DeveloperLogger(enabled: kDebugMode);` in `logger_provider.dart`, first lines `// coverage:ignore-file` + `// Reason: DI wiring; tests override loggerProvider.`
  - `RecordingLogger implements AppLogger` with `final events = <LogEvent>[]; final failures = <Failure>[]; final errors = <Object>[];`.

- [ ] **Step 1: Write the failing tests** with a capturing sink (`lines`, `stacks`) and a test-only `_TestEvent extends LogEvent` (name `'test_event'`, fields `ok: flag(true)`, `trigger: kind(_Trigger.background)`, `took: duration(1234ms)`, `days: count(3)`):
  - `'log renders the event and every value type'` → `event test_event ok=true trigger=background took=1234ms days=3`.
  - `'failure writes the variant and cause type only'`: `StorageFailure(cause: FormatException('steps=12345 user=abc'))` → exactly `failure StorageFailure cause=FormatException`; no line contains `12345` or `abc`.
  - `'failure without a cause'` → `failure HealthAccessDenied cause=none`.
  - `'error writes the type and passes the stack trace'`: `StateError('steps=12345')` → `error StateError`, stack captured, `12345` absent.
  - `'writes nothing when disabled'`: `enabled: false`, all three methods → `lines` empty.

- [ ] **Step 2: Run** `flutter test test/core/logging` — Expected: FAIL, not defined.

- [ ] **Step 3: Implement** Task 2 interfaces; `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Run** — Expected: 5 PASS; full gate; commit `feat(core): typed logger that never logs messages`.

### Task 3: App-level handlers and docs

**Files:**
- Create: `lib/app/error_handlers.dart`
- Modify: `lib/main.dart`
- Create: `docs/decisions/0005-error-handling.md`, `docs/decisions/0006-logging.md`
- Modify: `docs/AGENT_RULES.md` (1 and 5), `docs/ARCHITECTURE.md` (section 5)
- Test: `test/app/error_handlers_test.dart`

**Interfaces:**
- Consumes: `AppLogger`, `loggerProvider` (Task 2).
- Produces:
  - `FlutterExceptionHandler flutterErrorHandler(AppLogger logger, {required bool presentInDebug})` — calls `logger.error(details.exception, details.stack ?? StackTrace.empty)` and, when `presentInDebug`, `FlutterError.presentError(details)`.
  - `ErrorCallback platformErrorHandler(AppLogger logger)` — logs and returns `true`.
  - `main.dart`: create a `ProviderContainer`, install both handlers with the container's logger (`presentInDebug: kDebugMode`), then `runApp(UncontrolledProviderScope(container: container, child: const App()))`.

- [ ] **Step 1: Write the failing tests** with `RecordingLogger`:
  - `'flutter errors reach the logger'`: `flutterErrorHandler(logger, presentInDebug: false)(FlutterErrorDetails(exception: StateError('x'), stack: StackTrace.current))` → `logger.errors` has one `StateError`.
  - `'platform errors are logged and marked handled'`: `platformErrorHandler(logger)(StateError('x'), StackTrace.current)` returns `true`, `logger.errors` has one entry.

- [ ] **Step 2: Run** `flutter test test/app/error_handlers_test.dart` — Expected: FAIL, not defined.

- [ ] **Step 3: Implement** `error_handlers.dart` and the `main.dart` wiring. Check that `test/app/app_test.dart` (which pumps `App` inside its own `ProviderScope`) still passes.

- [ ] **Step 4: Docs.** ADR 0005 (errors: exceptions + sealed Failure vs `Result`, the layer rules, programmer errors uncaught) and ADR 0006 (logging: typed events vs free-form `logging` package vs none; types-only failures; debug-only sink; crash reporting later). AGENT_RULES 1: link ADR 0005 and add "repositories catch only specific exceptions and rethrow a `Failure`". AGENT_RULES 5: link ADR 0006 and the spec's logging bullet. ARCHITECTURE section 5: error handling and logging → [built]; section 8: remove the error handling / logging open question.

- [ ] **Step 5: Verify** the full gate; commit `feat(app): route unhandled errors to the logger` and `docs: ADRs 0005 and 0006 for errors and logging`; push; open the PR.
