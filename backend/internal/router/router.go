package router

import (
	"database/sql"

	"github.com/farizziezhi/circlestream/backend/internal/config"
	"github.com/farizziezhi/circlestream/backend/internal/handler"
	"github.com/farizziezhi/circlestream/backend/internal/middleware"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/ably"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/r2"
	"github.com/farizziezhi/circlestream/backend/internal/pkg/redis"
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
	circleRepo := repository.NewCircleRepository(db)
	inviteRepo := repository.NewInviteRepository(db)
	postRepo := repository.NewPostRepository(db)
	reactionRepo := repository.NewReactionRepository(db)

	// Clients
	ablyClient, err := ably.NewClient(cfg)
	if err != nil {
		panic("failed to initialize ably client: " + err.Error())
	}

	r2Client, err := r2.NewClient(cfg)
	if err != nil {
		panic("failed to initialize r2 client: " + err.Error())
	}

	redisClient := redis.NewClient(cfg)

	// Services
	authSvc := service.NewAuthService(userRepo, tokenRepo, cfg)
	circleSvc := service.NewCircleService(db, circleRepo, inviteRepo, userRepo, ablyClient)
	mediaSvc := service.NewMediaService(r2Client, postRepo, circleRepo, userRepo, ablyClient, cfg)
	postSvc := service.NewPostService(postRepo, circleRepo, redisClient)
	reactionSvc := service.NewReactionService(redisClient, reactionRepo, postRepo, circleRepo, ablyClient)

	// Handlers
	authHandler := handler.NewAuthHandler(authSvc)
	circleHandler := handler.NewCircleHandler(circleSvc)
	ablyHandler := handler.NewAblyHandler(ablyClient, circleRepo)
	mediaHandler := handler.NewMediaHandler(mediaSvc)
	postHandler := handler.NewPostHandler(postSvc)
	reactionHandler := handler.NewReactionHandler(reactionSvc)

	api := app.Group("/v1")

	// Auth rate limiter
	authLimiter := middleware.AuthRateLimiter()

	auth := api.Group("/auth")
	auth.Post("/register", authLimiter, authHandler.Register)
	auth.Post("/login", authLimiter, authHandler.Login)
	auth.Post("/refresh", authHandler.Refresh)
	auth.Post("/logout", middleware.Auth(cfg), authHandler.Logout)

	// Protected routes group (requires Auth)
	protected := api.Group("", middleware.Auth(cfg))

	// Ably Token route
	protected.Get("/ably/token", ablyHandler.GenerateToken)

	// Media upload routes
	protected.Post("/media/presign-upload", mediaHandler.PresignUpload)
	protected.Post("/media/finalize", mediaHandler.Finalize)

	// Circle routes
	protected.Post("/circles", circleHandler.Create)
	protected.Post("/circles/join", circleHandler.Join)

	// Circle-scoped routes (requires circle membership check)
	circleScoped := protected.Group("/circles/:circle_id", middleware.RequireCircleMember(circleRepo))
	circleScoped.Get("/", circleHandler.Detail)
	circleScoped.Get("/members", circleHandler.Members)
	circleScoped.Post("/leave", circleHandler.Leave)
	circleScoped.Get("/posts", postHandler.GetFeed)

	// Owner scoped routes (requires circle owner check)
	ownerScoped := circleScoped.Group("", middleware.RequireCircleOwner(circleRepo))
	ownerScoped.Get("/invite-codes", circleHandler.ListInviteCodes)
	ownerScoped.Post("/invite-codes", circleHandler.CreateInviteCode)

	// Single post route (membership validated inside handler/service)
	protected.Get("/posts/:post_id", postHandler.GetPost)

	// Reaction routes (membership validated inside service)
	protected.Post("/posts/:post_id/reactions", reactionHandler.AddReaction)
	protected.Get("/posts/:post_id/reactions", reactionHandler.GetReactions)

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		dbErr := db.PingContext(c.Context())
		redisErr := redisClient.Ping(c.Context())

		status := "ok"
		dbStatus := "connected"
		redisStatus := "connected"

		if dbErr != nil {
			status = "error"
			dbStatus = dbErr.Error()
		}
		if redisErr != nil {
			status = "error"
			redisStatus = redisErr.Error()
		}

		statusCode := fiber.StatusOK
		if status != "ok" {
			statusCode = fiber.StatusInternalServerError
		}

		return c.Status(statusCode).JSON(fiber.Map{
			"status":   status,
			"database": dbStatus,
			"redis":    redisStatus,
		})
	})
}
