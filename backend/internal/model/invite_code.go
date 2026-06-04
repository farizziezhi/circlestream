package model

import "time"

type InviteCode struct {
	ID        int64      `json:"id" db:"id"`
	CircleID  int64      `json:"circle_id" db:"circle_id"`
	Code      string     `json:"code" db:"code"`
	IsActive  bool       `json:"is_active" db:"is_active"`
	ExpiresAt *time.Time `json:"expires_at" db:"expires_at"`
	MaxUses   *int       `json:"max_uses" db:"max_uses"`
	UsedCount int        `json:"used_count" db:"used_count"`
	CreatedAt time.Time  `json:"created_at" db:"created_at"`
}
