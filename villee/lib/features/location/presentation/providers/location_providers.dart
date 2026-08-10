import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/location_repository.dart';
import '../../domain/location_access_state.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return const LocationRepository();
});

final currentLocationControllerProvider =
    AsyncNotifierProvider<CurrentLocationController, LocationAccessState>(
      CurrentLocationController.new,
    );

class CurrentLocationController extends AsyncNotifier<LocationAccessState> {
  @override
  Future<LocationAccessState> build() {
    // 初回は権限ダイアログを出さず、現在の状態だけ確認する。
    return ref.read(locationRepositoryProvider).getCurrentLocation();
  }

  /// ユーザー操作によって位置情報権限を要求する。
  Future<void> requestPermission() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => ref
          .read(locationRepositoryProvider)
          .getCurrentLocation(requestPermission: true),
    );
  }

  /// 現在位置を再取得する。
  Future<void> refreshLocation() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => ref.read(locationRepositoryProvider).getCurrentLocation(),
    );
  }

  /// アプリの権限設定画面を開く。
  Future<void> openAppSettings() async {
    await ref.read(locationRepositoryProvider).openAppSettings();
  }

  /// Androidの位置情報設定画面を開く。
  Future<void> openLocationSettings() async {
    await ref.read(locationRepositoryProvider).openLocationSettings();
  }
}
