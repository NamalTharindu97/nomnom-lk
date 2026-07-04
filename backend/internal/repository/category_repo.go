package repository

import (
	"github.com/google/uuid"
	"github.com/nomnom-lk/backend/internal/models"
	"gorm.io/gorm"
)

type CategoryRepo struct {
	db *gorm.DB
}

func NewCategoryRepo(db *gorm.DB) *CategoryRepo {
	return &CategoryRepo{db: db}
}

func (r *CategoryRepo) Create(cat *models.Category) error {
	return r.db.Create(cat).Error
}

func (r *CategoryRepo) FindAll() ([]models.Category, error) {
	var categories []models.Category
	err := r.db.Order("name ASC").Find(&categories).Error
	return categories, err
}

func (r *CategoryRepo) FindByID(id uuid.UUID) (*models.Category, error) {
	var cat models.Category
	err := r.db.Where("id = ?", id).First(&cat).Error
	if err != nil {
		return nil, err
	}
	return &cat, nil
}

func (r *CategoryRepo) Update(cat *models.Category) error {
	return r.db.Save(cat).Error
}

func (r *CategoryRepo) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.Category{}, id).Error
}
