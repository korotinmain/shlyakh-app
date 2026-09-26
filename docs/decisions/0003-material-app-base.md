# 0003. MaterialApp as the app root

Date: 2026-09-26
Status: accepted

## Context

Flutter offers two widget libraries: Material and Cupertino. The root
widget (`MaterialApp` or `CupertinoApp`) decides which one the rest of the
tree can rely on. The app is iOS-only, but its visual design is custom
(illustrated landscape, own typography) and must not look like a template
(`docs/PRODUCT.md`, design principles).

## Decision

Use `MaterialApp.router` with a custom `ThemeData`.

## Consequences

- The Material look is overridden by the theme, so the choice does not
  make the app look like Android.
- Material widgets (bottom sheets, ink effects) and most packages
  (Rive wrappers, flutter_animate examples) work without extra ancestors.
- iOS platform behavior (back swipe, bouncing scroll, system font) is kept:
  Flutter adapts it to the platform regardless of the widget library.
- Individual Cupertino widgets can still be used where a native feel is
  wanted (e.g. pickers).
