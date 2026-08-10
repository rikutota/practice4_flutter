import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_providers.dart';
import '../../location/presentation/providers/location_sharing_providers.dart';
import '../../profile/presentation/providers/profile_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    final profileState = ref.watch(currentUserProfileProvider);

    final sharingState = ref.watch(locationSharingControllerProvider);

    ref.listen(locationSharingControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(locationSharingErrorMessage(error))),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('設定情報の読み込みに失敗しました')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('プロフィールが設定されていません'));
          }

          return ListView(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.location_on_outlined),
                title: const Text('位置情報を共有'),
                subtitle: const Text('アプリ使用中のみ友達と位置情報を共有します'),
                value: profile.sharingEnabled,
                onChanged: sharingState.isLoading
                    ? null
                    : (enabled) {
                        if (enabled) {
                          ref
                              .read(locationSharingControllerProvider.notifier)
                              .enableSharing();
                        } else {
                          ref
                              .read(locationSharingControllerProvider.notifier)
                              .disableSharing();
                        }
                      },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('ログアウト'),
                onTap: authState.isLoading
                    ? null
                    : () {
                        ref.read(authControllerProvider.notifier).signOut();
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}
