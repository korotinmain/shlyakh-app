import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/core/database/storage_errors.dart';
import 'package:shlyakh/core/error/failure.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> brokenQuery() => db.customSelect('SELECT * FROM missing').get();

  group('guardStorage', () {
    test('returns the value of a working call', () async {
      expect(await guardStorage(() async => 42), 42);
    });

    test('a SQLite error becomes StorageFailure with it as the cause', () {
      expect(
        guardStorage(brokenQuery),
        throwsA(
          isA<StorageFailure>().having(
            (f) => f.cause,
            'cause',
            isA<SqliteException>(),
          ),
        ),
      );
    });

    test('a programmer error stays as it is', () {
      expect(
        guardStorage<void>(() => throw StateError('bug')),
        throwsStateError,
      );
    });
  });

  group('translateStorageErrors', () {
    test('passes values through', () {
      expect(Stream.value(1).translateStorageErrors(), emits(1));
    });

    test('a SQLite error becomes StorageFailure', () {
      expect(
        Stream.fromFuture(brokenQuery()).translateStorageErrors(),
        emitsError(isA<StorageFailure>()),
      );
    });

    test('a programmer error stays as it is', () {
      expect(
        Stream<int>.error(StateError('bug')).translateStorageErrors(),
        emitsError(isStateError),
      );
    });
  });
}
