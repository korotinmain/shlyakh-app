# App icon

The shipping icon is `ios/Runner/AppIcon.icon` (Icon Composer format, iOS 26
Liquid Glass). That file is the source of truth; this folder holds the
exploration that led to it.

- `concepts/` – three flat concepts (A: S-shaped path with a dot, B: road
  to the horizon, C: the letter Ш). Concept A was chosen.
- `layers/<concept>/` – each concept split into background, path and dot
  layers on a shared 1024×1024 canvas.
- `tools/outline_stroke.py` – converts the stroked S path into a filled
  outline. Icon Composer renders stroke-only SVG paths as closed shapes
  (a visible chord appears), so layers in `AppIcon.icon` must be filled.

## Updating the icon

1. Edit the layer SVGs in `ios/Runner/AppIcon.icon/Assets/` (filled shapes
   only) or open the file in Icon Composer
   (`/Applications/Xcode.app/Contents/Applications/Icon Composer.app`).
2. If the path geometry changes, update `S_PATH` in `tools/outline_stroke.py`
   and regenerate `path.svg`.
3. Build for the simulator and check Default, Dark, Clear and Tinted
   styles on the home screen (long press → Edit → Customise).
