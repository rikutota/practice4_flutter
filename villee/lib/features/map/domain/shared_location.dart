import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestoreに保存されている最新位置を表す。
class SharedLocation {
  const SharedLocation({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.updatedAt,
  });

  final String userId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime? updatedAt;

  factory SharedLocation.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw StateError('位置情報が存在しません');
    }

    final updatedAt = data['updatedAt'];

    return SharedLocation(
      userId: document.id,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      accuracy: (data['accuracy'] as num).toDouble(),
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
    );
  }
}
