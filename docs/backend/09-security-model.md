# Security Model

## CircleStream — Security Specification

---

## 1. Overview

Security CircleStream dibangun di atas prinsip:
- **Least privilege** — user hanya bisa akses resource yang memang miliknya
- **Defense in depth** — validasi di client DAN server
- **Stateless auth** — JWT, tidak ada session server-side

---

## 2. Authorization Layers

### Layer 1: JWT Authentication
Semua endpoint yang dilindungi memerlukan `Authorization: Bearer {token}` yang valid.

### Layer 2: Circle Membership Check
Setiap request yang berhubungan dengan circle (posts, members, reactions) harus diverifikasi bahwa user adalah member circle tersebut.

```go
func requireCircleMember(c *fiber.Ctx) error {
    userID := c.Locals("user_id").(int64)
    circleID, _ := strconv.ParseInt(c.Params("circle_id"), 10, 64)
    
    var count int
    db.QueryRow(
        "SELECT COUNT(*) FROM circle_members WHERE circle_id = ? AND user_id = ?",
        circleID, userID,
    ).Scan(&count)
    
    if count == 0 {
        return c.Status(403).JSON(fiber.Map{
            "error":   "not_member",
            "message": "You are not a member of this circle",
        })
    }
    
    c.Locals("circle_id", circleID)
    return c.Next()
}
```

### Layer 3: Owner Check
Endpoint tertentu (generate invite, update circle) hanya untuk owner.

```go
func requireCircleOwner(c *fiber.Ctx) error {
    userID := c.Locals("user_id").(int64)
    circleID := c.Locals("circle_id").(int64)
    
    var role string
    db.QueryRow(
        "SELECT role FROM circle_members WHERE circle_id = ? AND user_id = ?",
        circleID, userID,
    ).Scan(&role)
    
    if role != "owner" {
        return c.Status(403).JSON(fiber.Map{
            "error": "owner_required",
        })
    }
    
    return c.Next()
}
```

---

## 3. Input Validation

### File Upload Validation

```go
func validateUploadRequest(req PresignRequest) error {
    // Allowed content types
    allowed := map[string]bool{
        "image/jpeg": true,
        "image/jpg":  true,
        "image/png":  true,
        "image/webp": true,
    }
    
    if !allowed[req.ContentType] {
        return errors.New("unsupported_file_type")
    }
    
    // Max 10MB
    if req.FileSize > 10*1024*1024 {
        return errors.New("file_too_large")
    }
    
    return nil
}
```

### Emoji Validation

```go
var validEmojis = map[string]bool{
    "❤️": true, "😂": true, "😮": true, "🔥": true,
    "👏": true, "😢": true, "🤩": true, "💀": true,
}

func validateEmoji(emoji string) bool {
    return validEmojis[emoji]
}
```

### Object Key Validation (R2)

Pastikan object_key dari finalize request sesuai dengan circle_id user:

```go
func validateObjectKey(objectKey string, circleID int64) bool {
    expected := fmt.Sprintf("circles/%d/posts/", circleID)
    return strings.HasPrefix(objectKey, expected)
}
```

---

## 4. Invite Code Security

```go
func validateInviteCode(code string, userID int64) (*InviteCode, error) {
    var ic InviteCode
    err := db.QueryRow(`
        SELECT ic.*, c.id as circle_id
        FROM invite_codes ic
        JOIN circles c ON c.id = ic.circle_id
        WHERE ic.code = ?
    `, code).Scan(&ic)
    
    if err != nil {
        return nil, errors.New("invite_code_not_found")
    }
    
    // Check active
    if !ic.IsActive {
        return nil, errors.New("invite_code_inactive")
    }
    
    // Check expiry
    if ic.ExpiresAt != nil && time.Now().After(*ic.ExpiresAt) {
        return nil, errors.New("invite_code_expired")
    }
    
    // Check max uses
    if ic.MaxUses != nil && ic.UsedCount >= *ic.MaxUses {
        return nil, errors.New("invite_code_exhausted")
    }
    
    // Check circle capacity
    var memberCount int
    db.QueryRow(
        "SELECT COUNT(*) FROM circle_members WHERE circle_id = ?", ic.CircleID,
    ).Scan(&memberCount)
    
    if memberCount >= 10 {
        return nil, errors.New("circle_full")
    }
    
    // Check already member
    var existing int
    db.QueryRow(
        "SELECT COUNT(*) FROM circle_members WHERE circle_id = ? AND user_id = ?",
        ic.CircleID, userID,
    ).Scan(&existing)
    
    if existing > 0 {
        return nil, errors.New("already_member")
    }
    
    return &ic, nil
}
```

---

## 5. Rate Limiting

Tambahkan rate limiting menggunakan Fiber middleware:

```go
import "github.com/gofiber/fiber/v2/middleware/limiter"

// Global rate limit
app.Use(limiter.New(limiter.Config{
    Max:        100,
    Expiration: 1 * time.Minute,
    KeyGenerator: func(c *fiber.Ctx) string {
        return c.IP()
    },
}))

// Strict limit untuk auth endpoints
authLimiter := limiter.New(limiter.Config{
    Max:        10,
    Expiration: 1 * time.Minute,
    KeyGenerator: func(c *fiber.Ctx) string {
        return c.IP()
    },
})

app.Post("/auth/login", authLimiter, loginHandler)
app.Post("/auth/register", authLimiter, registerHandler)
```

---

## 6. CORS Configuration

```go
import "github.com/gofiber/fiber/v2/middleware/cors"

app.Use(cors.New(cors.Config{
    AllowOrigins: "*", // MVP — restrict di production
    AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
    AllowHeaders: "Origin,Content-Type,Authorization",
}))
```

---

## 7. Security Headers

```go
import "github.com/gofiber/fiber/v2/middleware/helmet"

app.Use(helmet.New())
```

Helmet menambahkan:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`

---

## 8. Environment Variables

```env
# Wajib ada di production
JWT_SECRET=minimum_32_char_random_string
R2_ACCESS_KEY_ID=...
R2_SECRET_ACCESS_KEY=...
UPSTASH_REDIS_PASSWORD=...
ABLY_API_KEY=...
TURSO_DATABASE_URL=...
TURSO_AUTH_TOKEN=...
```

**Rules:**
- Jangan pernah commit `.env` ke git
- Gunakan secret manager di production (Railway, Fly.io secrets)
- Rotate JWT_SECRET jika terjadi breach (akan invalidate semua token)

---

## 9. Threat Model Summary

| Threat | Mitigasi |
|---|---|
| Unauthorized circle access | Circle membership check di setiap endpoint |
| Token theft | Short-lived access token (15 min) |
| Password leak | bcrypt hash, tidak pernah log password |
| R2 unauthorized upload | Object key prefix validation |
| Emoji injection | Whitelist preset validation |
| File size abuse | Server-side file size check sebelum presign |
| Brute force login | Rate limiting pada auth endpoints |
| CSRF | JWT-based auth (tidak pakai cookies) |
| Replay attack on refresh | Token hash stored in DB, deletable on logout |
