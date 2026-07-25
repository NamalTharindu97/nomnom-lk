package repository

import (
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type CuisineTagRepo struct {
	db *gorm.DB
}

func NewCuisineTagRepo(db *gorm.DB) *CuisineTagRepo {
	return &CuisineTagRepo{db: db}
}

func (r *CuisineTagRepo) FindAll() ([]models.CuisineTag, error) {
	var tags []models.CuisineTag
	err := r.db.Order("name ASC").Find(&tags).Error
	return tags, err
}

func (r *CuisineTagRepo) Create(tag *models.CuisineTag) error {
	return r.db.Create(tag).Error
}

func (r *CuisineTagRepo) Update(id uuid.UUID, name string) error {
	return r.db.Model(&models.CuisineTag{}).Where("id = ?", id).Update("name", name).Error
}

func (r *CuisineTagRepo) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.CuisineTag{}, id).Error
}
