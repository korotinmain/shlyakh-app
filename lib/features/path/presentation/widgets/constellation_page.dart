import 'package:flutter/material.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/path/domain/path_pages.dart';
import 'package:shlyakh/features/path/presentation/providers/constellation_name.dart';
import 'package:shlyakh/features/path/presentation/providers/path_view.dart';
import 'package:shlyakh/features/path/presentation/widgets/path_info_card.dart';
import 'package:shlyakh/features/path/presentation/widgets/route_strip.dart';
import 'package:shlyakh/features/today/presentation/widgets/constellation_figure.dart';

/// Below this height the page scrolls and the figure gets a fixed zone.
const double _minFillHeight = 520;
const double _scrollFigureHeight = 220;

/// One constellation of the Path tab, in zones: the header at the top,
/// the figure in the middle, the info card and the route strip at the
/// bottom, above the tab bar.
class ConstellationPage extends StatelessWidget {
  const new({
    required this.index,
    required this.view,
    required this.onOpen,
    super.key,
  });

  /// Index of this page in `view.pages`.
  final int index;
  final PathView view;

  /// Animates the pager to a page index.
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final page = view.pages[index];
    final l10n = context.l10n;
    String nameAt(int i) =>
        constellationName(l10n, view.pages[i].constellation.id);
    final header = _Header(page: page, view: view);
    final figure = ConstellationFigure(
      constellation: page.constellation,
      figure: page.figure,
      done: page.state == PageState.done,
      showName: false,
    );
    final bottom = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PathInfoCard(page: page, view: view),
        const SizedBox(height: AppSpacing.s),
        RouteStrip(
          previous: index > 0 ? nameAt(index - 1) : null,
          current: nameAt(index),
          next: index + 1 < view.pages.length ? nameAt(index + 1) : null,
          onPrevious: index > 0 ? () => onOpen(index - 1) : null,
          onNext: index + 1 < view.pages.length
              ? () => onOpen(index + 1)
              : null,
        ),
      ],
    );
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.m,
          AppSpacing.screen,
          FloatingTabBar.bottomClearance(context),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight >= _minFillHeight) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Expanded(child: figure),
                  bottom,
                ],
              );
            }
            // Very large text: the page scrolls, the figure keeps a zone.
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  SizedBox(height: _scrollFigureHeight, child: figure),
                  bottom,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const new({required this.page, required this.view});

  final PathPageView page;
  final PathView view;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final (kicker, subtitle) = switch (page.state) {
      PageState.current => (
        l10n.pathNowHere,
        l10n.pathCompletedCount(view.completedCount),
      ),
      PageState.done => (l10n.pathDone, l10n.pathStarCount(page.ownStars)),
      PageState.ahead => (l10n.pathAhead, l10n.pathStarCount(page.ownStars)),
    };
    return Column(
      children: [
        Text(
          kicker,
          style: AppTypography.footnote.copyWith(
            color: page.state == PageState.done
                ? palette.done
                : palette.onSkyMuted,
          ),
        ),
        Text(
          constellationName(l10n, page.constellation.id),
          textAlign: TextAlign.center,
          style: AppTypography.title.copyWith(color: palette.onSky),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTypography.footnote.copyWith(color: palette.onSkyMuted),
        ),
      ],
    );
  }
}
