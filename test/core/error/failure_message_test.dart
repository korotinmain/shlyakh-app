import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/core/error/failure_message.dart';
import 'package:shlyakh/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final uk = lookupAppLocalizations(const Locale('uk'));

  group('failureMessage', () {
    // The message table of docs/superpowers/specs/2026-09-27-errors-and-logging-design.md.
    final cases = <(Object, String, String)>[
      (
        const HealthAccessDenied(),
        "Shlyakh can't read your steps. Allow access to Steps in the Health "
            'settings.',
        'Шлях не має доступу до кроків. Дозвольте доступ до кроків у '
            "налаштуваннях Здоров'я.",
      ),
      (
        const HealthUnavailable(),
        "Health data isn't available on this device.",
        "Дані про здоров'я недоступні на цьому пристрої.",
      ),
      (
        const HealthDataLocked(),
        'Unlock your iPhone to update your steps.',
        'Розблокуйте iPhone, щоб оновити кроки.',
      ),
      (
        const StorageFailure(),
        "Couldn't save your data on this device. Try restarting the app.",
        'Не вдалося зберегти дані на пристрої. Спробуйте перезапустити '
            'застосунок.',
      ),
      (
        const UnexpectedFailure(),
        'Something went wrong while reading your data.',
        'Під час читання даних щось пішло не так.',
      ),
      (StateError('a bug'), 'Something went wrong.', 'Щось пішло не так.'),
    ];
    for (final (error, english, ukrainian) in cases) {
      test('maps ${error.runtimeType}', () {
        expect(failureMessage(en, error), english);
        expect(failureMessage(uk, error), ukrainian);
      });
    }
  });

  group('variantName', () {
    final variants = <(Failure, String)>[
      (const HealthAccessDenied(), 'HealthAccessDenied'),
      (const HealthUnavailable(), 'HealthUnavailable'),
      (const HealthDataLocked(), 'HealthDataLocked'),
      (const StorageFailure(), 'StorageFailure'),
      (const UnexpectedFailure(), 'UnexpectedFailure'),
    ];
    for (final (failure, name) in variants) {
      test('is $name', () => expect(failure.toString(), name));
    }
  });

  test('toString names the variant only, never the cause', () {
    final failure = StorageFailure(cause: Exception('steps=12345'));

    expect(failure.toString(), 'StorageFailure');
    expect('$failure', isNot(contains('12345')));
  });
}
