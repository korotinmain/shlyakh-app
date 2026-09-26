// SPIKE (throwaway): HealthKit probe screen. Not merged into main.
// Breaks project rules on purpose (hardcoded strings, logic in widgets):
// the output of this spike is an answer, not code.
//
// Run: flutter run -t lib/spike/main_spike.dart
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:shlyakh/spike/health_spike_api.g.dart';

void main() => runApp(const MaterialApp(home: SpikeScreen()));

class SpikeScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _DayRow {
  new(this.day);

  final DateTime day;
  int rawSum = 0;
  final Map<String, int> rawBySource = {};
  int? pluginStats;
  int? native;
}

class _SpikeScreenState extends State<SpikeScreen> {
  static const _days = 7;
  final _health = Health();
  final _native = HealthSpikeHostApi();

  String _status = 'Not authorized yet';
  List<_DayRow> _rows = [];
  List<WakeupEvent> _wakeups = [];

  Future<void> _authorize() async {
    try {
      await _health.configure();
      final granted = await _health.requestAuthorization(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      // Observer registered at launch fails before authorization; restart it.
      await _native.startObserving();
      setState(() => _status = 'requestAuthorization returned $granted');
    } on Exception catch (e) {
      setState(() => _status = 'Authorization error: $e');
    }
  }

  Future<void> _load() async {
    setState(() => _status = 'Loading...');
    try {
      final now = DateTime.now();
      // Local midnights: DateTime(y, m, d) is local time, DST-safe.
      final days = [
        for (var i = _days - 1; i >= 0; i--)
          DateTime(now.year, now.month, now.day - i),
      ];
      final rows = {for (final d in days) d: _DayRow(d)};

      // A: raw samples summed by hand (expected to double count).
      final samples = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: days.first,
        endTime: DateTime(now.year, now.month, now.day + 1),
      );
      for (final s in samples) {
        final from = s.dateFrom;
        final row = rows[DateTime(from.year, from.month, from.day)];
        if (row == null) continue;
        final value = (s.value as NumericHealthValue).numericValue.round();
        row.rawSum += value;
        row.rawBySource.update(
          s.sourceName,
          (v) => v + value,
          ifAbsent: () => value,
        );
      }

      // B: plugin statistics query per local day (HKStatisticsQuery).
      for (final row in rows.values) {
        final d = row.day;
        row.pluginStats = await _health.getTotalStepsInInterval(
          d,
          DateTime(d.year, d.month, d.day + 1),
        );
      }

      // C: native HKStatisticsCollectionQuery via Pigeon.
      final nativeDays = await _native.dailySteps(_days);
      for (final n in nativeDays) {
        final row = rows[DateTime.parse(n.localDate)];
        row?.native = n.steps;
      }

      final wakeups = await _native.wakeups();
      setState(() {
        _rows = rows.values.toList().reversed.toList();
        _wakeups = wakeups.reversed.toList();
        _status =
            'Loaded ${samples.length} raw samples. '
            'Time zone: ${now.timeZoneName} (UTC${_offset(now)})';
      });
    } on Exception catch (e) {
      setState(() => _status = 'Load error: $e');
    }
  }

  Future<void> _clearWakeups() async {
    await _native.clearWakeups();
    await _load();
  }

  static String _offset(DateTime t) {
    final o = t.timeZoneOffset;
    final sign = o.isNegative ? '-' : '+';
    final h = o.inHours.abs().toString().padLeft(2, '0');
    final m = (o.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$h:$m';
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _time(int epochMs) {
    final t = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return '${_date(t)} ${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HealthKit spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: _authorize,
                child: const Text('Authorize'),
              ),
              FilledButton(onPressed: _load, child: const Text('Load')),
              OutlinedButton(
                onPressed: _clearWakeups,
                child: const Text('Clear wakeups'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_status),
          const SizedBox(height: 16),
          const Text('Day | A raw sum | B plugin stats | C native'),
          for (final r in _rows)
            ListTile(
              dense: true,
              title: Text(
                '${_date(r.day)} | A ${r.rawSum} | B ${r.pluginStats} | '
                'C ${r.native}',
              ),
              subtitle: Text(
                r.rawBySource.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join('\n'),
              ),
            ),
          const Divider(),
          Text('Observer wakeups (${_wakeups.length}), newest first'),
          for (final w in _wakeups)
            Text(
              '${_time(w.epochMs)}  ${w.appState}'
              '${w.error == null ? '' : '  ERROR: ${w.error}'}',
            ),
        ],
      ),
    );
  }
}
