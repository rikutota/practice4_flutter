import 'package:flutter_test/flutter_test.dart';
import 'package:villee/features/auth/presentation/auth_validators.dart';

void main() {
  group('AuthValidators.email', () {
    test('空文字はエラーになる', () {
      expect(AuthValidators.email(''), 'メールアドレスを入力してください');
    });

    test('正しいメールアドレスはnullになる', () {
      expect(AuthValidators.email('test@example.com'), isNull);
    });
  });

  group('AuthValidators.password', () {
    test('6文字未満はエラーになる', () {
      expect(AuthValidators.password('12345'), 'パスワードは6文字以上で入力してください');
    });

    test('6文字以上はnullになる', () {
      expect(AuthValidators.password('123456'), isNull);
    });
  });
}
