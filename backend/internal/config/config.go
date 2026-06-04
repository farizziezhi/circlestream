package config

import (
	"os"
	"strings"
)

type Config struct {
	Port          string
	TursoURL      string
	TursoToken    string
	JWTSecret     string
	R2AccountID   string
	R2AccessKey   string
	R2SecretKey   string
	R2BucketName  string
	R2PublicURL   string
	R2Endpoint    string
	RedisAddr     string
	RedisPassword string
	AblyAPIKey    string
}

func Load() *Config {
	redisURL := mustGetEnv("UPSTASH_REDIS_REST_URL")
	redisPassword := mustGetEnv("UPSTASH_REDIS_REST_TOKEN")

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
		R2Endpoint:    mustGetEnv("R2_ENDPOINT"),
		RedisAddr:     parseRedisAddr(redisURL),
		RedisPassword: strings.Trim(redisPassword, `"'`),
		AblyAPIKey:    mustGetEnv("ABLY_API_KEY"),
	}
}

func parseRedisAddr(url string) string {
	url = strings.Trim(url, `"'`)
	url = strings.TrimPrefix(url, "https://")
	url = strings.TrimPrefix(url, "http://")
	if !strings.Contains(url, ":") {
		url = url + ":6379"
	}
	return url
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
