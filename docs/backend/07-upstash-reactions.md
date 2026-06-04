# Upstash Redis — Reaction Counters

## CircleStream — Fast Reaction Counter System

---

## 1. Overview

Reaction counter menggunakan **Upstash Redis** untuk:
- Atomic counter increment (tanpa race condition)
- Sub-millisecond read latency
- Tidak membebani Turso dengan high-frequency writes

Turso tetap menyimpan tabel `reactions` sebagai persistent backup.

---

## 2. Key Schema

```
reaction:count:{post_id}:{emoji}   → integer
```

**Contoh:**
```
reaction:count:42:❤️   → 7
reaction:count:42:😂   → 2
reaction:count:42:🔥   → 4
```

---

## 3. Golang — Redis Client Setup

```go
import "github.com/redis/go-redis/v9"

func NewRedisClient() *redis.Client {
    return redis.NewClient(&redis.Options{
        Addr:     os.Getenv("UPSTASH_REDIS_ADDR"),
        Password: os.Getenv("UPSTASH_REDIS_PASSWORD"),
        TLS:      &tls.Config{},
    })
}
```

**Environment Variables:**
```env
UPSTASH_REDIS_ADDR=your-endpoint.upstash.io:6379
UPSTASH_REDIS_PASSWORD=your_password
```

---

## 4. Add Reaction Handler

```go
func addReaction(c *fiber.Ctx) error {
    userID := c.Locals("user_id").(int64)
    postID, _ := strconv.ParseInt(c.Params("post_id"), 10, 64)
    
    var req struct {
        Emoji string `json:"emoji"`
    }
    c.BodyParser(&req)
    
    // 1. Validasi emoji dari preset
    if !isValidEmoji(req.Emoji) {
        return c.Status(400).JSON(fiber.Map{
            "error": "invalid_emoji",
        })
    }
    
    // 2. Validasi user adalah member circle dari post ini
    if !isMemberOfPostCircle(userID, postID) {
        return c.Status(403).JSON(fiber.Map{
            "error": "not_member",
        })
    }
    
    ctx := context.Background()
    redisKey := fmt.Sprintf("reaction:count:%d:%s", postID, req.Emoji)
    
    // 3. Increment counter di Redis (atomic)
    newCount, err := redisClient.Incr(ctx, redisKey).Result()
    if err != nil {
        return c.Status(500).JSON(fiber.Map{"error": "redis_error"})
    }
    
    // 4. Simpan ke Turso (async, non-blocking)
    go func() {
        db.Exec(
            "INSERT INTO reactions (post_id, user_id, emoji, created_at) VALUES (?, ?, ?, ?)",
            postID, userID, req.Emoji, time.Now().UTC(),
        )
    }()
    
    // 5. Publish ke Ably
    publishToCircle(getCircleIDFromPost(postID), "reaction_added", map[string]interface{}{
        "post_id": postID,
        "emoji":   req.Emoji,
        "count":   newCount,
        "user_id": userID,
    })
    
    return c.JSON(fiber.Map{
        "post_id": postID,
        "emoji":   req.Emoji,
        "count":   newCount,
    })
}
```

---

## 5. Get Reaction Counts

```go
func getReactions(c *fiber.Ctx) error {
    postID, _ := strconv.ParseInt(c.Params("post_id"), 10, 64)
    
    presets := []string{"❤️", "😂", "😮", "🔥", "👏", "😢", "🤩", "💀"}
    ctx := context.Background()
    
    // Pipeline semua GET sekaligus (lebih efisien)
    pipe := redisClient.Pipeline()
    cmds := make([]*redis.IntCmd, len(presets))
    
    for i, emoji := range presets {
        key := fmt.Sprintf("reaction:count:%d:%s", postID, emoji)
        cmds[i] = pipe.Get(ctx, key)
    }
    
    pipe.Exec(ctx)
    
    counts := make(map[string]int64)
    total := int64(0)
    
    for i, emoji := range presets {
        count, err := cmds[i].Int64()
        if err == nil && count > 0 {
            counts[emoji] = count
            total += count
        }
    }
    
    return c.JSON(fiber.Map{
        "post_id":   postID,
        "reactions": counts,
        "total":     total,
    })
}
```

---

## 6. Feed Response — Include Reaction Counts

Saat load feed, backend harus include reaction counts dari Redis:

```go
func enrichPostsWithReactions(posts []Post) []PostWithReactions {
    presets := []string{"❤️", "😂", "😮", "🔥", "👏", "😢", "🤩", "💀"}
    ctx := context.Background()
    
    // Batch pipeline untuk semua post sekaligus
    pipe := redisClient.Pipeline()
    
    for _, post := range posts {
        for _, emoji := range presets {
            key := fmt.Sprintf("reaction:count:%d:%s", post.ID, emoji)
            pipe.Get(ctx, key)
        }
    }
    
    results, _ := pipe.Exec(ctx)
    // ... parse results dan assign ke masing-masing post
}
```

---

## 7. Emoji Preset Validation

```go
var validEmojis = map[string]bool{
    "❤️":  true,
    "😂":  true,
    "😮":  true,
    "🔥":  true,
    "👏":  true,
    "😢":  true,
    "🤩":  true,
    "💀":  true,
}

func isValidEmoji(emoji string) bool {
    return validEmojis[emoji]
}
```

---

## 8. Key Expiry Strategy

Reaction counters tidak di-expire (persist selamanya) karena merupakan data permanen.

Jika post dihapus (future feature), hapus Redis keys:
```go
func deletePostReactions(postID int64) {
    presets := []string{"❤️", "😂", "😮", "🔥", "👏", "😢", "🤩", "💀"}
    keys := make([]string, len(presets))
    for i, emoji := range presets {
        keys[i] = fmt.Sprintf("reaction:count:%d:%s", postID, emoji)
    }
    redisClient.Del(context.Background(), keys...)
}
```
