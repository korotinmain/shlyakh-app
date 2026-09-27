// coverage:ignore-file
// Reason: DI wiring for the file database; tests override appDatabaseProvider.
import 'package:drift_flutter/drift_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shlyakh/core/database/app_database.dart';

part 'app_database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(driftDatabase(name: 'shlyakh'));
  ref.onDispose(db.close);
  return db;
}
