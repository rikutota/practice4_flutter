class ProfileValidators {
  ProfileValidators._();

  /// 表示名は1〜30文字とする。
  static String? displayName(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return '表示名を入力してください';
    }

    if (input.length > 30) {
      return '表示名は30文字以内で入力してください';
    }

    return null;
  }

  /// 公開IDは小文字英数字とアンダースコアのみ許可する。
  ///
  /// 大文字で入力された場合も、保存時には小文字へ変換する。
  static String? publicId(String? value) {
    final input = value?.trim().toLowerCase() ?? '';

    if (input.isEmpty) {
      return '公開IDを入力してください';
    }

    if (input.length < 3 || input.length > 20) {
      return '公開IDは3〜20文字で入力してください';
    }

    final pattern = RegExp(r'^[a-z0-9_]+$');

    if (!pattern.hasMatch(input)) {
      return '半角英数字とアンダースコアのみ使用できます';
    }

    return null;
  }

  /// 自己紹介は任意だが、最大200文字とする。
  static String? profileText(String? value) {
    final input = value?.trim() ?? '';

    if (input.length > 200) {
      return '自己紹介は200文字以内で入力してください';
    }

    return null;
  }
}
