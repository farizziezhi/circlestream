package service

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/farizziezhi/circlestream/backend/internal/dto"
	"github.com/farizziezhi/circlestream/backend/internal/model"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/ably"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/invite"
	"github.com/farizziezhi/circlestream/backend/internal/repository"
)

var (
	ErrCircleFull       = errors.New("circle_full")
	ErrAlreadyMember    = errors.New("already_member")
	ErrInviteNotFound   = errors.New("invite_code_not_found")
	ErrInviteExpired    = errors.New("invite_code_expired")
	ErrInviteExhausted  = errors.New("invite_code_exhausted")
	ErrOwnerCannotLeave = errors.New("owner_cannot_leave")
	ErrCircleNotFound   = errors.New("circle_not_found")
	ErrNotCircleMember  = errors.New("not_member")
)

type CircleService interface {
	CreateCircle(ctx context.Context, userID int64, name string) (*dto.CreateCircleResponse, error)
	JoinCircle(ctx context.Context, userID int64, code string) (*dto.JoinCircleResponse, error)
	LeaveCircle(ctx context.Context, userID int64, circleID int64) error
	GetDetail(ctx context.Context, circleID int64) (*dto.CircleDetailResponseData, error)
	GetMembers(ctx context.Context, circleID int64) ([]dto.CircleMemberResponse, error)
	CreateInviteCode(ctx context.Context, circleID int64, maxUses *int, expiresAt *time.Time) (*dto.InviteCodeResponseData, error)
	ListInviteCodes(ctx context.Context, circleID int64) ([]dto.InviteCodeResponseData, error)
}

type circleService struct {
	db         *sql.DB
	circleRepo repository.CircleRepository
	inviteRepo repository.InviteRepository
	ablyClient *ably.AblyClient
}

func NewCircleService(db *sql.DB, circleRepo repository.CircleRepository, inviteRepo repository.InviteRepository, ablyClient *ably.AblyClient) CircleService {
	return &circleService{
		db:         db,
		circleRepo: circleRepo,
		inviteRepo: inviteRepo,
		ablyClient: ablyClient,
	}
}

func (s *circleService) generateUniqueInviteCode(ctx context.Context) (string, error) {
	for i := 0; i < 10; i++ {
		code, err := invite.GenerateInviteCode()
		if err != nil {
			return "", err
		}
		existing, _ := s.inviteRepo.FindByCode(ctx, code)
		if existing == nil {
			return code, nil
		}
	}
	return "", errors.New("failed to generate unique invite code")
}

func (s *circleService) CreateCircle(ctx context.Context, userID int64, name string) (*dto.CreateCircleResponse, error) {
	if name == "" {
		return nil, errors.New("circle name cannot be empty")
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	circle := &model.Circle{
		Name:    name,
		OwnerID: userID,
	}
	if err := s.circleRepo.CreateCircle(ctx, tx, circle); err != nil {
		return nil, err
	}

	member := &model.CircleMember{
		CircleID: circle.ID,
		UserID:   userID,
		Role:     "owner",
	}
	if err := s.circleRepo.AddMember(ctx, tx, member); err != nil {
		return nil, err
	}

	code, err := s.generateUniqueInviteCode(ctx)
	if err != nil {
		return nil, err
	}
	inviteCode := &model.InviteCode{
		CircleID:  circle.ID,
		Code:      code,
		IsActive:  true,
		MaxUses:   nil,
		UsedCount: 0,
		ExpiresAt: nil,
	}
	if err := s.inviteRepo.CreateInviteCode(ctx, tx, inviteCode); err != nil {
		return nil, err
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	dbCircle, err := s.circleRepo.FindByID(ctx, circle.ID)
	if err == nil {
		circle.CreatedAt = dbCircle.CreatedAt
	}
	dbInvite, err := s.inviteRepo.FindByCode(ctx, code)
	if err == nil {
		inviteCode.ID = dbInvite.ID
		inviteCode.CreatedAt = dbInvite.CreatedAt
	}

	return &dto.CreateCircleResponse{
		Circle: dto.CircleResponse{
			ID:        circle.ID,
			Name:      circle.Name,
			OwnerID:   circle.OwnerID,
			CreatedAt: circle.CreatedAt,
		},
		InviteCode: dto.InviteCodeResponseData{
			ID:        inviteCode.ID,
			Code:      inviteCode.Code,
			IsActive:  inviteCode.IsActive,
			MaxUses:   inviteCode.MaxUses,
			UsedCount: inviteCode.UsedCount,
			ExpiresAt: inviteCode.ExpiresAt,
			CreatedAt: inviteCode.CreatedAt,
		},
	}, nil
}

func (s *circleService) JoinCircle(ctx context.Context, userID int64, code string) (*dto.JoinCircleResponse, error) {
	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()

	ic, err := s.inviteRepo.FindByCode(ctx, code)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, ErrInviteNotFound
		}
		return nil, err
	}

	if !ic.IsActive {
		return nil, ErrInviteNotFound
	}
	if ic.ExpiresAt != nil && time.Now().After(*ic.ExpiresAt) {
		return nil, ErrInviteExpired
	}
	if ic.MaxUses != nil && ic.UsedCount >= *ic.MaxUses {
		return nil, ErrInviteExhausted
	}

	memberCount, err := s.circleRepo.GetMemberCount(ctx, ic.CircleID)
	if err != nil {
		return nil, err
	}
	if memberCount >= 10 {
		return nil, ErrCircleFull
	}

	isMember, err := s.circleRepo.IsMember(ctx, ic.CircleID, userID)
	if err != nil {
		return nil, err
	}
	if isMember {
		return nil, ErrAlreadyMember
	}

	member := &model.CircleMember{
		CircleID: ic.CircleID,
		UserID:   userID,
		Role:     "member",
	}
	if err := s.circleRepo.AddMember(ctx, tx, member); err != nil {
		return nil, err
	}

	if err := s.inviteRepo.IncrementUsedCount(ctx, tx, ic.Code); err != nil {
		return nil, err
	}

	if err := tx.Commit(); err != nil {
		return nil, err
	}

	circle, err := s.circleRepo.FindByID(ctx, ic.CircleID)
	if err != nil {
		return nil, err
	}

	updatedMemberCount, _ := s.circleRepo.GetMemberCount(ctx, ic.CircleID)

	return &dto.JoinCircleResponse{
		Circle: dto.JoinCircleResponseCircle{
			ID:          circle.ID,
			Name:        circle.Name,
			MemberCount: updatedMemberCount,
		},
		Member: dto.JoinCircleResponseMember{
			UserID:   userID,
			Role:     "member",
			JoinedAt: time.Now(),
		},
	}, nil
}

