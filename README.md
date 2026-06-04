# CircleStream

CircleStream is a private real-time photo sharing mobile application designed for small friend groups.

## Stack Summary

- **Frontend:** Flutter
- **Backend API:** Golang + Fiber
- **Database:** Turso (SQLite edge)
- **Media Storage:** Cloudflare R2
- **Real-Time Pub/Sub:** Ably
- **Cache & Counters:** Upstash Redis

## Project Structure

```text
circlestream/
├── docs/                      # Full project documentation
├── backend/                   # Golang backend API project
│   ├── cmd/
│   │   └── api/
│   │       └── main.go        # Entry point
│   ├── internal/              # Core application logic
│   │   ├── config/
│   │   ├── database/
│   │   ├── dto/
│   │   ├── handler/
│   │   ├── middleware/
│   │   ├── model/
│   │   ├── pkg/
│   │   ├── repository/
│   │   ├── router/
│   │   └── service/
│   ├── .env.example
│   ├── .gitignore
│   ├── Dockerfile
│   ├── go.mod
│   └── Makefile
└── frontend/                  # Flutter frontend application (future)
```
