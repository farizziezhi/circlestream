package service

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/farizziezhi/circlestream/backend/internal/dto"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/redis"
	"github.com/farizziezhi/circlestream/backend/internal/repository"
)

type PostService interface {
	GetFeed(ctx context.Context, circleID int64, cursor *time.Time, limit int) (*dto.FeedResponse, error)
	GetPost(ctx context.Context, userID, postID int64) (*dto.PostResponse, error)
}

type postService struct {
	postRepo    repository.PostRepository
	circleRepo  repository.CircleRepository
	redisClient *redis.RedisClient
}

func NewPostService(postRepo repository.PostRepository, circleRepo repository.CircleRepository, redisClient *redis.RedisClient) PostService {
	return &postService{
		postRepo:    postRepo,
		circleRepo:  circleRepo,
		redisClient: redisClient,
	}
}

func (s *postService) GetFeed(ctx context.Context, circleID int64, cursor *time.Time, limit int) (*dto.FeedResponse, error) {
	if limit <= 0 {
		limit = 20
	} else if limit > 50 {
		limit = 50
	}

	posts, err := s.postRepo.ListByCircle(ctx, circleID, cursor, limit)
	if err != nil {
		return nil, err
	}

	hasMore := false
	var nextCursor *string

	if len(posts) > limit {
		hasMore = true
		posts = posts[:limit]

		lastPost := posts[len(posts)-1]
		cursorStr := lastPost.CreatedAt.Format(time.RFC3339)
		nextCursor = &cursorStr
	}

	postIDs := make([]int64, len(posts))
	for i, p := range posts {
		postIDs[i] = p.ID
	}

	reactionsBatch, err := s.redisClient.GetReactionCountsBatch(ctx, postIDs)
	if err != nil {
		reactionsBatch = make(map[int64]map[string]int64)
	}

	var dtoList []dto.PostResponse
	for _, p := range posts {
		counts := reactionsBatch[p.ID]
		if counts == nil {
			counts = make(map[string]int64)
		}

		dtoCounts := make(map[string]int)
		for k, v := range counts {
			dtoCounts[k] = int(v)
		}

		dtoList = append(dtoList, dto.PostResponse{
			ID:             p.ID,
			CircleID:       p.CircleID,
			UserID:         p.UserID,
			Username:       p.Username,
			ImageURL:       p.ImageURL,
			ThumbnailURL:   p.ThumbnailURL,
			ReactionCounts: dtoCounts,
			CreatedAt:      p.CreatedAt,
		})
	}

	return &dto.FeedResponse{
		Posts:      dtoList,
		NextCursor: nextCursor,
		HasMore:    hasMore,
	}, nil
}

func (s *postService) GetPost(ctx context.Context, userID, postID int64) (*dto.PostResponse, error) {
	post, err := s.postRepo.FindByID(ctx, postID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, errors.New("post_not_found")
		}
		return nil, err
	}

	isMember, err := s.circleRepo.IsMember(ctx, post.CircleID, userID)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, ErrNotCircleMember
	}

	counts, err := s.redisClient.GetReactionCounts(ctx, postID)
	if err != nil {
		counts = make(map[string]int64)
	}

	dtoCounts := make(map[string]int)
	for k, v := range counts {
		dtoCounts[k] = int(v)
	}

	return &dto.PostResponse{
		ID:             post.ID,
		CircleID:       post.CircleID,
		UserID:         post.UserID,
		Username:       post.Username,
		ImageURL:       post.ImageURL,
		ThumbnailURL:   post.ThumbnailURL,
		ReactionCounts: dtoCounts,
		CreatedAt:      post.CreatedAt,
	}, nil
}
