import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/friend_repository.dart';
import '../../domain/friend_item.dart';
import '../../domain/friend_request.dart';
import '../../domain/friendship.dart';

final friendRepositoryProvider = Provider<FriendRepository>((ref) {
  return FriendRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
    firebaseAuth: ref.watch(firebaseAuthProvider),
  );
});

/// 自分宛ての友達申請。
final incomingFriendRequestsProvider =
    StreamProvider.autoDispose<List<FriendRequest>>((ref) {
      return ref.watch(friendRepositoryProvider).watchIncomingRequests();
    });

/// 自分が送った友達申請。
final outgoingFriendRequestsProvider =
    StreamProvider.autoDispose<List<FriendRequest>>((ref) {
      return ref.watch(friendRepositoryProvider).watchOutgoingRequests();
    });

/// 自分の友達関係。
final friendshipsProvider = StreamProvider.autoDispose<List<Friendship>>((ref) {
  return ref.watch(friendRepositoryProvider).watchFriendships();
});

/// 友達一覧画面で表示するプロフィールを組み立てる。
final friendItemsProvider = FutureProvider.autoDispose<List<FriendItem>>((
  ref,
) async {
  final currentUser = ref.watch(firebaseAuthProvider).currentUser;

  if (currentUser == null) {
    return [];
  }

  final friendships = await ref.watch(friendshipsProvider.future);
  final repository = ref.watch(friendRepositoryProvider);

  return Future.wait(
    friendships.map((friendship) async {
      final otherUserId = friendship.otherUserId(currentUser.uid);

      final profile = await repository.fetchUserProfile(otherUserId);

      return FriendItem(friendship: friendship, profile: profile);
    }),
  );
});

/// 受信申請と申請者プロフィールを組み合わせる。
final incomingRequestItemsProvider =
    FutureProvider.autoDispose<List<FriendRequestItem>>((ref) async {
      final requests = await ref.watch(incomingFriendRequestsProvider.future);

      final repository = ref.watch(friendRepositoryProvider);

      return Future.wait(
        requests.map((request) async {
          final profile = await repository.fetchUserProfile(request.senderId);

          return FriendRequestItem(request: request, profile: profile);
        }),
      );
    });

/// 送信申請と相手プロフィールを組み合わせる。
final outgoingRequestItemsProvider =
    FutureProvider.autoDispose<List<FriendRequestItem>>((ref) async {
      final requests = await ref.watch(outgoingFriendRequestsProvider.future);

      final repository = ref.watch(friendRepositoryProvider);

      return Future.wait(
        requests.map((request) async {
          final profile = await repository.fetchUserProfile(request.receiverId);

          return FriendRequestItem(request: request, profile: profile);
        }),
      );
    });

/// 公開ID検索専用の状態管理。
final friendSearchControllerProvider =
    AsyncNotifierProvider<FriendSearchController, UserProfile?>(
      FriendSearchController.new,
    );

class FriendSearchController extends AsyncNotifier<UserProfile?> {
  @override
  FutureOr<UserProfile?> build() {
    return null;
  }

  /// 公開IDからユーザーを検索する。
  Future<void> search(String publicId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(
      () => ref.read(friendRepositoryProvider).findUserByPublicId(publicId),
    );
  }
}

/// 申請・承認・拒否・解除などの変更処理を管理する。
final friendActionControllerProvider =
    AsyncNotifierProvider<FriendActionController, void>(
      FriendActionController.new,
    );

class FriendActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() async {}

  Future<bool> sendRequest(String receiverId) {
    return _execute(
      () => ref
          .read(friendRepositoryProvider)
          .sendFriendRequest(receiverId: receiverId),
    );
  }

  Future<bool> accept(String requestId) {
    return _execute(
      () => ref.read(friendRepositoryProvider).acceptFriendRequest(requestId),
    );
  }

  Future<bool> reject(String requestId) {
    return _execute(
      () => ref.read(friendRepositoryProvider).rejectFriendRequest(requestId),
    );
  }

  Future<bool> cancel(String requestId) {
    return _execute(
      () => ref.read(friendRepositoryProvider).cancelFriendRequest(requestId),
    );
  }

  Future<bool> removeFriend(String friendshipId) {
    return _execute(
      () => ref.read(friendRepositoryProvider).removeFriend(friendshipId),
    );
  }

  Future<bool> _execute(Future<void> Function() operation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(operation);

    return !state.hasError;
  }
}

/// 友達機能の例外をユーザー向けメッセージへ変換する。
String friendErrorMessage(Object error) {
  if (error is FriendUserNotFoundException) {
    return 'ユーザーが見つかりません';
  }

  if (error is CannotAddSelfException) {
    return '自分自身を友達に追加することはできません';
  }

  if (error is FriendRequestAlreadyExistsException) {
    return '既に友達申請があります';
  }

  if (error is AlreadyFriendsException) {
    return '既に友達です';
  }

  if (error is FriendRequestNotFoundException) {
    return '友達申請が見つかりません';
  }

  if (error is FriendPermissionException) {
    return 'この操作を実行する権限がありません';
  }

  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'この操作を実行する権限がありません',
      'unavailable' => '通信環境を確認してください',
      _ => '友達機能の処理に失敗しました',
    };
  }

  return '予期しないエラーが発生しました';
}
