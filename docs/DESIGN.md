# Design

The visual language of Shlyakh. Values here are the design tokens in
`lib/core/design/`; when they disagree, the code is right and this file
needs an update in the same PR. Product principles are in
`docs/PRODUCT.md` ("Design principles", "Today screen content").

The constellation path (`docs/superpowers/specs/2026-09-28-constellation-path-design.md`)
replaces the time-of-day sky with light and dark themes and the landscape
with constellations. Until its plan 3 lands, the Sky section and the
landscape notes below describe the code as it is.

## Principles

- The illustrated landscape is the hero; interface elements sit on it
  and stay quiet.
- One strong accent per screen, taken from the sky; restrained type.
- Calm and fair: rewards feel pleasant, never pushy.
- No template look: no generic dashboard cards, default gradients or
  stock icon grids.

## Sky

The sky follows the real time of day through seven keyframes. Between two
keyframes every colour is interpolated in OkLCh (lightness and chroma
linearly, hue along the shorter arc), so warm-to-cool transitions keep
their colour instead of passing through grey. The gradient places its
three colours at 0%, 55% and 100% of the height. Text drawn directly on
the sky uses its keyframe's text colour and meets WCAG AA (4.5:1) against
the top sky colour; put it in the upper part of the sky. A 12% overlay grain sits
on top.

| Keyframe | Sky top → bottom | Hills far → near | Accent | Text on sky | Glass |
|---|---|---|---|---|---|
| Pre-dawn | `#2E345E` `#5D5F8E` `#9A8FAE` | `#7A7597` `#565673` `#34364F` | `#B8A4D9` | white | dark |
| Dawn | `#545784` `#CF98A2` `#F2C7A8` | `#C29AAB` `#8B7790` `#4F4D63` | `#F2A98A` | white | dark |
| Morning | `#7EA8CF` `#BCD6E6` `#F2EBDD` | `#B7D0C6` `#8CB392` `#5B8C64` | `#F0C27A` | `#18293A` | light |
| Day | `#6C9DCC` `#A2C8E5` `#E0EEF1` | `#AECFC2` `#7EAF85` `#4D8259` | `#E9B44C` | `#18293A` | light |
| Golden hour | `#D38A6C` `#EEB385` `#F7DCB0` | `#DCA689` `#A8786A` `#634448` | `#F29A5B` | `#18293A` | dark |
| Blue hour | `#2C3868` `#546A9C` `#A2B0CF` | `#5C6A92` `#3C4870` `#252D4A` | `#A9B8E8` | white | dark |
| Night | `#121831` `#222B54` `#364378` | `#323C6C` `#222A4D` `#141A35` | `#C8D2F0` | white | dark |

When each keyframe applies, relative to local sunrise `S`, solar noon `N`
and sunset `E`:

| Keyframe | Time |
|---|---|
| Pre-dawn | `S − 60 min` |
| Dawn | `S` |
| Morning | `S + 90 min` |
| Day | `N` |
| Golden hour | `E − 60 min` |
| Blue hour | `E + 20 min` |
| Night | `E + 90 min`, held until 60 min before the next pre-dawn, then blending into it |

Sun times come from the NOAA Solar Calculator equations for Kyiv
(50.45° N, 30.52° E) until location is a deliberate privacy decision; the
error anywhere in Ukraine is minutes. Code: `skyAt(...)` in
`lib/core/design/sky/sky_palette.dart`, always called with the injected
clock's time.

## Members

Each Спільно member has one of six muted colours, chosen by an FNV-1a hash
of their user id (the same on every device): coral `#E8927C`, sage
`#8DB596`, sky `#7FA7D9`, lavender `#A99BD3`, sand `#D9B26F`, rose
`#D98BA9`.

## Typography

Geologica (bundled, SIL Open Font License, `assets/fonts/geologica/`),
one variable font: `fontWeight` drives its `wght` axis, so styles never
pin the axis themselves.

| Style | Size / weight | Use |
|---|---|---|
| `hero` | 44 / 700, −2% | the day's big number |
| `display` | 30 / 700, −2% | section numbers |
| `title` | 22 / 700, −2% | level titles |
| `headline` | 17 / 500 | labels, list titles |
| `body` | 15 / 400 | text |
| `footnote` | 13 / 400 | secondary text |
| `caption` | 11 / 300 | small print |

Numbers use tabular figures (`tabular(style)`) and locale formatting
(`intl`), which also gives Ukrainian a non-breaking space in "10 420".

## Surfaces

Matte glass: light tint white at 68% over morning and day skies, dark
tint `#161C38` at 72% otherwise; backdrop blur sigma 12; no border;
shadow `0 6 18` black at 16%. No user setting for materials.

## Spacing, radii, motion

- Spacing: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 48; screen side margin 20.
- Radii: card 20; sheet 24 (top corners); the floating tab bar is fully
  rounded.
- Motion: 150 / 300 / 600 ms, curve `easeOutCubic`. Animations are phase F.

## Delivering art (phase D)

- One file per layer: far hills, middle hills, near hills, path, trees
  or bushes. No sky (it is drawn in code).
- SVG, or PNG at @3x with transparency.
- Monochrome (values only) or a neutral daylight version, so each time of
  day can tint it; art with baked-in lighting would need a version per
  time of day.
- One style for all layers; ideally a variant per chapter (home land,
  beaten road, steppe, Carpathians, starry night).
- A licence that allows use in the app.
