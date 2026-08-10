import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/profile_repository.dart';
import '../../domain/user_profile.dart';

/// Firestoreインスタンスをアプリ内へ提供する。
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// ProfileRepositoryの依存関係を組み立てる。
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

/// 現在のプロフィールをリアルタイムに監視する。
///
/// autoDisposeにより、ログアウトして画面から離れた際に
/// Firestoreの監視を破棄する。
final currentUserProfileProvider = StreamProvider.autoDispose<UserProfile?>((
  ref,
) {
  return ref.watch(profileRepositoryProvider).watchCurrentProfile();
});

/// プロフィール作成・更新処理の実行状態を管理する。
final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);

class ProfileController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {}

  /// 初回プロフィールを作成する。
  Future<bool> createProfile({
    required String displayName,
    required String publicId,
    required String profileText,
  }) {
    return _execute(
      () => ref
          .read(profileRepositoryProvider)
          .createProfile(
            displayName: displayName,
            publicId: publicId,
            profileText: profileText,
          ),
    );
  }

  /// 表示名と自己紹介を更新する。
  Future<bool> updateProfile({
    required String displayName,
    required String profileText,
  }) {
    return _execute(
      () => ref
          .read(profileRepositoryProvider)
          .updateProfile(displayName: displayName, profileText: profileText),
    );
  }

  /// 非同期処理のローディング・成功・失敗を共通管理する。
  Future<bool> _execute(Future<void> Function() operation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(operation);

    return !state.hasError;
  }
}

/// プロフィール処理の例外を画面表示用メッセージへ変換する。
String profileErrorMessage(Object error) {
  if (error is PublicIdAlreadyInUseException) {
    return 'この公開IDは既に使用されています';
  }

  if (error is ProfileAlreadyExistsException) {
    return 'プロフィールは既に作成されています';
  }

  if (error is ProfileUnauthenticatedException) {
    return 'ログイン状態を確認してください';
  }

  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'プロフィールを保存する権限がありません',
      'unavailable' => '通信環境を確認してください',
      'not-found' => 'プロフィールが見つかりません',
      _ => 'プロフィール処理に失敗しました',
    };
  }

  return '予期しないエラーが発生しました';
}
