import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shlyakh/app/floating_tab_bar.dart';

/// The tab branches with the floating tab bar over them.
class AppShell extends StatelessWidget {
  const new({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                onSelect: (i) =>
                    shell.goBranch(i, initialLocation: i == shell.currentIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
