import 'package:cloud_firestore/cloud_firestore.dart';

/// 成立済みの友達関係を表す。
class Friendship {
  const Friendship({
    required this.id,
    required this.userIds,
    required this.createdAt,
  });

  final String id;
  final List<String> userIds;
  final DateTime? createdAt;

  factory Friendship.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('友達関係データが存在しません');
    }

    final createdAt = data['createdAt'];

    return Friendship(
      id: document.id,
      userIds: List<String>.from(data['userIds'] as List),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  /// 自分ではない方のUIDを返す。
  ///
  /// friendshipsには必ず2人のUIDが保存される前提。
  String otherUserId(String currentUserId) {
    return userIds.firstWhere((userId) => userId != currentUserId);
  }
}
