import 'package:geolocator/geolocator.dart';

/// 位置情報を利用できる状態を表す。
enum LocationAccessStatus {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// 現在の位置情報権限と取得結果をまとめて保持する。
class LocationAccessState {
  const LocationAccessState({required this.status, this.position});

  final LocationAccessStatus status;

  /// statusがreadyの場合に現在位置が入る。
  final Position? position;
}
