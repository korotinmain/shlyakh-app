import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/features/steps/data/drift_journey_repository.dart';
import 'package:shlyakh/features/steps/domain/journey_start.dart';

final JourneyStart _start = (
  userId: 'local',
  startedAt: DateTime.utc(2026, 9, 28, 6, 30),
  timezone: 'Europe/Kyiv',
);

void main() {
  late AppDatabase db;
  late DriftJourneyRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftJourneyRepository(db.journeyStartDao);
  });

  tearDown(() => db.close());

  test('emits null, then the start once it is stored', () async {
    final emitted = repository.watchStart('local').take(2).toList();

    await pumpEventQueue();
    expect(await repository.start(_start), isTrue);

    expect(await emitted, [null, _start]);
  });

  test('never overwrites a stored start', () async {
    await repository.start(_start);

    final later = (
      userId: 'local',
      startedAt: DateTime.utc(2026, 10),
      timezone: 'Europe/Warsaw',
    );
    expect(await repository.start(later), isFalse);
    expect(await repository.watchStart('local').first, _start);
  });

  group('a storage error becomes StorageFailure', () {
    setUp(() => db.customStatement('DROP TABLE journey_start'));

    test('when watching', () {
      expect(repository.watchStart('local'), emitsError(isA<StorageFailure>()));
    });

    test('when starting', () {
      expect(repository.start(_start), throwsA(isA<StorageFailure>()));
    });
  });
}
