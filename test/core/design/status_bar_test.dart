import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/design/status_bar.dart';

void main() {
  test('the dark theme gets light status bar icons', () {
    expect(statusBarStyleFor(Brightness.dark), SystemUiOverlayStyle.light);
  });

  test('the light theme gets dark status bar icons', () {
    expect(statusBarStyleFor(Brightness.light), SystemUiOverlayStyle.dark);
  });
}
