import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../location/domain/location_access_state.dart';
import '../../location/presentation/providers/location_providers.dart';
import '../domain/friend_map_item.dart';
import 'providers/map_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  static const double _defaultZoom = 16;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// 現在位置を再取得し、その場所へマップを移動する。
  Future<void> _moveToCurrentLocation() async {
    await ref
        .read(currentLocationControllerProvider.notifier)
        .refreshLocation();

    if (!mounted) {
      return;
    }

    final locationState = ref.read(currentLocationControllerProvider);

    locationState.whenData((location) {
      if (location.status != LocationAccessStatus.ready ||
          location.position == null) {
        return;
      }

      final position = location.position!;

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _defaultZoom,
      );
    });
  }

  /// 友達マーカーを押したときに情報を表示する。
  void _showFriendDetails(FriendMapItem item) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.profile.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('@${item.profile.publicId}'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '最終更新: '
                  '${_formatUpdatedAt(item.location.updatedAt)}',
                ),
                const SizedBox(height: 8),
                Text(
                  '精度: '
                  '${item.location.accuracy.toStringAsFixed(1)} m',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 最終更新日時を「○秒前」「○分前」の形式にする。
  String _formatUpdatedAt(DateTime? updatedAt) {
    if (updatedAt == null) {
      return '不明';
    }

    final difference = DateTime.now().difference(updatedAt);

    if (difference.isNegative) {
      return 'たった今';
    }

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}秒前';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    }

    return '${difference.inDays}日前';
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(currentLocationControllerProvider);

    final friendMapState = ref.watch(friendMapItemsProvider);

    ref.listen(friendMapItemsProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('友達の位置情報を取得できませんでした')));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('マップ')),
      body: locationState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildLocationError(),
        data: (location) {
          switch (location.status) {
            case LocationAccessStatus.ready:
              if (location.position == null) {
                return _buildLocationError();
              }

              final friendItems = friendMapState.when(
                data: (items) => items,
                loading: () => const <FriendMapItem>[],
                error: (error, stackTrace) => const <FriendMapItem>[],
              );

              return _buildMap(
                latitude: location.position!.latitude,
                longitude: location.position!.longitude,
                friendItems: friendItems,
              );

            case LocationAccessStatus.serviceDisabled:
              return _buildServiceDisabled();

            case LocationAccessStatus.permissionDenied:
              return _buildPermissionDenied();

            case LocationAccessStatus.permissionDeniedForever:
              return _buildPermissionDeniedForever();
          }
        },
      ),
      floatingActionButton: locationState.when(
        data: (location) {
          if (location.status != LocationAccessStatus.ready) {
            return null;
          }

          return FloatingActionButton(
            onPressed: _moveToCurrentLocation,
            tooltip: '現在位置へ戻る',
            child: const Icon(Icons.my_location),
          );
        },
        loading: () => null,
        error: (error, stackTrace) => null,
      ),
    );
  }

  Widget _buildMap({
    required double latitude,
    required double longitude,
    required List<FriendMapItem> friendItems,
  }) {
    final currentPosition = LatLng(latitude, longitude);

    final markers = <Marker>[
      Marker(
        point: currentPosition,
        width: 56,
        height: 56,
        child: Icon(
          Icons.my_location,
          size: 36,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),

      ...friendItems.map(
        (item) => Marker(
          point: LatLng(item.location.latitude, item.location.longitude),
          width: 100,
          height: 64,
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {
              _showFriendDetails(item);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Text(
                    item.profile.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: currentPosition,
        initialZoom: _defaultZoom,
        minZoom: 3,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

          // flutter_mapからOpenStreetMapを直接利用する場合は、
          // User-Agent識別子を設定する。
          userAgentPackageName: 'villee',
        ),

        MarkerLayer(markers: markers),

        const SimpleAttributionWidget(
          source: Text('OpenStreetMap contributors'),
        ),
      ],
    );
  }

  Widget _buildLocationError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('位置情報の取得に失敗しました'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref
                  .read(currentLocationControllerProvider.notifier)
                  .refreshLocation();
            },
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDisabled() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('端末の位置情報サービスがオフになっています'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref
                  .read(currentLocationControllerProvider.notifier)
                  .openLocationSettings();
            },
            child: const Text('位置情報設定を開く'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('マップを利用するには位置情報の権限が必要です'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref
                  .read(currentLocationControllerProvider.notifier)
                  .requestPermission();
            },
            child: const Text('位置情報を許可'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedForever() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '位置情報の権限が無効になっています。\n'
            'Androidの設定から許可してください。',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref
                  .read(currentLocationControllerProvider.notifier)
                  .openAppSettings();
            },
            child: const Text('アプリ設定を開く'),
          ),
        ],
      ),
    );
  }
}
