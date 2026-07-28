# Firestore データ構造

users/{userId}
ユーザーのプロフィール情報を保存
{
    "displayName":"ユーザー名",
    "publicId": "taro_123",
    "profileText": "自己紹介",
    "photoUrl": "https://...",
    "sharingEnabled": true,
    "createdAt": "Timestamp",
    "updatedAt": "Timestamp"
}

public_ids/{publicId}
公開IDの重複を防ぐために使用
{
    "userId": "Firebase Authentication UID"
}

locations/{userId}
ユーザーの最新位置だけを保存
{
    "latitude": 35.6812,
    "longitude": 139.7671,
    "accuracy": 12.5,
    "updatedAt": "Timestamp"
}

friend_requests/{requestId}
友達申請を保存
{
    "senderId": "申請者UID",
    "receiverId": "受信者UID",
    "status": "pending",
    "createdAt": "Timestamp",
    "updatedAt": "Timestamp"
}
statusの候補

- pending
- accepted
- rejected
- cancelled

friendships/{friendshipId}
成立した友達関係を保存
{
    "userIds":[
        "userAのUID"，
        "userBのUID"
    ],
    "createdAt": "Timestamp"
}

