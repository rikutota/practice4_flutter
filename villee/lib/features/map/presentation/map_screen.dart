import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../location/domain/location_access_state.dart';
import '../../location/presentation/providers/location_providers.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(currentLocationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('マップ')),
      body: locationState.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (error, stackTrace) => Center(
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
        ),

        data: (location) {
          switch (location.status) {
            case LocationAccessStatus.ready:
              final position = location.position!;

              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, size: 48),
                    const SizedBox(height: 16),
                    Text('緯度: ${position.latitude}'),
                    Text('経度: ${position.longitude}'),
                    Text('精度: ${position.accuracy.toStringAsFixed(1)} m'),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        ref
                            .read(currentLocationControllerProvider.notifier)
                            .refreshLocation();
                      },
                      child: const Text('現在位置を再取得'),
                    ),
                  ],
                ),
              );

            case LocationAccessStatus.serviceDisabled:
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

            case LocationAccessStatus.permissionDenied:
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

            case LocationAccessStatus.permissionDeniedForever:
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
        },
      ),
    );
  }
}
