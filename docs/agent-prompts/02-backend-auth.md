# CircleStream — Phase 1: Database & Auth

Paste prompt ini setelah prompt 01 selesai dan di-commit.

---

## Prompt

```
Continue building CircleStream backend. The project structure is already set up.

Re-read these documents before starting:
- docs/backend/01-database-schema.md
- docs/backend/08-authentication.md
- docs/backend/09-security-model.md
- docs/implementation/02-database-migrations.md
- docs/implementation/03-api-checklist.md (Phase 1 and Phase 2 sections only)

---

## TASK: Database + Auth Implementation

Implement in this exact order. Commit after each step.

### Step 1 — Database Setup
- Implement internal/database/turso.go (Turso libsql client)
- Implement internal/database/migrations/migrate.go (migration runner)
- Create internal/database/migrations/001_initial.sql (full schema from docs)
- Create internal/database/migrations/002_add_refresh_tokens.sql
- Implement internal/config/config.go (load all env vars)

Commit: chore: setup turso database client and migrations

---

### Step 2 — Models & DTOs
- Implement internal/model/user.go
- Implement internal/dto/auth_dto.go
  - RegisterRequest, LoginRequest, RefreshRequest, LogoutRequest
  - TokenResponse, AuthResponse

Commit: feat: add user model and auth DTOs

---

### Step 3 — Password & JWT Packages
- Implement internal/pkg/password/password.go
  - Hash(password string) (string, error)
  - Compare(password, hash string) bool
  - Use bcrypt, cost factor 12
- Implement internal/pkg/jwt/jwt.go
  - GenerateAccessToken(userID int64, username string) (string, error)
  - GenerateRefreshToken(userID int64) (string, error)
  - ValidateToken(tokenStr string) (*Claims, error)
  - Access token expires 15 minutes, refresh token 30 days

Commit: feat: add password hashing and jwt token packages

---

### Step 4 — User Repository
- Implement internal/repository/user_repository.go
  - Interface + implementation
  - CreateUser()
  - FindByEmail()
  - FindByUsername()
  - FindByID()
- Implement internal/repository/token_repository.go
  - SaveRefreshToken()
  - FindRefreshToken()
  - DeleteRefreshToken()
  - Use SHA-256 hash for storing token, never store raw token

Commit: feat: add user and token repositories

---

### Step 5 — Auth Service
- Implement internal/service/auth_service.go
  - Register() — validate input, check duplicate, hash password, generate tokens
  - Login() — find user, verify password, generate tokens
  - Refresh() — validate refresh token, generate new access token
  - Logout() — delete refresh token from DB

Commit: feat: add auth service with register, login, refresh, logout

---

### Step 6 — Auth Middleware
- Implement internal/middleware/auth.go
  - Parse and validate JWT from Authorization header
  - Set user_id and username to fiber.Ctx locals
  - Return 401 if missing or invalid
- Implement internal/middleware/rate_limit.go
  - Auth endpoints: max 10 requests per minute per IP
  - Global: max 100 requests per minute per IP

Commit: feat: add jwt auth middleware and rate limiter

---

### Step 7 — Auth Handler
- Implement internal/handler/auth_handler.go
  - POST /auth/register → 201
  - POST /auth/login → 200
  - POST /auth/refresh → 200
  - POST /auth/logout → 200 (requires auth middleware)
  - Follow exact request/response format from docs/backend/02-api-specification.md

Commit: feat: add auth handler with all four endpoints

---

### Step 8 — Router (Auth Routes Only)
- Implement internal/router/router.go
  - Register only auth routes for now
  - Apply rate limiter to /auth/login and /auth/register
  - Apply auth middleware to /auth/logout
  - Add GET /health endpoint

Commit: feat: wire auth routes in router

---

### Step 9 — Entry Point
- Implement cmd/api/main.go
  - Load config
  - Connect to Turso
  - Run migrations
  - Setup Fiber app
  - Call router.Setup()
  - Start server

Commit: feat: implement main entry point, server starts successfully

---

## COMMIT RULES
- Commit after every step above, no exceptions
- Use the exact commit messages shown above
- Push after every commit: git push origin main
- Never commit .env

## RULES
- Use parameterized queries always, never string concatenation
- Never log passwords or tokens
- Return consistent error format: { "error": "error_code", "message": "..." }
- All errors must use appropriate HTTP status codes as per docs/backend/02-api-specification.md

When done, confirm all steps completed and list what endpoints are ready to test.
```
