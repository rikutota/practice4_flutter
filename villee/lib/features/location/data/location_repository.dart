import 'package:geolocator/geolocator.dart';

import '../domain/location_access_state.dart';

/// 端末の位置情報機能へのアクセスを担当する。
class LocationRepository {
  const LocationRepository();

  /// 現在位置を取得する。
  Future<LocationAccessState> getCurrentLocation({
    bool requestPermission = false,
  }) async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return const LocationAccessState(
        status: LocationAccessStatus.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied &&
        requestPermission) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationAccessState(
        status: LocationAccessStatus.permissionDenied,
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationAccessState(
        status: LocationAccessStatus.permissionDeniedForever,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LocationAccessState(
      status: LocationAccessStatus.ready,
      position: position,
    );
  }

  /// 指定距離以上移動した場合の位置変化を監視する。
  Stream<Position> watchPositionChanges({
    required int distanceFilter,
  }) {
    final settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
    );

    return Geolocator.getPositionStream(
      locationSettings: settings,
    );
  }

  /// 2地点間の距離をメートル単位で求める。
  double distanceBetween(
    Position first,
    Position second,
  ) {
    return Geolocator.distanceBetween(
      first.latitude,
      first.longitude,
      second.latitude,
      second.longitude,
    );
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}