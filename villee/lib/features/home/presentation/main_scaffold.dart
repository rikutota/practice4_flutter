import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../location/presentation/providers/location_sharing_providers.dart';
import '../../profile/presentation/providers/profile_providers.dart';

class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with WidgetsBindingObserver {
  late final LocationSharingController _sharingController;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _sharingController = ref.read(locationSharingControllerProvider.notifier);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeSharingIfEnabled();
      return;
    }

    // バックグラウンドでは位置更新を停止する。
    _sharingController.pauseMonitoring();
  }

  void _resumeSharingIfEnabled() {
    ref.read(currentUserProfileProvider).whenData((profile) {
      if (profile?.sharingEnabled == true) {
        unawaited(_sharingController.resumeMonitoring());
      }
    });
  }

  void _onDestinationSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // sharingEnabledが変化した場合も監視状態を合わせる。
    ref.listen(currentUserProfileProvider, (previous, next) {
      next.whenData((profile) {
        if (profile?.sharingEnabled == true) {
          if (WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed) {
            unawaited(_sharingController.resumeMonitoring());
          }
        } else {
          _sharingController.endSession();
        }
      });
    });

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // ログアウトなどでメイン画面自体が破棄された場合にも停止する。
    _sharingController.endSession();

    super.dispose();
  }
}
