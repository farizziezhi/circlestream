package repository

import (
	"context"
	"database/sql"

	"github.com/farizziezhi/circlestream/backend/internal/model"
)

type ReactionRepository interface {
	CreateReaction(ctx context.Context, reaction *model.Reaction) error
}

type reactionRepository struct {
	db *sql.DB
}

func NewReactionRepository(db *sql.DB) ReactionRepository {
	return &reactionRepository{db: db}
}

func (r *reactionRepository) CreateReaction(ctx context.Context, reaction *model.Reaction) error {
	query := "INSERT INTO reactions (post_id, user_id, emoji) VALUES (?, ?, ?)"
	result, err := r.db.ExecContext(ctx, query, reaction.PostID, reaction.UserID, reaction.Emoji)
	if err != nil {
		return err
	}
	id, err := result.LastInsertId()
	if err != nil {
		return err
	}
	reaction.ID = id
	return nil
}
