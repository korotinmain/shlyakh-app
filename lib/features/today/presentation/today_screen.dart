import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/steps/presentation/providers/health_access_hint.dart';
import 'package:shlyakh/features/today/presentation/providers/today_provider.dart';
import 'package:shlyakh/features/today/presentation/widgets/constellation_figure.dart';
import 'package:shlyakh/features/today/presentation/widgets/hills_silhouette.dart';
import 'package:shlyakh/features/today/presentation/widgets/progress_sheet.dart';
import 'package:shlyakh/features/today/presentation/widgets/sky_background.dart';
import 'package:shlyakh/features/today/presentation/widgets/today_card.dart';

/// How far the hills rise above the collapsed sheet: the constellation
/// ends above them, in the sky.
const double _hillsRise = 96;

/// The Today tab, in zones (docs/DESIGN.md, "Layout"): the card at the
/// top, the current constellation between the card and the collapsed
/// sheet, a hills silhouette under it, and the sheet.
class TodayScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final today = ref.watch(todayProvider);
    final view = today.value;
    final clearance = FloatingTabBar.bottomClearance(context);
    final collapsed = ProgressSheet.collapsedHeight(
      MediaQuery.sizeOf(context).height,
      clearance,
    );
    return Stack(
      children: [
        const Positioned.fill(child: SkyBackground()),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: collapsed + _hillsRise,
          child: const HillsSilhouette(),
        ),
        // The card on top; the sheet takes the space below it, so even
        // expanded it never covers the card. It runs under the floating tab
        // bar to the bottom edge; its sizes and content keep clear of the
        // bar. The constellation fills what the collapsed sheet leaves.
        Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.m,
                  AppSpacing.screen,
                  AppSpacing.s,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TodayCard(view: today),
                    if (ref.watch(healthAccessHintProvider).value ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s),
                        child: Text(
                          context.l10n.healthAccessHint,
                          style: AppTypography.footnote.copyWith(
                            color: palette.onSky,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    if (view != null)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: math.max(
                          0,
                          constraints.maxHeight - collapsed - _hillsRise,
                        ),
                        child: ConstellationFigure(
                          constellation: view.constellation,
                          figure: view.figure,
                        ),
                      ),
                    Positioned.fill(
                      child: ProgressSheet(
                        view: view,
                        bottomClearance: clearance,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
