import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/location_sharing_repository.dart';
import '../../domain/location_access_state.dart';
import 'location_providers.dart';

const _locationUploadInterval = Duration(seconds: 30);
const _locationDistanceFilter = 50;

final locationSharingRepositoryProvider = Provider<LocationSharingRepository>((
  ref,
) {
  return LocationSharingRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

final locationSharingControllerProvider =
    AsyncNotifierProvider<LocationSharingController, void>(
      LocationSharingController.new,
    );

/// 位置情報を利用できない状態を表す例外。
class LocationSharingUnavailableException implements Exception {
  const LocationSharingUnavailableException(this.status);

  final LocationAccessStatus status;
}

/// 位置共有ON/OFFと定期更新を管理する。
class LocationSharingController extends AsyncNotifier<void> {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;

  Position? _lastUploadedPosition;
  DateTime? _lastUploadedAt;

  bool _monitoring = false;
  bool _writeInProgress = false;

  @override
  FutureOr<void> build() {
    ref.onDispose(endSession);
  }

  /// 位置共有をONにする。
  Future<bool> enableSharing() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final accessState = await ref
          .read(locationRepositoryProvider)
          .getCurrentLocation(requestPermission: true);

      if (accessState.status != LocationAccessStatus.ready ||
          accessState.position == null) {
        throw LocationSharingUnavailableException(accessState.status);
      }

      final position = accessState.position!;

      await ref.read(locationSharingRepositoryProvider).enableSharing(position);

      _lastUploadedPosition = position;
      _lastUploadedAt = DateTime.now();

      _startMonitoring();
    });

    return !state.hasError;
  }

  /// 位置共有をOFFにする。
  Future<bool> disableSharing() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(locationSharingRepositoryProvider).disableSharing();

      endSession();
    });

    return !state.hasError;
  }

  /// バックグラウンドから復帰したときに監視を再開する。
  Future<void> resumeMonitoring() async {
    if (_monitoring) {
      return;
    }

    final accessState = await ref
        .read(locationRepositoryProvider)
        .getCurrentLocation();

    if (accessState.status != LocationAccessStatus.ready ||
        accessState.position == null) {
      return;
    }

    _startMonitoring();

    // 30秒以上経過していれば復帰時にも更新される。
    await _uploadIfNeeded(accessState.position!);
  }

  /// バックグラウンドへ移動したときは監視だけ止める。
  void pauseMonitoring() {
    _stopMonitoring();
  }

  /// ログアウトや共有OFFでは監視状態も初期化する。
  void endSession() {
    _stopMonitoring();

    _lastUploadedPosition = null;
    _lastUploadedAt = null;
  }

  void _startMonitoring() {
    if (_monitoring) {
      return;
    }

    _monitoring = true;

    // 50m以上移動した場合の更新。
    _positionSubscription = ref
        .read(locationRepositoryProvider)
        .watchPositionChanges(distanceFilter: _locationDistanceFilter)
        .listen(
          (position) {
            unawaited(_uploadIfNeeded(position));
          },
          onError: (Object error) {
            debugPrint('Location stream failed: $error');
          },
        );

    // 移動していなくても30秒ごとに現在位置を確認する。
    _timer = Timer.periodic(_locationUploadInterval, (_) {
      unawaited(_checkTimedUpdate());
    });
  }

  void _stopMonitoring() {
    _monitoring = false;

    _timer?.cancel();
    _timer = null;

    final subscription = _positionSubscription;

    if (subscription != null) {
      unawaited(subscription.cancel());
    }

    _positionSubscription = null;
  }

  /// 30秒経過による位置更新。
  Future<void> _checkTimedUpdate() async {
    if (!_monitoring) {
      return;
    }

    try {
      final accessState = await ref
          .read(locationRepositoryProvider)
          .getCurrentLocation();

      if (accessState.status == LocationAccessStatus.ready &&
          accessState.position != null) {
        await _uploadIfNeeded(accessState.position!);
      }
    } catch (error) {
      debugPrint('Periodic location update failed: $error');
    }
  }

  /// 30秒経過または50m移動した場合だけFirestoreへ保存する。
  Future<void> _uploadIfNeeded(Position position) async {
    if (!_monitoring || _writeInProgress) {
      return;
    }

    final now = DateTime.now();

    final elapsedEnough =
        _lastUploadedAt == null ||
        now.difference(_lastUploadedAt!) >= _locationUploadInterval;

    var movedEnough = _lastUploadedPosition == null;

    if (_lastUploadedPosition != null) {
      final distance = ref
          .read(locationRepositoryProvider)
          .distanceBetween(_lastUploadedPosition!, position);

      movedEnough = distance >= _locationDistanceFilter;
    }

    if (!elapsedEnough && !movedEnough) {
      return;
    }

    _writeInProgress = true;

    try {
      await ref
          .read(locationSharingRepositoryProvider)
          .updateLocation(position);

      _lastUploadedPosition = position;
      _lastUploadedAt = now;
    } catch (error) {
      // 一時的な通信失敗なら次の30秒または移動時に再試行する。
      debugPrint('Location upload failed: $error');
    } finally {
      _writeInProgress = false;
    }
  }
}

String locationSharingErrorMessage(Object error) {
  if (error is LocationSharingUnauthenticatedException) {
    return 'ログイン状態を確認してください';
  }

  if (error is LocationSharingUnavailableException) {
    return switch (error.status) {
      LocationAccessStatus.serviceDisabled => '端末の位置情報を有効にしてください',
      LocationAccessStatus.permissionDenied => '位置情報の権限が必要です',
      LocationAccessStatus.permissionDeniedForever =>
        'Androidの設定から位置情報を許可してください',
      LocationAccessStatus.ready => '位置情報を取得できませんでした',
    };
  }

  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => '位置情報を保存する権限がありません',
      'unavailable' => '通信環境を確認してください',
      _ => '位置共有の変更に失敗しました',
    };
  }

  return '予期しないエラーが発生しました';
}
