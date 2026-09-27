// The seven sky keyframes chosen on the visual companion (direction B,
// calmed towards A). Values: docs/DESIGN.md, "Sky".

/// A moment of the day with its own palette, in the order they occur.
enum SkyKeyframe { preDawn, dawn, morning, day, goldenHour, blueHour, night }

/// Which matte glass tint to use over the sky.
enum SurfaceTone { light, dark }

/// Colours of the sky at one moment. `sky` is the gradient top → bottom
/// (at 0%, 55%, 100%), `hills` far → near, `onSky` is text drawn directly
/// on the sky. Colours are ARGB ints.
typedef SkyPalette = ({
  List<int> sky,
  List<int> hills,
  int accent,
  int onSky,
  SurfaceTone surfaceTone,
});

/// Where the three sky colours sit in the gradient, top to bottom.
const List<double> skyGradientStops = [0, 0.55, 1];

/// Opacity of the overlay grain drawn over the sky.
const double skyGrainOpacity = 0.12;

const _onDark = 0xFFFFFFFF;
const _onLight = 0xFF18293A;

const Map<SkyKeyframe, SkyPalette> skyKeyframes = {
  SkyKeyframe.preDawn: (
    sky: [0xFF2E345E, 0xFF5D5F8E, 0xFF9A8FAE],
    hills: [0xFF7A7597, 0xFF565673, 0xFF34364F],
    accent: 0xFFB8A4D9,
    onSky: _onDark,
    surfaceTone: SurfaceTone.dark,
  ),
  SkyKeyframe.dawn: (
    sky: [0xFF545784, 0xFFCF98A2, 0xFFF2C7A8],
    hills: [0xFFC29AAB, 0xFF8B7790, 0xFF4F4D63],
    accent: 0xFFF2A98A,
    onSky: _onDark,
    surfaceTone: SurfaceTone.dark,
  ),
  SkyKeyframe.morning: (
    sky: [0xFF7EA8CF, 0xFFBCD6E6, 0xFFF2EBDD],
    hills: [0xFFB7D0C6, 0xFF8CB392, 0xFF5B8C64],
    accent: 0xFFF0C27A,
    onSky: _onLight,
    surfaceTone: SurfaceTone.light,
  ),
  SkyKeyframe.day: (
    sky: [0xFF6C9DCC, 0xFFA2C8E5, 0xFFE0EEF1],
    hills: [0xFFAECFC2, 0xFF7EAF85, 0xFF4D8259],
    accent: 0xFFE9B44C,
    onSky: _onLight,
    surfaceTone: SurfaceTone.light,
  ),
  SkyKeyframe.goldenHour: (
    sky: [0xFFD38A6C, 0xFFEEB385, 0xFFF7DCB0],
    hills: [0xFFDCA689, 0xFFA8786A, 0xFF634448],
    accent: 0xFFF29A5B,
    onSky: _onDark,
    surfaceTone: SurfaceTone.dark,
  ),
  SkyKeyframe.blueHour: (
    sky: [0xFF2C3868, 0xFF546A9C, 0xFFA2B0CF],
    hills: [0xFF5C6A92, 0xFF3C4870, 0xFF252D4A],
    accent: 0xFFA9B8E8,
    onSky: _onDark,
    surfaceTone: SurfaceTone.dark,
  ),
  SkyKeyframe.night: (
    sky: [0xFF121831, 0xFF222B54, 0xFF364378],
    hills: [0xFF323C6C, 0xFF222A4D, 0xFF141A35],
    accent: 0xFFC8D2F0,
    onSky: _onDark,
    surfaceTone: SurfaceTone.dark,
  ),
};
