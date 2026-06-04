package model

import "time"

type Reaction struct {
	ID        int64     `json:"id" db:"id"`
	PostID    int64     `json:"post_id" db:"post_id"`
	UserID    int64     `json:"user_id" db:"user_id"`
	Emoji     string    `json:"emoji" db:"emoji"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}
