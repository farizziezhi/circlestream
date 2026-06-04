package dto

import "time"

type PresignUploadRequest struct {
	CircleID    int64  `json:"circle_id"`
	Filename    string `json:"filename"`
	ContentType string `json:"content_type"`
	FileSize    int64  `json:"file_size"`
}

type PresignUploadResponse struct {
	UploadURL string `json:"upload_url"`
	ObjectKey string `json:"object_key"`
	ExpiresIn int    `json:"expires_in"`
}

type FinalizeUploadRequest struct {
	CircleID     int64   `json:"circle_id"`
	ObjectKey    string  `json:"object_key"`
	ThumbnailKey *string `json:"thumbnail_key"`
}

type PostResponse struct {
	ID             int64          `json:"id"`
	CircleID       int64          `json:"circle_id"`
	UserID         int64          `json:"user_id"`
	Username       string         `json:"username"`
	ImageURL       string         `json:"image_url"`
	ThumbnailURL   *string        `json:"thumbnail_url"`
	ReactionCounts map[string]int `json:"reaction_counts"`
	CreatedAt      time.Time      `json:"created_at"`
}

type FinalizeUploadResponse struct {
	Post PostResponse `json:"post"`
}

type FeedResponse struct {
	Posts      []PostResponse `json:"posts"`
	NextCursor *string        `json:"next_cursor"`
	HasMore    bool           `json:"has_more"`
}
