import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../friends/domain/friend_item.dart';
import '../domain/friend_map_item.dart';
import '../domain/shared_location.dart';

/// マップ表示に必要なFirestoreデータを取得する。
class MapRepository {
  const MapRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// 各友達のlocations/{uid}をリアルタイム監視する。
  ///
  /// 位置共有OFFの場合はlocationsドキュメントが存在しないため、
  /// そのユーザーは結果から除外する。
  Stream<List<FriendMapItem>> watchFriendLocations(List<FriendItem> friends) {
    if (friends.isEmpty) {
      return Stream.value(const []);
    }

    late final StreamController<List<FriendMapItem>> controller;

    final subscriptions =
        <StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>[];

    final latestItems = <String, FriendMapItem>{};

    void emitItems() {
      final items = latestItems.values.toList()
        ..sort(
          (a, b) => a.profile.displayName.compareTo(b.profile.displayName),
        );

      if (!controller.isClosed) {
        controller.add(items);
      }
    }

    controller = StreamController<List<FriendMapItem>>(
      onListen: () {
        // 最初に空リストを流すことで、
        // 友達の位置取得を待たずマップ自体は表示できる。
        emitItems();

        for (final friend in friends) {
          final userId = friend.profile.id;

          final subscription = _firestore
              .collection('locations')
              .doc(userId)
              .snapshots()
              .listen(
                (document) {
                  if (!document.exists) {
                    latestItems.remove(userId);
                    emitItems();
                    return;
                  }

                  latestItems[userId] = FriendMapItem(
                    profile: friend.profile,
                    location: SharedLocation.fromDocument(document),
                  );

                  emitItems();
                },
                onError: (Object error, StackTrace stackTrace) {
                  if (!controller.isClosed) {
                    controller.addError(error, stackTrace);
                  }
                },
              );

          subscriptions.add(subscription);
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );

    return controller.stream;
  }
}
