import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/design/app_colors.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/design/sky_status_bar.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/steps/presentation/providers/health_access_hint.dart';
import 'package:shlyakh/features/today/presentation/providers/current_user_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/sky_provider.dart';
import 'package:shlyakh/features/today/presentation/providers/today_provider.dart';
import 'package:shlyakh/features/today/presentation/widgets/placeholder_hills.dart';
import 'package:shlyakh/features/today/presentation/widgets/progress_sheet.dart';
import 'package:shlyakh/features/today/presentation/widgets/sky_background.dart';
import 'package:shlyakh/features/today/presentation/widgets/today_card.dart';

/// The Today tab: the sky, the card, the landscape and the sheet.
class TodayScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(skyProvider);
    final today = ref.watch(todayProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyleFor(palette),
      child: Stack(
        children: [
          Positioned.fill(child: SkyBackground(palette: palette)),
          Positioned.fill(
            child: PlaceholderHills(
              palette: palette,
              dotColor: memberColorFor(ref.watch(currentUserIdProvider)).color,
            ),
          ),
          // The card on top; the sheet takes the space below it, so even
          // expanded it never covers the card. It runs under the floating
          // tab bar to the bottom edge; its sizes and content keep clear of
          // the bar.
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
                      TodayCard(view: today, palette: palette),
                      if (ref.watch(healthAccessHintProvider).value ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.s),
                          child: Text(
                            context.l10n.healthAccessHint,
                            style: AppTypography.footnote.copyWith(
                              color: palette.onSky.color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ProgressSheet(
                  view: today.value,
                  palette: palette,
                  bottomClearance: FloatingTabBar.bottomClearance(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
