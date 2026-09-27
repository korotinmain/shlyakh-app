# 0004. English template and fallback for localization

Date: 2026-09-26
Status: accepted

## Context

The app supports Ukrainian and English (gen-l10n, ARB files). Flutter picks
the first supported locale that matches the device's preferred languages
and otherwise falls back to the first entry of `supportedLocales`. We need
a fallback for devices set to any other language.

## Decision

- Supported locales, in order: `en`, `uk`.
- `app_en.arb` is the template ARB; `app_uk.arb` is a translation.
- Unsupported system languages fall back to English.
- No in-app language switcher: iOS offers a per-app language in
  Settings, enabled by `CFBundleLocalizations` in `Info.plist`.

## Consequences

- The fallback language and the template are the same, so gen-l10n never
  reports template keys missing from the fallback.
- A device with preferred languages `[pl, uk]` gets Ukrainian: a supported
  language anywhere in the list wins over the fallback.
- Every new string is written in English first and must be translated to
  Ukrainian in the same change.

## Manual check on iOS

Widget tests cover Flutter's locale resolution but not what iOS reports.
Check on the simulator after touching localization or `Info.plist`:

```bash
xcrun simctl spawn <sim> defaults write -g AppleLanguages '("en-UA","uk-UA")'
xcrun simctl launch --terminate-running-process <sim> com.denyskorotin.shlyakh
```

Expect "Shlyakh"; with `'("uk-UA","en-UA")'` expect "Шлях".
`--terminate-running-process` is required: `defaults write` does not
restart running apps (unlike the Settings app), and the Flutter engine
reads the preferred languages only at startup and on
`NSCurrentLocaleDidChangeNotification`, which a `defaults write` of
`AppleLanguages` does not send. A plain `simctl launch` brings the old
process to the foreground with the old languages.
