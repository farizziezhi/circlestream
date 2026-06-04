# Authentication

## CircleStream — Auth System Specification

---

## 1. Overview

CircleStream menggunakan **JWT (JSON Web Token)** dengan dua token:
- **Access Token** — short-lived (15 menit), untuk request API
- **Refresh Token** — long-lived (30 hari), untuk mendapat access token baru

---

## 2. Token Specs

### Access Token
```
Algorithm : HS256
Expiry    : 15 menit
Claims    : sub (user_id), username, exp, iat, type: "access"
```

### Refresh Token
```
Algorithm : HS256
Expiry    : 30 hari
Claims    : sub (user_id), exp, iat, type: "refresh", jti (unique ID)
Storage   : Hash-nya disimpan di tabel refresh_tokens di Turso
```

---

## 3. Password Hashing

Gunakan **bcrypt** dengan cost factor 12:

```go
import "golang.org/x/crypto/bcrypt"

func hashPassword(password string) (string, error) {
    bytes, err := bcrypt.GenerateFromPassword([]byte(password), 12)
    return string(bytes), err
}

func checkPassword(password, hash string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    return err == nil
}
```

---

## 4. Registration Flow

```go
func register(c *fiber.Ctx) error {
    var req RegisterRequest
    c.BodyParser(&req)
    
    // 1. Validasi input
    if len(req.Password) < 8 {
        return c.Status(400).JSON(fiber.Map{"error": "password_too_short"})
    }
    
    // 2. Check email dan username unik
    // ...
    
    // 3. Hash password
    hash, _ := hashPassword(req.Password)
    
    // 4. Insert user ke Turso
    result, _ := db.Exec(
        "INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)",
        req.Username, req.Email, hash,
    )
    userID, _ := result.LastInsertId()
    
    // 5. Generate token pair
    tokens, _ := generateTokenPair(userID, req.Username)
    
    // 6. Simpan refresh token hash ke Turso
    saveRefreshToken(userID, tokens.RefreshToken)
    
    return c.Status(201).JSON(fiber.Map{
        "user":   userFromDB,
        "tokens": tokens,
    })
}
```

---

## 5. Login Flow

```go
func login(c *fiber.Ctx) error {
    var req LoginRequest
    c.BodyParser(&req)
    
    // 1. Query user by email
    var user User
    db.QueryRow("SELECT * FROM users WHERE email = ?", req.Email).Scan(&user)
    
    // 2. Verify password
    if !checkPassword(req.Password, user.PasswordHash) {
        return c.Status(401).JSON(fiber.Map{"error": "invalid_credentials"})
    }
    
    // 3. Generate token pair
    tokens, _ := generateTokenPair(user.ID, user.Username)
    
    // 4. Simpan refresh token
    saveRefreshToken(user.ID, tokens.RefreshToken)
    
    return c.JSON(fiber.Map{
        "user":   user,
        "tokens": tokens,
    })
}
```

---

## 6. Token Generation

```go
import "github.com/golang-jwt/jwt/v5"

type TokenPair struct {
    AccessToken  string `json:"access_token"`
    RefreshToken string `json:"refresh_token"`
    ExpiresIn    int    `json:"expires_in"`
}

func generateTokenPair(userID int64, username string) (*TokenPair, error) {
    jwtSecret := os.Getenv("JWT_SECRET")
    
    // Access token
    accessClaims := jwt.MapClaims{
        "sub":      userID,
        "username": username,
        "type":     "access",
        "exp":      time.Now().Add(15 * time.Minute).Unix(),
        "iat":      time.Now().Unix(),
    }
    accessToken, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims).
        SignedString([]byte(jwtSecret))
    
    // Refresh token
    jti := uuid.New().String()
    refreshClaims := jwt.MapClaims{
        "sub":  userID,
        "type": "refresh",
        "jti":  jti,
        "exp":  time.Now().Add(30 * 24 * time.Hour).Unix(),
        "iat":  time.Now().Unix(),
    }
    refreshToken, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims).
        SignedString([]byte(jwtSecret))
    
    return &TokenPair{
        AccessToken:  accessToken,
        RefreshToken: refreshToken,
        ExpiresIn:    900,
    }, nil
}
```

---

## 7. Auth Middleware

```go
func authMiddleware(c *fiber.Ctx) error {
    authHeader := c.Get("Authorization")
    if !strings.HasPrefix(authHeader, "Bearer ") {
        return c.Status(401).JSON(fiber.Map{"error": "missing_token"})
    }
    
    tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
    
    token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (interface{}, error) {
        if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fmt.Errorf("unexpected signing method")
        }
        return []byte(os.Getenv("JWT_SECRET")), nil
    })
    
    if err != nil || !token.Valid {
        return c.Status(401).JSON(fiber.Map{"error": "invalid_token"})
    }
    
    claims := token.Claims.(jwt.MapClaims)
    
    // Pastikan ini access token bukan refresh token
    if claims["type"] != "access" {
        return c.Status(401).JSON(fiber.Map{"error": "invalid_token_type"})
    }
    
    userID := int64(claims["sub"].(float64))
    c.Locals("user_id", userID)
    c.Locals("username", claims["username"].(string))
    
    return c.Next()
}
```

---

## 8. Refresh Token Flow

```go
func refreshToken(c *fiber.Ctx) error {
    var req struct {
        RefreshToken string `json:"refresh_token"`
    }
    c.BodyParser(&req)
    
    // 1. Parse dan validasi refresh token
    token, err := jwt.Parse(req.RefreshToken, keyFunc)
    if err != nil || !token.Valid {
        return c.Status(401).JSON(fiber.Map{"error": "invalid_refresh_token"})
    }
    
    claims := token.Claims.(jwt.MapClaims)
    if claims["type"] != "refresh" {
        return c.Status(401).JSON(fiber.Map{"error": "invalid_token_type"})
    }
    
    // 2. Hash token dan cek di database (anti-replay)
    tokenHash := sha256Hash(req.RefreshToken)
    var storedToken RefreshToken
    err = db.QueryRow(
        "SELECT * FROM refresh_tokens WHERE token_hash = ?", tokenHash,
    ).Scan(&storedToken)
    
    if err != nil {
        return c.Status(401).JSON(fiber.Map{"error": "refresh_token_not_found"})
    }
    
    // 3. Cek expiry
    if time.Now().After(storedToken.ExpiresAt) {
        return c.Status(401).JSON(fiber.Map{"error": "refresh_token_expired"})
    }
    
    // 4. Generate access token baru
    userID := int64(claims["sub"].(float64))
    newAccessToken, _ := generateAccessToken(userID)
    
    return c.JSON(fiber.Map{
        "access_token": newAccessToken,
        "expires_in":   900,
    })
}
```

---

## 9. Logout

```go
func logout(c *fiber.Ctx) error {
    var req struct {
        RefreshToken string `json:"refresh_token"`
    }
    c.BodyParser(&req)
    
    // Hash token dan hapus dari database
    tokenHash := sha256Hash(req.RefreshToken)
    db.Exec("DELETE FROM refresh_tokens WHERE token_hash = ?", tokenHash)
    
    return c.JSON(fiber.Map{"message": "Logged out successfully"})
}
```

---

## 10. Environment Variables

```env
JWT_SECRET=your_very_long_random_secret_minimum_32_chars
```

Generate JWT_SECRET:
```bash
openssl rand -hex 32
```
