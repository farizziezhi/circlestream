package repository

import (
	"context"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"time"
)

type TokenRepository interface {
	SaveRefreshToken(ctx context.Context, userID int64, token string, expiresAt time.Time) error
	FindRefreshToken(ctx context.Context, token string) (int64, time.Time, error)
	DeleteRefreshToken(ctx context.Context, token string) error
}

type tokenRepository struct {
	db *sql.DB
}

func NewTokenRepository(db *sql.DB) TokenRepository {
	return &tokenRepository{db: db}
}

func hashToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}

func (r *tokenRepository) SaveRefreshToken(ctx context.Context, userID int64, token string, expiresAt time.Time) error {
	tokenHash := hashToken(token)
	expiresAtStr := expiresAt.Format("2006-01-02 15:04:05")
	query := "INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES (?, ?, ?)"
	_, err := r.db.ExecContext(ctx, query, userID, tokenHash, expiresAtStr)
	return err
}

func (r *tokenRepository) FindRefreshToken(ctx context.Context, token string) (int64, time.Time, error) {
	tokenHash := hashToken(token)
	query := "SELECT user_id, expires_at FROM refresh_tokens WHERE token_hash = ?"
	row := r.db.QueryRowContext(ctx, query, tokenHash)
	var userID int64
	var expiresAtStr string
	err := row.Scan(&userID, &expiresAtStr)
	if err != nil {
		return 0, time.Time{}, err
	}
	expiresAt, err := time.Parse("2006-01-02 15:04:05", expiresAtStr)
	if err != nil {
		layouts := []string{
			"2006-01-02 15:04:05",
			time.RFC3339,
			"2006-01-02T15:04:05Z",
		}
		for _, layout := range layouts {
			if t, errParse := time.Parse(layout, expiresAtStr); errParse == nil {
				return userID, t, nil
			}
		}
		return 0, time.Time{}, err
	}
	return userID, expiresAt, nil
}

func (r *tokenRepository) DeleteRefreshToken(ctx context.Context, token string) error {
	tokenHash := hashToken(token)
	query := "DELETE FROM refresh_tokens WHERE token_hash = ?"
	_, err := r.db.ExecContext(ctx, query, tokenHash)
	return err
}
