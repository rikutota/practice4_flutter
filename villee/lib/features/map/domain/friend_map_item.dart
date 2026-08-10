import '../../profile/domain/user_profile.dart';
import 'shared_location.dart';

/// マップ上に表示する友達情報。
///
/// プロフィールと最新位置をまとめて画面へ渡す。
class FriendMapItem {
  const FriendMapItem({required this.profile, required this.location});

  final UserProfile profile;
  final SharedLocation location;
}
