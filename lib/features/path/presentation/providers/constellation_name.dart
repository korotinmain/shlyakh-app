import 'package:shlyakh/l10n/app_localizations.dart';

/// Localized name of the route constellation [id] (IAU abbreviation).
///
/// Throws [ArgumentError] for an id that is not on the route.
String constellationName(AppLocalizations l10n, String id) => switch (id) {
  'Sge' => l10n.constellationSge,
  'Vul' => l10n.constellationVul,
  'Cyg' => l10n.constellationCyg,
  'Lac' => l10n.constellationLac,
  'Cep' => l10n.constellationCep,
  'Cas' => l10n.constellationCas,
  'Per' => l10n.constellationPer,
  'Aur' => l10n.constellationAur,
  'Tau' => l10n.constellationTau,
  'Gem' => l10n.constellationGem,
  'Ori' => l10n.constellationOri,
  'Mon' => l10n.constellationMon,
  'CMa' => l10n.constellationCMa,
  'Aql' => l10n.constellationAql,
  'Sct' => l10n.constellationSct,
  'Sgr' => l10n.constellationSgr,
  _ => throw ArgumentError.value(id, 'id', 'not a route constellation'),
};
