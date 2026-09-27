import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  group('App locale resolution', () {
    final cases = <(String, List<Locale>, String)>[
      ('shows English title for en', [const Locale('en')], 'Shlyakh'),
      ('shows Ukrainian title for uk', [const Locale('uk')], 'Шлях'),
      (
        'shows Ukrainian title for regional uk_UA',
        [const Locale('uk', 'UA')],
        'Шлях',
      ),
      (
        'falls back to English for unsupported pl',
        [const Locale('pl')],
        'Shlyakh',
      ),
      (
        'prefers a supported second language over the fallback',
        [const Locale('pl'), const Locale('uk')],
        'Шлях',
      ),
    ];

    for (final (name, locales, title) in cases) {
      testWidgets(name, (tester) async {
        await pumpApp(tester, systemLocales: locales);

        expect(find.text(title), findsOneWidget);
      });
    }
  });
}
