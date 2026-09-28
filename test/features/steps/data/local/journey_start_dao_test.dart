import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/features/steps/data/local/journey_start_dao.dart';
import 'package:shlyakh/features/steps/domain/journey_start.dart';

JourneyStart _start(String user, DateTime startedAt) =>
    (userId: user, startedAt: startedAt, timezone: 'Europe/Kyiv');

void main() {
  late AppDatabase db;
  late JourneyStartDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.journeyStartDao;
  });

  tearDown(() => db.close());

  test('insertOnce stores a start', () async {
    final startedAt = DateTime.utc(2026, 9, 28, 7, 20, 15, 123);

    expect(await dao.insertOnce(_start('local', startedAt)), isTrue);

    final stored = await dao.get('local');
    expect(stored?.startedAt, startedAt);
    expect(stored?.startedAt.isUtc, isTrue);
    expect(stored?.timezone, 'Europe/Kyiv');
  });

  test('insertOnce never overwrites', () async {
    final first = DateTime.utc(2026, 9, 28, 7);
    await dao.insertOnce(_start('local', first));

    expect(
      await dao.insertOnce(_start('local', DateTime.utc(2026, 9, 29))),
      isFalse,
    );
    expect((await dao.get('local'))?.startedAt, first);
  });

  test('get returns null for another user', () async {
    await dao.insertOnce(_start('local', DateTime.utc(2026, 9, 28)));

    expect(await dao.get('other'), isNull);
  });

  test('watch emits null, then the start', () async {
    final startedAt = DateTime.utc(2026, 9, 28, 7);
    final emitted = dao.watch('local').take(2).toList();

    await pumpEventQueue();
    await dao.insertOnce(_start('local', startedAt));

    final values = await emitted;
    expect(values.first, isNull);
    expect(values.last?.startedAt, startedAt);
  });

  test('deleteForUser removes only that user', () async {
    await dao.insertOnce(_start('local', DateTime.utc(2026, 9, 28)));
    await dao.insertOnce(_start('other', DateTime.utc(2026, 9, 28)));

    expect(await dao.deleteForUser('local'), 1);
    expect(await dao.get('local'), isNull);
    expect(await dao.get('other'), isNotNull);
  });

  test('an empty zone is rejected by the database', () async {
    await expectLater(
      db.customStatement(
        'INSERT INTO journey_start (user_id, started_at, timezone) '
        "VALUES ('local', 0, '')",
      ),
      throwsA(isA<SqliteException>()),
    );
  });
}
