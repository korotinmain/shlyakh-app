// dart format width=80
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shlyakh/core/database/app_database.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // v1 → v2 only adds journey_start; daily_steps rows must survive as they
  // are.
  test('migration from v1 to v2 does not corrupt data', () async {
    final oldDailyStepsData = <v1.DailyStepsData>[
      const v1.DailyStepsData(
        userId: 'local',
        localDate: '2026-09-27',
        timezone: 'Europe/Kyiv',
        steps: 5000,
      ),
    ];
    final expectedNewDailyStepsData = <v2.DailyStepsData>[
      const v2.DailyStepsData(
        userId: 'local',
        localDate: '2026-09-27',
        timezone: 'Europe/Kyiv',
        steps: 5000,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.dailySteps, oldDailyStepsData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewDailyStepsData,
          await newDb.select(newDb.dailySteps).get(),
        );
      },
    );
  });

  // v2 → v3 adds journey_start.celebrated_level; an existing start keeps
  // its values and gets level 1.
  test('migration from v2 to v3 keeps the journey start', () async {
    final oldJourneyStartData = <v2.JourneyStartData>[
      const v2.JourneyStartData(
        userId: 'local',
        startedAt: 1790486400000,
        timezone: 'Europe/Kyiv',
      ),
    ];
    final expectedNewJourneyStartData = <v3.JourneyStartData>[
      const v3.JourneyStartData(
        userId: 'local',
        startedAt: 1790486400000,
        timezone: 'Europe/Kyiv',
        celebratedLevel: 1,
      ),
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.journeyStart, oldJourneyStartData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewJourneyStartData,
          await newDb.select(newDb.journeyStart).get(),
        );
      },
    );
  });
}
