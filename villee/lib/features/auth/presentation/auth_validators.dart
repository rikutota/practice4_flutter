//入力チェックを画面ごとに重複して書かず、ログイン画面と新規登録画面で共通利用

class AuthValidators {
  AuthValidators._();

  static String? email(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'メールアドレスを入力してください';
    }

    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!pattern.hasMatch(input)) {
      return '正しいメールアドレスを入力してください';
    }

    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';

    if (input.isEmpty) {
      return 'パスワードを入力してください';
    }

    if (input.length < 6) {
      return 'パスワードは6文字以上で入力してください';
    }

    return null;
  }
}
