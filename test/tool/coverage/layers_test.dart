import 'package:flutter_test/flutter_test.dart';

import '../../../tool/coverage/src/layers.dart';

void main() {
  group('classify', () {
    final cases = <(String, String, Layer)>[
      ('generated g.dart', 'lib/features/x/domain/a.g.dart', Layer.excluded),
      (
        'generated freezed',
        'lib/features/x/data/a.freezed.dart',
        Layer.excluded,
      ),
      ('l10n output', 'lib/l10n/app_localizations.dart', Layer.excluded),
      ('main', 'lib/main.dart', Layer.excluded),
      ('bootstrap', 'lib/app/router.dart', Layer.excluded),
      ('domain', 'lib/features/steps/domain/xp.dart', Layer.domain),
      (
        'nested domain',
        'lib/features/steps/domain/rules/level.dart',
        Layer.domain,
      ),
      ('data', 'lib/features/steps/data/steps_repository.dart', Layer.data),
      (
        'providers',
        'lib/features/steps/presentation/providers/today.dart',
        Layer.presentationLogic,
      ),
      (
        'widget',
        'lib/features/steps/presentation/widgets/ring.dart',
        Layer.excluded,
      ),
      (
        'screen',
        'lib/features/home/presentation/home_screen.dart',
        Layer.excluded,
      ),
      ('core', 'lib/core/time/clock_provider.dart', Layer.core),
      ('other lib file', 'lib/shared/x.dart', Layer.core),
    ];

    for (final (name, path, layer) in cases) {
      test('classifies $name as ${layer.name}', () {
        expect(classify(path), layer);
      });
    }
  });

  group('hasIgnoreFileComment', () {
    test('detects the bare comment', () {
      expect(
        hasIgnoreFileComment('// coverage:ignore-file\nvoid f() {}'),
        isTrue,
      );
    });

    test('detects the comment followed by a reason', () {
      expect(
        hasIgnoreFileComment('// coverage:ignore-file reason: FFI glue'),
        isTrue,
      );
    });

    test('ignores other coverage comments', () {
      expect(hasIgnoreFileComment('// coverage:ignore-line'), isFalse);
    });

    test('ignores the marker inside code', () {
      expect(
        hasIgnoreFileComment('final s = "// coverage:ignore-file";'),
        isFalse,
      );
    });
  });
}
