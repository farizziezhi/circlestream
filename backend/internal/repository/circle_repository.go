package repository

import (
	"context"
	"database/sql"
	"time"

	"github.com/farizziezhi/circlestream/backend/internal/model"
)

type CircleMemberWithUser struct {
	CircleID int64     `db:"circle_id"`
	UserID   int64     `db:"user_id"`
	Role     string    `db:"role"`
	JoinedAt time.Time `db:"joined_at"`
	Username string    `db:"username"`
}

type CircleWithMemberCount struct {
	ID          int64     `db:"id"`
	Name        string    `db:"name"`
	OwnerID     int64     `db:"owner_id"`
	MemberCount int       `db:"member_count"`
	CreatedAt   time.Time `db:"created_at"`
}

type CircleRepository interface {
	CreateCircle(ctx context.Context, tx *sql.Tx, circle *model.Circle) error
	FindByID(ctx context.Context, id int64) (*model.Circle, error)
	GetMemberCount(ctx context.Context, id int64) (int, error)
	AddMember(ctx context.Context, tx *sql.Tx, member *model.CircleMember) error
	RemoveMember(ctx context.Context, circleID, userID int64) error
	GetMembers(ctx context.Context, circleID int64) ([]CircleMemberWithUser, error)
	IsMember(ctx context.Context, circleID, userID int64) (bool, error)
	GetMemberRole(ctx context.Context, circleID, userID int64) (string, error)
	GetUserCircles(ctx context.Context, userID int64) ([]CircleWithMemberCount, error)
}

type circleRepository struct {
	db *sql.DB
}

func NewCircleRepository(db *sql.DB) CircleRepository {
	return &circleRepository{db: db}
}

type dbExecutor interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
	QueryContext(ctx context.Context, query string, args ...any) (*sql.Rows, error)
	QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row
}

func (r *circleRepository) getExecutor(tx *sql.Tx) dbExecutor {
	if tx != nil {
		return tx
	}
	return r.db
}

func (r *circleRepository) CreateCircle(ctx context.Context, tx *sql.Tx, circle *model.Circle) error {
	exec := r.getExecutor(tx)
	query := "INSERT INTO circles (name, owner_id) VALUES (?, ?)"
	result, err := exec.ExecContext(ctx, query, circle.Name, circle.OwnerID)
	if err != nil {
		return err
	}
	id, err := result.LastInsertId()
	if err != nil {
		return err
	}
	circle.ID = id
	return nil
}

func (r *circleRepository) FindByID(ctx context.Context, id int64) (*model.Circle, error) {
	query := "SELECT id, name, owner_id, created_at FROM circles WHERE id = ?"
	row := r.db.QueryRowContext(ctx, query, id)
	var circle model.Circle
	var createdAtStr string
	err := row.Scan(&circle.ID, &circle.Name, &circle.OwnerID, &createdAtStr)
	if err != nil {
		return nil, err
	}
	circle.CreatedAt = parseSQLiteTime(createdAtStr)
	return &circle, nil
}

func (r *circleRepository) GetMemberCount(ctx context.Context, id int64) (int, error) {
	query := "SELECT COUNT(*) FROM circle_members WHERE circle_id = ?"
	var count int
	err := r.db.QueryRowContext(ctx, query, id).Scan(&count)
	return count, err
}

func (r *circleRepository) AddMember(ctx context.Context, tx *sql.Tx, member *model.CircleMember) error {
	exec := r.getExecutor(tx)
	query := "INSERT INTO circle_members (circle_id, user_id, role) VALUES (?, ?, ?)"
	_, err := exec.ExecContext(ctx, query, member.CircleID, member.UserID, member.Role)
	return err
}

func (r *circleRepository) RemoveMember(ctx context.Context, circleID, userID int64) error {
	query := "DELETE FROM circle_members WHERE circle_id = ? AND user_id = ?"
	_, err := r.db.ExecContext(ctx, query, circleID, userID)
	return err
}

func (r *circleRepository) GetMembers(ctx context.Context, circleID int64) ([]CircleMemberWithUser, error) {
	query := `
		SELECT cm.circle_id, cm.user_id, cm.role, cm.joined_at, u.username
		FROM circle_members cm
		JOIN users u ON cm.user_id = u.id
		WHERE cm.circle_id = ?
		ORDER BY cm.joined_at ASC
	`
	rows, err := r.db.QueryContext(ctx, query, circleID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var members []CircleMemberWithUser
	for rows.Next() {
		var m CircleMemberWithUser
		var joinedAtStr string
		err := rows.Scan(&m.CircleID, &m.UserID, &m.Role, &joinedAtStr, &m.Username)
		if err != nil {
			return nil, err
		}
		m.JoinedAt = parseSQLiteTime(joinedAtStr)
		members = append(members, m)
	}
	return members, nil
}

func (r *circleRepository) IsMember(ctx context.Context, circleID, userID int64) (bool, error) {
	query := "SELECT COUNT(*) FROM circle_members WHERE circle_id = ? AND user_id = ?"
	var count int
	err := r.db.QueryRowContext(ctx, query, circleID, userID).Scan(&count)
	return count > 0, err
}

func (r *circleRepository) GetMemberRole(ctx context.Context, circleID, userID int64) (string, error) {
	query := "SELECT role FROM circle_members WHERE circle_id = ? AND user_id = ?"
	var role string
	err := r.db.QueryRowContext(ctx, query, circleID, userID).Scan(&role)
	if err == sql.ErrNoRows {
		return "", nil
	}
	return role, err
}

func (r *circleRepository) GetUserCircles(ctx context.Context, userID int64) ([]CircleWithMemberCount, error) {
	query := `
		SELECT c.id, c.name, c.owner_id,
			(SELECT COUNT(*) FROM circle_members WHERE circle_id = c.id) AS member_count,
			c.created_at
		FROM circles c
		JOIN circle_members cm ON c.id = cm.circle_id
		WHERE cm.user_id = ?
		ORDER BY c.created_at DESC
	`
	rows, err := r.db.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var circles []CircleWithMemberCount
	for rows.Next() {
		var c CircleWithMemberCount
		var createdAtStr string
		err := rows.Scan(&c.ID, &c.Name, &c.OwnerID, &c.MemberCount, &createdAtStr)
		if err != nil {
			return nil, err
		}
		c.CreatedAt = parseSQLiteTime(createdAtStr)
		circles = append(circles, c)
	}
	return circles, nil
}
