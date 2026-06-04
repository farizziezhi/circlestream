package middleware

import (
	"github.com/farizziezhi/circlestream/backend/internal/repository"
	"github.com/gofiber/fiber/v2"
)

func RequireCircleOwner(circleRepo repository.CircleRepository) fiber.Handler {
	return func(c *fiber.Ctx) error {
		userIDVal := c.Locals("user_id")
		circleIDVal := c.Locals("circle_id")
		if userIDVal == nil || circleIDVal == nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error":   "unauthorized",
				"message": "Missing authentication or circle context",
			})
		}
		userID := userIDVal.(int64)
		circleID := circleIDVal.(int64)

		role, err := circleRepo.GetMemberRole(c.Context(), circleID, userID)
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error":   "internal_error",
				"message": err.Error(),
			})
		}

		if role != "owner" {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error":   "owner_required",
				"message": "Only the circle owner can perform this action",
			})
		}

		return c.Next()
	}
}
