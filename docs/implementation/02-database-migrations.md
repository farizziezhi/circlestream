# Database Migrations

## CircleStream — Migration Files & Strategy

---

## 1. Migration Strategy

- Migration dijalankan saat server start (`RunMigrations`)
- Menggunakan tabel `schema_migrations` untuk tracking
- Idempotent: aman dijalankan berkali-kali
- Urutan file: `001_`, `002_`, dst

---

## 2. Migration Runner

```go
// internal/database/migrations/migrate.go

package migrations

import (
    "database/sql"
    "embed"
    "fmt"
    "log"
    "sort"
    "strings"
)

//go:embed *.sql
var migrationFiles embed.FS

func RunMigrations(db *sql.DB) {
    // Create migrations tracking table
    _, err := db.Exec(`
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version TEXT PRIMARY KEY,
            applied_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
    `)
    if err != nil {
        log.Fatalf("Failed to create migrations table: %v", err)
    }

    // Read all .sql files
    entries, _ := migrationFiles.ReadDir(".")
    var files []string
    for _, e := range entries {
        if strings.HasSuffix(e.Name(), ".sql") {
            files = append(files, e.Name())
        }
    }
    sort.Strings(files)

    // Apply each migration if not already applied
    for _, filename := range files {
        version := strings.TrimSuffix(filename, ".sql")

        var count int
        db.QueryRow(
            "SELECT COUNT(*) FROM schema_migrations WHERE version = ?", version,
        ).Scan(&count)

        if count > 0 {
            log.Printf("Migration %s already applied, skipping", version)
            continue
        }

        content, _ := migrationFiles.ReadFile(filename)
        _, err := db.Exec(string(content))
        if err != nil {
            log.Fatalf("Failed to apply migration %s: %v", filename, err)
        }

        db.Exec(
            "INSERT INTO schema_migrations (version) VALUES (?)", version,
        )
        log.Printf("Applied migration: %s", filename)
    }

    log.Println("All migrations applied successfully")
}
```

---

## 3. Migration Files

### `001_initial.sql`

```sql
-- CircleStream Initial Schema
-- Migration: 001_initial

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    username      TEXT    NOT NULL UNIQUE,
    email         TEXT    NOT NULL UNIQUE,
    password_hash TEXT    NOT NULL,
    created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_users_email    ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- Circles table
CREATE TABLE IF NOT EXISTS circles (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    name       TEXT    NOT NULL,
    owner_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_circles_owner ON circles(owner_id);

-- Circle members table
CREATE TABLE IF NOT EXISTS circle_members (
    circle_id INTEGER NOT NULL REFERENCES circles(id) ON DELETE CASCADE,
    user_id   INTEGER NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
    role      TEXT    NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
    joined_at TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (circle_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_circle_members_user   ON circle_members(user_id);
CREATE INDEX IF NOT EXISTS idx_circle_members_circle ON circle_members(circle_id);

-- Invite codes table
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

CREATE INDEX IF NOT EXISTS idx_invite_codes_code   ON invite_codes(code);
CREATE INDEX IF NOT EXISTS idx_invite_codes_circle ON invite_codes(circle_id);

-- Posts table
CREATE TABLE IF NOT EXISTS posts (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    circle_id     INTEGER NOT NULL REFERENCES circles(id) ON DELETE CASCADE,
    user_id       INTEGER NOT NULL REFERENCES users(id)   ON DELETE SET NULL,
    image_url     TEXT    NOT NULL,
    thumbnail_url TEXT    NULL,
    created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_posts_circle ON posts(circle_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_user   ON posts(user_id);

-- Reactions table
CREATE TABLE IF NOT EXISTS reactions (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id    INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emoji      TEXT    NOT NULL,
    created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_reactions_post ON reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_reactions_user ON reactions(user_id);
```

---

### `002_add_refresh_tokens.sql`

```sql
-- Add refresh tokens table
-- Migration: 002_add_refresh_tokens

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

## 4. Turso Client Setup

```go
// internal/database/turso.go

package database

import (
    "database/sql"
    "fmt"

    _ "github.com/tursodatabase/libsql-client-go/libsql"
)

func NewTursoClient(url, token string) (*sql.DB, error) {
    dsn := fmt.Sprintf("%s?authToken=%s", url, token)
    db, err := sql.Open("libsql", dsn)
    if err != nil {
        return nil, fmt.Errorf("failed to open database: %w", err)
    }

    // Connection pool settings
    db.SetMaxOpenConns(10)
    db.SetMaxIdleConns(5)

    // Test connection
    if err := db.Ping(); err != nil {
        return nil, fmt.Errorf("failed to ping database: %w", err)
    }

    // Enable WAL mode and foreign keys
    db.Exec("PRAGMA journal_mode = WAL")
    db.Exec("PRAGMA foreign_keys = ON")

    return db, nil
}
```

---

## 5. go.mod Dependencies

```go
module circlestream

go 1.22

require (
    github.com/gofiber/fiber/v2 v2.52.0
    github.com/golang-jwt/jwt/v5 v5.2.0
    github.com/google/uuid v1.6.0
    github.com/joho/godotenv v1.5.1
    github.com/redis/go-redis/v9 v9.4.0
    github.com/tursodatabase/libsql-client-go v0.0.0-20240220085343-4ae548702a87
    golang.org/x/crypto v0.19.0
    github.com/aws/aws-sdk-go-v2 v1.25.0
    github.com/aws/aws-sdk-go-v2/config v1.27.0
    github.com/aws/aws-sdk-go-v2/service/s3 v1.50.0
    github.com/ably/ably-go v1.2.13
    github.com/gofiber/fiber/v2/middleware/limiter v0.0.0
    github.com/gofiber/fiber/v2/middleware/helmet v0.0.0
    github.com/gofiber/fiber/v2/middleware/cors v0.0.0
)
```

---

## 6. Quick Setup Commands

```bash
# Install Go dependencies
go mod tidy

# Run migrations (via make)
make migrate

# Or run directly
go run cmd/api/main.go  # migrations run on start

# Verify database
# Connect to Turso shell:
turso db shell your-db-name

# Check tables
.tables
```
