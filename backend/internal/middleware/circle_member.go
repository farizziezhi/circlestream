package middleware

import (
	"strconv"

	"github.com/farizziezhi/circlestream/backend/internal/repository"
	"github.com/gofiber/fiber/v2"
)

func RequireCircleMember(circleRepo repository.CircleRepository) fiber.Handler {
	return func(c *fiber.Ctx) error {
		userIDVal := c.Locals("user_id")
		if userIDVal == nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":   "unauthorized",
				"message": "Missing user authentication context",
			})
		}
		userID := userIDVal.(int64)

		circleIDStr := c.Params("circle_id")
		circleID, err := strconv.ParseInt(circleIDStr, 10, 64)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "validation_error",
				"message": "Invalid circle ID format",
			})
		}

		isMember, err := circleRepo.IsMember(c.Context(), circleID, userID)
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

		c.Locals("circle_id", circleID)
		return c.Next()
	}
}
