package handler

import (
	"errors"
	"strconv"

	"github.com/farizziezhi/circlestream/backend/internal/dto"
	"github.com/farizziezhi/circlestream/backend/internal/service"
	"github.com/gofiber/fiber/v2"
)

type ReactionHandler struct {
	reactionSvc service.ReactionService
}

func NewReactionHandler(reactionSvc service.ReactionService) *ReactionHandler {
	return &ReactionHandler{reactionSvc: reactionSvc}
}

func (h *ReactionHandler) AddReaction(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(int64)

	postID, err := strconv.ParseInt(c.Params("post_id"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid post_id",
		})
	}

	var req dto.AddReactionRequest
	if err := c.BodyParser(&req); err != nil || req.Emoji == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid request body or missing emoji",
		})
	}

	resp, err := h.reactionSvc.AddReaction(c.Context(), userID, postID, req.Emoji)
	if err != nil {
		return handleReactionError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(resp)
}

func (h *ReactionHandler) GetReactions(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(int64)

	postID, err := strconv.ParseInt(c.Params("post_id"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid post_id",
		})
	}

	resp, err := h.reactionSvc.GetReactions(c.Context(), userID, postID)
	if err != nil {
		return handleReactionError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(resp)
}

func handleReactionError(c *fiber.Ctx, err error) error {
	if errors.Is(err, service.ErrInvalidEmoji) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "invalid_emoji",
			"message": "Emoji is not in the whitelist preset",
		})
	}
	if errors.Is(err, service.ErrPostNotFound) {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error":   "post_not_found",
			"message": "Post not found",
		})
	}
	if errors.Is(err, service.ErrNotCircleMember) || err.Error() == "not_member" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "not_member",
			"message": "You are not a member of this circle",
		})
	}

	return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
		"error":   "internal_error",
		"message": err.Error(),
	})
}
