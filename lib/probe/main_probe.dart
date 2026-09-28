// SPIKE (throwaway, never merged): does Dart run when HealthKit relaunches
// the app in the background, and can it read HealthKit and write Drift?
// Breaks project rules on purpose (hardcoded strings, logic in widgets).
// Journals times, app states and counts only; never step values.
//
// Run: flutter run --release -d <iPhone> -t lib/probe/main_probe.dart
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shlyakh/core/database/app_database.dart';
import 'package:shlyakh/features/steps/data/healthkit/health_kit_steps_source.dart';
import 'package:shlyakh/features/steps/data/healthkit/steps_api.g.dart';
import 'package:shlyakh/features/steps/data/local/daily_steps_dao.dart';

final _api = StepsHostApi();
final _source = HealthKitStepsSource(_api);
final _db = AppDatabase(driftDatabase(name: 'shlyakh'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _api.probeLog('dart main');
  StepsEventsApi.setUp(_Events());
  runApp(const MaterialApp(home: _ProbeScreen()));
}

Future<void> _sync(String trigger) async {
  final watch = Stopwatch()..start();
  try {
    final days = await _source.dailySteps(
      userId: 'local',
      from: const Clock().daysAgo(2),
    );
    final dao = DailyStepsDao(_db);
    for (final day in days) {
      await dao.upsert(day);
    }
    await _api.probeLog(
      'dart sync ($trigger): ${days.length} days written in '
      '${watch.elapsedMilliseconds} ms',
    );
  } on Exception catch (e) {
    await _api.probeLog('dart sync ($trigger) failed: ${e.runtimeType}');
  }
}

final class _Events implements StepsEventsApi {
  @override
  Future<void> onStepsChanged() => _sync('observer');
}

class _ProbeScreen extends StatefulWidget {
  const new();

  @override
  State<_ProbeScreen> createState() => _ProbeScreenState();
}

class _ProbeScreenState extends State<_ProbeScreen> {
  List<String> _journal = [];
  int _rows = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final journal = await _api.probeJournal();
    final rows = await _db.select(_db.dailyStepsTable).get();
    setState(() {
      _journal = journal.reversed.toList();
      _rows = rows.length;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Background Dart probe')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: () async {
                await _api.requestAccess();
                await _sync('allow');
                await _refresh();
              },
              child: const Text('Allow'),
            ),
            FilledButton(onPressed: _refresh, child: const Text('Refresh')),
            OutlinedButton(
              onPressed: () async {
                await _api.clearProbeJournal();
                await _refresh();
              },
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Drift rows: $_rows'),
        const Divider(),
        Text('Journal (${_journal.length}), newest first'),
        for (final line in _journal) Text(line),
      ],
    ),
  );
}
