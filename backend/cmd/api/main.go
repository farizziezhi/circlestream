package main

import (
	"log"

	"github.com/farizziezhi/circlestream/backend/internal/config"
	"github.com/farizziezhi/circlestream/backend/internal/database"
	"github.com/farizziezhi/circlestream/backend/internal/database/migrations"
	"github.com/farizziezhi/circlestream/backend/internal/router"
	"github.com/gofiber/fiber/v2"
	"github.com/joho/godotenv"
)

func main() {
	// Load .env
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using environment variables")
	}

	// Load config
	cfg := config.Load()

	// Init database
	db, err := database.NewTursoClient(cfg.TursoURL, cfg.TursoToken)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Run migrations
	migrations.RunMigrations(db)

	// Init Fiber
	app := fiber.New(fiber.Config{
		AppName:      "CircleStream API v1",
		ErrorHandler: customErrorHandler,
	})

	// Setup routes
	router.Setup(app, db, cfg)

	// Start server
	port := cfg.Port
	if port == "" {
		port = "8080"
	}

	log.Printf("CircleStream API starting on :%s", port)
	log.Fatal(app.Listen(":" + port))
}

func customErrorHandler(c *fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError
	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
	}
	return c.Status(code).JSON(fiber.Map{
		"error":   "internal_error",
		"message": err.Error(),
	})
}
