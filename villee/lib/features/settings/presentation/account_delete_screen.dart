import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../location/presentation/providers/location_sharing_providers.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import 'providers/account_providers.dart';

class AccountDeleteScreen extends ConsumerStatefulWidget {
  const AccountDeleteScreen({super.key});

  @override
  ConsumerState<AccountDeleteScreen> createState() =>
      _AccountDeleteScreenState();
}

class _AccountDeleteScreenState extends ConsumerState<AccountDeleteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('アカウントを削除しますか？'),
          content: const Text(
            'プロフィール、友達関係、位置情報などの'
            'アカウントデータが削除されます。\n\n'
            'この操作は元に戻せません。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('削除する'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final profileState = ref.read(currentUserProfileProvider);

    final sharingWasEnabled = profileState.when(
      data: (profile) => profile?.sharingEnabled ?? false,
      loading: () => false,
      error: (error, stackTrace) => false,
    );

    // 削除処理中に位置情報が再書き込みされないよう監視を止める。
    ref.read(locationSharingControllerProvider.notifier).pauseMonitoring();

    final success = await ref
        .read(accountControllerProvider.notifier)
        .deleteAccount(password: _passwordController.text);

    if (!mounted) {
      return;
    }

    if (!success && sharingWasEnabled) {
      await ref
          .read(locationSharingControllerProvider.notifier)
          .resumeMonitoring();
    }

    // 成功するとFirebase Authenticationのユーザーがnullになり、
    // router.dartが自動的に/loginへ遷移する。
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountControllerProvider);

    ref.listen(accountControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(accountErrorMessage(error))));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('アカウント削除')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('アカウントを削除すると、以下のデータが削除されます。'),

                const SizedBox(height: 16),

                const Text('・プロフィール'),
                const Text('・公開ID'),
                const Text('・最新位置情報'),
                const Text('・友達関係'),
                const Text('・送受信した友達申請'),
                const Text('・ログインアカウント'),

                const SizedBox(height: 24),

                const Text('本人確認のため、現在のパスワードを入力してください。'),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'パスワード',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'パスワードを入力してください';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: accountState.isLoading ? null : _deleteAccount,
                  child: accountState.isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('アカウントを削除'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
