import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The registry is global: register once for the whole file.
  setUpAll(registerLicenses);

  test('the Geologica licence ships with the app', () async {
    final licenses = await LicenseRegistry.licenses.toList();
    final geologica = licenses.where((l) => l.packages.contains('Geologica'));

    expect(geologica, hasLength(1));
    expect(
      geologica.single.paragraphs.map((p) => p.text).join('\n'),
      contains('SIL Open Font License'),
    );
  });

  test('the sky data is credited', () async {
    final licenses = await LicenseRegistry.licenses.toList();
    final sky = licenses.where((l) => l.packages.contains('d3-celestial'));

    expect(sky, hasLength(1));
    final text = sky.single.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('BSD'));
    expect(text, contains('Sky & Telescope'));
    expect(text, contains('XHIP'));
  });
}
