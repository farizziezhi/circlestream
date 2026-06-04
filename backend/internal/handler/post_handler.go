package handler

import (
	"errors"
	"strconv"
	"time"

	"github.com/farizziezhi/circlestream/backend/internal/service"
	"github.com/gofiber/fiber/v2"
)

type PostHandler struct {
	postSvc service.PostService
}

func NewPostHandler(postSvc service.PostService) *PostHandler {
	return &PostHandler{postSvc: postSvc}
}

func (h *PostHandler) GetFeed(c *fiber.Ctx) error {
	var circleID int64
	if val := c.Locals("circle_id"); val != nil {
		circleID = val.(int64)
	} else {
		id, err := strconv.ParseInt(c.Params("circle_id"), 10, 64)
		if err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error":   "validation_error",
				"message": "Invalid circle_id",
			})
		}
		circleID = id
	}

	limit := 20
	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}

	var cursor *time.Time
	if cursorStr := c.Query("cursor"); cursorStr != "" {
		t, err := time.Parse(time.RFC3339, cursorStr)
		if err != nil {
			// Fallback to SQLite format in case format was simplified
			t, err = time.Parse("2006-01-02 15:04:05", cursorStr)
			if err != nil {
				return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
					"error":   "validation_error",
					"message": "Invalid cursor format, must be RFC3339 timestamp",
				})
			}
		}
		cursor = &t
	}

	resp, err := h.postSvc.GetFeed(c.Context(), circleID, cursor, limit)
	if err != nil {
		return handlePostError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(resp)
}

func (h *PostHandler) GetPost(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(int64)

	postID, err := strconv.ParseInt(c.Params("post_id"), 10, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid post_id",
		})
	}

	resp, err := h.postSvc.GetPost(c.Context(), userID, postID)
	if err != nil {
		return handlePostError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"post": resp,
	})
}

func handlePostError(c *fiber.Ctx, err error) error {
	if errors.Is(err, service.ErrNotCircleMember) || err.Error() == "not_member" {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "not_member",
			"message": "You are not a member of this circle",
		})
	}

	switch err.Error() {
	case "post_not_found":
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error":   "post_not_found",
			"message": "Post not found",
		})
	default:
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "internal_error",
			"message": err.Error(),
		})
	}
}
