import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseAuth = ref.watch(firebaseAuthProvider);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          IconButton(
            tooltip: '編集',
            onPressed: () {
              // 編集対象をextraとして編集画面へ渡す。
              context.push('/profile/edit', extra: profile);
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 48,
                child: Icon(Icons.person, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                profile.displayName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 4),
            Center(child: Text('@${profile.publicId}')),
            const SizedBox(height: 24),
            const Text('自己紹介', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              profile.profileText.isEmpty
                  ? '自己紹介は設定されていません'
                  : profile.profileText,
            ),
            const SizedBox(height: 24),
            const Text(
              'メールアドレス',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(firebaseAuth.currentUser?.email ?? ''),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: authState.isLoading
                  ? null
                  : () {
                      // 設定画面完成までは、動作確認用としてここに置く。
                      ref.read(authControllerProvider.notifier).signOut();
                    },
              child: const Text('ログアウト'),
            ),
          ],
        ),
      ),
    );
  }
}
