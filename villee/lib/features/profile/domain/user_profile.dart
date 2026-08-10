import 'package:cloud_firestore/cloud_firestore.dart';

/// FirestoreのusersドキュメントをFlutter内で扱うための型。
///
/// [id]はドキュメント内部のフィールドではなく、
/// FirestoreのドキュメントIDであるFirebase AuthenticationのUIDを使う。
class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.publicId,
    required this.profileText,
    required this.sharingEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String publicId;
  final String profileText;
  final bool sharingEnabled;

  /// serverTimestampの確定前はnullになる可能性がある。
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// FirestoreのドキュメントをUserProfileへ変換する。
  factory UserProfile.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('プロフィールデータが存在しません');
    }

    return UserProfile(
      id: document.id,
      displayName: data['displayName'] as String,
      publicId: data['publicId'] as String,
      profileText: data['profileText'] as String,
      sharingEnabled: data['sharingEnabled'] as bool,
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  /// FirestoreのTimestampをDartのDateTimeへ変換する。
  static DateTime? _timestampToDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}
