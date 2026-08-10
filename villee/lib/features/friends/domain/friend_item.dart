import '../../profile/domain/user_profile.dart';
import 'friend_request.dart';
import 'friendship.dart';

/// 友達一覧画面で使うデータ。
///
/// Friendshipだけでは表示名が分からないため、
/// UserProfileと組み合わせて画面へ渡す。
class FriendItem {
  const FriendItem({required this.friendship, required this.profile});

  final Friendship friendship;
  final UserProfile profile;
}

/// 友達申請一覧画面で使うデータ。
class FriendRequestItem {
  const FriendRequestItem({required this.request, required this.profile});

  final FriendRequest request;
  final UserProfile profile;
}
