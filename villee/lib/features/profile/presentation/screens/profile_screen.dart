import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Firestore上の現在ユーザーのプロフィールを監視する。
    final profileState = ref.watch(currentUserProfileProvider);

    return profileState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('プロフィール')),
        body: const Center(child: Text('プロフィールの読み込みに失敗しました')),
      ),

      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('プロフィールが設定されていません')));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('プロフィール'),
            actions: [
              IconButton(
                tooltip: '編集',
                onPressed: () {
                  // 編集画面には現在のプロフィールを渡す。
                  context.push('/profile/edit', extra: profile);
                },
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
          body: ListView(
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
            ],
          ),
        );
      },
    );
  }
}
