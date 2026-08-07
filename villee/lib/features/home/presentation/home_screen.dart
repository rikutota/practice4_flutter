import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/presentation/providers/profile_providers.dart';
import '../../profile/presentation/screens/profile_screen.dart';
import '../../profile/presentation/screens/profile_setup_screen.dart';

/// ログインユーザーのプロフィール有無を判定する入口。
///
/// プロフィールがなければ初期設定、存在すれば表示画面へ切り替える。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentUserProfileProvider);

    return profileState.when(
      data: (profile) {
        if (profile == null) {
          return const ProfileSetupScreen();
        }

        return ProfileScreen(profile: profile);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('エラー')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('プロフィールの読み込みに失敗しました'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  // Providerを破棄してFirestoreから再取得する。
                  ref.invalidate(currentUserProfileProvider);
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
