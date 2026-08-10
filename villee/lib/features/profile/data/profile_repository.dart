import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/user_profile.dart';

/// 公開IDが既に使われている場合の例外。
class PublicIdAlreadyInUseException implements Exception {
  const PublicIdAlreadyInUseException();
}

/// 既にプロフィールが作成済みの場合の例外。
class ProfileAlreadyExistsException implements Exception {
  const ProfileAlreadyExistsException();
}

/// 未ログイン状態でプロフィール操作を行った場合の例外。
class ProfileUnauthenticatedException implements Exception {
  const ProfileUnauthenticatedException();
}

/// プロフィールに関するFirestoreアクセスを担当する。
///
/// 画面からFirestoreを直接操作せず、このRepositoryを経由する。
class ProfileRepository {
  const ProfileRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  }) : _firestore = firestore,
       _firebaseAuth = firebaseAuth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  /// 現在ログインしているユーザーのプロフィールを監視する。
  ///
  /// プロフィールがまだ作成されていない場合はnullを返す。
  Stream<UserProfile?> watchCurrentProfile() {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      return Stream.value(null);
    }

    return _firestore.collection('users').doc(user.uid).snapshots().map((
      document,
    ) {
      if (!document.exists) {
        return null;
      }

      return UserProfile.fromDocument(document);
    });
  }

  /// 初回プロフィールと公開ID予約情報を同時に作成する。
  ///
  /// usersとpublic_idsの一方だけが作成されることを防ぐため、
  /// Firestore Transactionを使用する。
  Future<void> createProfile({
    required String displayName,
    required String publicId,
    required String profileText,
  }) async {
    final user = _requireCurrentUser();
    final normalizedPublicId = publicId.trim().toLowerCase();

    final userReference = _firestore.collection('users').doc(user.uid);
    final publicIdReference = _firestore
        .collection('public_ids')
        .doc(normalizedPublicId);

    await _firestore.runTransaction((transaction) async {
      // Transactionでは、すべての読み取りを先に実行する。
      final userSnapshot = await transaction.get(userReference);
      final publicIdSnapshot = await transaction.get(publicIdReference);

      if (userSnapshot.exists) {
        throw const ProfileAlreadyExistsException();
      }

      if (publicIdSnapshot.exists) {
        throw const PublicIdAlreadyInUseException();
      }

      // 端末時刻ではなくFirestoreサーバー側の時刻を保存する。
      final serverTimestamp = FieldValue.serverTimestamp();

      transaction.set(userReference, {
        'displayName': displayName.trim(),
        'publicId': normalizedPublicId,
        'profileText': profileText.trim(),
        // 初期状態では位置共有をオフにする。
        'sharingEnabled': false,
        'createdAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      });

      // 公開IDをドキュメントIDにすることで、重複を検出しやすくする。
      transaction.set(publicIdReference, {
        'userId': user.uid,
        'createdAt': serverTimestamp,
      });
    });
  }

  /// 表示名と自己紹介を更新する。
  ///
  /// MVPでは公開IDを変更できないため、更新対象に含めない。
  Future<void> updateProfile({
    required String displayName,
    required String profileText,
  }) async {
    final user = _requireCurrentUser();

    await _firestore.collection('users').doc(user.uid).update({
      'displayName': displayName.trim(),
      'profileText': profileText.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ログイン中のユーザーを取得し、未ログインなら処理を中止する。
  User _requireCurrentUser() {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const ProfileUnauthenticatedException();
    }

    return user;
  }
}
