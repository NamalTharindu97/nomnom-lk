package services

import (
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestAuditService_LogAction_Success(t *testing.T) {
	repo := newMockAuditLogRepo()
	svc := NewAuditService(repo)

	svc.LogAction(uuid.New(), "Admin User", "admin", "restaurant.create", "restaurant", uuid.New().String(), "Created restaurant")

	require.Len(t, repo.logs, 1)
	assert.Equal(t, "restaurant.create", repo.logs[0].Action)
	assert.Equal(t, "restaurant", repo.logs[0].EntityType)
	assert.Equal(t, "Admin User", repo.logs[0].AdminName)
}

func TestAuditService_LogAction_WithRole(t *testing.T) {
	repo := newMockAuditLogRepo()
	svc := NewAuditService(repo)

	svc.LogAction(uuid.New(), "Admin", "admin", "user.suspend", "user", uuid.New().String(), "Suspended user")

	require.Len(t, repo.logs, 1)
	assert.Equal(t, "admin", repo.logs[0].AdminRole)
}

func TestAuditService_LogAction_EmptyDetails(t *testing.T) {
	repo := newMockAuditLogRepo()
	svc := NewAuditService(repo)

	svc.LogAction(uuid.New(), "Admin", "admin", "auth.login", "user", uuid.New().String(), "")

	require.Len(t, repo.logs, 1)
	assert.Contains(t, repo.logs[0].Details, "description")
}
