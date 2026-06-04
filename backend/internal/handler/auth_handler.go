package handler

import (
	"github.com/farizziezhi/circlestream/backend/internal/dto"
	"github.com/farizziezhi/circlestream/backend/internal/service"
	"github.com/gofiber/fiber/v2"
)

type AuthHandler struct {
	authSvc service.AuthService
}

func NewAuthHandler(authSvc service.AuthService) *AuthHandler {
	return &AuthHandler{authSvc: authSvc}
}

func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var req dto.RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid request body",
		})
	}

	resp, err := h.authSvc.Register(c.Context(), req)
	if err != nil {
		return handleError(c, err)
	}

	return c.Status(fiber.StatusCreated).JSON(resp)
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req dto.LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid request body",
		})
	}

	resp, err := h.authSvc.Login(c.Context(), req)
	if err != nil {
		return handleError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(resp)
}

func (h *AuthHandler) Refresh(c *fiber.Ctx) error {
	var req dto.RefreshRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid request body",
		})
	}

	resp, err := h.authSvc.Refresh(c.Context(), req)
	if err != nil {
		return handleError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(resp)
}

func (h *AuthHandler) Logout(c *fiber.Ctx) error {
	var req dto.LogoutRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid request body",
		})
	}

	err := h.authSvc.Logout(c.Context(), req)
	if err != nil {
		return handleError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Logged out successfully",
	})
}

func handleError(c *fiber.Ctx, err error) error {
	switch err {
	case service.ErrValidationError:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Input validation failed",
		})
	case service.ErrEmailTaken:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "email_taken",
			"message": "Email is already registered",
		})
	case service.ErrUsernameTaken:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "username_taken",
			"message": "Username is already taken",
		})
	case service.ErrInvalidCredentials:
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "invalid_credentials",
			"message": "Invalid email or password",
		})
	case service.ErrInvalidRefreshToken:
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "invalid_refresh_token",
			"message": "Invalid refresh token",
		})
	case service.ErrRefreshTokenNotFound:
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "refresh_token_not_found",
			"message": "Refresh token not found or already invalidated",
		})
	case service.ErrRefreshTokenExpired:
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "refresh_token_expired",
			"message": "Refresh token has expired",
		})
	default:
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "internal_error",
			"message": err.Error(),
		})
	}
}
