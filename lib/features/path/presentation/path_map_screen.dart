import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/design/glass_panel.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/path/domain/path_pages.dart';
import 'package:shlyakh/features/path/domain/sky_map.dart';
import 'package:shlyakh/features/path/presentation/providers/constellation_name.dart';
import 'package:shlyakh/features/path/presentation/providers/path_provider.dart';
import 'package:shlyakh/features/path/presentation/providers/path_view.dart';
import 'package:shlyakh/features/path/presentation/widgets/sky_map_painter.dart';
import 'package:shlyakh/features/today/presentation/widgets/sky_background.dart';

/// Width of a constellation's name label on the map, and its gap below
/// the figure, in logical pixels.
const double _labelWidth = 140;
const double _labelGap = AppSpacing.xxs;

/// The Milky Way map: the band on a star chart, the completed
/// constellations in gold, the current one with its marker, the next one,
/// and fog beyond.
class PathMapScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final l10n = context.l10n;
    final view = ref.watch(pathProvider).value;
    return Stack(
      children: [
        const Positioned.fill(child: SkyBackground()),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: FloatingTabBar.bottomClearance(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen,
                    AppSpacing.s,
                    AppSpacing.screen,
                    0,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Semantics(
                      button: true,
                      label: l10n.back,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: const GlassPanel(
                          shape: CircleBorder(),
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.xs),
                            child: Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (view != null) ...[
                  Text(
                    l10n.pathMapKicker,
                    textAlign: TextAlign.center,
                    style: AppTypography.footnote.copyWith(
                      color: palette.onSkyMuted,
                    ),
                  ),
                  Text(
                    l10n.pathCompletedCount(view.completedCount),
                    textAlign: TextAlign.center,
                    style: AppTypography.title.copyWith(color: palette.onSky),
                  ),
                  Text(
                    view.progress.next == null
                        ? l10n.pathLitStars(view.progress.starsLit)
                        : l10n.pathMapSubtitle(
                            l10n.pathLitStars(view.progress.starsLit),
                          ),
                    textAlign: TextAlign.center,
                    style: AppTypography.footnote.copyWith(
                      color: palette.onSkyMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Expanded(child: _Chart(view: view)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Chart extends StatefulWidget {
  const new({required this.view});

  final PathView view;

  @override
  State<_Chart> createState() => _ChartState();
}

class _ChartState extends State<_Chart> {
  ScrollController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final palette = context.palette;
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final lastVisible = view.route.constellations.indexOf(
          view.pages.last.constellation,
        );
        final layout = skyMapLayout(
          view.route,
          width: constraints.maxWidth,
          lastVisible: lastVisible,
        );
        final current =
            layout.constellations[view.route.constellations.indexOf(
              view.pages[view.currentPage].constellation,
            )];
        _controller ??= ScrollController(
          initialScrollOffset: (current.y - constraints.maxHeight / 2).clamp(
            0,
            (layout.height - constraints.maxHeight).clamp(0, double.infinity),
          ),
        );
        return SingleChildScrollView(
          controller: _controller,
          child: SizedBox(
            width: layout.width,
            height: layout.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: SkyMapPainter(
                      layout: layout,
                      view: view,
                      palette: palette,
                    ),
                  ),
                ),
                for (final page in view.pages)
                  _label(
                    layout.constellations[view.route.constellations.indexOf(
                      page.constellation,
                    )],
                    constellationName(l10n, page.constellation.id),
                    page.state == PageState.current,
                    palette,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _label(
    MapPlacement at,
    String name,
    bool current,
    AppPalette palette,
  ) => Positioned(
    left: at.x - _labelWidth / 2,
    top: at.y + at.side / 2 + _labelGap,
    width: _labelWidth,
    child: Text(
      name,
      textAlign: TextAlign.center,
      style: AppTypography.footnote.copyWith(
        color: current ? palette.onSky : palette.onSkyMuted,
        fontWeight: current ? FontWeight.w600 : null,
      ),
    ),
  );
}
