# Design foundation (phase B) — design

Date: 2026-09-27
Status: approved in chat (visual companion screens), pending spec review

## Goal

Turn the choices made on the visual companion screens into design tokens
in code and a `docs/DESIGN.md`, so phase C (main screen) is built only
from tokens and the placeholder seed colour disappears.

## Decisions (from the visual companion)

| Topic | Decision |
|---|---|
| Sky mood | Direction B calmed towards A ("variant 2"): 7 keyframe palettes |
| Typography | Geologica only (300 / 400 / 500 / 700), tabular figures for numbers |
| Surfaces | Matte glass ("C"): dense tint, light blur, no border, soft shadow |
| Glass toggle | No user setting; one material |

## Sky

### Keyframes

| Keyframe | Sky top → bottom | Hills far → near | Accent |
|---|---|---|---|
| `preDawn` | `#2E345E` `#5D5F8E` `#9A8FAE` | `#7A7597` `#565673` `#34364F` | `#B8A4D9` |
| `dawn` | `#545784` `#CF98A2` `#F2C7A8` | `#C29AAB` `#8B7790` `#4F4D63` | `#F2A98A` |
| `morning` | `#7EA8CF` `#BCD6E6` `#F2EBDD` | `#B7D0C6` `#8CB392` `#5B8C64` | `#F0C27A` |
| `day` | `#6C9DCC` `#A2C8E5` `#E0EEF1` | `#AECFC2` `#7EAF85` `#4D8259` | `#E9B44C` |
| `goldenHour` | `#D38A6C` `#EEB385` `#F7DCB0` | `#DCA689` `#A8786A` `#634448` | `#F29A5B` |
| `blueHour` | `#2C3868` `#546A9C` `#A2B0CF` | `#5C6A92` `#3C4870` `#252D4A` | `#A9B8E8` |
| `night` | `#121831` `#222B54` `#364378` | `#323C6C` `#222A4D` `#141A35` | `#C8D2F0` |

Each keyframe also defines two separate values:

- `onSky`, the colour of text drawn directly on the sky: `#18293A` for
  `morning` and `day`, `#FFFFFF` for the other five.
- `surfaceTone`, which matte glass tint to use: `light` for `morning` and
  `day`, `dark` for `preDawn`, `dawn`, `goldenHour`, `blueHour` and `night`.

The sky gradient places its three colours at 0%, 55% and 100% of the
height.

### When each keyframe applies

Relative to local sunrise `S`, solar noon `N` and sunset `E` of the day:

| Keyframe | Time |
|---|---|
| `preDawn` | `S − 60 min` |
| `dawn` | `S` |
| `morning` | `S + 90 min` |
| `day` | `N` |
| `goldenHour` | `E − 60 min` |
| `blueHour` | `E + 20 min` |
| `night` | `E + 90 min`, held until the next day's `preDawn` |

Between two consecutive keyframes every colour is interpolated in
**OkLCh** (implementation note: a straight Oklab line still goes grey
between opposite hues, so hue follows the shorter arc; see the plan
rulings), by the fraction of time
elapsed between them. From `night` to the next `preDawn` the night palette
holds, then blends into `preDawn` over the last 60 minutes before it.

### Sunrise and sunset

- Computed with the NOAA Solar Calculator equations (Meeus-based; the
  shorter Spencer series drifts by about a day near equinoxes) (pure Dart,
  no dependency) for a date and coordinates, in UTC, then shown in local time
  via the device clock's offset.
- Coordinates: a fixed default of Kyiv (50.45° N, 30.52° E) until location
  is a deliberate decision (privacy; out of scope). The error for anywhere
  in Ukraine is minutes, invisible in a sky gradient.
- Polar day/night (no sunrise/sunset) is not handled beyond "hold `day`"
  or "hold `night`"; irrelevant at supported latitudes but must not throw.
- Time comes from the injected `Clock` (ADR 0002); never `DateTime.now()`.

## Other tokens

- **Grain:** overlay noise at 12% opacity over the sky (asset or painter,
  decided in the plan).
