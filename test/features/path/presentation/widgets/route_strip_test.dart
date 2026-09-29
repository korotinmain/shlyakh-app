import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/app/theme.dart';
import 'package:shlyakh/features/path/presentation/widgets/route_strip.dart';

Future<void> _pump(WidgetTester tester, RouteStrip strip) => tester.pumpWidget(
  MaterialApp(
    theme: buildAppTheme(Brightness.dark),
    home: Scaffold(body: Center(child: strip)),
  ),
);

void main() {
  testWidgets('shows the neighbours around the current constellation', (
    tester,
  ) async {
    await _pump(
      tester,
      const RouteStrip(
        previous: 'Sagitta',
        current: 'Vulpecula',
        next: 'Cygnus',
      ),
    );

    expect(find.text('Sagitta'), findsOneWidget);
    expect(find.text('Vulpecula'), findsOneWidget);
    expect(find.text('Cygnus'), findsOneWidget);
    expect(find.byKey(RouteStrip.fogKey), findsNothing);
  });

  testWidgets('shows a dot where there is no neighbour', (tester) async {
    await _pump(
      tester,
      const RouteStrip(current: 'Sagitta', next: 'Vulpecula'),
    );

    expect(find.byKey(RouteStrip.fogKey), findsOneWidget);
  });

  testWidgets('opens a neighbour on tap', (tester) async {
    var opened = '';
    await _pump(
      tester,
      RouteStrip(
        previous: 'Sagitta',
        current: 'Vulpecula',
        next: 'Cygnus',
        onPrevious: () => opened = 'previous',
        onNext: () => opened = 'next',
      ),
    );

    await tester.tap(find.text('Cygnus'));
    expect(opened, 'next');
    await tester.tap(find.text('Sagitta'));
    expect(opened, 'previous');
  });
}
