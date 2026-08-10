import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountUnauthenticatedException implements Exception {
  const AccountUnauthenticatedException();
}

class AccountEmailUnavailableException implements Exception {
  const AccountEmailUnavailableException();
}

/// アカウント削除に必要なFirebase操作を担当する。
class AccountRepository {
  const AccountRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  }) : _firestore = firestore,
       _firebaseAuth = firebaseAuth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  /// パスワードで再認証した後、関連データとAuthユーザーを削除する。
  Future<void> deleteAccount({required String password}) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AccountUnauthenticatedException();
    }

    final email = user.email;

    if (email == null || email.isEmpty) {
      throw const AccountEmailUnavailableException();
    }

    // アカウント削除は重要操作なので、最初に再認証する。
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);

    final userId = user.uid;

    final userReference = _firestore.collection('users').doc(userId);

    final userSnapshot = await userReference.get();

    final publicId = userSnapshot.data()?['publicId'] as String?;

    final incomingRequests = await _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: userId)
        .get();

    final outgoingRequests = await _firestore
        .collection('friend_requests')
        .where('senderId', isEqualTo: userId)
        .get();

    final friendships = await _firestore
        .collection('friendships')
        .where('userIds', arrayContains: userId)
        .get();

    final references = <String, DocumentReference<Map<String, dynamic>>>{};

    void addReference(DocumentReference<Map<String, dynamic>> reference) {
      // 同じfriend_requestが重複した場合も1回だけ削除する。
      references[reference.path] = reference;
    }

    for (final document in incomingRequests.docs) {
      addReference(document.reference);
    }

    for (final document in outgoingRequests.docs) {
      addReference(document.reference);
    }

    for (final document in friendships.docs) {
      addReference(document.reference);
    }

    addReference(_firestore.collection('locations').doc(userId));

    if (publicId != null && publicId.isNotEmpty) {
      final publicIdReference = _firestore
          .collection('public_ids')
          .doc(publicId);

      final publicIdSnapshot = await publicIdReference.get();

      if (publicIdSnapshot.exists) {
        addReference(publicIdReference);
      }
    }

    if (userSnapshot.exists) {
      addReference(userReference);
    }

    await _deleteReferences(references.values.toList());

    // Firestoreデータを削除した後、
    // Firebase Authenticationのユーザーを削除する。
    await user.delete();
  }

  /// FirestoreのWriteBatch上限を超えないよう分割して削除する。
  Future<void> _deleteReferences(
    List<DocumentReference<Map<String, dynamic>>> references,
  ) async {
    const batchSize = 400;

    for (var start = 0; start < references.length; start += batchSize) {
      final end = (start + batchSize < references.length)
          ? start + batchSize
          : references.length;

      final batch = _firestore.batch();

      for (final reference in references.sublist(start, end)) {
        batch.delete(reference);
      }

      await batch.commit();
    }
  }
}
