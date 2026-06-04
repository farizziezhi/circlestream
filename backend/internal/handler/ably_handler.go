package handler

import (
	"strconv"

	"github.com/farizziezhi/circlestream/backend/internal/pkg/ably"
	"github.com/farizziezhi/circlestream/backend/internal/repository"
	"github.com/gofiber/fiber/v2"
)

type AblyHandler struct {
	ablyClient *ably.AblyClient
	circleRepo repository.CircleRepository
}

func NewAblyHandler(ablyClient *ably.AblyClient, circleRepo repository.CircleRepository) *AblyHandler {
	return &AblyHandler{
		ablyClient: ablyClient,
		circleRepo: circleRepo,
	}
}

func (h *AblyHandler) GenerateToken(c *fiber.Ctx) error {
	userIDVal := c.Locals("user_id")
	if userIDVal == nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error":   "unauthorized",
			"message": "Missing user authentication context",
		})
	}
	userID := userIDVal.(int64)

	circleIDStr := c.Query("circle_id")
	circleID, err := strconv.ParseInt(circleIDStr, 10, 64)
	if err != nil || circleID <= 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid circle_id",
		})
	}

	isMember, err := h.circleRepo.IsMember(c.Context(), circleID, userID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "internal_error",
			"message": err.Error(),
		})
	}

	if !isMember {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "not_member",
			"message": "You are not a member of this circle",
		})
	}

	token, err := h.ablyClient.GenerateToken(circleID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "internal_error",
			"message": err.Error(),
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"token":   token,
		"expires": 3600, // 1 hour in seconds
	})
}
