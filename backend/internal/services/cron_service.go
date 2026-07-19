package services

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"github.com/nomnom-lk/backend/internal/repository"
	"gorm.io/gorm"
)

type CronService struct {
	db               *gorm.DB
	notificationSvc  *NotificationService
	notificationRepo *repository.NotificationRepo
	scheduledRepo    *repository.ScheduledNotificationRepo
	auditLogRepo     *repository.AuditLogRepo
}

func NewCronService(db *gorm.DB, notificationSvc *NotificationService, notificationRepo *repository.NotificationRepo) *CronService {
	return &CronService{
		db:               db,
		notificationSvc:  notificationSvc,
		notificationRepo: notificationRepo,
	}
}

func (s *CronService) SetAuditLogRepo(repo *repository.AuditLogRepo) {
	s.auditLogRepo = repo
}

func (s *CronService) SetScheduledRepo(repo *repository.ScheduledNotificationRepo) {
	s.scheduledRepo = repo
}

func (s *CronService) MarkExpiredOffers() {
	var expiredIDs []uuid.UUID
	s.db.Model(&models.Offer{}).
		Where("status = ? AND end_date < NOW()", models.OfferApproved).
		Pluck("id", &expiredIDs)

	if len(expiredIDs) > 0 {
		result := s.db.Model(&models.Offer{}).
			Where("id IN ?", expiredIDs).
			Update("status", models.OfferExpired)
		if result.Error != nil {
			fmt.Printf("CRON: failed to mark expired offers: %v\n", result.Error)
			return
		}
		fmt.Printf("CRON: marked %d offers as expired\n", result.RowsAffected)
		offerIDStrings := make([]string, len(expiredIDs))
		for i, id := range expiredIDs {
			offerIDStrings[i] = id.String()
		}
		if err := s.db.Model(&models.Banner{}).
			Where("offer_id IN ? OR (link_type = 'offer' AND link_value IN ?)", expiredIDs, offerIDStrings).
			Update("status", models.BannerRejected).Error; err != nil {
			fmt.Printf("CRON: failed to deactivate banners for expired offers: %v\n", err)
		}

		if err := s.notificationRepo.DeleteByOfferIDs(expiredIDs); err != nil {
			fmt.Printf("CRON: failed to delete notifications for expired offers: %v\n", err)
		} else {
			fmt.Printf("CRON: deleted notifications for %d expired offers\n", len(expiredIDs))
		}
	}
}

func (s *CronService) NotifyExpiringSoon() {
	window := 24 * time.Hour
	now := time.Now()

	var offers []models.Offer
	err := s.db.Preload("Restaurant").
		Where("status = ?", models.OfferApproved).
		Where("end_date BETWEEN ? AND ?", now, now.Add(window)).
		Find(&offers).Error
	if err != nil {
		fmt.Printf("CRON: failed to fetch expiring offers: %v\n", err)
		return
	}

	for _, offer := range offers {
		title := fmt.Sprintf("Offer ending soon: %s", offer.Title)
		body := fmt.Sprintf("The offer at %s expires %s. Grab it now!",
			offer.Restaurant.Name,
			offer.EndDate.Format("Jan 2, 3:04 PM"),
		)

		var userIDs []uuid.UUID
		s.db.Model(&models.Favorite{}).
			Where("offer_id = ?", offer.ID).
			Pluck("user_id", &userIDs)

		for _, userID := range userIDs {
			s.notificationSvc.SendPush(SendPushInput{
				Title:   title,
				Body:    body,
				Type:    "offer_expiring",
				UserID:  &userID,
				OfferID: &offer.ID,
			})
		}
	}
}

func (s *CronService) ProcessScheduledNotifications() {
	if s.scheduledRepo == nil {
		return
	}

	due, err := s.scheduledRepo.FindDue()
	if err != nil {
		fmt.Printf("CRON: failed to find due notifications: %v\n", err)
		return
	}

	for _, n := range due {
		input := SendPushInput{
			Title: n.Title,
			Body:  n.Body,
			Type:  "admin",
		}
		if n.UserID != nil {
			input.UserID = n.UserID
		}
		if n.OfferID != nil {
			input.OfferID = n.OfferID
		}

		if err := s.notificationSvc.SendPush(input); err != nil {
			s.scheduledRepo.MarkFailed(n.ID)
			continue
		}
		s.scheduledRepo.MarkSent(n.ID)
	}
	fmt.Printf("CRON: processed %d scheduled notifications\n", len(due))
}

func (s *CronService) ProcessScheduledPublishes() {
	var offers []models.Offer
	s.db.Model(&models.Offer{}).
		Where("status = ? AND publish_at IS NOT NULL AND publish_at <= NOW()", models.OfferPending).
		Find(&offers)

	for _, offer := range offers {
		s.db.Model(&offer).Update("status", models.OfferApproved)
	}

	if len(offers) > 0 {
		fmt.Printf("CRON: auto-published %d scheduled offers\n", len(offers))
	}
}

func (s *CronService) PruneAuditLogs() {
	if s.auditLogRepo == nil {
		return
	}
	err := s.auditLogRepo.DeleteOlderThan(7)
	if err != nil {
		fmt.Printf("CRON: failed to prune audit logs: %v\n", err)
		return
	}
	fmt.Println("CRON: pruned audit logs older than 7 days")
}

func (s *CronService) RunAll() {
	s.MarkExpiredOffers()
	s.NotifyExpiringSoon()
	s.ProcessScheduledNotifications()
	s.ProcessScheduledPublishes()
	s.PruneAuditLogs()
}
