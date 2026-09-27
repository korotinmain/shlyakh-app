import 'package:shlyakh/core/error/failure.dart';
import 'package:shlyakh/l10n/app_localizations.dart';

/// The localized message for [error]: a specific one for every [Failure],
/// the generic one for anything else (a bug, which is logged separately).
String failureMessage(AppLocalizations l10n, Object error) => switch (error) {
  // Exhaustive over the sealed type: a new Failure breaks compilation here.
  final Failure failure => switch (failure) {
    HealthAccessDenied() => l10n.errorHealthAccessDenied,
    HealthUnavailable() => l10n.errorHealthUnavailable,
    StorageFailure() => l10n.errorStorage,
    UnexpectedFailure() => l10n.errorUnexpected,
  },
  _ => l10n.errorGeneric,
};
