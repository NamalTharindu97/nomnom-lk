package services

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type CronService struct {
	db              *gorm.DB
	notificationSvc *NotificationService
}

func NewCronService(db *gorm.DB, notificationSvc *NotificationService) *CronService {
	return &CronService{
		db:              db,
		notificationSvc: notificationSvc,
	}
}

func (s *CronService) MarkExpiredOffers() {
	result := s.db.Model(&models.Offer{}).
		Where("status = ? AND end_date < NOW()", models.OfferApproved).
		Update("status", models.OfferExpired)

	if result.Error != nil {
		fmt.Printf("CRON: failed to mark expired offers: %v\n", result.Error)
		return
	}

	if result.RowsAffected > 0 {
		fmt.Printf("CRON: marked %d offers as expired\n", result.RowsAffected)
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
				Title:  title,
				Body:   body,
				Type:   "offer_expiring",
				UserID: &userID,
			})
		}
	}
}

func (s *CronService) RunAll() {
	s.MarkExpiredOffers()
	s.NotifyExpiringSoon()
}
