import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../profile/domain/user_profile.dart';
import '../domain/friend_request.dart';
import '../domain/friendship.dart';

class FriendUserNotFoundException implements Exception {
  const FriendUserNotFoundException();
}

class CannotAddSelfException implements Exception {
  const CannotAddSelfException();
}

class FriendRequestAlreadyExistsException implements Exception {
  const FriendRequestAlreadyExistsException();
}

class AlreadyFriendsException implements Exception {
  const AlreadyFriendsException();
}

class FriendRequestNotFoundException implements Exception {
  const FriendRequestNotFoundException();
}

class FriendPermissionException implements Exception {
  const FriendPermissionException();
}

class FriendUnauthenticatedException implements Exception {
  const FriendUnauthenticatedException();
}

/// 友達機能に関するFirestoreアクセスを担当する。
class FriendRepository {
  const FriendRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  }) : _firestore = firestore,
       _firebaseAuth = firebaseAuth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  /// 2人のUIDから常に同じpairIdを生成する。
  ///
  /// A→BとB→Aで異なるIDにならないよう、
  /// 辞書順で並べてから連結する。
  static String createPairId(String firstUserId, String secondUserId) {
    if (firstUserId.compareTo(secondUserId) < 0) {
      return '${firstUserId}_$secondUserId';
    }

    return '${secondUserId}_$firstUserId';
  }

  /// 公開IDからユーザーを検索する。
  Future<UserProfile> findUserByPublicId(String publicId) async {
    final currentUser = _requireCurrentUser();
    final normalizedPublicId = publicId.trim().toLowerCase();

    // public_idsのドキュメントIDが公開IDなので、
    // users全件を検索する必要がない。
    final publicIdDocument = await _firestore
        .collection('public_ids')
        .doc(normalizedPublicId)
        .get();

    if (!publicIdDocument.exists) {
      throw const FriendUserNotFoundException();
    }

    final targetUserId = publicIdDocument.data()?['userId'] as String?;

    if (targetUserId == null) {
      throw const FriendUserNotFoundException();
    }

    // 自分自身への友達申請は禁止する。
    if (targetUserId == currentUser.uid) {
      throw const CannotAddSelfException();
    }

    final userDocument = await _firestore
        .collection('users')
        .doc(targetUserId)
        .get();

    if (!userDocument.exists) {
      throw const FriendUserNotFoundException();
    }

    return UserProfile.fromDocument(userDocument);
  }

  /// 友達申請を送信する。
  ///
  /// 友達関係と申請データをTransaction内で確認し、
  /// 重複申請や既存の友達への申請を防ぐ。
  Future<void> sendFriendRequest({required String receiverId}) async {
    final currentUser = _requireCurrentUser();

    if (currentUser.uid == receiverId) {
      throw const CannotAddSelfException();
    }

    final pairId = createPairId(currentUser.uid, receiverId);

    final receiverReference = _firestore.collection('users').doc(receiverId);

    final requestReference = _firestore
        .collection('friend_requests')
        .doc(pairId);

    final friendshipReference = _firestore
        .collection('friendships')
        .doc(pairId);

    await _firestore.runTransaction((transaction) async {
      // Transactionでは読み取りを先に行う。
      final receiverSnapshot = await transaction.get(receiverReference);

      final requestSnapshot = await transaction.get(requestReference);

      final friendshipSnapshot = await transaction.get(friendshipReference);

      if (!receiverSnapshot.exists) {
        throw const FriendUserNotFoundException();
      }

      if (friendshipSnapshot.exists) {
        throw const AlreadyFriendsException();
      }

      // A→BまたはB→Aのどちらかの申請が存在する場合も
      // 同じpairIdになるため重複を防げる。
      if (requestSnapshot.exists) {
        throw const FriendRequestAlreadyExistsException();
      }

      transaction.set(requestReference, {
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 自分宛ての友達申請を監視する。
  Stream<List<FriendRequest>> watchIncomingRequests() {
    final currentUser = _requireCurrentUser();

    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(FriendRequest.fromDocument)
              .toList();

          // 複合インデックスを増やさないため、
          // 今回はcreatedAtによる並び替えをアプリ側で行う。
          requests.sort(
            (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
              a.createdAt ?? DateTime(1970),
            ),
          );

          return requests;
        });
  }

  /// 自分が送信した友達申請を監視する。
  Stream<List<FriendRequest>> watchOutgoingRequests() {
    final currentUser = _requireCurrentUser();

    return _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(FriendRequest.fromDocument)
              .toList();

          requests.sort(
            (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
              a.createdAt ?? DateTime(1970),
            ),
          );

          return requests;
        });
  }

  /// 自分が参加している友達関係を監視する。
  Stream<List<Friendship>> watchFriendships() {
    final currentUser = _requireCurrentUser();

    return _firestore
        .collection('friendships')
        .where('userIds', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Friendship.fromDocument).toList());
  }

  /// UIDからプロフィールを取得する。
  Future<UserProfile> fetchUserProfile(String userId) async {
    final document = await _firestore.collection('users').doc(userId).get();

    if (!document.exists) {
      throw const FriendUserNotFoundException();
    }

    return UserProfile.fromDocument(document);
  }

  /// 受信した友達申請を承認する。
  ///
  /// friendship作成とfriend_request削除を
  /// 同じTransactionで行う。
  Future<void> acceptFriendRequest(String requestId) async {
    final currentUser = _requireCurrentUser();

    final requestReference = _firestore
        .collection('friend_requests')
        .doc(requestId);

    final friendshipReference = _firestore
        .collection('friendships')
        .doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestReference);

      final friendshipSnapshot = await transaction.get(friendshipReference);

      if (!requestSnapshot.exists) {
        throw const FriendRequestNotFoundException();
      }

      final request = FriendRequest.fromDocument(requestSnapshot);

      // 申請を受け取った本人だけが承認できる。
      if (request.receiverId != currentUser.uid) {
        throw const FriendPermissionException();
      }

      if (friendshipSnapshot.exists) {
        transaction.delete(requestReference);
        return;
      }

      final userIds = [request.senderId, request.receiverId]..sort();

      transaction.set(friendshipReference, {
        'userIds': userIds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.delete(requestReference);
    });
  }

  /// 受信した申請を拒否する。
  Future<void> rejectFriendRequest(String requestId) async {
    final currentUser = _requireCurrentUser();

    final reference = _firestore.collection('friend_requests').doc(requestId);

    final snapshot = await reference.get();

    if (!snapshot.exists) {
      throw const FriendRequestNotFoundException();
    }

    final request = FriendRequest.fromDocument(snapshot);

    if (request.receiverId != currentUser.uid) {
      throw const FriendPermissionException();
    }

    await reference.delete();
  }

  /// 自分が送った申請を取り消す。
  Future<void> cancelFriendRequest(String requestId) async {
    final currentUser = _requireCurrentUser();

    final reference = _firestore.collection('friend_requests').doc(requestId);

    final snapshot = await reference.get();

    if (!snapshot.exists) {
      throw const FriendRequestNotFoundException();
    }

    final request = FriendRequest.fromDocument(snapshot);

    if (request.senderId != currentUser.uid) {
      throw const FriendPermissionException();
    }

    await reference.delete();
  }

  /// 友達関係を解除する。
  Future<void> removeFriend(String friendshipId) async {
    final currentUser = _requireCurrentUser();

    final reference = _firestore.collection('friendships').doc(friendshipId);

    final snapshot = await reference.get();

    if (!snapshot.exists) {
      return;
    }

    final friendship = Friendship.fromDocument(snapshot);

    if (!friendship.userIds.contains(currentUser.uid)) {
      throw const FriendPermissionException();
    }

    await reference.delete();
  }

  /// 未ログイン状態で友達機能を使用しないようにする。
  User _requireCurrentUser() {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const FriendUnauthenticatedException();
    }

    return user;
  }
}
