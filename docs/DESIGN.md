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
| `done` | `#F3D9A0` | `#8A5E0B` |
| `doneLine` | `#F7E2B4` at 90 % | `#8A5E0B` at 80 % |
| `doneGlow` | `#F3D9A0` at 30 % | none |
| `seal` | `#EBC57F` | `#8A5E0B` |
| `onSeal` | `#2A1D08` | `#FFFFFF` |
| grain | 12 % | 6 % |
| backdrop | violet nebula (`#6E5AA8` at 32 %, fading) | star-chart grid (24 pt, ink at 5 %, top two thirds) |

Contrast (WCAG 2, pinned by `test/core/design/app_palette_test.dart`):
text on every sky colour, on the accent, on glass over the sky and on
the seal is at least 4.5:1; the accent on glass (ring, bar, active tab),
the stars, the marker and the gold of completed constellations on the
sky at least 3:1.
The status bar has light icons in the dark theme and dark icons in the
light theme.

## Layout

Every screen is zones: a top zone, a flexible zone and a bottom zone,
plus a reserved strip under the floating tab bar where nothing but glass
shows. On Today: the card at the top (with the Health hint under it when
shown); a hills silhouette rises 96 pt above the collapsed sheet and
runs under it; the current constellation fills the sky between the card
and the hills, its name just under its lowest star; the sheet runs under the tab bar to the screen edge
and its content ends above the bar. With large text the card and the
sheet grow and the constellation zone shrinks, never overlapping them.

## Constellation figure

Drawn in code (`ConstellationFigure`) from the bundled route; the Rive
art replaces it later with the same states.

- The figure's unit box fits the largest square that leaves 24 pt on
  each side of its zone (less 48 pt kept for the name), centred. The name
  sits 16 pt under the lowest star in `footnote`, `onSkyMuted`, sentence
  case, no letter-spacing.
  When that would leave the figure a square smaller than 48 pt (very
  large text on a small phone), the name is left out and the stars take
  the whole zone.
- A lit star is a dot of radius `(3.5 − 0.5 × magnitude)` clamped to
  1.5–3.5 in `star`, with a glow three times that radius in `starGlow`
  (dark only). A star ahead is a ring of radius 3, stroke 0.8, in
  `starAhead`.
- Lines are solid (`starLine`, stroke 1) where neither end lies ahead,
  so the line reaches the current star; dashed (`aheadLine`, stroke
  0.8, dash 2 / gap 4) otherwise.
- The current star's marker: a core of radius 3.2 in `star`, a ring of
  radius 9 with one gap in `marker` at 60 %, cross spikes of half-length
  16 at 50 % and a soft disc of radius 16 at 12 %. Static for now; the
  star moment animates it.

## Path pages

One page per constellation, swiped horizontally: the completed ones, the
current one and the next one; the rest stay in the fog. The tab opens on
the current page. Zones: a "Map of the path" pill at the top right, then
the header, the figure in the flexible middle, and the info card and the
route strip at the bottom, above the tab bar. Below 520 pt of page height
(very large text) the page scrolls and the figure keeps a 220 pt zone.

| Page | Header (kicker · subtitle) | Card |
|---|---|---|
| current | "You are here" · constellations complete (no total) | XP to the next star, a bar, "≈ N days at your pace" (hidden with less than 7 days of history) |
| done | "Complete" in `done` · its stars | the seal "✓ Completed <day month>" in `seal` / `onSeal` |
| ahead | "Ahead" · its stars | a lock and "Opens once the current constellation is complete" |

A done figure is drawn in gold (`done`, `doneLine`, `doneGlow`) with no
marker. The route strip shows the previous, this (bold) and the next
name over a dashed line; a missing neighbour is a faint dot, and tapping
a name opens that page.

## Map

A star chart of the stretch out of the fog: plate carrée in J2000, turned
90° clockwise so north is to the right and right ascension grows upwards
(a rotation, never a mirror). It fits the visible constellations' span
plus 20° of sky at either end, zoomed in at most 8 px a degree and
centred, and scrolls vertically, opening on the current constellation.

- Each visible constellation sits at its place on the chart, and its
  stars at their true offsets from its centre (a gnomonic projection,
  turned like the chart), so shapes keep their proportions even near the
  pole. A shared star is placed from its owner, so Elnath is one point.
  Done in gold, the current one with its marker, the next one as rings.
  Each name sits just under its lowest star; names that would overlap
  are pushed down.
- The band is the galactic equator (J2000 pole α 192.85948°, δ
  27.12825°), 20° wide in `onSkyMuted` at 12 % with a blur. It fades into
  the fog from the last visible constellation onwards, in the route's
  direction (up on the main route, down on the branch); with the whole
  route lit it does not fade.

## Members

Each Спільно member has one of six muted colours, chosen by an FNV-1a hash
of their user id (the same on every device): coral `#E8927C`, sage
`#8DB596`, sky `#7FA7D9`, lavender `#A99BD3`, sand `#D9B26F`, rose
`#D98BA9`. Built with Спільно (stage 5).

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
