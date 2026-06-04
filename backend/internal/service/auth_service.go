package service

import (
	"context"
	"errors"
	"regexp"
	"time"

	"github.com/farizziezhi/circlestream/backend/internal/config"
	"github.com/farizziezhi/circlestream/backend/internal/dto"
	"github.com/farizziezhi/circlestream/backend/internal/model"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/jwt"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/password"
	"github.com/farizziezhi/circlestream/backend/internal/repository"
)

var (
	ErrEmailTaken           = errors.New("email_taken")
	ErrUsernameTaken        = errors.New("username_taken")
	ErrValidationError      = errors.New("validation_error")
	ErrInvalidCredentials   = errors.New("invalid_credentials")
	ErrInvalidRefreshToken  = errors.New("invalid_refresh_token")
	ErrRefreshTokenExpired  = errors.New("refresh_token_expired")
	ErrRefreshTokenNotFound = errors.New("refresh_token_not_found")
)

type AuthService interface {
	Register(ctx context.Context, req dto.RegisterRequest) (*dto.AuthResponse, error)
	Login(ctx context.Context, req dto.LoginRequest) (*dto.AuthResponse, error)
	Refresh(ctx context.Context, req dto.RefreshRequest) (*dto.TokenResponse, error)
	Logout(ctx context.Context, req dto.LogoutRequest) error
}

type authService struct {
	userRepo  repository.UserRepository
	tokenRepo repository.TokenRepository
	cfg       *config.Config
}

func NewAuthService(userRepo repository.UserRepository, tokenRepo repository.TokenRepository, cfg *config.Config) AuthService {
	return &authService{
		userRepo:  userRepo,
		tokenRepo: tokenRepo,
		cfg:       cfg,
	}
}

var (
	emailRegex    = regexp.MustCompile(`(?i)^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$`)
	usernameRegex = regexp.MustCompile(`^[a-zA-Z0-9_]{3,30}$`)
)

func (s *authService) Register(ctx context.Context, req dto.RegisterRequest) (*dto.AuthResponse, error) {
	if !emailRegex.MatchString(req.Email) {
		return nil, ErrValidationError
	}
	if !usernameRegex.MatchString(req.Username) {
		return nil, ErrValidationError
	}
	if len(req.Password) < 8 {
		return nil, ErrValidationError
	}

	existingUser, _ := s.userRepo.FindByEmail(ctx, req.Email)
	if existingUser != nil {
		return nil, ErrEmailTaken
	}
	existingUser, _ = s.userRepo.FindByUsername(ctx, req.Username)
	if existingUser != nil {
		return nil, ErrUsernameTaken
	}

	hashedPassword, err := password.Hash(req.Password)
	if err != nil {
		return nil, err
	}

	user := &model.User{
		Username:     req.Username,
		Email:        req.Email,
		PasswordHash: hashedPassword,
	}
	if err := s.userRepo.CreateUser(ctx, user); err != nil {
		return nil, err
	}

	accessToken, err := jwt.GenerateAccessToken(user.ID, user.Username)
	if err != nil {
		return nil, err
	}
	refreshToken, err := jwt.GenerateRefreshToken(user.ID)
	if err != nil {
		return nil, err
	}

	expiresAt := time.Now().Add(30 * 24 * time.Hour)
	if err := s.tokenRepo.SaveRefreshToken(ctx, user.ID, refreshToken, expiresAt); err != nil {
		return nil, err
	}

	return &dto.AuthResponse{
		User: dto.UserResponse{
			ID:        user.ID,
			Username:  user.Username,
			Email:     user.Email,
			CreatedAt: user.CreatedAt,
		},
		Tokens: dto.TokenResponse{
			AccessToken:  accessToken,
			RefreshToken: refreshToken,
			ExpiresIn:    900,
		},
	}, nil
}

func (s *authService) Login(ctx context.Context, req dto.LoginRequest) (*dto.AuthResponse, error) {
	user, err := s.userRepo.FindByEmail(ctx, req.Email)
	if err != nil {
		return nil, ErrInvalidCredentials
	}

	if !password.Compare(req.Password, user.PasswordHash) {
		return nil, ErrInvalidCredentials
	}

	accessToken, err := jwt.GenerateAccessToken(user.ID, user.Username)
	if err != nil {
		return nil, err
	}
	refreshToken, err := jwt.GenerateRefreshToken(user.ID)
	if err != nil {
		return nil, err
	}

	expiresAt := time.Now().Add(30 * 24 * time.Hour)
	if err := s.tokenRepo.SaveRefreshToken(ctx, user.ID, refreshToken, expiresAt); err != nil {
		return nil, err
	}

	return &dto.AuthResponse{
		User: dto.UserResponse{
			ID:        user.ID,
			Username:  user.Username,
			Email:     user.Email,
			CreatedAt: user.CreatedAt,
		},
		Tokens: dto.TokenResponse{
			AccessToken:  accessToken,
			RefreshToken: refreshToken,
			ExpiresIn:    900,
		},
	}, nil
}

func (s *authService) Refresh(ctx context.Context, req dto.RefreshRequest) (*dto.TokenResponse, error) {
	claims, err := jwt.ValidateToken(req.RefreshToken)
	if err != nil {
		return nil, ErrInvalidRefreshToken
	}
	if claims.Type != "refresh" {
		return nil, ErrInvalidRefreshToken
	}

	userID, expiresAt, err := s.tokenRepo.FindRefreshToken(ctx, req.RefreshToken)
	if err != nil {
		return nil, ErrRefreshTokenNotFound
	}

	if time.Now().After(expiresAt) {
		_ = s.tokenRepo.DeleteRefreshToken(ctx, req.RefreshToken)
		return nil, ErrRefreshTokenExpired
	}

	user, err := s.userRepo.FindByID(ctx, userID)
	if err != nil {
		return nil, ErrInvalidRefreshToken
	}

	newAccessToken, err := jwt.GenerateAccessToken(userID, user.Username)
	if err != nil {
		return nil, err
	}

	return &dto.TokenResponse{
		AccessToken:  newAccessToken,
		RefreshToken: req.RefreshToken,
		ExpiresIn:    900,
	}, nil
}

func (s *authService) Logout(ctx context.Context, req dto.LogoutRequest) error {
	return s.tokenRepo.DeleteRefreshToken(ctx, req.RefreshToken)
}
