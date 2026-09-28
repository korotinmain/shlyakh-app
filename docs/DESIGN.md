# Design

The visual language of Shlyakh. Values here are the design tokens in
`lib/core/design/`; when they disagree, the code is right and this file
needs an update in the same PR. Product principles are in
`docs/PRODUCT.md` ("Design principles", "Today screen content").

## Principles

- The sky and its constellations are the hero; interface elements sit on
  it and stay quiet.
- One strong accent per screen, from the theme; restrained type.
- Calm and fair: rewards feel pleasant, never pushy.
- No template look: no generic dashboard cards, default gradients or
  stock icon grids.

## Themes

The app follows the system appearance (`ThemeMode.system`); there is no
in-app toggle and no sky that follows the time of day. Dark is a night
sky; light is an ink star chart on a pale background. Tokens live in
`AppPalette` (`lib/core/design/app_palette.dart`), a `ThemeExtension`
read as `context.palette`; a change of appearance animates between the
two palettes.

| Token | Dark | Light |
|---|---|---|
| `sky` (top, 55 %, bottom) | `#070B1E` `#161E46` `#2C3670` | `#DCE6F4` `#EEF1F6` `#F6F1E8` |
| `hills` (far → near) | `#1B2250` `#141A40` `#0E1333` | `#E6ECF2` `#DCE4EC` `#C9D5DF` |
| `accent` | `#F3D9A0` gold | `#3D4F9A` ink blue |
| `onAccent` | `#1A2440` | `#FFFFFF` |
| `onSky` | `#F4F1EA` | `#1A2440` |
| `onSkyMuted` | `#C8D2F0` | `#3D4F9A` |
| `glass` | `#121836` at 72 % | white at 68 % |
| `onGlass` | `#F4F1EA` | `#1A2440` |
| `star` | `#FFFFFF` | `#3D4F9A` |
| `starGlow` | `#F3E3BE` at 22 % | none |
| `starLine` | `#F3E3BE` at 80 % | `#3D4F9A` at 70 % |
| `starAhead` | `#C8D2F0` at 45 % | `#3D4F9A` at 38 % |
| `aheadLine` | `#C8D2F0` at 30 % | `#3D4F9A` at 25 % |
| `marker` | `#FFE9B8` | `#3D4F9A` |
| grain | 12 % | 6 % |
| backdrop | violet nebula (`#6E5AA8` at 32 %, fading) | star-chart grid (24 pt, ink at 5 %, top two thirds) |

Contrast (WCAG 2, pinned by `test/core/design/app_palette_test.dart`):
text on every sky colour, on the accent and on glass over the sky is at
least 4.5:1; the accent on glass (ring, bar, active tab) and the stars and the
marker on the sky at least 3:1.
The status bar has light icons in the dark theme and dark icons in the
light theme.

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

Matte glass: the theme's `glass` tint over a backdrop blur of sigma 12;
text and icons in `onGlass`; no border; shadow `0 6 18` black at 16 %.
Tracks use `onGlass` at 18 %, secondary marks at 28 %. No user setting
for materials.

## Spacing, radii, motion

- Spacing: 4 / 8 / 12 / 16 / 20 / 24 / 32 / 48; screen side margin 20.
- Radii: card 20; sheet 24 (top corners); the floating tab bar is fully
  rounded.
- Motion: 150 / 300 / 600 ms, curve `easeOutCubic`. Animations are phase F.

## Delivering art

- Art is animated in Rive; it never contains text (all text is Flutter
  and l10n). The contract for the constellation artboards comes with the
  star moment (constellation path, plan 6).
- Art works in both themes: either one monochrome version tinted in code,
  or a dark and a light version.
- SVG for import into Rive, or PNG at @3x with transparency.
- A licence that allows use in the app.
