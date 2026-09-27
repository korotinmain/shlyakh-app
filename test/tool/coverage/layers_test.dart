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
    // Must match what flutter test omits from lcov (package:coverage regex).
    final cases = <(String, String, bool)>[
      ('the bare comment', '// coverage:ignore-file\nvoid f() {}', true),
      ('extra spaces after //', '//  coverage:ignore-file', true),
      ('the comment after code', 'int a() => 1; // coverage:ignore-file', true),
      ('a reason after a colon', '// coverage:ignore-file reason: x', false),
      ('other coverage comments', '// coverage:ignore-line', false),
      (
        'the marker inside a string',
        'final s = "// coverage:ignore-file";',
        false,
      ),
    ];
    for (final (name, source, expected) in cases) {
      test('returns $expected for $name', () {
        expect(hasIgnoreFileComment(source), expected);
      });
    }
  });

  group('hasExecutableCode', () {
    final cases = <(String, String, bool)>[
      (
        'an interface',
        'abstract interface class R {\n  int steps();\n}',
        false,
      ),
      ('an enum', 'enum Kind { a, b }', false),
      (
        'constants and typedefs',
        'const int max = 5;\ntypedef Steps = int;',
        false,
      ),
      (
        'a const constructor',
        'class A {\n  const A(this.v);\n  final int v;\n}',
        false,
      ),
      ('an arrow function', 'int f(int x) => x + 1;', true),
      ('a block body', 'void f() {\n  g();\n}', true),
      ('an async block body', 'Future<void> f() async {\n}', true),
      ('an arrow getter', 'class A {\n  int get v => 1;\n}', true),
      ('an arrow only in a comment', '// f() => 1\nenum K { a }', false),
      ('an arrow only in a string', "const s = 'a => b';", false),
    ];
    for (final (name, source, expected) in cases) {
      test('returns $expected for $name', () {
        expect(hasExecutableCode(source), expected);
      });
    }
  });
}
