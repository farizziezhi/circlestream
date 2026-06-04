package handler

import (
	"github.com/farizziezhi/circlestream/backend/internal/dto"
	"github.com/farizziezhi/circlestream/backend/internal/service"
	"github.com/gofiber/fiber/v2"
)

type MediaHandler struct {
	mediaSvc service.MediaService
}

func NewMediaHandler(mediaSvc service.MediaService) *MediaHandler {
	return &MediaHandler{mediaSvc: mediaSvc}
}

func (h *MediaHandler) PresignUpload(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(int64)

	var req dto.PresignUploadRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid request body",
		})
	}

	if req.CircleID <= 0 || req.Filename == "" || req.ContentType == "" || req.FileSize <= 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Missing required fields",
		})
	}

	resp, err := h.mediaSvc.PresignUpload(c.Context(), userID, req.CircleID, req)
	if err != nil {
		return handleMediaError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(resp)
}

func (h *MediaHandler) Finalize(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(int64)

	var req dto.FinalizeUploadRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid request body",
		})
	}

	if req.CircleID <= 0 || req.ObjectKey == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Missing required fields",
		})
	}

	resp, err := h.mediaSvc.FinalizeUpload(c.Context(), userID, req.CircleID, req)
	if err != nil {
		return handleMediaError(c, err)
	}

	return c.Status(fiber.StatusCreated).JSON(dto.FinalizeUploadResponse{
		Post: *resp,
	})
}

func handleMediaError(c *fiber.Ctx, err error) error {
	switch err {
	case service.ErrUnsupportedFileType:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "unsupported_file_type",
			"message": "Only JPG, JPEG, PNG, and WEBP formats are allowed",
		})
	case service.ErrFileTooLarge:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "file_too_large",
			"message": "File size cannot exceed 10 MB",
		})
	case service.ErrNotCircleMember:
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "not_member",
			"message": "You are not a member of this circle",
		})
	case service.ErrKeyMismatch:
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "object_key_mismatch",
			"message": "Object key is not valid for this circle",
		})
	default:
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "internal_error",
			"message": err.Error(),
		})
	}
}
