package database

import (
	"database/sql"
	"fmt"

	_ "github.com/tursodatabase/libsql-client-go/libsql"
)

func NewTursoClient(url, token string) (*sql.DB, error) {
	dsn := fmt.Sprintf("%s?authToken=%s", url, token)
	db, err := sql.Open("libsql", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Connection pool settings
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Enable WAL mode and foreign keys
	db.Exec("PRAGMA journal_mode = WAL")
	db.Exec("PRAGMA foreign_keys = ON")

	return db, nil
}
