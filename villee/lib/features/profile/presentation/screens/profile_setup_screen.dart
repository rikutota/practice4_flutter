import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../profile_validators.dart';
import '../providers/profile_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _publicIdController = TextEditingController();
  final _profileTextController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _publicIdController.dispose();
    _profileTextController.dispose();
    super.dispose();
  }

  /// 入力内容を検証してFirestoreへプロフィールを作成する。
  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(profileControllerProvider.notifier)
        .createProfile(
          displayName: _displayNameController.text,
          publicId: _publicIdController.text,
          profileText: _profileTextController.text,
        );

    // 作成成功後はcurrentUserProfileProviderのStreamが更新され、
    // HomeScreenが自動的にプロフィール表示へ切り替わる。
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final authState = ref.watch(authControllerProvider);

    ref.listen(profileControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(profileErrorMessage(error))));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール初期設定'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'ログアウト',
            onPressed: authState.isLoading
                ? null
                : () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('友達から確認できるプロフィールを設定してください。'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _displayNameController,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: '表示名',
                    border: OutlineInputBorder(),
                  ),
                  validator: ProfileValidators.displayName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _publicIdController,
                  maxLength: 20,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: '公開ID',
                    prefixText: '@',
                    border: OutlineInputBorder(),
                    helperText: '作成後は変更できません',
                  ),
                  validator: ProfileValidators.publicId,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _profileTextController,
                  maxLength: 200,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '自己紹介',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  validator: ProfileValidators.profileText,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: profileState.isLoading ? null : _createProfile,
                  child: profileState.isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('プロフィールを作成'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
