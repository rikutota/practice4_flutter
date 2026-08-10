import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../friends/presentation/providers/friend_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/map_repository.dart';
import '../../domain/friend_map_item.dart';

final mapRepositoryProvider = Provider<MapRepository>((ref) {
  return MapRepository(ref.watch(firebaseFirestoreProvider));
});

/// 現在の友達一覧を取得し、各友達の最新位置を監視する。
final friendMapItemsProvider = StreamProvider.autoDispose<List<FriendMapItem>>((
  ref,
) async* {
  final friends = await ref.watch(friendItemsProvider.future);

  final repository = ref.watch(mapRepositoryProvider);

  yield* repository.watchFriendLocations(friends);
});