func (s *circleService) LeaveCircle(ctx context.Context, userID int64, circleID int64) error {
	role, err := s.circleRepo.GetMemberRole(ctx, circleID, userID)
	if err != nil {
		return err
	}
	if role == "" {
		return ErrNotCircleMember
	}
	if role == "owner" {
		return ErrOwnerCannotLeave
	}
	return s.circleRepo.RemoveMember(ctx, circleID, userID)
}

func (s *circleService) GetDetail(ctx context.Context, circleID int64) (*dto.CircleDetailResponseData, error) {
	circle, err := s.circleRepo.FindByID(ctx, circleID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, ErrCircleNotFound
		}
		return nil, err
	}

	memberCount, err := s.circleRepo.GetMemberCount(ctx, circleID)
	if err != nil {
		return nil, err
	}

	return &dto.CircleDetailResponseData{
		ID:          circle.ID,
		Name:        circle.Name,
		OwnerID:     circle.OwnerID,
		MemberCount: memberCount,
		CreatedAt:   circle.CreatedAt,
	}, nil
}

func (s *circleService) GetMembers(ctx context.Context, circleID int64) ([]dto.CircleMemberResponse, error) {
	members, err := s.circleRepo.GetMembers(ctx, circleID)
	if err != nil {
		return nil, err
	}

	var resp []dto.CircleMemberResponse
	for _, m := range members {
		resp = append(resp, dto.CircleMemberResponse{
			UserID:   m.UserID,
			Username: m.Username,
			Role:     m.Role,
			JoinedAt: m.JoinedAt,
		})
	}
	return resp, nil
}

func (s *circleService) CreateInviteCode(ctx context.Context, circleID int64, maxUses *int, expiresAt *time.Time) (*dto.InviteCodeResponseData, error) {
	code, err := s.generateUniqueInviteCode(ctx)
	if err != nil {
		return nil, err
	}

	inviteCode := &model.InviteCode{
		CircleID:  circleID,
		Code:      code,
		IsActive:  true,
		MaxUses:   maxUses,
		UsedCount: 0,
		ExpiresAt: expiresAt,
	}

	if err := s.inviteRepo.CreateInviteCode(ctx, nil, inviteCode); err != nil {
		return nil, err
	}

	dbInvite, err := s.inviteRepo.FindByCode(ctx, code)
	if err == nil {
		inviteCode.ID = dbInvite.ID
		inviteCode.CreatedAt = dbInvite.CreatedAt
	}

	return &dto.InviteCodeResponseData{
		ID:        inviteCode.ID,
		Code:      inviteCode.Code,
		IsActive:  inviteCode.IsActive,
		MaxUses:   inviteCode.MaxUses,
		UsedCount: inviteCode.UsedCount,
		ExpiresAt: inviteCode.ExpiresAt,
		CreatedAt: inviteCode.CreatedAt,
	}, nil
}

func (s *circleService) ListInviteCodes(ctx context.Context, circleID int64) ([]dto.InviteCodeResponseData, error) {
	invites, err := s.inviteRepo.ListByCircle(ctx, circleID)
	if err != nil {
		return nil, err
	}

	var resp []dto.InviteCodeResponseData
	for _, ic := range invites {
		resp = append(resp, dto.InviteCodeResponseData{
			ID:        ic.ID,
			Code:      ic.Code,
			IsActive:  ic.IsActive,
			MaxUses:   ic.MaxUses,
			UsedCount: ic.UsedCount,
			ExpiresAt: ic.ExpiresAt,
			CreatedAt: ic.CreatedAt,
		})
	}
	return resp, nil
}
