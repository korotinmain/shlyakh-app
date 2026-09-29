import 'dart:async';

import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:drift/native.dart';
import 'package:shlyakh/core/error/failure.dart';

/// The [StorageFailure] for a SQLite error, or null for anything else
/// (docs/decisions/0005-error-handling.md).
///
/// The app's database runs on a background isolate (drift_flutter), which
/// wraps SQLite errors in [DriftRemoteException]; any other error stays a
/// bug.
StorageFailure? storageFailureOf(Object error) => switch (error) {
  SqliteException() => StorageFailure(cause: error),
  DriftRemoteException(remoteCause: SqliteException()) => StorageFailure(
    cause: error,
  ),
  _ => null,
};

/// Runs [body] and throws a [StorageFailure] instead of a SQLite error.
Future<T> guardStorage<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on Exception catch (e, stackTrace) {
    final failure = storageFailureOf(e);
    if (failure == null) rethrow;
    Error.throwWithStackTrace(failure, stackTrace);
  }
}

/// Stream errors from SQLite become [StorageFailure].
extension StorageErrors<T> on Stream<T> {
  Stream<T> translateStorageErrors() => transform(
    StreamTransformer.fromHandlers(
      handleError: (error, stackTrace, sink) =>
          sink.addError(storageFailureOf(error) ?? error, stackTrace),
    ),
  );
}
