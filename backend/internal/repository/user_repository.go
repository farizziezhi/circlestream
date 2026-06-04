package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/farizziezhi/circlestream/backend/internal/model"
)

type UserRepository interface {
	CreateUser(ctx context.Context, user *model.User) error
	FindByEmail(ctx context.Context, email string) (*model.User, error)
	FindByUsername(ctx context.Context, username string) (*model.User, error)
	FindByID(ctx context.Context, id int64) (*model.User, error)
}

type userRepository struct {
	db *sql.DB
}

func NewUserRepository(db *sql.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) CreateUser(ctx context.Context, user *model.User) error {
	query := "INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)"
	result, err := r.db.ExecContext(ctx, query, user.Username, user.Email, user.PasswordHash)
	if err != nil {
		return err
	}
	id, err := result.LastInsertId()
	if err != nil {
		return err
	}
	user.ID = id
	return nil
}

func (r *userRepository) FindByEmail(ctx context.Context, email string) (*model.User, error) {
	query := "SELECT id, username, email, password_hash, created_at FROM users WHERE email = ?"
	row := r.db.QueryRowContext(ctx, query, email)
	var user model.User
	var createdAtStr string
	err := row.Scan(&user.ID, &user.Username, &user.Email, &user.PasswordHash, &createdAtStr)
	if err != nil {
		return nil, err
	}
	user.CreatedAt = parseSQLiteTime(createdAtStr)
	return &user, nil
}

func (r *userRepository) FindByUsername(ctx context.Context, username string) (*model.User, error) {
	query := "SELECT id, username, email, password_hash, created_at FROM users WHERE username = ?"
	row := r.db.QueryRowContext(ctx, query, username)
	var user model.User
	var createdAtStr string
	err := row.Scan(&user.ID, &user.Username, &user.Email, &user.PasswordHash, &createdAtStr)
	if err != nil {
		return nil, err
	}
	user.CreatedAt = parseSQLiteTime(createdAtStr)
	return &user, nil
}

func (r *userRepository) FindByID(ctx context.Context, id int64) (*model.User, error) {
	query := "SELECT id, username, email, password_hash, created_at FROM users WHERE id = ?"
	row := r.db.QueryRowContext(ctx, query, id)
	var user model.User
	var createdAtStr string
	err := row.Scan(&user.ID, &user.Username, &user.Email, &user.PasswordHash, &createdAtStr)
	if err != nil {
		return nil, err
	}
	user.CreatedAt = parseSQLiteTime(createdAtStr)
	return &user, nil
}

func parseSQLiteTime(s string) time.Time {
	layouts := []string{
		"2006-01-02 15:04:05",
		time.RFC3339,
		"2006-01-02T15:04:05Z",
		"2006-01-02T15:04:05-07:00",
	}
	for _, layout := range layouts {
		if t, err := time.Parse(layout, s); err == nil {
			return t
		}
	}
	return time.Time{}
}
