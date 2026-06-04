-- CircleStream Initial Schema
-- Migration: 001_initial

PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    username      TEXT    NOT NULL UNIQUE,
    email         TEXT    NOT NULL UNIQUE,
    password_hash TEXT    NOT NULL,
    created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_users_email    ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- Circles table
CREATE TABLE IF NOT EXISTS circles (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    name       TEXT    NOT NULL,
    owner_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_circles_owner ON circles(owner_id);

-- Circle members table
CREATE TABLE IF NOT EXISTS circle_members (
    circle_id INTEGER NOT NULL REFERENCES circles(id) ON DELETE CASCADE,
    user_id   INTEGER NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
    role      TEXT    NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
    joined_at TEXT    NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (circle_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_circle_members_user   ON circle_members(user_id);
CREATE INDEX IF NOT EXISTS idx_circle_members_circle ON circle_members(circle_id);

-- Invite codes table
CREATE TABLE IF NOT EXISTS invite_codes (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    circle_id  INTEGER NOT NULL REFERENCES circles(id) ON DELETE CASCADE,
    code       TEXT    NOT NULL UNIQUE,
    is_active  INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    expires_at TEXT    NULL,
    max_uses   INTEGER NULL,
    used_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_invite_codes_code   ON invite_codes(code);
CREATE INDEX IF NOT EXISTS idx_invite_codes_circle ON invite_codes(circle_id);

-- Posts table
CREATE TABLE IF NOT EXISTS posts (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    circle_id     INTEGER NOT NULL REFERENCES circles(id) ON DELETE CASCADE,
    user_id       INTEGER NOT NULL REFERENCES users(id)   ON DELETE SET NULL,
    image_url     TEXT    NOT NULL,
    thumbnail_url TEXT    NULL,
    created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_posts_circle ON posts(circle_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_user   ON posts(user_id);

-- Reactions table
CREATE TABLE IF NOT EXISTS reactions (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    post_id    INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emoji      TEXT    NOT NULL,
    created_at TEXT    NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_reactions_post ON reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_reactions_user ON reactions(user_id);
