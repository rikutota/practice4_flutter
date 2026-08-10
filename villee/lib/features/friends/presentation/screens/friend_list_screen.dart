import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friend_providers.dart';

class FriendListScreen extends ConsumerWidget {
  const FriendListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsState = ref.watch(friendItemsProvider);
    final actionState = ref.watch(friendActionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('友達一覧')),
      body: friendsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('友達一覧の取得に失敗しました')),
        data: (friends) {
          if (friends.isEmpty) {
            return const Center(child: Text('友達はいません'));
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final item = friends[index];

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(item.profile.displayName),
                subtitle: Text('@${item.profile.publicId}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value != 'remove') {
                      return;
                    }

                    await ref
                        .read(friendActionControllerProvider.notifier)
                        .removeFriend(item.friendship.id);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'remove', child: Text('友達を解除')),
                  ],
                ),
                enabled: !actionState.isLoading,
              );
            },
          );
        },
      ),
    );
  }
}
