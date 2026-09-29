import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shlyakh/core/design/app_motion.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/app_spacing.dart';
import 'package:shlyakh/core/design/app_typography.dart';
import 'package:shlyakh/core/error/failure_message.dart';
import 'package:shlyakh/core/l10n/l10n_extension.dart';
import 'package:shlyakh/features/path/presentation/providers/path_provider.dart';
import 'package:shlyakh/features/path/presentation/providers/path_view.dart';
import 'package:shlyakh/features/path/presentation/widgets/constellation_page.dart';
import 'package:shlyakh/features/today/presentation/widgets/sky_background.dart';

/// The Path tab: one page per constellation, from the completed ones to
/// the next one, opening on the current one.
class PathScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(pathProvider);
    return Stack(
      children: [
        const Positioned.fill(child: SkyBackground()),
        switch (path) {
          AsyncValue(:final error?) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: Text(
                failureMessage(context.l10n, error),
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: context.palette.onSky,
                ),
              ),
            ),
          ),
          AsyncValue(:final value?) => _Pages(view: value),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _Pages extends StatefulWidget {
  const new({required this.view});

  final PathView view;

  @override
  State<_Pages> createState() => _PagesState();
}

class _PagesState extends State<_Pages> {
  late final PageController _controller = PageController(
    initialPage: widget.view.currentPage,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(int page) => _controller.animateToPage(
    page,
    duration: AppMotion.normal,
    curve: AppMotion.curve,
  );

  @override
  Widget build(BuildContext context) => PageView.builder(
    controller: _controller,
    itemCount: widget.view.pages.length,
    itemBuilder: (context, i) =>
        ConstellationPage(index: i, view: widget.view, onOpen: _open),
  );
}
