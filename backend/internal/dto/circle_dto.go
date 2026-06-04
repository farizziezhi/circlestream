package dto

import "time"

type CreateCircleRequest struct {
	Name string `json:"name"`
}

type CircleResponse struct {
	ID        int64     `json:"id"`
	Name      string    `json:"name"`
	OwnerID   int64     `json:"owner_id"`
	CreatedAt time.Time `json:"created_at"`
}

type InviteCodeResponseData struct {
	ID        int64      `json:"id"`
	Code      string     `json:"code"`
	IsActive  bool       `json:"is_active"`
	MaxUses   *int       `json:"max_uses"`
	UsedCount int        `json:"used_count"`
	ExpiresAt *time.Time `json:"expires_at"`
	CreatedAt time.Time  `json:"created_at,omitempty"`
}

type CreateCircleResponse struct {
	Circle     CircleResponse         `json:"circle"`
	InviteCode InviteCodeResponseData `json:"invite_code"`
}

type JoinCircleRequest struct {
	InviteCode string `json:"invite_code"`
}

type JoinCircleResponseCircle struct {
	ID          int64  `json:"id"`
	Name        string `json:"name"`
	MemberCount int    `json:"member_count"`
}

type JoinCircleResponseMember struct {
	UserID   int64     `json:"user_id"`
	Role     string    `json:"role"`
	JoinedAt time.Time `json:"joined_at"`
}

type JoinCircleResponse struct {
	Circle JoinCircleResponseCircle `json:"circle"`
	Member JoinCircleResponseMember `json:"member"`
}

type CircleDetailResponseData struct {
	ID          int64     `json:"id"`
	Name        string    `json:"name"`
	OwnerID     int64     `json:"owner_id"`
	MemberCount int       `json:"member_count"`
	CreatedAt   time.Time `json:"created_at"`
}

type CircleDetailResponse struct {
	Circle CircleDetailResponseData `json:"circle"`
}

type CircleMemberResponse struct {
	UserID   int64     `json:"user_id"`
	Username string    `json:"username"`
	Role     string    `json:"role"`
	JoinedAt time.Time `json:"joined_at"`
}

type MembersResponse struct {
	Members []CircleMemberResponse `json:"members"`
}

type CreateInviteCodeRequest struct {
	MaxUses   *int       `json:"max_uses"`
	ExpiresAt *time.Time `json:"expires_at"`
}

type InviteCodeResponse struct {
	InviteCode InviteCodeResponseData `json:"invite_code"`
}

type ListInviteCodesResponse struct {
	InviteCodes []InviteCodeResponseData `json:"invite_codes"`
}
