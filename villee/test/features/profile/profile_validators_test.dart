import 'package:flutter_test/flutter_test.dart';
import 'package:villee/features/profile/presentation/profile_validators.dart';

void main() {
  group('ProfileValidators.displayName', () {
    test('空文字はエラーになる', () {
      expect(ProfileValidators.displayName(''), '表示名を入力してください');
    });

    test('30文字以内ならnullになる', () {
      expect(ProfileValidators.displayName('テストユーザー'), isNull);
    });
  });

  group('ProfileValidators.publicId', () {
    test('日本語を含むIDはエラーになる', () {
      expect(ProfileValidators.publicId('ユーザー123'), '半角英数字とアンダースコアのみ使用できます');
    });

    test('英数字とアンダースコアは使用できる', () {
      expect(ProfileValidators.publicId('taka_123'), isNull);
    });

    test('3文字未満はエラーになる', () {
      expect(ProfileValidators.publicId('ab'), '公開IDは3〜20文字で入力してください');
    });
  });

  group('ProfileValidators.profileText', () {
    test('200文字を超えるとエラーになる', () {
      expect(ProfileValidators.profileText('a' * 201), '自己紹介は200文字以内で入力してください');
    });
  });
}
