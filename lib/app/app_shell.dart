import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';
import 'package:shlyakh/core/design/app_palette.dart';
import 'package:shlyakh/core/design/status_bar.dart';

/// The tab branches with the floating tab bar over them. The status bar
/// follows the theme on every tab.
class AppShell extends StatelessWidget {
  const new({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyleFor(context.palette.brightness),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: shell),
            Positioned(
              left: 0,
              right: 0,
              bottom: FloatingTabBar.bottomInset(context),
              child: Center(
                child: FloatingTabBar(
                  index: shell.currentIndex,
                  // Tapping the current tab again returns to its first page.
                  onSelect: (i) => shell.goBranch(
                    i,
                    initialLocation: i == shell.currentIndex,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
