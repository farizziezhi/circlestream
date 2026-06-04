# Real-Time Events

## CircleStream — Ably Event Specification

---

## 1. Overview

CircleStream menggunakan **Ably** untuk semua real-time communication. Setiap circle memiliki dedicated Ably channel.

**Channel naming:**
```
circle:{circle_id}
```

Contoh: `circle:1`, `circle:42`

---

## 2. Flutter Client — Subscribe

```dart
// Subscribe ke channel circle
final channel = ably.channels.get('circle:$circleId');

channel.subscribe().listen((message) {
  final data = jsonDecode(message.data as String);
  final type = data['type'];
  
  switch (type) {
    case 'post_created':
      handlePostCreated(data);
      break;
    case 'reaction_added':
      handleReactionAdded(data);
      break;
    case 'member_joined':
      handleMemberJoined(data);
      break;
    case 'member_left':
      handleMemberLeft(data);
      break;
    case 'circle_updated':
      handleCircleUpdated(data);
      break;
  }
});
```

---

## 3. Backend — Publish (Golang)

```go
// Publish event ke channel circle
func publishToCircle(circleID int64, eventType string, payload interface{}) error {
    channel := ablyClient.Channels.Get(fmt.Sprintf("circle:%d", circleID))
    
    data, err := json.Marshal(map[string]interface{}{
        "type": eventType,
        "data": payload,
    })
    if err != nil {
        return err
    }
    
    return channel.Publish(context.Background(), eventType, string(data))
}
```

---

## 4. Ably Token Authentication

Flutter tidak boleh menggunakan Ably API key langsung. Gunakan token authentication.

### Backend — Generate Ably Token

```
GET /ably/token
```

🔒 Requires Auth

**Response:**
```json
{
  "token": "...",
  "expires": 3600
}
```

Backend generate Ably token dengan capability terbatas:
```go
params := &ably.TokenParams{
    Capability: fmt.Sprintf(`{"circle:%d":["subscribe"]}`, circleID),
    TTL:        3600 * 1000, // 1 hour in ms
}
```

Member hanya bisa **subscribe**, tidak bisa publish langsung ke Ably.

---

## 5. Event Definitions

### `post_created`

Dipublish saat: post baru berhasil di-finalize dan disimpan ke Turso.

```json
{
  "type": "post_created",
  "circle_id": 1,
  "post": {
    "id": 42,
    "user_id": 5,
    "username": "johndoe",
    "image_url": "https://cdn.circlestream.app/circles/1/posts/abc123.jpg",
    "thumbnail_url": "https://cdn.circlestream.app/circles/1/posts/thumb_abc123.jpg",
    "reaction_counts": {},
    "created_at": "2026-01-01T12:00:00Z"
  }
}
```

**Flutter handler:**
- Tambah post baru ke bagian atas feed list
- Trigger animasi "new photo" jika post dari orang lain
- Scroll to top jika user sedang di atas

---

### `reaction_added`

Dipublish saat: user menambah reaction ke sebuah post.

```json
{
  "type": "reaction_added",
  "post_id": 42,
  "emoji": "❤️",
  "count": 12,
  "user_id": 7
}
```

**Flutter handler:**
- Update reaction count di post card
- Trigger floating emoji animation dari bottom post card
- Animasi muncul di semua device yang melihat post tersebut

---

### `member_joined`

Dipublish saat: user berhasil join circle.

```json
{
  "type": "member_joined",
  "circle_id": 1,
  "user": {
    "id": 9,
    "username": "newmember"
  },
  "member_count": 6
}
```

**Flutter handler:**
- Update member count di circle header
- Tampilkan toast/snackbar "newmember joined"

---

### `member_left`

Dipublish saat: user leave circle.

```json
{
  "type": "member_left",
  "circle_id": 1,
  "user": {
    "id": 9,
    "username": "newmember"
  },
  "member_count": 5
}
```

**Flutter handler:**
- Update member count di circle header
- Tampilkan toast/snackbar "newmember left"

---

### `circle_updated`

Dipublish saat: nama circle berubah atau setting lain diupdate.

```json
{
  "type": "circle_updated",
  "circle_id": 1,
  "changes": {
    "name": "New Circle Name"
  }
}
```

**Flutter handler:**
- Refresh circle detail dari API
- Update nama di UI

---

## 6. Reconnection Strategy (Flutter)

Ably SDK menangani reconnection otomatis. Tambahkan handler untuk:

```dart
ably.connection.on().listen((stateChange) {
  if (stateChange.current == ably.ConnectionState.connected) {
    // Fetch latest posts yang mungkin missed
    feedBloc.add(RefreshFeedEvent(circleId));
  }
  
  if (stateChange.current == ably.ConnectionState.disconnected) {
    // Tampilkan "offline" indicator
    showOfflineIndicator();
  }
});
```

Ketika reconnect, Flutter harus:
1. Fetch feed terbaru dari REST API (bukan hanya rely pada Ably)
2. Sync reaction counts dari REST API
3. Lanjutkan subscribe ke channel

---

## 7. Channel Lifecycle

- Subscribe saat masuk ke feed screen circle
- Unsubscribe saat keluar dari feed screen atau leave circle
- Token refresh sebelum token Ably expired (setiap ~50 menit)
