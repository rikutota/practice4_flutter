import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthRepository(firebaseAuth);
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {}

  Future<bool> signUp({
    required String email,
    required String password,
  }) {
    return _execute(
      () => ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
          ),
    );
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) {
    return _execute(
      () => ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          ),
    );
  }

  Future<bool> sendPasswordResetEmail({
    required String email,
  }) {
    return _execute(
      () => ref.read(authRepositoryProvider).sendPasswordResetEmail(
            email: email,
          ),
    );
  }

  Future<bool> signOut() {
    return _execute(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }

  Future<bool> _execute(Future<void> Function() operation) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(operation);

    return !state.hasError;
  }
}

String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return '予期しないエラーが発生しました';
  }

  return switch (error.code) {
    'invalid-email' => 'メールアドレスの形式が正しくありません',
    'email-already-in-use' => 'このメールアドレスは既に登録されています',
    'weak-password' => 'パスワードが弱すぎます',
    'user-disabled' => 'このアカウントは無効になっています',
    'user-not-found' => 'メールアドレスまたはパスワードが正しくありません',
    'wrong-password' => 'メールアドレスまたはパスワードが正しくありません',
    'invalid-credential' => 'メールアドレスまたはパスワードが正しくありません',
    'too-many-requests' => '試行回数が多すぎます。時間を置いて再度お試しください',
    'network-request-failed' => '通信環境を確認してください',
    _ => '認証処理に失敗しました',
  };
}