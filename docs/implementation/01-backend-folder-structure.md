# Backend Folder Structure

## CircleStream — Golang Fiber Project Layout

---

## 1. Full Directory Structure

```
circlestream-backend/
├── cmd/
│   └── api/
│       └── main.go                    ← Entry point
│
├── internal/
│   ├── config/
│   │   └── config.go                  ← Load env vars, app config struct
│   │
│   ├── database/
│   │   ├── turso.go                   ← Turso/libsql client setup
│   │   └── migrations/
│   │       ├── 001_initial.sql
│   │       ├── 002_add_refresh_tokens.sql
│   │       └── migrate.go
│   │
│   ├── middleware/
│   │   ├── auth.go                    ← JWT validation middleware
│   │   ├── circle_member.go           ← Circle membership check
│   │   ├── circle_owner.go            ← Circle owner check
│   │   ├── rate_limit.go              ← Rate limiter
│   │   └── logger.go                  ← Request logger
│   │
│   ├── handler/
│   │   ├── auth_handler.go            ← /auth/* endpoints
│   │   ├── circle_handler.go          ← /circles/* endpoints
│   │   ├── media_handler.go           ← /media/* endpoints
│   │   ├── post_handler.go            ← /posts/* endpoints
│   │   ├── reaction_handler.go        ← /posts/:id/reactions
│   │   └── ably_handler.go            ← /ably/token
│   │
│   ├── service/
│   │   ├── auth_service.go            ← Business logic: auth
│   │   ├── circle_service.go          ← Business logic: circle
│   │   ├── media_service.go           ← Business logic: upload/finalize
│   │   ├── post_service.go            ← Business logic: feed
│   │   └── reaction_service.go        ← Business logic: reaction
│   │
│   ├── repository/
│   │   ├── user_repository.go         ← DB queries: users
│   │   ├── circle_repository.go       ← DB queries: circles + members
│   │   ├── post_repository.go         ← DB queries: posts
│   │   ├── reaction_repository.go     ← DB queries: reactions
│   │   └── invite_repository.go       ← DB queries: invite codes
│   │
│   ├── model/
│   │   ├── user.go
│   │   ├── circle.go
│   │   ├── post.go
│   │   ├── reaction.go
│   │   └── invite_code.go
│   │
│   ├── dto/
│   │   ├── auth_dto.go                ← Request/Response structs auth
│   │   ├── circle_dto.go
│   │   ├── post_dto.go
│   │   └── reaction_dto.go
│   │
│   ├── pkg/
│   │   ├── jwt/
│   │   │   └── jwt.go                 ← Token generate & validate
│   │   ├── password/
│   │   │   └── password.go            ← bcrypt hash & compare
│   │   ├── r2/
│   │   │   └── r2_client.go           ← Cloudflare R2 S3 client
│   │   ├── redis/
│   │   │   └── redis_client.go        ← Upstash Redis client
│   │   └── ably/
│   │       └── ably_client.go         ← Ably publish + token gen
│   │
│   └── router/
│       └── router.go                  ← Fiber route registration
│
├── .env
├── .env.example
├── .gitignore
├── Dockerfile
├── go.mod
├── go.sum
└── Makefile
```

---

## 2. Key File Details

### `cmd/api/main.go`

```go
package main

import (
    "log"
    "os"

    "github.com/gofiber/fiber/v2"
    "github.com/joho/godotenv"
    "circlestream/internal/config"
    "circlestream/internal/database"
    "circlestream/internal/router"
)

func main() {
    // Load .env
    if err := godotenv.Load(); err != nil {
        log.Println("No .env file found, using environment variables")
    }

    // Load config
    cfg := config.Load()

    // Init database
    db, err := database.NewTursoClient(cfg.TursoURL, cfg.TursoToken)
    if err != nil {
        log.Fatalf("Failed to connect to database: %v", err)
    }

    // Run migrations
    database.RunMigrations(db)

    // Init Fiber
    app := fiber.New(fiber.Config{
        AppName:      "CircleStream API v1",
        ErrorHandler: customErrorHandler,
    })

    // Setup routes
    router.Setup(app, db, cfg)

    // Start server
    port := cfg.Port
    if port == "" {
        port = "8080"
    }

    log.Printf("CircleStream API starting on :%s", port)
    log.Fatal(app.Listen(":" + port))
}

func customErrorHandler(c *fiber.Ctx, err error) error {
    code := fiber.StatusInternalServerError
    if e, ok := err.(*fiber.Error); ok {
        code = e.Code
    }
    return c.Status(code).JSON(fiber.Map{
        "error":   "internal_error",
        "message": err.Error(),
    })
}
```

