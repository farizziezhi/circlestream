# Database Schema

## CircleStream — Turso / SQLite Schema

---

## 1. Notes

- Database: Turso (libsql, SQLite-compatible)
- All IDs: INTEGER PRIMARY KEY AUTOINCREMENT (atau UUID TEXT tergantung preference)
- Timestamps: TEXT dalam format ISO 8601 (`2026-01-01T12:00:00Z`)
- Passwords: NEVER stored plain text — bcrypt atau argon2id hash
- Foreign key enforcement harus diaktifkan: `PRAGMA foreign_keys = ON;`

---

## 2. Full Schema

```sql
-- ============================================================
-- PRAGMA
-- ============================================================
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- ============================================================
-- USERS
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  username      TEXT    NOT NULL UNIQUE,
  email         TEXT    NOT NULL UNIQUE,
  password_hash TEXT    NOT NULL,
  created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_users_email    ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- ============================================================
-- CIRCLES
-- ============================================================
CREATE TABLE IF NOT EXISTS circles (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT    NOT NULL,
  owner_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_circles_owner ON circles(owner_id);

-- ============================================================
-- CIRCLE_MEMBERS
-- ============================================================
CREATE TABLE IF NOT EXISTS circle_members (
  circle_id INTEGER NOT NULL REFERENCES circles(id) ON DELETE CASCADE,
  user_id   INTEGER NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
  role      TEXT    NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  joined_at TEXT    NOT NULL DEFAULT (datetime('now')),
  PRIMARY KEY (circle_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_circle_members_user   ON circle_members(user_id);
CREATE INDEX IF NOT EXISTS idx_circle_members_circle ON circle_members(circle_id);

-- ============================================================
-- INVITE_CODES
-- ============================================================
CREATE TABLE IF NOT EXISTS invite_codes (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  circle_id  INTEGER NOT NULL REFERENCES circles(id) ON DELETE CASCADE,
  code       TEXT    NOT NULL UNIQUE,
  is_active  INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  expires_at TEXT    NULL,
  max_uses   INTEGER NULL,
  used_count INTEGER NOT NULL DEFAULT 0,
  created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_invite_codes_code      ON invite_codes(code);
CREATE INDEX IF NOT EXISTS idx_invite_codes_circle    ON invite_codes(circle_id);

-- ============================================================
-- POSTS
-- ============================================================
CREATE TABLE IF NOT EXISTS posts (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  circle_id     INTEGER NOT NULL REFERENCES circles(id) ON DELETE CASCADE,
  user_id       INTEGER NOT NULL REFERENCES users(id)   ON DELETE SET NULL,
  image_url     TEXT    NOT NULL,
  thumbnail_url TEXT    NULL,
  created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_posts_circle     ON posts(circle_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_user       ON posts(user_id);

-- ============================================================
-- REACTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS reactions (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  post_id    INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  emoji      TEXT    NOT NULL,
  created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_reactions_post  ON reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_reactions_user  ON reactions(user_id);

-- ============================================================
-- REFRESH_TOKENS
-- ============================================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT    NOT NULL UNIQUE,
  expires_at TEXT    NOT NULL,
  created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user  ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens(token_hash);
```

---

## 3. Table Descriptions

### `users`
Menyimpan semua user terdaftar. Password tidak pernah disimpan plain text.

### `circles`
Menyimpan circle privat. owner_id merujuk ke user yang membuat circle.

### `circle_members`
Pivot table many-to-many antara users dan circles. Role bisa 'owner' atau 'member'.

### `invite_codes`
Menyimpan invite code untuk bergabung ke circle.
- `is_active` = 0 berarti code dinonaktifkan
- `max_uses` = NULL berarti unlimited
- `expires_at` = NULL berarti tidak ada expiry

### `posts`
Menyimpan metadata foto. File fisik ada di R2.
- `image_url` = full URL ke file di R2
- `thumbnail_url` = URL thumbnail (lebih kecil, opsional)

### `reactions`
Backup persistensi reaction. Counter aktif ada di Redis.

### `refresh_tokens`
Menyimpan hash dari refresh token. Token asli tidak disimpan.

---

## 4. Redis Key Patterns (Upstash)

```
reaction:count:{post_id}:{emoji}    → integer counter
reaction:total:{post_id}            → total semua reaction
```

Contoh:
```
reaction:count:42:❤️    → 7
reaction:count:42:🔥    → 3
reaction:total:42       → 10
```

---

## 5. Notes untuk AI Agent

- Selalu gunakan parameterized queries, JANGAN string concatenation
- Selalu validasi user adalah member circle sebelum query circle-scoped
- Gunakan transaction untuk operasi yang melibatkan multiple table
- Increment Redis counter dan insert ke Turso reactions dalam satu request handler
- Pagination menggunakan `WHERE created_at < :cursor ORDER BY created_at DESC LIMIT 20`
