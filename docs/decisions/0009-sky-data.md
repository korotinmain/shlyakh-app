# 0009. Sky data: source, licences and build

Date: 2026-09-28
Status: accepted

## Context

The constellation path (`docs/superpowers/specs/2026-09-28-constellation-path-design.md`)
needs real star positions and the standard constellation figures, and
people who know the sky must not find errors. The data ships inside a
closed-source, free iOS app, so its licence must allow bundling without
opening the app's code. Candidates, checked at their sources:

- **d3-celestial** by Olaf Frohn: BSD-3-Clause. `constellations.lines.json`
  holds the IAU / Sky & Telescope figures as coordinates ("some line
  modifications" by the author); `stars.6.json` holds HIP id, magnitude
  and position derived from XHIP (Anderson & Francis 2012).
- **HYG database** v4.1: CC BY-SA 4.0.
- **Stellarium sky cultures** (`modern_iau`, `modern`): CC BY-SA 4.0,
  `modern_st` CC BY-SA 2.0; the program itself is GPL.
- **IAU / Sky & Telescope charts**: CC BY 4.0, but images, not data.
- **VizieR** (Hipparcos, Yale BSC): no blanket licence; per catalogue.

## Decision

- Use d3-celestial `constellations.lines.json`, `stars.6.json` and
  `starnames.json`, pinned at commit
  `7e720a3de062059d4c5400a379146a601d9010e0` (2022-07-05).
- A Dart tool, `tool/sky/build_route.dart`, downloads those files at the
  pinned commit (cached in `.dart_tool/sky/`, never committed), matches
  every figure vertex to a catalogue star, projects each route
  constellation and writes `assets/sky/route.json` and
  `assets/sky/SOURCES.md`. The asset and the tool are committed; the build
  is deterministic and fails when a star count differs from the spec.
- The licences page credits d3-celestial (BSD-3-Clause text), the figures
  to "IAU and Sky & Telescope (CC BY 4.0)" and the star data to XHIP.
- HYG and Stellarium data are not bundled: share-alike on data would
  reach the app.

## Consequences

- Figures follow d3-celestial, which differs from Stellarium's
  `modern_iau` for a few constellations (Vulpecula 5 vs 2 stars, Perseus
  23 vs 19, Gemini 12 vs 17, Sagittarius 25 vs 14). We follow d3 and cite
  it; the counts are pinned by tests.
- Updating the data means bumping the commit, rerunning the tool and
  reviewing the asset diff; nothing changes silently.
- Names are not taken from the data: constellation and star names are
  l10n strings checked against Ukrainian sources.
