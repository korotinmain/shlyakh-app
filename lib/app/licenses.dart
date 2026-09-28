import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ships the licences of bundled third-party material, so they appear on
/// the licences page: the Geologica font (SIL OFL requires it to
/// accompany the font) and the sky data (docs/decisions/0009-sky-data.md).
void registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/geologica/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Geologica'], text);
  });
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/licenses/sky.txt');
    yield LicenseEntryWithLineBreaks(const [
      'd3-celestial',
      'IAU and Sky & Telescope constellation figures',
      'XHIP',
    ], text);
  });
}
