import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/design/app_colors.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/features/progress/presentation/providers/level_title.dart';
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
    return Stack(
      children: [
        Positioned.fill(child: SkyBackground(palette: palette)),
        Positioned.fill(
          child: PlaceholderHills(
            palette: palette,
            dotColor: memberColorFor(ref.watch(currentUserIdProvider)).color,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.m,
              AppSpacing.screen,
              0,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: TodayCard(view: today, palette: palette),
            ),
          ),
        ),
        Positioned.fill(
          bottom: FloatingTabBar.bottomClearance(context),
          child: ProgressSheet(
            view: today.value,
            palette: palette,
            gender: ref.watch(grammaticalGenderProvider),
          ),
        ),
      ],
    );
  }
}
