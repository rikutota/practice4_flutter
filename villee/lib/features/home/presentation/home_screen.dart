import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/presentation/providers/profile_providers.dart';
import '../../profile/presentation/screens/profile_setup_screen.dart';

/// ログイン直後のプロフィール確認を担当する画面。
///
/// プロフィール未作成なら初期設定画面を表示し、
/// 作成済みならメイン画面へ進める。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentUserProfileProvider);

    return profileState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('プロフィールの読み込みに失敗しました'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  // Firestoreからプロフィールを再取得する。
                  ref.invalidate(currentUserProfileProvider);
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),

      data: (profile) {
        if (profile == null) {
          return const ProfileSetupScreen();
        }

        // build中に直接画面遷移するとエラーになる可能性があるため、
        // 現在の描画が終了した後でメイン画面へ移動する。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/profile');
          }
        });

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
