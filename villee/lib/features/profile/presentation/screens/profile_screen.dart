import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentUserProfileProvider);

    return profileState.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),

      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: const Text('プロフィール'),
        ),
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
          return const Scaffold(
            body: Center(
              child: Text('プロフィールが設定されていません'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('プロフィール'),
            actions: [
              IconButton(
                tooltip: '編集',
                onPressed: () {
                  context.push(
                    '/profile/edit',
                    extra: profile,
                  );
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
                    child: Icon(
                      Icons.person,
                      size: 48,
                    ),
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

                Center(
                  child: Text(
                    '@${profile.publicId}',
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  '自己紹介',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  profile.profileText.isEmpty
                      ? '自己紹介は設定されていません'
                      : profile.profileText,
                ),

                const SizedBox(height: 32),

                const Divider(),

                // 友達一覧
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.people),
                  title: const Text('友達一覧'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/profile/friends');
                  },
                ),

                // 公開IDから友達を検索して申請する。
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_add),
                  title: const Text('友達を追加'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/profile/friend-search');
                  },
                ),

                // 受信・送信中の友達申請を確認する。
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.mark_email_unread_outlined,
                  ),
                  title: const Text('友達申請'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/profile/friend-requests');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}