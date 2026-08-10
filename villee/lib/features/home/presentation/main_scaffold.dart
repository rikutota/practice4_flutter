import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// アプリの主要3画面を切り替える共通レイアウト。
///
/// StatefulNavigationShellが各タブのNavigatorを管理するため、
/// タブを切り替えても各画面の状態を保持できる。
class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// ボトムナビゲーションで選択されたタブへ切り替える。
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,

      // 現在選択中のタブをもう一度押した場合は、
      // そのタブの最初の画面へ戻す。
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'プロフィール',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'マップ',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
