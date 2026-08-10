import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friend_providers.dart';

class FriendSearchScreen extends ConsumerStatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  ConsumerState<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends ConsumerState<FriendSearchScreen> {
  final _publicIdController = TextEditingController();

  @override
  void dispose() {
    _publicIdController.dispose();
    super.dispose();
  }

  /// 入力された公開IDでユーザーを検索する。
  Future<void> _search() async {
    final publicId = _publicIdController.text.trim();

    if (publicId.isEmpty) {
      return;
    }

    await ref.read(friendSearchControllerProvider.notifier).search(publicId);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(friendSearchControllerProvider);

    final actionState = ref.watch(friendActionControllerProvider);

    ref.listen(friendSearchControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(friendErrorMessage(error))));
        },
      );
    });

    ref.listen(friendActionControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(friendErrorMessage(error))));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('友達を検索')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _publicIdController,
              decoration: const InputDecoration(
                labelText: '公開ID',
                prefixText: '@',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: searchState.isLoading ? null : _search,
              child: const Text('検索'),
            ),
            const SizedBox(height: 24),

            searchState.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (profile) {
                if (profile == null) {
                  return const SizedBox.shrink();
                }

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(profile.displayName),
                    subtitle: Text('@${profile.publicId}'),
                    trailing: FilledButton(
                      onPressed: actionState.isLoading
                          ? null
                          : () async {
                              final success = await ref
                                  .read(friendActionControllerProvider.notifier)
                                  .sendRequest(profile.id);

                              if (!context.mounted || !success) {
                                return;
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('友達申請を送信しました')),
                              );
                            },
                      child: const Text('申請'),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
