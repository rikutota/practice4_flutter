import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore上の友達申請を表す。
///
/// friend_requestsには「申請中」のデータだけを保存する。
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final DateTime? createdAt;

  /// FirestoreのDocumentSnapshotをFriendRequestへ変換する。
  factory FriendRequest.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('友達申請データが存在しません');
    }

    final createdAt = data['createdAt'];

    return FriendRequest(
      id: document.id,
      senderId: data['senderId'] as String,
      receiverId: data['receiverId'] as String,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
