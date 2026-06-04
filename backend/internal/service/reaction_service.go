package service

import (
	"context"
	"errors"
	"fmt"
	"log"

	"github.com/farizziezhi/circlestream/backend/internal/dto"
	"github.com/farizziezhi/circlestream/backend/internal/model"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/ably"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/redis"
	"github.com/farizziezhi/circlestream/backend/internal/repository"
)

var (
	ErrInvalidEmoji = errors.New("invalid_emoji")
	ErrPostNotFound = errors.New("post_not_found")
)

type ReactionService interface {
	AddReaction(ctx context.Context, userID, postID int64, emoji string) (*dto.AddReactionResponse, error)
	GetReactions(ctx context.Context, userID, postID int64) (*dto.GetReactionsResponse, error)
}

type reactionService struct {
	redisClient  *redis.RedisClient
	reactionRepo repository.ReactionRepository
	postRepo     repository.PostRepository
	circleRepo   repository.CircleRepository
	ablyClient   *ably.AblyClient
}

func NewReactionService(
	redisClient *redis.RedisClient,
	reactionRepo repository.ReactionRepository,
	postRepo repository.PostRepository,
	circleRepo repository.CircleRepository,
	ablyClient *ably.AblyClient,
) ReactionService {
	return &reactionService{
		redisClient:  redisClient,
		reactionRepo: reactionRepo,
		postRepo:     postRepo,
		circleRepo:   circleRepo,
		ablyClient:   ablyClient,
	}
}

var validEmojis = map[string]bool{
	"❤️":  true,
	"😂":  true,
	"😮":  true,
	"🔥":  true,
	"👏":  true,
	"😢":  true,
	"🤩":  true,
	"💀":  true,
}

func (s *reactionService) AddReaction(ctx context.Context, userID, postID int64, emoji string) (*dto.AddReactionResponse, error) {
	if !validEmojis[emoji] {
		return nil, ErrInvalidEmoji
	}

	post, err := s.postRepo.FindByID(ctx, postID)
	if err != nil {
		return nil, ErrPostNotFound
	}

	isMember, err := s.circleRepo.IsMember(ctx, post.CircleID, userID)
	if err != nil {
		return nil, err
	}
	if !isMember {
		return nil, ErrNotCircleMember
	}

	newCount, err := s.redisClient.IncrReaction(ctx, postID, emoji)
	if err != nil {
		return nil, err
	}

	go func() {
		dbCtx := context.Background()
		r := &model.Reaction{
			PostID: postID,
			UserID: userID,
			Emoji:  emoji,
		}
		if err := s.reactionRepo.CreateReaction(dbCtx, r); err != nil {
			log.Printf("Failed to backup reaction to database: %v", err)
		}
	}()

	channelName := fmt.Sprintf("circle:%d", post.CircleID)
	eventPayload := map[string]interface{}{
		"post_id": postID,
		"emoji":   emoji,
		"count":   newCount,
		"user_id": userID,
	}
	_ = s.ablyClient.Publish(channelName, "reaction_added", eventPayload)

	return &dto.AddReactionResponse{
		PostID: postID,
		Emoji:  emoji,
		Count:  newCount,
	}, nil
}

func (s *reactionService) GetReactions(ctx context.Context, userID, postID int64) (*dto.GetReactionsResponse, error) {
	post, err := s.postRepo.FindByID(ctx, postID)
	if err != nil {
		return nil, ErrPostNotFound
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
		return nil, err
	}

	var total int64
	for _, count := range counts {
		total += count
	}

	return &dto.GetReactionsResponse{
		PostID:    postID,
		Reactions: counts,
		Total:     total,
	}, nil
}
