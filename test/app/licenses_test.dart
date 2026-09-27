import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the Geologica licence ships with the app', () async {
    registerFontLicenses();

    final licenses = await LicenseRegistry.licenses.toList();
    final geologica = licenses.where((l) => l.packages.contains('Geologica'));

    expect(geologica, hasLength(1));
    expect(
      geologica.single.paragraphs.map((p) => p.text).join('\n'),
      contains('SIL Open Font License'),
    );
  });
}