---

### `internal/config/config.go`

```go
package config

import "os"

type Config struct {
    Port             string
    TursoURL         string
    TursoToken       string
    JWTSecret        string
    R2AccountID      string
    R2AccessKey      string
    R2SecretKey      string
    R2BucketName     string
    R2PublicURL      string
    RedisAddr        string
    RedisPassword    string
    AblyAPIKey       string
}

func Load() *Config {
    return &Config{
        Port:          getEnv("PORT", "8080"),
        TursoURL:      mustGetEnv("TURSO_DATABASE_URL"),
        TursoToken:    mustGetEnv("TURSO_AUTH_TOKEN"),
        JWTSecret:     mustGetEnv("JWT_SECRET"),
        R2AccountID:   mustGetEnv("R2_ACCOUNT_ID"),
        R2AccessKey:   mustGetEnv("R2_ACCESS_KEY_ID"),
        R2SecretKey:   mustGetEnv("R2_SECRET_ACCESS_KEY"),
        R2BucketName:  getEnv("R2_BUCKET_NAME", "circlestream-media"),
        R2PublicURL:   mustGetEnv("R2_PUBLIC_URL"),
        RedisAddr:     mustGetEnv("UPSTASH_REDIS_ADDR"),
        RedisPassword: mustGetEnv("UPSTASH_REDIS_PASSWORD"),
        AblyAPIKey:    mustGetEnv("ABLY_API_KEY"),
    }
}

func getEnv(key, fallback string) string {
    if v := os.Getenv(key); v != "" {
        return v
    }
    return fallback
}

func mustGetEnv(key string) string {
    v := os.Getenv(key)
    if v == "" {
        panic("Required environment variable not set: " + key)
    }
    return v
}
```

---

### `internal/router/router.go`

```go
package router

import (
    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/cors"
    "github.com/gofiber/fiber/v2/middleware/helmet"
    "github.com/gofiber/fiber/v2/middleware/recover"
    "circlestream/internal/config"
    "circlestream/internal/handler"
    "circlestream/internal/middleware"
    "database/sql"
)

func Setup(app *fiber.App, db *sql.DB, cfg *config.Config) {
    // Global middleware
    app.Use(recover.New())
    app.Use(helmet.New())
    app.Use(cors.New())

    // Init dependencies
    // (repositories, services, handlers — dependency injection manual)
    userRepo    := repository.NewUserRepository(db)
    circleRepo  := repository.NewCircleRepository(db)
    postRepo    := repository.NewPostRepository(db)
    reactionRepo := repository.NewReactionRepository(db)
    inviteRepo  := repository.NewInviteRepository(db)

    r2Client    := r2.NewClient(cfg)
    redisClient := redis.NewClient(cfg)
    ablyClient  := ably.NewClient(cfg)

    authSvc     := service.NewAuthService(userRepo, cfg)
    circleSvc   := service.NewCircleService(circleRepo, inviteRepo, ablyClient)
    mediaSvc    := service.NewMediaService(r2Client, postRepo, ablyClient, cfg)
    postSvc     := service.NewPostService(postRepo, redisClient)
    reactionSvc := service.NewReactionService(reactionRepo, redisClient, ablyClient)

    authHandler     := handler.NewAuthHandler(authSvc)
    circleHandler   := handler.NewCircleHandler(circleSvc)
    mediaHandler    := handler.NewMediaHandler(mediaSvc)
    postHandler     := handler.NewPostHandler(postSvc)
    reactionHandler := handler.NewReactionHandler(reactionSvc)
    ablyHandler     := handler.NewAblyHandler(ablyClient, circleRepo, cfg)

    api := app.Group("/v1")

    // Auth routes (no auth middleware)
    authLimiter := middleware.AuthRateLimiter()
    auth := api.Group("/auth")
    auth.Post("/register", authLimiter, authHandler.Register)
    auth.Post("/login",    authLimiter, authHandler.Login)
    auth.Post("/refresh",  authHandler.Refresh)
    auth.Post("/logout",   middleware.Auth(cfg), authHandler.Logout)

    // Protected routes
    protected := api.Group("", middleware.Auth(cfg))

    // Ably token
    protected.Get("/ably/token", ablyHandler.GetToken)

    // Circle routes
    protected.Post("/circles",      circleHandler.Create)
    protected.Post("/circles/join", circleHandler.Join)

    circleScoped := protected.Group("/circles/:circle_id",
        middleware.RequireCircleMember(circleRepo))
    circleScoped.Get("/",         circleHandler.Detail)
    circleScoped.Get("/members",  circleHandler.Members)
    circleScoped.Post("/leave",   circleHandler.Leave)
    circleScoped.Get("/posts",    postHandler.List)

    // Owner only
    ownerScoped := circleScoped.Group("", middleware.RequireCircleOwner(circleRepo))
    ownerScoped.Get("/invite-codes",  circleHandler.ListInviteCodes)
    ownerScoped.Post("/invite-codes", circleHandler.CreateInviteCode)

    // Media
    protected.Post("/media/presign-upload", mediaHandler.PresignUpload)
    protected.Post("/media/finalize",       mediaHandler.Finalize)

    // Posts
    protected.Get("/posts/:post_id",  postHandler.Detail)

    // Reactions
    protected.Post("/posts/:post_id/reactions", reactionHandler.Add)
    protected.Get("/posts/:post_id/reactions",  reactionHandler.List)

    // Health check
    app.Get("/health", func(c *fiber.Ctx) error {
        return c.JSON(fiber.Map{"status": "ok"})
    })
}
```

