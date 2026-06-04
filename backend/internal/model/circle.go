package model

import "time"

type Circle struct {
	ID        int64     `json:"id" db:"id"`
	Name      string    `json:"name" db:"name"`
	OwnerID   int64     `json:"owner_id" db:"owner_id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type CircleMember struct {
	CircleID int64     `json:"circle_id" db:"circle_id"`
	UserID   int64     `json:"user_id" db:"user_id"`
	Role     string    `json:"role" db:"role"`
	JoinedAt time.Time `json:"joined_at" db:"joined_at"`
}
