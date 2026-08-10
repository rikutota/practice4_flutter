import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

final accountControllerProvider =
    AsyncNotifierProvider<AccountController, void>(AccountController.new);

class AccountController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {}

  Future<bool> deleteAccount({required String password}) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () =>
          ref.read(accountRepositoryProvider).deleteAccount(password: password),
    );

    return !state.hasError;
  }
}

/// アカウント削除エラーを画面表示用メッセージへ変換する。
String accountErrorMessage(Object error) {
  if (error is AccountUnauthenticatedException) {
    return 'ログイン状態を確認してください';
  }

  if (error is AccountEmailUnavailableException) {
    return 'メールアドレスを確認できません';
  }

  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'wrong-password' || 'invalid-credential' => 'パスワードが正しくありません',

      'requires-recent-login' => '再度ログインしてから削除してください',

      'too-many-requests' => '試行回数が多すぎます。時間をおいて再度お試しください',

      'network-request-failed' => '通信環境を確認してください',

      _ => 'アカウントの削除に失敗しました',
    };
  }

  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'データを削除する権限がありません',

      'unavailable' => '通信環境を確認してください',

      _ => 'アカウントデータの削除に失敗しました',
    };
  }

  return '予期しないエラーが発生しました';
}
