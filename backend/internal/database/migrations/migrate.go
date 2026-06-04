package migrations

import (
	"database/sql"
	"embed"
	"log"
	"sort"
	"strings"
)

//go:embed *.sql
var migrationFiles embed.FS

func RunMigrations(db *sql.DB) {
	// Create migrations tracking table
	_, err := db.Exec(`
        CREATE TABLE IF NOT EXISTS schema_migrations (
            version TEXT PRIMARY KEY,
            applied_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
    `)
	if err != nil {
		log.Fatalf("Failed to create migrations table: %v", err)
	}

	// Read all .sql files
	entries, err := migrationFiles.ReadDir(".")
	if err != nil {
		log.Fatalf("Failed to read migration files directory: %v", err)
	}

	var files []string
	for _, e := range entries {
		if strings.HasSuffix(e.Name(), ".sql") {
			files = append(files, e.Name())
		}
	}
	sort.Strings(files)

	// Apply each migration if not already applied
	for _, filename := range files {
		version := strings.TrimSuffix(filename, ".sql")

		var count int
		db.QueryRow(
			"SELECT COUNT(*) FROM schema_migrations WHERE version = ?", version,
		).Scan(&count)

		if count > 0 {
			log.Printf("Migration %s already applied, skipping", version)
			continue
		}

		content, err := migrationFiles.ReadFile(filename)
		if err != nil {
			log.Fatalf("Failed to read migration file %s: %v", filename, err)
		}

		_, err = db.Exec(string(content))
		if err != nil {
			log.Fatalf("Failed to apply migration %s: %v", filename, err)
		}

		_, err = db.Exec(
			"INSERT INTO schema_migrations (version) VALUES (?)", version,
		)
		if err != nil {
			log.Fatalf("Failed to record migration completion %s: %v", filename, err)
		}
		log.Printf("Applied migration: %s", filename)
	}

	log.Println("All migrations applied successfully")
}
