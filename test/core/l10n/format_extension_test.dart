import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shlyakh/core/l10n/format_extension.dart';

Future<String> _format(
  WidgetTester tester,
  Locale locale,
  String Function(BuildContext) format,
) async {
  late String result;
  await tester.pumpWidget(
    Localizations(
      locale: locale,
      delegates: const [DefaultWidgetsLocalizations.delegate],
      child: Builder(
        builder: (context) {
          result = format(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return result;
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('formatDayMonth writes the day and the month', (tester) async {
    final date = DateTime(2026, 9, 24);

    expect(
      await _format(tester, const Locale('en'), (c) => c.formatDayMonth(date)),
      'September 24',
    );
    expect(
      await _format(tester, const Locale('uk'), (c) => c.formatDayMonth(date)),
      '24 вересня',
    );
  });

  testWidgets('formatInt groups thousands per locale', (tester) async {
    expect(
      await _format(tester, const Locale('en'), (c) => c.formatInt(6870)),
      '6,870',
    );
    expect(
      await _format(tester, const Locale('uk'), (c) => c.formatInt(6870)),
      '6 870',
    );
  });
}
