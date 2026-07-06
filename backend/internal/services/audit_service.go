package services

import (
	"encoding/json"
	"fmt"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"github.com/rs/zerolog/log"
)

type AuditService struct {
	repo *repository.AuditLogRepo
}

func NewAuditService(repo *repository.AuditLogRepo) *AuditService {
	return &AuditService{repo: repo}
}

func (s *AuditService) LogAction(userID uuid.UUID, userName, userRole, action, entityType, entityID, details string) {
	detailsBytes, err := json.Marshal(map[string]string{"description": details})
	if err != nil {
		log.Warn().Err(err).Msg("audit: failed to marshal details")
		detailsBytes = []byte(fmt.Sprintf(`{"description":"%s"}`, details))
	}

	logEntry := &models.AuditLog{
		AdminID:    userID,
		AdminName:  userName,
		AdminRole:  userRole,
		Action:     action,
		EntityType: entityType,
		EntityID:   entityID,
		Details:    string(detailsBytes),
	}

	if err := s.repo.Create(logEntry); err != nil {
		log.Warn().Err(err).Str("action", action).Msg("audit: failed to persist log")
	}
}
