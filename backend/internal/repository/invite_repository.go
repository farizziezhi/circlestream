package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/farizziezhi/circlestream/backend/internal/model"
)

type InviteRepository interface {
	CreateInviteCode(ctx context.Context, tx *sql.Tx, invite *model.InviteCode) error
	FindByCode(ctx context.Context, code string) (*model.InviteCode, error)
	IncrementUsedCount(ctx context.Context, tx *sql.Tx, code string) error
	DeactivateCode(ctx context.Context, code string) error
	ListByCircle(ctx context.Context, circleID int64) ([]model.InviteCode, error)
}

type inviteRepository struct {
	db *sql.DB
}

func NewInviteRepository(db *sql.DB) InviteRepository {
	return &inviteRepository{db: db}
}

func (r *inviteRepository) getExecutor(tx *sql.Tx) dbExecutor {
	if tx != nil {
		return tx
	}
	return r.db
}

func (r *inviteRepository) CreateInviteCode(ctx context.Context, tx *sql.Tx, invite *model.InviteCode) error {
	exec := r.getExecutor(tx)
	var expiresAtStr *string
	if invite.ExpiresAt != nil {
		s := invite.ExpiresAt.Format("2006-01-02 15:04:05")
		expiresAtStr = &s
	}

	isActiveInt := 0
	if invite.IsActive {
		isActiveInt = 1
	}

	query := `
		INSERT INTO invite_codes (circle_id, code, is_active, expires_at, max_uses, used_count)
		VALUES (?, ?, ?, ?, ?, ?)
	`
	result, err := exec.ExecContext(ctx, query, invite.CircleID, invite.Code, isActiveInt, expiresAtStr, invite.MaxUses, invite.UsedCount)
	if err != nil {
		return err
	}
	id, err := result.LastInsertId()
	if err != nil {
		return err
	}
	invite.ID = id
	return nil
}

func (r *inviteRepository) FindByCode(ctx context.Context, code string) (*model.InviteCode, error) {
	query := `
		SELECT id, circle_id, code, is_active, expires_at, max_uses, used_count, created_at
		FROM invite_codes
		WHERE code = ?
	`
	row := r.db.QueryRowContext(ctx, query, code)
	var invite model.InviteCode
	var expiresAtStr *string
	var createdAtStr string
	var isActiveInt int

	err := row.Scan(&invite.ID, &invite.CircleID, &invite.Code, &isActiveInt, &expiresAtStr, &invite.MaxUses, &invite.UsedCount, &createdAtStr)
	if err != nil {
		return nil, err
	}

	invite.IsActive = isActiveInt != 0
	if expiresAtStr != nil {
		t, err := time.Parse("2006-01-02 15:04:05", *expiresAtStr)
		if err == nil {
			invite.ExpiresAt = &t
		} else {
			layouts := []string{time.RFC3339, "2006-01-02T15:04:05Z"}
			for _, l := range layouts {
				if val, errParse := time.Parse(l, *expiresAtStr); errParse == nil {
					invite.ExpiresAt = &val
					break
				}
			}
		}
	}
	invite.CreatedAt = parseSQLiteTime(createdAtStr)
	return &invite, nil
}

func (r *inviteRepository) IncrementUsedCount(ctx context.Context, tx *sql.Tx, code string) error {
	exec := r.getExecutor(tx)
	query := "UPDATE invite_codes SET used_count = used_count + 1 WHERE code = ?"
	_, err := exec.ExecContext(ctx, query, code)
	return err
}

func (r *inviteRepository) DeactivateCode(ctx context.Context, code string) error {
	query := "UPDATE invite_codes SET is_active = 0 WHERE code = ?"
	_, err := r.db.ExecContext(ctx, query, code)
	return err
}

func (r *inviteRepository) ListByCircle(ctx context.Context, circleID int64) ([]model.InviteCode, error) {
	query := `
		SELECT id, circle_id, code, is_active, expires_at, max_uses, used_count, created_at
		FROM invite_codes
		WHERE circle_id = ?
		ORDER BY created_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query, circleID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var invites []model.InviteCode
	for rows.Next() {
		var invite model.InviteCode
		var expiresAtStr *string
		var createdAtStr string
		var isActiveInt int

		err := rows.Scan(&invite.ID, &invite.CircleID, &invite.Code, &isActiveInt, &expiresAtStr, &invite.MaxUses, &invite.UsedCount, &createdAtStr)
		if err != nil {
			return nil, err
		}

		invite.IsActive = isActiveInt != 0
		if expiresAtStr != nil {
			t, err := time.Parse("2006-01-02 15:04:05", *expiresAtStr)
			if err == nil {
				invite.ExpiresAt = &t
			} else {
				layouts := []string{time.RFC3339, "2006-01-02T15:04:05Z"}
				for _, l := range layouts {
					if val, errParse := time.Parse(l, *expiresAtStr); errParse == nil {
						invite.ExpiresAt = &val
						break
					}
				}
			}
		}
		invite.CreatedAt = parseSQLiteTime(createdAtStr)
		invites = append(invites, invite)
	}
	return invites, nil
}
