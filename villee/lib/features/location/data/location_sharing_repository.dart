import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationSharingUnauthenticatedException
    implements Exception {
  const LocationSharingUnauthenticatedException();
}

/// 共有位置と共有状態のFirestore操作を担当する。
class LocationSharingRepository {
  const LocationSharingRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  }) : _firestore = firestore,
       _firebaseAuth = firebaseAuth;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  /// 位置共有をONにし、最初の位置を保存する。
  Future<void> enableSharing(Position position) async {
    final user = _requireCurrentUser();

    final userReference =
        _firestore.collection('users').doc(user.uid);

    final locationReference =
        _firestore.collection('locations').doc(user.uid);

    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    batch.update(userReference, {
      'sharingEnabled': true,
      'updatedAt': timestamp,
    });

    batch.set(locationReference, {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'updatedAt': timestamp,
    });

    await batch.commit();
  }

  /// 最新位置を上書きする。
  Future<void> updateLocation(Position position) async {
    final user = _requireCurrentUser();

    await _firestore.collection('locations').doc(user.uid).set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 位置共有をOFFにし、保存中の最新位置を削除する。
  Future<void> disableSharing() async {
    final user = _requireCurrentUser();

    final userReference =
        _firestore.collection('users').doc(user.uid);

    final locationReference =
        _firestore.collection('locations').doc(user.uid);

    final batch = _firestore.batch();

    batch.update(userReference, {
      'sharingEnabled': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.delete(locationReference);

    await batch.commit();
  }

  User _requireCurrentUser() {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const LocationSharingUnauthenticatedException();
    }

    return user;
  }
}