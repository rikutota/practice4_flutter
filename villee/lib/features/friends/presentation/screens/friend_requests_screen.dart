import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friend_providers.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _FriendRequestsAppBar(),
        body: TabBarView(children: [_IncomingRequests(), _OutgoingRequests()]),
      ),
    );
  }
}

class _FriendRequestsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _FriendRequestsAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('友達申請'),
      bottom: const TabBar(
        tabs: [
          Tab(text: '受信'),
          Tab(text: '送信'),
        ],
      ),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);
}

class _IncomingRequests extends ConsumerWidget {
  const _IncomingRequests();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(incomingRequestItemsProvider);

    final actionState = ref.watch(friendActionControllerProvider);

    return requests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('申請の取得に失敗しました')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('受信した申請はありません'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(item.profile.displayName),
              subtitle: Text('@${item.profile.publicId}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '承認',
                    onPressed: actionState.isLoading
                        ? null
                        : () {
                            ref
                                .read(friendActionControllerProvider.notifier)
                                .accept(item.request.id);
                          },
                    icon: const Icon(Icons.check),
                  ),
                  IconButton(
                    tooltip: '拒否',
                    onPressed: actionState.isLoading
                        ? null
                        : () {
                            ref
                                .read(friendActionControllerProvider.notifier)
                                .reject(item.request.id);
                          },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _OutgoingRequests extends ConsumerWidget {
  const _OutgoingRequests();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(outgoingRequestItemsProvider);

    final actionState = ref.watch(friendActionControllerProvider);

    return requests.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('申請の取得に失敗しました')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('送信中の申請はありません'));
        }

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];

            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(item.profile.displayName),
              subtitle: Text('@${item.profile.publicId}'),
              trailing: TextButton(
                onPressed: actionState.isLoading
                    ? null
                    : () {
                        ref
                            .read(friendActionControllerProvider.notifier)
                            .cancel(item.request.id);
                      },
                child: const Text('取り消す'),
              ),
            );
          },
        );
      },
    );
  }
}
