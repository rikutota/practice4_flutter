import 'package:geolocator/geolocator.dart';

import '../domain/location_access_state.dart';

/// geolocatorを利用した位置情報アクセスを担当する。
class LocationRepository {
  const LocationRepository();

  /// 現在の位置情報利用状態を確認する。
  ///
  /// [requestPermission]がtrueの場合、
  /// 未許可ならAndroidの権限ダイアログを表示する。
  Future<LocationAccessState> getCurrentLocation({
    bool requestPermission = false,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return const LocationAccessState(
        status: LocationAccessStatus.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied && requestPermission) {
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

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
    );

    final position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    return LocationAccessState(
      status: LocationAccessStatus.ready,
      position: position,
    );
  }

  /// Villeeのアプリ設定画面を開く。
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Androidの位置情報設定画面を開く。
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