- **Member colours** (Спільно): `#E8927C` coral, `#8DB596` sage,
  `#7FA7D9` sky, `#A99BD3` lavender, `#D9B26F` sand, `#D98BA9` rose.
  A member's colour is chosen by a stable hash (FNV-1a 32-bit) of their
  `user_id` modulo 6, so it is the same on every device. Collisions inside
  one Спільно are possible and accepted until stage 5 assigns colours.
- **Typography (Geologica, bundled, OFL):** `hero` 44/700, `display`
  30/700, `title` 22/700, `headline` 17/500, `body` 15/400, `footnote`
  13/400, `caption` 11/300 (size/weight). Numbers use tabular figures
  (`FontFeature.tabularFigures()`). Letter spacing −2% for `hero`,
  `display`, `title`.
- **Spacing:** 4 / 8 / 12 / 16 / 20 / 24 / 32 / 48; screen side margin 20.
- **Radii:** card 20, sheet 24 (top corners), tab bar fully rounded.
- **Matte glass surface:** light `#FFFFFF` at 68%, dark `#161C38` at 72%;
  backdrop blur sigma 12; no border; shadow `0 6 18` at 16% black.
- **Motion:** durations 150 / 300 / 600 ms; curve `Curves.easeOutCubic`
  (the chosen "soft deceleration").

## Structure

```
lib/core/design/
├── sky/
│   ├── oklab.dart            # sRGB ⇄ Oklab, lerp (pure Dart, ints)
│   ├── solar.dart            # NOAA sunrise / solar noon / sunset (pure Dart)
│   ├── sky_keyframes.dart    # the 7 keyframes (colour ints) and their timing rule
│   └── sky_palette.dart      # skyAt(DateTime local, {lat, lng}) → SkyPalette
├── app_colors.dart           # member colours, memberColor(userId)
├── app_typography.dart       # TextTheme from the scale, tabular numbers
├── app_spacing.dart
├── app_radii.dart
├── app_motion.dart
└── glass.dart                # matte glass surface values
assets/fonts/geologica/        # Geologica-{Light,Regular,Medium,Bold}.ttf + OFL.txt
docs/DESIGN.md
```

- The sky and colour logic uses plain `int` ARGB so it is testable without
  Flutter; thin extensions convert to `Color`.
- `lib/app/theme.dart` builds `ThemeData` from the tokens (font family
  Geologica, `TextTheme` from the scale, `ColorScheme` from the `day`
  keyframe for widgets that are not sky-aware yet); the seed colour goes.
- A `skyProvider` (presentation) that ticks per minute is phase C; this
  phase only provides `skyAt(...)`.

## Testing

- `oklab_test`: round-trip sRGB → Oklab → sRGB within 1/255 for the 42
  palette colours; lerp at 0 and 1 returns the endpoints; midpoint of
  black/white is not the sRGB midpoint (proves Oklab, not RGB).
- `solar_test`: Kyiv sunrise/sunset within ±3 min for 2026-03-20,
  2026-06-21, 2026-09-22, 2026-12-21 (reference values recorded in the
  test from NOAA's calculator); a UTC offset change (DST) shifts local
  times by the offset only; polar coordinates do not throw.
- `sky_palette_test`: at each keyframe instant the palette equals that
  keyframe exactly; halfway between `day` and `goldenHour` it is neither;
  the night hold returns `night` at 01:00; the blend into `preDawn`;
  table of `onSky` and dark flags.
- `app_colors_test`: `memberColor` is stable for a user id, spreads 60
  sample ids over all 6 colours.
- Theme: a widget test that `App` renders with Geologica and no seed
  colour (the existing app test keeps passing).

## Docs

- `docs/DESIGN.md`: principles recap, the palette table, timing rule,
  typography scale, surfaces, spacing, radii, motion, and how art (phase D)
  must be delivered (monochrome or neutral day layers, separate files).
- `docs/ARCHITECTURE.md`: design tokens [built]. `ROADMAP.md`: phase B.
- Font licence: `assets/fonts/geologica/OFL.txt` committed with the fonts.

## Out of scope

- Location-based sunrise (privacy decision), the per-minute sky provider,
  any widget of the main screen (phase C), art and the Milky Way (phase D),
  animations (phase F).
