import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_providers.dart';

/// アプリ設定をまとめる画面。
///
/// 現段階ではログアウトだけ実装し、
/// バージョン表示・位置共有設定・アカウント削除は後で追加する。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
            onTap: authState.isLoading
                ? null
                : () {
                    // Firebase Authenticationからログアウトする。
                    //
                    // 認証状態の変更はrouter.dartが監視しているため、
                    // ここでログイン画面への遷移を直接行う必要はない。
                    ref.read(authControllerProvider.notifier).signOut();
                  },
          ),
        ],
      ),
    );
  }
}
