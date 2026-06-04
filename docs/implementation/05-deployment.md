# Deployment Guide

## CircleStream — Backend & Infrastructure Deployment

---

## 1. Overview

| Service | Platform | Method |
|---|---|---|
| Backend API | Railway | Docker container |
| Database | Turso Cloud | Managed |
| Storage | Cloudflare R2 | Managed |
| Real-time | Ably Cloud | Managed |
| Cache | Upstash Redis | Managed |
| Flutter App | App Store / Play Store | Manual release |

---

## 2. Backend — Dockerfile

```dockerfile
# Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o circlestream-api ./cmd/api/main.go

# Run stage
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app
COPY --from=builder /app/circlestream-api .

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["./circlestream-api"]
```

---

## 3. Railway Deployment

### Setup Railway

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Init project (dari root backend)
railway init

# Link ke project
railway link
```

### Set Environment Variables di Railway

Di Railway dashboard → Settings → Variables, tambahkan:

```
PORT=8080
TURSO_DATABASE_URL=libsql://your-db.turso.io
TURSO_AUTH_TOKEN=eyJ...
JWT_SECRET=your_32_char_secret
R2_ACCOUNT_ID=abc123
R2_ACCESS_KEY_ID=key123
R2_SECRET_ACCESS_KEY=secret123
R2_BUCKET_NAME=circlestream-media
R2_PUBLIC_URL=https://cdn.circlestream.app
UPSTASH_REDIS_ADDR=your-redis.upstash.io:6379
UPSTASH_REDIS_PASSWORD=your_password
ABLY_API_KEY=your_ably_key
```

### Deploy

```bash
# Deploy dari CLI
railway up

# Atau setup GitHub integration untuk auto-deploy
# Railway dashboard → Settings → Deployments → Connect GitHub
```

---

## 4. Turso Setup

```bash
# Install Turso CLI
curl -sSfL https://get.tur.so/install.sh | bash

# Login
turso auth login

# Create database
turso db create circlestream-prod

# Get database URL
turso db show circlestream-prod --url

# Create auth token
turso db tokens create circlestream-prod

# Shell access (untuk debug)
turso db shell circlestream-prod
```

Salin URL dan token ke Railway environment variables.

---

## 5. Cloudflare R2 Setup

### Buat Bucket

1. Login ke [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Pilih **R2 Object Storage**
3. Klik **Create Bucket**
4. Nama: `circlestream-media`
5. Region: Auto

### Buat API Token

1. R2 → **Manage R2 API Tokens**
2. **Create API Token**
3. Permissions: Object Read & Write
4. Salin `Access Key ID` dan `Secret Access Key`

### Setup Custom Domain (CDN)

1. R2 bucket → **Settings** → **Custom Domains**
2. Tambahkan: `cdn.circlestream.app`
3. Set DNS CNAME di Cloudflare DNS

### CORS Configuration

Di R2 bucket settings → CORS:

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "PUT"],
    "AllowedHeaders": ["*"],
    "MaxAgeSeconds": 3600
  }
]
```

---

## 6. Upstash Redis Setup

1. Login ke [Upstash Console](https://console.upstash.com)
2. **Create Database**
3. Type: Redis
4. Region: pilih yang paling dekat dengan Railway deployment
5. Salin `UPSTASH_REDIS_ADDR` dan `UPSTASH_REDIS_PASSWORD`

---

## 7. Ably Setup

1. Login ke [Ably Dashboard](https://ably.com/dashboard)
2. **Create App** → nama: CircleStream
3. Salin **API Key** dari app settings
4. Format: `xxxxx:yyyyyy`

---

## 8. Flutter App Deployment

### Android — Google Play

```bash
# Generate keystore (sekali saja)
keytool -genkey -v -keystore circlestream.keystore \
  -alias circlestream -keyalg RSA -keysize 2048 -validity 10000

# Build release APK
flutter build apk --release

# Build release App Bundle (untuk Play Store)
flutter build appbundle --release
```

`android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=circlestream
storeFile=../circlestream.keystore
```

### iOS — App Store

```bash
# Build iOS release
flutter build ios --release

# Buka Xcode untuk signing dan upload
open ios/Runner.xcworkspace
```

### Environment Variables Flutter (Build Time)

```bash
# Build dengan env vars
flutter build apk \
  --dart-define=API_BASE_URL=https://api.circlestream.app/v1
```

---

## 9. Post-Deployment Checklist

### Backend
- [ ] Health check endpoint response OK: `GET /health`
- [ ] Register endpoint berjalan
- [ ] Login endpoint berjalan
- [ ] Database terhubung (cek migrations)
- [ ] Redis terhubung (cek dengan add reaction)
- [ ] R2 terhubung (cek dengan presign upload)
- [ ] Ably terhubung (cek publish event)

### Security
- [ ] HTTPS berjalan (Railway otomatis)
- [ ] `.env` tidak ter-commit di git
- [ ] JWT secret sudah di-set
- [ ] Rate limiting aktif

### Performance
- [ ] Response time < 200ms untuk health check
- [ ] Feed load < 2 detik

---

## 10. Monitoring

### Railway Metrics
- CPU, Memory, Network tersedia di Railway dashboard
- Setup alerts untuk high CPU/memory

### Logging

```go
// Semua request di-log oleh Fiber logger middleware
app.Use(logger.New(logger.Config{
    Format: "[${time}] ${status} - ${method} ${path} (${latency})\n",
}))
```

### Health Check Endpoint

```go
app.Get("/health", func(c *fiber.Ctx) error {
    // Cek DB connection
    if err := db.Ping(); err != nil {
        return c.Status(503).JSON(fiber.Map{
            "status": "unhealthy",
            "db":     "disconnected",
        })
    }
    return c.JSON(fiber.Map{
        "status":  "ok",
        "version": "1.0.0",
    })
})
```

---

## 11. Rollback Strategy

Railway menyimpan history deployment:

```bash
# List deployments
railway deployments

# Rollback ke deployment sebelumnya
railway rollback
```

Turso: SQLite tidak support rollback schema otomatis — pastikan migration idempotent dan backward compatible.
