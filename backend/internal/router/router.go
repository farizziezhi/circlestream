package router

import (
	"database/sql"

	"github.com/farizziezhi/circlestream/backend/internal/config"
	"github.com/farizziezhi/circlestream/backend/internal/handler"
	"github.com/farizziezhi/circlestream/backend/internal/middleware"
	"github.com/farizziezhi/circlestream/backend/internal/repository"
	"github.com/farizziezhi/circlestream/backend/internal/service"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/helmet"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func Setup(app *fiber.App, db *sql.DB, cfg *config.Config) {
	// Global middleware
	app.Use(recover.New())
	app.Use(helmet.New())
	app.Use(cors.New())

	// Global rate limiter
	app.Use(middleware.GlobalRateLimiter())

	// Repositories
	userRepo := repository.NewUserRepository(db)
	tokenRepo := repository.NewTokenRepository(db)

	// Services
	authSvc := service.NewAuthService(userRepo, tokenRepo, cfg)

	// Handlers
	authHandler := handler.NewAuthHandler(authSvc)

	api := app.Group("/v1")

	// Auth rate limiter
	authLimiter := middleware.AuthRateLimiter()

	auth := api.Group("/auth")
	auth.Post("/register", authLimiter, authHandler.Register)
	auth.Post("/login", authLimiter, authHandler.Login)
	auth.Post("/refresh", authHandler.Refresh)
	auth.Post("/logout", middleware.Auth(cfg), authHandler.Logout)

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok"})
	})
}
