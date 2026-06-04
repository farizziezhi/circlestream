package handler

import (
	"github.com/farizziezhi/circlestream/backend/internal/dto"
	"github.com/farizziezhi/circlestream/backend/internal/service"
	"github.com/gofiber/fiber/v2"
)

type CircleHandler struct {
	circleSvc service.CircleService
}

func NewCircleHandler(circleSvc service.CircleService) *CircleHandler {
	return &CircleHandler{circleSvc: circleSvc}
}

func (h *CircleHandler) Create(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(int64)

	var req dto.CreateCircleRequest
	if err := c.BodyParser(&req); err != nil || req.Name == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid circle name",
		})
	}

	resp, err := h.circleSvc.CreateCircle(c.Context(), userID, req.Name)
	if err != nil {
		return handleCircleError(c, err)
	}

	return c.Status(fiber.StatusCreated).JSON(resp)
}

func (h *CircleHandler) Join(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(int64)

	var req dto.JoinCircleRequest
	if err := c.BodyParser(&req); err != nil || req.InviteCode == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid invite code",
		})
	}

	resp, err := h.circleSvc.JoinCircle(c.Context(), userID, req.InviteCode)
	if err != nil {
		return handleCircleError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(resp)
}

func (h *CircleHandler) Detail(c *fiber.Ctx) error {
	circleID := c.Locals("circle_id").(int64)

	detail, err := h.circleSvc.GetDetail(c.Context(), circleID)
	if err != nil {
		return handleCircleError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"circle": detail,
	})
}

func (h *CircleHandler) Members(c *fiber.Ctx) error {
	circleID := c.Locals("circle_id").(int64)

	members, err := h.circleSvc.GetMembers(c.Context(), circleID)
	if err != nil {
		return handleCircleError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"members": members,
	})
}

func (h *CircleHandler) Leave(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(int64)
	circleID := c.Locals("circle_id").(int64)

	err := h.circleSvc.LeaveCircle(c.Context(), userID, circleID)
	if err != nil {
		return handleCircleError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"message": "Left circle successfully",
	})
}

func (h *CircleHandler) CreateInviteCode(c *fiber.Ctx) error {
	circleID := c.Locals("circle_id").(int64)

	var req dto.CreateInviteCodeRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "validation_error",
			"message": "Invalid request body",
		})
	}

	resp, err := h.circleSvc.CreateInviteCode(c.Context(), circleID, req.MaxUses, req.ExpiresAt)
	if err != nil {
		return handleCircleError(c, err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"invite_code": resp,
	})
}

func (h *CircleHandler) ListInviteCodes(c *fiber.Ctx) error {
	circleID := c.Locals("circle_id").(int64)

	invites, err := h.circleSvc.ListInviteCodes(c.Context(), circleID)
	if err != nil {
		return handleCircleError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"invite_codes": invites,
	})
}

func handleCircleError(c *fiber.Ctx, err error) error {
	switch err {
	case service.ErrCircleNotFound:
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error":   "circle_not_found",
			"message": "Circle not found",
		})
	case service.ErrInviteNotFound:
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error":   "invite_code_not_found",
			"message": "Invite code is invalid or deactivated",
		})
	case service.ErrInviteExpired:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "invite_code_expired",
			"message": "Invite code has expired",
		})
	case service.ErrInviteExhausted:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "invite_code_exhausted",
			"message": "Invite code use limit reached",
		})
	case service.ErrCircleFull:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "circle_full",
			"message": "Circle member capacity reached",
		})
	case service.ErrAlreadyMember:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "already_member",
			"message": "You are already a member of this circle",
		})
	case service.ErrOwnerCannotLeave:
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error":   "owner_cannot_leave",
			"message": "Owner cannot leave without transferring ownership or deleting the circle",
		})
	case service.ErrNotCircleMember:
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"error":   "not_member",
			"message": "You are not a member of this circle",
		})
	default:
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error":   "internal_error",
			"message": err.Error(),
		})
	}
}
