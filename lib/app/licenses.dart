import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ships the Geologica licence with the app (SIL OFL: the licence must
/// accompany the font), so it appears on the licences page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/geologica/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Geologica'], text);
  });
}