---

### `internal/model/post.go`

```go
package model

import "time"

type Post struct {
    ID           int64      `json:"id" db:"id"`
    CircleID     int64      `json:"circle_id" db:"circle_id"`
    UserID       int64      `json:"user_id" db:"user_id"`
    ImageURL     string     `json:"image_url" db:"image_url"`
    ThumbnailURL *string    `json:"thumbnail_url" db:"thumbnail_url"`
    CreatedAt    time.Time  `json:"created_at" db:"created_at"`
}

type PostWithUser struct {
    Post
    Username string `json:"username" db:"username"`
}
```

---

### `.env.example`

```env
PORT=8080

# Turso
TURSO_DATABASE_URL=libsql://your-db.turso.io
TURSO_AUTH_TOKEN=your_turso_token

# JWT
JWT_SECRET=your_minimum_32_char_random_secret

# Cloudflare R2
R2_ACCOUNT_ID=your_account_id
R2_ACCESS_KEY_ID=your_access_key
R2_SECRET_ACCESS_KEY=your_secret_key
R2_BUCKET_NAME=circlestream-media
R2_PUBLIC_URL=https://cdn.circlestream.app

# Upstash Redis
UPSTASH_REDIS_ADDR=your-endpoint.upstash.io:6379
UPSTASH_REDIS_PASSWORD=your_redis_password

# Ably
ABLY_API_KEY=your_ably_api_key
```

---

### `Makefile`

```makefile
.PHONY: run build test migrate lint

run:
	go run cmd/api/main.go

build:
	go build -o bin/circlestream cmd/api/main.go

test:
	go test ./... -v -cover

migrate:
	go run internal/database/migrations/migrate.go

lint:
	golangci-lint run

docker-build:
	docker build -t circlestream-api .

docker-run:
	docker run -p 8080:8080 --env-file .env circlestream-api
```

---

## 3. Naming Conventions

| Type | Convention | Example |
|---|---|---|
| Files | snake_case | `auth_handler.go` |
| Packages | lowercase | `handler`, `service` |
| Structs | PascalCase | `AuthService` |
| Interfaces | PascalCase | `UserRepository` |
| Functions | PascalCase (exported) | `NewAuthService` |
| Variables | camelCase | `userRepo` |
| Constants | PascalCase | `MaxCircleMembers` |
| DB columns | snake_case | `created_at` |
| JSON keys | snake_case | `circle_id` |
