.PHONY: run build test migrate lint docker-build docker-run

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
