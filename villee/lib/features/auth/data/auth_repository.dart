import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  /// 現在の認証状態を監視する。
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  /// メールアドレスとパスワードで新規登録する。
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// メールアドレスとパスワードでログインする。
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// パスワード再設定メールを送信する。
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _firebaseAuth.sendPasswordResetEmail(
      email: email,
    );
  }

  /// 現在のユーザーをログアウトさせる。
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}