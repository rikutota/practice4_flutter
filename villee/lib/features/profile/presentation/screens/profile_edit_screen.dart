import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/user_profile.dart';
import '../profile_validators.dart';
import '../providers/profile_providers.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _displayNameController;
  late final TextEditingController _profileTextController;

  @override
  void initState() {
    super.initState();

    // 編集前の値を入力欄の初期値として設定する。
    _displayNameController = TextEditingController(
      text: widget.profile.displayName,
    );
    _profileTextController = TextEditingController(
      text: widget.profile.profileText,
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _profileTextController.dispose();
    super.dispose();
  }

  /// 入力内容を検証してプロフィールを更新する。
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(
          displayName: _displayNameController.text,
          profileText: _profileTextController.text,
        );

    // 非同期処理後にcontextを使うため、画面が残っているか確認する。
    if (!mounted || !success) {
      return;
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);

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
      appBar: AppBar(title: const Text('プロフィール編集')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '公開ID',
                    border: OutlineInputBorder(),
                    helperText: '公開IDは変更できません',
                  ),
                  child: Text('@${widget.profile.publicId}'),
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
                  onPressed: profileState.isLoading ? null : _updateProfile,
                  child: profileState.isLoading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('保存'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
