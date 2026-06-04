package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/farizziezhi/circlestream/backend/internal/model"
)

type PostRepository interface {
	CreatePost(ctx context.Context, post *model.Post) (*model.Post, error)
	FindByID(ctx context.Context, postID int64) (*model.PostWithUser, error)
	ListByCircle(ctx context.Context, circleID int64, cursor *time.Time, limit int) ([]model.PostWithUser, error)
}

type postRepository struct {
	db *sql.DB
}

func NewPostRepository(db *sql.DB) PostRepository {
	return &postRepository{db: db}
}

func (r *postRepository) CreatePost(ctx context.Context, post *model.Post) (*model.Post, error) {
	query := "INSERT INTO posts (circle_id, user_id, image_url, thumbnail_url) VALUES (?, ?, ?, ?)"
	result, err := r.db.ExecContext(ctx, query, post.CircleID, post.UserID, post.ImageURL, post.ThumbnailURL)
	if err != nil {
		return nil, err
	}
	id, err := result.LastInsertId()
	if err != nil {
		return nil, err
	}
	post.ID = id

	dbPost, err := r.FindByID(ctx, id)
	if err == nil {
		post.CreatedAt = dbPost.CreatedAt
	}
	return post, nil
}

func (r *postRepository) FindByID(ctx context.Context, postID int64) (*model.PostWithUser, error) {
	query := `
		SELECT p.id, p.circle_id, p.user_id, p.image_url, p.thumbnail_url, p.created_at, u.username
		FROM posts p
		LEFT JOIN users u ON p.user_id = u.id
		WHERE p.id = ?
	`
	row := r.db.QueryRowContext(ctx, query, postID)
	var p model.PostWithUser
	var createdAtStr string
	err := row.Scan(&p.ID, &p.CircleID, &p.UserID, &p.ImageURL, &p.ThumbnailURL, &createdAtStr, &p.Username)
	if err != nil {
		return nil, err
	}
	p.CreatedAt = parseSQLiteTime(createdAtStr)
	return &p, nil
}

func (r *postRepository) ListByCircle(ctx context.Context, circleID int64, cursor *time.Time, limit int) ([]model.PostWithUser, error) {
	if limit <= 0 {
		limit = 20
	} else if limit > 50 {
		limit = 50
	}

	fetchLimit := limit + 1

	var rows *sql.Rows
	var err error

	if cursor == nil {
		query := `
			SELECT p.id, p.circle_id, p.user_id, p.image_url, p.thumbnail_url, p.created_at, u.username
			FROM posts p
			LEFT JOIN users u ON p.user_id = u.id
			WHERE p.circle_id = ?
			ORDER BY p.created_at DESC
			LIMIT ?
		`
		rows, err = r.db.QueryContext(ctx, query, circleID, fetchLimit)
	} else {
		cursorStr := cursor.Format("2006-01-02 15:04:05")
		query := `
			SELECT p.id, p.circle_id, p.user_id, p.image_url, p.thumbnail_url, p.created_at, u.username
			FROM posts p
			LEFT JOIN users u ON p.user_id = u.id
			WHERE p.circle_id = ? AND p.created_at < ?
			ORDER BY p.created_at DESC
			LIMIT ?
		`
		rows, err = r.db.QueryContext(ctx, query, circleID, cursorStr, fetchLimit)
	}

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var posts []model.PostWithUser
	for rows.Next() {
		var p model.PostWithUser
		var createdAtStr string
		err := rows.Scan(&p.ID, &p.CircleID, &p.UserID, &p.ImageURL, &p.ThumbnailURL, &createdAtStr, &p.Username)
		if err != nil {
			return nil, err
		}
		p.CreatedAt = parseSQLiteTime(createdAtStr)
		posts = append(posts, p)
	}

	return posts, nil
}
