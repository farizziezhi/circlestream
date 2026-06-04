package model

import "time"

type Post struct {
	ID           int64     `json:"id" db:"id"`
	CircleID     int64     `json:"circle_id" db:"circle_id"`
	UserID       int64     `json:"user_id" db:"user_id"`
	ImageURL     string    `json:"image_url" db:"image_url"`
	ThumbnailURL *string   `json:"thumbnail_url" db:"thumbnail_url"`
	CreatedAt    time.Time `json:"created_at" db:"created_at"`
}

type PostWithUser struct {
	Post
	Username string `json:"username" db:"username"`
}
