package service

import (
	"context"
	"errors"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/farizziezhi/circlestream/backend/internal/config"
	"github.com/farizziezhi/circlestream/backend/internal/dto"
	"github.com/farizziezhi/circlestream/backend/internal/model"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/ably"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/r2"
	"github.com/farizziezhi/circlestream/backend/internal/repository"
	"github.com/google/uuid"
)

var (
	ErrUnsupportedFileType = errors.New("unsupported_file_type")
	ErrFileTooLarge        = errors.New("file_too_large")
	ErrKeyMismatch         = errors.New("object_key_mismatch")
)

type MediaService interface {
	PresignUpload(ctx context.Context, userID, circleID int64, req dto.PresignUploadRequest) (*dto.PresignUploadResponse, error)
	FinalizeUpload(ctx context.Context, userID, circleID int64, req dto.FinalizeUploadRequest) (*dto.PostResponse, error)
}

type mediaService struct {
	r2Client   *r2.R2Client
	postRepo   repository.PostRepository
	circleRepo repository.CircleRepository
	userRepo   repository.UserRepository
	ablyClient *ably.AblyClient
	cfg        *config.Config
}

func NewMediaService(r2Client *r2.R2Client, postRepo repository.PostRepository, circleRepo repository.CircleRepository, userRepo repository.UserRepository, ablyClient *ably.AblyClient, cfg *config.Config) MediaService {
	return &mediaService{
		r2Client:   r2Client,
		postRepo:   postRepo,
		circleRepo: circleRepo,
		userRepo:   userRepo,
		ablyClient: ablyClient,
		cfg:        cfg,
	}
}

func (s *mediaService) PresignUpload(ctx context.Context, userID, circleID int64, req dto.PresignUploadRequest) (*dto.PresignUploadResponse, error) {
	isMember, err := s.circleRepo.IsMember(ctx, circleID, userID)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, ErrNotCircleMember
	}

	allowedTypes := map[string]bool{
		"image/jpeg": true,
		"image/jpg":  true,
		"image/png":  true,
		"image/webp": true,
	}
	if !allowedTypes[req.ContentType] {
		return nil, ErrUnsupportedFileType
	}

	if req.FileSize > 10*1024*1024 {
		return nil, ErrFileTooLarge
	}

	ext := filepath.Ext(req.Filename)
	if ext == "" {
		switch req.ContentType {
		case "image/jpeg", "image/jpg":
			ext = ".jpg"
		case "image/png":
			ext = ".png"
		case "image/webp":
			ext = ".webp"
		}
	}

	uniqueID := uuid.New().String()
	objectKey := fmt.Sprintf("circles/%d/posts/%s%s", circleID, uniqueID, ext)

	uploadURL, err := s.r2Client.GeneratePresignedURL(objectKey, req.ContentType, 15*time.Minute)
	if err != nil {
		return nil, err
	}

	return &dto.PresignUploadResponse{
		UploadURL: uploadURL,
		ObjectKey: objectKey,
		ExpiresIn: 900,
	}, nil
}

func (s *mediaService) FinalizeUpload(ctx context.Context, userID, circleID int64, req dto.FinalizeUploadRequest) (*dto.PostResponse, error) {
	isMember, err := s.circleRepo.IsMember(ctx, circleID, userID)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, ErrNotCircleMember
	}

	expectedPrefix := fmt.Sprintf("circles/%d/posts/", circleID)
	if !strings.HasPrefix(req.ObjectKey, expectedPrefix) {
		return nil, ErrKeyMismatch
	}

	if req.ThumbnailKey != nil && !strings.HasPrefix(*req.ThumbnailKey, expectedPrefix) {
		return nil, ErrKeyMismatch
	}

	imageURL := s.r2Client.BuildPublicURL(req.ObjectKey)
	var thumbnailURL *string
	if req.ThumbnailKey != nil {
		s := s.r2Client.BuildPublicURL(*req.ThumbnailKey)
		thumbnailURL = &s
	}

	post := &model.Post{
		CircleID:     circleID,
		UserID:       userID,
		ImageURL:     imageURL,
		ThumbnailURL: thumbnailURL,
	}
	createdPost, err := s.postRepo.CreatePost(ctx, post)
	if err != nil {
		return nil, err
	}

	user, err := s.userRepo.FindByID(ctx, userID)
	username := ""
	if err == nil {
		username = user.Username
	}

	channelName := fmt.Sprintf("circle:%d", circleID)
	eventPayload := map[string]interface{}{
		"circle_id": circleID,
		"post": map[string]interface{}{
			"id":              createdPost.ID,
			"user_id":         createdPost.UserID,
			"username":        username,
			"image_url":       createdPost.ImageURL,
			"thumbnail_url":   createdPost.ThumbnailURL,
			"reaction_counts": map[string]int{},
			"created_at":      createdPost.CreatedAt,
		},
	}
	_ = s.ablyClient.Publish(channelName, "post_created", eventPayload)

	return &dto.PostResponse{
		ID:             createdPost.ID,
		CircleID:       createdPost.CircleID,
		UserID:         createdPost.UserID,
		Username:       username,
		ImageURL:       createdPost.ImageURL,
		ThumbnailURL:   createdPost.ThumbnailURL,
		ReactionCounts: map[string]int{},
		CreatedAt:      createdPost.CreatedAt,
	}, nil
}
